"""Config-driven front door for the local LLM serving commands."""

from __future__ import annotations

import argparse
import copy
import os
import shlex
import shutil
import socket
import sys
from pathlib import Path
from typing import Any

import tomllib

CONFIG_VERSION = 1
SUPPORTED_BACKENDS = {"llama", "vllm", "embeddings-cpu", "command"}
GPU_EXPECTATIONS = {"full", "mostly-full", "partial", "cpu", "dynamic", "full+cpu"}
TARGET_KEYS = {
    "args",
    "backend",
    "batch_size",
    "cache_type_k",
    "cache_type_v",
    "command",
    "convert",
    "ctx_size",
    "description",
    "dry_multiplier",
    "dtype",
    "enable_qwen_defaults",
    "enforce_eager",
    "environment",
    "expert_parallel",
    "fit",
    "fit_ctx",
    "fit_target_mib",
    "flash_attn",
    "frequency_penalty",
    "gpu_expectation",
    "gpu_layers",
    "gpu_memory_headroom_mib",
    "gpu_memory_utilization",
    "hf_config_path",
    "host",
    "host_env",
    "jinja",
    "local_model",
    "max_model_len",
    "max_num_seqs",
    "min_p",
    "model",
    "model_env",
    "n_cpu_moe",
    "override_kv",
    "parallel",
    "port",
    "port_env",
    "presence_penalty",
    "reasoning_budget",
    "reasoning_format",
    "reasoning_parser",
    "repeat_penalty",
    "runner",
    "served_name",
    "temperature",
    "tensor_parallel_size",
    "threads",
    "tokenizer",
    "top_k",
    "top_p",
    "ubatch_size",
}


class ConfigError(RuntimeError):
    pass


