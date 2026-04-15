#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import logging
import os
import threading
from dataclasses import dataclass
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib.parse import urlparse

import orjson
import torch
import torch.nn.functional as F
from transformers import AutoModel, AutoTokenizer


LOGGER = logging.getLogger("openai-embeddings-cpu")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Serve a local embedding model over an OpenAI-compatible /v1/embeddings API."
    )
    parser.add_argument("model", help="Local model path or Hugging Face model id.")
    return parser.parse_args()


def env_int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None or raw == "":
        return default

    try:
        return int(raw)
    except ValueError as exc:
        raise SystemExit(f"{name} must be an integer, got: {raw}") from exc


def model_dtype_from_env() -> torch.dtype:
    dtype_name = os.getenv("VLLM_DTYPE", "float32").strip().lower()
    dtype_map = {
        "auto": torch.float32,
        "float32": torch.float32,
        "fp32": torch.float32,
        "float": torch.float32,
        "bfloat16": torch.bfloat16,
        "bf16": torch.bfloat16,
        "float16": torch.float16,
        "fp16": torch.float16,
        "half": torch.float16,
    }
    if dtype_name not in dtype_map:
        raise SystemExit(f"Unsupported VLLM_DTYPE for CPU embeddings server: {dtype_name}")
    return dtype_map[dtype_name]


def last_token_pool(last_hidden_states: torch.Tensor, attention_mask: torch.Tensor) -> torch.Tensor:
    left_padding = bool(torch.all(attention_mask[:, -1] == 1))
    if left_padding:
        return last_hidden_states[:, -1]

    sequence_lengths = attention_mask.sum(dim=1) - 1
    batch_size = last_hidden_states.shape[0]
    batch_indices = torch.arange(batch_size, device=last_hidden_states.device)
    return last_hidden_states[batch_indices, sequence_lengths]


def normalize_embeddings(embeddings: torch.Tensor) -> torch.Tensor:
    return F.normalize(embeddings, p=2, dim=1)


def json_dumps(payload: Any) -> bytes:
    return orjson.dumps(payload)


def json_loads(payload: bytes) -> Any:
    return orjson.loads(payload)


def error_payload(message: str, *, err_type: str = "invalid_request_error", param: str | None = None) -> dict[str, Any]:
    return {
        "error": {
            "message": message,
            "type": err_type,
            "param": param,
            "code": None,
        }
    }


@dataclass
class ServerConfig:
    model_arg: str
    model_name: str
    host: str
    port: int
    max_model_len: int
    batch_size: int
    api_key: str | None
    device: str
    torch_dtype: torch.dtype
    trust_remote_code: bool


class EmbeddingRuntime:
    def __init__(self, config: ServerConfig) -> None:
        self.config = config
        self.inference_lock = threading.Lock()
        self.device = torch.device(config.device)
        self.tokenizer = self._load_tokenizer()
        self.model = self._load_model()
        self.model.eval()
        self.embedding_dimension = int(getattr(self.model.config, "hidden_size", 0))
        if self.embedding_dimension <= 0:
            raise RuntimeError("Could not determine embedding dimension from the loaded model")
        self.allowed_model_names = {
            config.model_name,
            config.model_arg,
            os.path.basename(config.model_arg.rstrip("/")),
        }

        if self.tokenizer.pad_token_id is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token

    def _load_tokenizer(self) -> Any:
        local_files_only = os.path.exists(self.config.model_arg)
        return AutoTokenizer.from_pretrained(
            self.config.model_arg,
            padding_side="left",
            trust_remote_code=self.config.trust_remote_code,
            local_files_only=local_files_only,
        )

    def _load_model(self) -> Any:
        local_files_only = os.path.exists(self.config.model_arg)
        model = AutoModel.from_pretrained(
            self.config.model_arg,
            torch_dtype=self.config.torch_dtype,
            trust_remote_code=self.config.trust_remote_code,
            local_files_only=local_files_only,
        )
        return model.to(self.device)

    def validate_model_name(self, requested_model: Any) -> None:
        if requested_model in (None, ""):
            return
        if not isinstance(requested_model, str):
            raise ValueError("model must be a string")
        if requested_model not in self.allowed_model_names:
            raise ValueError(
                f"Requested model {requested_model!r} does not match the served model {self.config.model_name!r}"
            )

    def decode_token_ids(self, token_ids: list[int]) -> str:
        return self.tokenizer.decode(
            token_ids,
            skip_special_tokens=False,
            clean_up_tokenization_spaces=False,
        )

    def normalize_inputs(self, raw_input: Any) -> tuple[list[str], list[int | None]]:
        if isinstance(raw_input, str):
            return [raw_input], [None]

        if isinstance(raw_input, list):
            if not raw_input:
                raise ValueError("input must not be empty")

            if all(isinstance(item, int) for item in raw_input):
                token_ids = [int(item) for item in raw_input]
                return [self.decode_token_ids(token_ids)], [len(token_ids)]

            texts: list[str] = []
            explicit_prompt_tokens: list[int | None] = []
            for index, item in enumerate(raw_input):
                if isinstance(item, str):
                    texts.append(item)
                    explicit_prompt_tokens.append(None)
                elif isinstance(item, list) and all(isinstance(token, int) for token in item):
                    token_ids = [int(token) for token in item]
                    texts.append(self.decode_token_ids(token_ids))
                    explicit_prompt_tokens.append(len(token_ids))
                else:
                    raise ValueError(
                        f"input[{index}] must be a string or a list of token ids"
                    )
            return texts, explicit_prompt_tokens

        raise ValueError("input must be a string, a list of strings, or token id arrays")

    def embed(
        self,
        texts: list[str],
        explicit_prompt_tokens: list[int | None],
        dimensions: int | None,
    ) -> tuple[list[list[float]], int]:
        embeddings_out: list[list[float]] = []
        total_prompt_tokens = 0

        with self.inference_lock:
            for start in range(0, len(texts), self.config.batch_size):
                batch_texts = texts[start : start + self.config.batch_size]
                batch_explicit_prompt_tokens = explicit_prompt_tokens[
                    start : start + self.config.batch_size
                ]

                encoded = self.tokenizer(
                    batch_texts,
                    padding=True,
                    truncation=True,
                    max_length=self.config.max_model_len,
                    return_tensors="pt",
                )
                encoded = {key: value.to(self.device) for key, value in encoded.items()}

                prompt_token_counts = encoded["attention_mask"].sum(dim=1).tolist()
                for index, count in enumerate(prompt_token_counts):
                    explicit = batch_explicit_prompt_tokens[index]
                    total_prompt_tokens += explicit if explicit is not None else int(count)

                with torch.inference_mode():
                    outputs = self.model(**encoded)
                    pooled = last_token_pool(outputs.last_hidden_state, encoded["attention_mask"])
                    pooled = normalize_embeddings(pooled)

                    if dimensions is not None:
                        pooled = pooled[:, :dimensions]
                        pooled = normalize_embeddings(pooled)

                embeddings_out.extend(pooled.to(torch.float32).cpu().tolist())

        return embeddings_out, total_prompt_tokens