def merge_dicts(*values: dict[str, Any]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for value in values:
        for key, item in value.items():
            if isinstance(item, dict) and isinstance(result.get(key), dict):
                result[key] = merge_dicts(result[key], item)
            else:
                result[key] = copy.deepcopy(item)
    return result


def config_path_from_environment() -> Path:
    if value := os.environ.get("LLM_SERVE_CONFIG"):
        return Path(value).expanduser()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config_home / "llm-serve" / "config.toml"


def load_config(path: Path) -> dict[str, Any]:
    try:
        with path.open("rb") as handle:
            config = tomllib.load(handle)
    except FileNotFoundError as error:
        raise ConfigError(
            f"Configuration not found: {path}\n"
            "Apply the Home Manager configuration or pass --config PATH."
        ) from error
    except tomllib.TOMLDecodeError as error:
        raise ConfigError(f"Invalid TOML in {path}: {error}") from error

    if config.get("version") != CONFIG_VERSION:
        raise ConfigError(
            f"Unsupported configuration version {config.get('version')!r}; "
            f"expected {CONFIG_VERSION}."
        )
    targets = config.get("targets")
    if not isinstance(targets, dict) or not targets:
        raise ConfigError("The configuration must contain at least one [targets.NAME] entry.")
    return config


def short_hostname() -> str:
    return socket.gethostname().split(".", 1)[0]


def host_config(config: dict[str, Any], profile: str) -> dict[str, Any]:
    hosts = config.get("hosts", {})
    value = hosts.get(profile, {}) if isinstance(hosts, dict) else {}
    return value if isinstance(value, dict) else {}


def default_target(config: dict[str, Any], profile: str) -> str:
    host_default = host_config(config, profile).get("default")
    name = host_default or config.get("default")
    if not isinstance(name, str) or not name:
        raise ConfigError("Set a top-level default target in the registry.")
    if name not in config["targets"]:
        raise ConfigError(f"Default target {name!r} is not present in [targets].")
    return name


def effective_target(config: dict[str, Any], name: str, profile: str) -> dict[str, Any]:
    raw_target = config["targets"].get(name)
    if not isinstance(raw_target, dict):
        known = ", ".join(sorted(config["targets"]))
        raise ConfigError(f"Unknown target {name!r}. Available targets: {known}")

    backend = raw_target.get("backend")
    if backend not in SUPPORTED_BACKENDS:
        raise ConfigError(f"Target {name!r} has unsupported backend {backend!r}.")

    backends = config.get("backends", {})
    backend_defaults = backends.get(backend, {}) if isinstance(backends, dict) else {}
    current_host = host_config(config, profile)
    host_defaults = current_host.get("defaults", {})
    host_backends = current_host.get("backends", {})
    host_backend = host_backends.get(backend, {}) if isinstance(host_backends, dict) else {}
    host_targets = current_host.get("targets", {})
    host_target = host_targets.get(name, {}) if isinstance(host_targets, dict) else {}

    result = merge_dicts(
        config.get("defaults", {}),
        backend_defaults,
        raw_target,
        host_defaults,
        host_backend,
        host_target,
    )
    unknown = sorted(set(result) - TARGET_KEYS)
    if unknown:
        raise ConfigError(
            f"Target {name!r} has unknown setting(s): {', '.join(unknown)}"
        )
    expectation = result.get("gpu_expectation")
    if expectation is not None and expectation not in GPU_EXPECTATIONS:
        raise ConfigError(
            f"Target {name!r} has unknown gpu_expectation {expectation!r}."
        )
    result["backend"] = backend
    result["nickname"] = name
    return result


def models_root(config: dict[str, Any]) -> Path:
    configured = config.get("models_root")
    value = configured or os.environ.get("LLAMA_MODELS_DIR")
    if not value:
        value = Path.home() / "Games" / "Models"
    return Path(value).expanduser()


def local_path(value: str, root: Path) -> Path:
    path = Path(value).expanduser()
    return path if path.is_absolute() else root / path


def normalize_split_gguf(path: Path) -> Path:
    name = path.name
    marker = "-of-"
    if marker not in name or not name.endswith(".gguf"):
        return path

    stem = name[:-5]
    left, count_text = stem.rsplit(marker, 1)
    if len(count_text) != 5 or not count_text.isdigit() or len(left) < 6:
        return path
    split_text = left[-5:]
    if not split_text.isdigit() or left[-6] != "-":
        return path

    prefix = left[:-6]
    first = path.with_name(f"{prefix}-00001-of-{count_text}.gguf")
    if not first.is_file():
        raise ConfigError(f"Missing first GGUF shard: {first}")

    missing = [
        first.with_name(f"{prefix}-{index:05d}-of-{count_text}.gguf")
        for index in range(1, int(count_text) + 1)
        if not first.with_name(f"{prefix}-{index:05d}-of-{count_text}.gguf").is_file()
    ]
    if missing:
        formatted = "\n".join(f"  {item}" for item in missing)
        raise ConfigError(f"Missing GGUF shard(s):\n{formatted}")
    return first


def resolve_llama_model(target: dict[str, Any], root: Path, override: str | None) -> Path:
    value = override or target.get("model")
    if not isinstance(value, str) or not value:
        raise ConfigError(f"Llama target {target['nickname']!r} needs a model path.")
    path = local_path(value, root)
    if not path.is_file():
        raise ConfigError(f"Model file not found: {path}")
    return normalize_split_gguf(path)


def resolve_repository_model(
    target: dict[str, Any], root: Path, override: str | None
) -> str:
    if override:
        candidate = Path(override).expanduser()
        rooted = candidate if candidate.is_absolute() else root / candidate
        return str(rooted) if rooted.exists() else override

    local_model = target.get("local_model")
    if isinstance(local_model, str) and local_model:
        candidate = local_path(local_model, root)
        if candidate.exists():
            return str(candidate)

    model = target.get("model")
    if not isinstance(model, str) or not model:
        raise ConfigError(f"Target {target['nickname']!r} needs a model or local_model.")
    candidate = Path(model).expanduser()
    if candidate.is_absolute() and not candidate.exists():
        raise ConfigError(f"Model path not found: {candidate}")
    return model


def scalar(value: Any) -> str:
    if isinstance(value, bool):
        return "1" if value else "0"
    return str(value)


def append_option(command: list[str], flag: str, value: Any) -> None:
    if value is None:
        return
    if isinstance(value, list):
        value = ",".join(scalar(item) for item in value)
    command.extend((flag, scalar(value)))


def apply_llama_environment(settings: dict[str, Any]) -> None:
    mapping = {
        "LLAMA_HOST": "host",
        "LLAMA_PORT": "port",
        "LLAMA_THREADS": "threads",
        "LLAMA_CTX_SIZE": "ctx_size",
        "LLAMA_BATCH_SIZE": "batch_size",
        "LLAMA_UBATCH_SIZE": "ubatch_size",
        "LLAMA_N_GPU_LAYERS": "gpu_layers",
        "LLAMA_FIT": "fit",
        "LLAMA_OVERRIDE_KV": "override_kv",
        "LLAMA_ALIAS": "served_name",
        "LLAMA_REASONING_FORMAT": "reasoning_format",
        "LLAMA_REASONING_BUDGET": "reasoning_budget",
        "LLAMA_FLASH_ATTN": "flash_attn",
        "LLAMA_N_CPU_MOE": "n_cpu_moe",
    }
    for variable, key in mapping.items():
        if variable in os.environ:
            settings[key] = os.environ[variable]


def llama_command(
    target: dict[str, Any], root: Path, args: argparse.Namespace, passthrough: list[str]
) -> tuple[list[str], dict[str, str]]:
    settings = copy.deepcopy(target)
    apply_llama_environment(settings)
    if args.bind_host is not None:
        settings["host"] = args.bind_host
    if args.port is not None:
        settings["port"] = args.port
    if args.ctx_size is not None:
        settings["ctx_size"] = args.ctx_size
    if args.gpu_layers is not None:
        settings["gpu_layers"] = args.gpu_layers

    model = resolve_llama_model(settings, root, args.model)
    command = ["llama-server", "--model", str(model)]
    append_option(command, "--alias", settings.get("served_name", settings["nickname"]))

    option_mapping = (
        ("host", "--host"),
        ("port", "--port"),
        ("threads", "--threads"),
        ("ctx_size", "--ctx-size"),
        ("batch_size", "--batch-size"),
        ("ubatch_size", "--ubatch-size"),
        ("parallel", "--parallel"),
        ("gpu_layers", "--n-gpu-layers"),
        ("fit_target_mib", "--fit-target"),
        ("fit_ctx", "--fit-ctx"),
        ("flash_attn", "--flash-attn"),
        ("cache_type_k", "--cache-type-k"),
        ("cache_type_v", "--cache-type-v"),
        ("reasoning_format", "--reasoning-format"),
        ("reasoning_budget", "--reasoning-budget"),
        ("n_cpu_moe", "--n-cpu-moe"),
        ("temperature", "--temp"),
        ("top_p", "--top-p"),
        ("top_k", "--top-k"),
        ("min_p", "--min-p"),
        ("repeat_penalty", "--repeat-penalty"),
        ("presence_penalty", "--presence-penalty"),
        ("frequency_penalty", "--frequency-penalty"),
        ("dry_multiplier", "--dry-multiplier"),
    )
    for key, flag in option_mapping:
        value = settings.get(key)
        if key == "threads" and value == "auto":
            value = os.cpu_count() or 1
        append_option(command, flag, value)

    if "fit" in settings:
        fit = settings["fit"]
        if isinstance(fit, bool):
            fit = "on" if fit else "off"
        append_option(command, "--fit", fit)

    if settings.get("jinja") is True:
        command.append("--jinja")
    elif settings.get("jinja") is False:
        command.append("--no-jinja")

    override_kv = settings.get("override_kv")
    if isinstance(override_kv, str) and override_kv:
        append_option(command, "--override-kv", override_kv)
    elif isinstance(override_kv, list):
        for value in override_kv:
            append_option(command, "--override-kv", value)

    command.extend(valid_args(settings))
    if legacy_args := os.environ.get("LLAMA_SERVER_ARGS"):
        try:
            command.extend(shlex.split(legacy_args))
        except ValueError as error:
            raise ConfigError(f"Invalid quoting in LLAMA_SERVER_ARGS: {error}") from error
    command.extend(passthrough)
    return command, os.environ.copy()


def valid_args(target: dict[str, Any]) -> list[str]:
    values = target.get("args", [])
    if not isinstance(values, list) or not all(isinstance(item, str) for item in values):
        raise ConfigError(f"Target {target['nickname']!r} args must be an array of strings.")
    return list(values)


def environment_with_target(target: dict[str, Any]) -> dict[str, str]:
    environment = os.environ.copy()
    configured = target.get("environment", {})
    if not isinstance(configured, dict):
        raise ConfigError(f"Target {target['nickname']!r} environment must be a table.")
    for key, value in configured.items():
        environment[str(key)] = scalar(value)
    return environment


def vllm_command(
    target: dict[str, Any], root: Path, args: argparse.Namespace, passthrough: list[str]
) -> tuple[list[str], dict[str, str]]:
    model = resolve_repository_model(target, root, args.model)
    environment = environment_with_target(target)
    setting_variables = {
        "host": "VLLM_HOST",
        "port": "VLLM_PORT",
        "served_name": "VLLM_SERVED_MODEL_NAME",
        "dtype": "VLLM_DTYPE",
        "tensor_parallel_size": "VLLM_TENSOR_PARALLEL_SIZE",
        "gpu_memory_utilization": "VLLM_GPU_MEMORY_UTILIZATION",
        "gpu_memory_headroom_mib": "VLLM_GPU_MEMORY_HEADROOM_MIB",
        "max_model_len": "VLLM_MAX_MODEL_LEN",
        "max_num_seqs": "VLLM_MAX_NUM_SEQS",
        "enforce_eager": "VLLM_ENFORCE_EAGER",
        "reasoning_parser": "VLLM_REASONING_PARSER",
        "enable_qwen_defaults": "VLLM_ENABLE_QWEN_DEFAULTS",
        "expert_parallel": "VLLM_ENABLE_EXPERT_PARALLEL",
        "tokenizer": "VLLM_TOKENIZER",
        "hf_config_path": "VLLM_HF_CONFIG_PATH",
        "runner": "VLLM_RUNNER",
        "convert": "VLLM_CONVERT",
    }
    for key, variable in setting_variables.items():
        if key in target:
            environment[variable] = scalar(target[key])
    if args.bind_host is not None:
        environment["VLLM_HOST"] = args.bind_host
    if args.port is not None:
        environment["VLLM_PORT"] = str(args.port)
    if args.ctx_size is not None:
        environment["VLLM_MAX_MODEL_LEN"] = str(args.ctx_size)

    command = ["vllm-serve", model]
    command.extend(valid_args(target))
    command.extend(passthrough)
    return command, environment


def embeddings_command(
    target: dict[str, Any], root: Path, args: argparse.Namespace, passthrough: list[str]
) -> tuple[list[str], dict[str, str]]:
    if passthrough:
        raise ConfigError("The CPU embeddings adapter does not accept backend passthrough arguments.")
    model = resolve_repository_model(target, root, args.model)
    environment = environment_with_target(target)
    mapping = {
        "host": "VLLM_HOST",
        "port": "VLLM_PORT",
        "served_name": "VLLM_SERVED_MODEL_NAME",
        "dtype": "VLLM_DTYPE",
        "max_model_len": "VLLM_MAX_MODEL_LEN",
        "max_num_seqs": "VLLM_MAX_NUM_SEQS",
    }
    for key, variable in mapping.items():
        if key in target:
            environment[variable] = scalar(target[key])
    if args.bind_host is not None:
        environment["VLLM_HOST"] = args.bind_host
    if args.port is not None:
        environment["VLLM_PORT"] = str(args.port)
    command = ["vllm-serve-embeddings", model]
    return command, environment


def delegated_command(
    target: dict[str, Any], args: argparse.Namespace, passthrough: list[str]
) -> tuple[list[str], dict[str, str]]:
    command = target.get("command")
    if not isinstance(command, list) or not command or not all(
        isinstance(item, str) for item in command
    ):
        raise ConfigError(f"Command target {target['nickname']!r} needs a string array command.")
    environment = environment_with_target(target)
    model_env = target.get("model_env")
    if target.get("host_env") and "host" in target:
        environment[str(target["host_env"])] = scalar(target["host"])
    if target.get("port_env") and "port" in target:
        environment[str(target["port_env"])] = scalar(target["port"])
    if args.model is not None:
        if not isinstance(model_env, str) or not model_env:
            raise ConfigError(f"Target {target['nickname']!r} does not support --model.")
        environment[model_env] = args.model
    if args.bind_host is not None and target.get("host_env"):
        environment[str(target["host_env"])] = args.bind_host
    if args.port is not None and target.get("port_env"):
        environment[str(target["port_env"])] = str(args.port)
    result = list(command)
    result.extend(valid_args(target))
    result.extend(passthrough)
    return result, environment


def build_launch(
    target: dict[str, Any], root: Path, args: argparse.Namespace, passthrough: list[str]
) -> tuple[list[str], dict[str, str]]:
    backend = target["backend"]
    if backend == "llama":
        return llama_command(target, root, args, passthrough)
    if backend == "vllm":
        return vllm_command(target, root, args, passthrough)
    if backend == "embeddings-cpu":
        return embeddings_command(target, root, args, passthrough)
    return delegated_command(target, args, passthrough)


def redact_environment(environment: dict[str, str], original: dict[str, str]) -> list[str]:
    changed: list[str] = []
    for key in sorted(environment):
        if original.get(key) == environment[key]:
            continue
        value = environment[key]
        if any(marker in key.upper() for marker in ("KEY", "TOKEN", "PASSWORD", "SECRET")):
            value = "<redacted>"
        changed.append(f"{key}={shlex.quote(value)}")
    return changed


def print_launch(target: dict[str, Any], command: list[str], environment: dict[str, str]) -> None:
    print(f"target: {target['nickname']}")
    print(f"backend: {target['backend']}")
    print(f"gpu expectation: {target.get('gpu_expectation', 'unspecified')}")
    for assignment in redact_environment(environment, os.environ):
        print(f"env: {assignment}")
    print(f"command: {shlex.join(command)}")


def validate_registry(config: dict[str, Any], profile: str, root: Path) -> list[str]:
    errors: list[str] = []
    try:
        default_target(config, profile)
    except ConfigError as error:
        errors.append(str(error))

    dummy = argparse.Namespace(
        model=None,
        bind_host=None,
        port=None,
        ctx_size=None,
        gpu_layers=None,
    )
    for name in sorted(config["targets"]):
        try:
            target = effective_target(config, name, profile)
            command, _ = build_launch(target, root, dummy, [])
            if shutil.which(command[0]) is None:
                raise ConfigError(f"Command not found on PATH: {command[0]}")
        except ConfigError as error:
            errors.append(f"{name}: {error}")
    return errors


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(
        prog="llm-serve",
        description="Launch a configured local model-serving target.",
        epilog="Pass backend-specific arguments after --, for example: "
        "llm-serve oss -- --ctx-size 16384",
    )
    result.add_argument("target", nargs="?", help="registry nickname; defaults to the configured target")
    result.add_argument("--config", type=Path, help="registry path (default: $XDG_CONFIG_HOME/llm-serve/config.toml)")
    result.add_argument("--host-profile", help="hardware profile name (default: short hostname)")
    result.add_argument("--model", help="override the target's model path or repository ID")
    result.add_argument("--bind-host", help="override the server bind address")
    result.add_argument("--port", type=int, help="override the server port")
    result.add_argument("--ctx-size", type=int, help="override llama context or vLLM max model length")
    result.add_argument("--gpu-layers", help="override llama.cpp --n-gpu-layers")
    result.add_argument("--dry-run", action="store_true", help="print the resolved launch without executing")
    result.add_argument("--list", action="store_true", help="list configured targets")
    result.add_argument("--show", metavar="NAME", help="show a target's fully resolved launch")
    result.add_argument("--validate", action="store_true", help="validate targets, model paths, and commands")
    return result


def main(argv: list[str] | None = None) -> int:
    raw = list(sys.argv[1:] if argv is None else argv)
    if "--" in raw:
        separator = raw.index("--")
        launcher_args = raw[:separator]
        passthrough = raw[separator + 1 :]
    else:
        launcher_args = raw
        passthrough = []

    args = parser().parse_args(launcher_args)
    path = (args.config or config_path_from_environment()).expanduser()
    config = load_config(path)
    profile = args.host_profile or os.environ.get("LLM_SERVE_HOST_PROFILE") or short_hostname()
    root = models_root(config)

    if args.list:
        selected_default = default_target(config, profile)
        for name in sorted(config["targets"]):
            target = effective_target(config, name, profile)
            marker = "*" if name == selected_default else " "
            expectation = target.get("gpu_expectation", "unspecified")
            description = target.get("description", "")
            print(f"{marker} {name:<20} {target['backend']:<15} {expectation:<12} {description}")
        return 0

    if args.validate:
        errors = validate_registry(config, profile, root)
        if errors:
            print("Registry validation failed:", file=sys.stderr)
            for error in errors:
                print(f"  - {error}", file=sys.stderr)
            return 1
        print(f"Registry is valid for host profile {profile!r}.")
        return 0

    name = args.show or args.target or default_target(config, profile)
    target = effective_target(config, name, profile)
    command, environment = build_launch(target, root, args, passthrough)
    if args.show or args.dry_run:
        print_launch(target, command, environment)
        return 0

    executable = shutil.which(command[0], path=environment.get("PATH"))
    if executable is None:
        raise ConfigError(f"Command not found on PATH: {command[0]}")
    command[0] = executable
    print(
        f"Launching {name} ({target['backend']}, GPU: "
        f"{target.get('gpu_expectation', 'unspecified')})",
        file=sys.stderr,
    )
    os.execvpe(command[0], command, environment)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ConfigError as error:
        print(f"llm-serve: {error}", file=sys.stderr)
        raise SystemExit(2) from error