class ReusableThreadingHTTPServer(ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


class OpenAIEmbeddingsHandler(BaseHTTPRequestHandler):
    runtime: EmbeddingRuntime

    protocol_version = "HTTP/1.1"
    server_version = "OpenAIEmbeddingsCPU/1.0"

    def log_message(self, fmt: str, *args: Any) -> None:
        LOGGER.info("%s - %s", self.address_string(), fmt % args)

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path == "/health":
            self.send_json(HTTPStatus.OK, {"status": "ok"})
            return

        if path == "/v1/models":
            self.send_json(
                HTTPStatus.OK,
                {
                    "object": "list",
                    "data": [
                        {
                            "id": self.runtime.config.model_name,
                            "object": "model",
                            "owned_by": "local",
                        }
                    ],
                },
            )
            return

        self.send_json(HTTPStatus.NOT_FOUND, error_payload("Not found", err_type="not_found_error"))

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path != "/v1/embeddings":
            self.send_json(HTTPStatus.NOT_FOUND, error_payload("Not found", err_type="not_found_error"))
            return

        try:
            self.check_auth()
            body = self.read_json_body()
            payload = self.handle_embeddings_request(body)
            self.send_json(HTTPStatus.OK, payload)
        except PermissionError as exc:
            self.send_json(HTTPStatus.UNAUTHORIZED, error_payload(str(exc), err_type="authentication_error"))
        except ValueError as exc:
            self.send_json(HTTPStatus.BAD_REQUEST, error_payload(str(exc)))
        except Exception:  # noqa: BLE001
            LOGGER.exception("Unhandled embeddings server error")
            self.send_json(
                HTTPStatus.INTERNAL_SERVER_ERROR,
                error_payload("Internal server error", err_type="server_error"),
            )

    def check_auth(self) -> None:
        api_key = self.runtime.config.api_key
        if not api_key:
            return

        authorization = self.headers.get("Authorization", "")
        expected = f"Bearer {api_key}"
        if authorization != expected:
            raise PermissionError("Invalid or missing bearer token")

    def read_json_body(self) -> dict[str, Any]:
        content_length = self.headers.get("Content-Length")
        if not content_length:
            raise ValueError("Missing Content-Length header")

        length = int(content_length)
        if length <= 0:
            raise ValueError("Request body must not be empty")

        body = self.rfile.read(length)
        try:
            decoded = json_loads(body)
        except orjson.JSONDecodeError as exc:
            raise ValueError("Request body is not valid JSON") from exc

        if not isinstance(decoded, dict):
            raise ValueError("Request body must be a JSON object")
        return decoded

    def handle_embeddings_request(self, body: dict[str, Any]) -> dict[str, Any]:
        if "input" not in body:
            raise ValueError("Missing required field: input")

        dimensions = body.get("dimensions")
        if dimensions is not None:
            if not isinstance(dimensions, int):
                raise ValueError("dimensions must be an integer")
            if dimensions < 32:
                raise ValueError("dimensions must be at least 32")
            if dimensions > self.runtime.embedding_dimension:
                raise ValueError(
                    f"dimensions must be at most {self.runtime.embedding_dimension} for the loaded model"
                )

        encoding_format = body.get("encoding_format", "float")
        if encoding_format not in ("float", "base64"):
            raise ValueError("encoding_format must be 'float' or 'base64'")

        self.runtime.validate_model_name(body.get("model"))
        texts, explicit_prompt_tokens = self.runtime.normalize_inputs(body["input"])
        embeddings, prompt_tokens = self.runtime.embed(
            texts,
            explicit_prompt_tokens,
            dimensions,
        )

        response_data = []
        for index, embedding in enumerate(embeddings):
            response_embedding: list[float] | str
            if encoding_format == "base64":
                tensor = torch.tensor(embedding, dtype=torch.float32)
                response_embedding = base64.b64encode(tensor.numpy().tobytes()).decode("ascii")
            else:
                response_embedding = embedding

            response_data.append(
                {
                    "object": "embedding",
                    "index": index,
                    "embedding": response_embedding,
                }
            )

        return {
            "object": "list",
            "data": response_data,
            "model": self.runtime.config.model_name,
            "usage": {
                "prompt_tokens": prompt_tokens,
                "total_tokens": prompt_tokens,
            },
        }

    def send_json(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
        body = json_dumps(payload)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def build_runtime(model_arg: str) -> EmbeddingRuntime:
    host = os.getenv("VLLM_HOST", "127.0.0.1")
    port = env_int("VLLM_PORT", 11435)
    max_model_len = env_int("VLLM_MAX_MODEL_LEN", 8192)
    batch_size = max(1, env_int("VLLM_MAX_NUM_SEQS", 32))
    api_key = os.getenv("VLLM_API_KEY") or None
    served_model_name = os.getenv(
        "VLLM_SERVED_MODEL_NAME",
        os.getenv("EMBEDDINGS_MODEL", os.path.basename(model_arg.rstrip("/")) or model_arg),
    )
    trust_remote_code = os.getenv("VLLM_TRUST_REMOTE_CODE", "").strip().lower() in {
        "1",
        "true",
        "yes",
        "on",
    }
    threads = env_int("OMP_NUM_THREADS", 4)
    torch.set_num_threads(max(1, threads))
    os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")

    return EmbeddingRuntime(
        ServerConfig(
            model_arg=model_arg,
            model_name=served_model_name,
            host=host,
            port=port,
            max_model_len=max_model_len,
            batch_size=batch_size,
            api_key=api_key,
            device="cpu",
            torch_dtype=model_dtype_from_env(),
            trust_remote_code=trust_remote_code,
        )
    )


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    args = parse_args()
    runtime = build_runtime(args.model)
    OpenAIEmbeddingsHandler.runtime = runtime

    server = ReusableThreadingHTTPServer(
        (runtime.config.host, runtime.config.port),
        OpenAIEmbeddingsHandler,
    )
    LOGGER.info(
        "Serving embeddings model %s on http://%s:%d/v1/embeddings",
        runtime.config.model_name,
        runtime.config.host,
        runtime.config.port,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        LOGGER.info("Shutting down embeddings server")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
