#!/usr/bin/env python3
"""Generate a provenance sidecar alongside Chatterbox narration."""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path

import torch
import torchaudio


MODEL_REPOSITORIES = {
    "turbo": "ResembleAI/chatterbox-turbo",
    "multilingual-v3": "ResembleAI/chatterbox",
}


def resolved_model_revision(repository: str) -> str | None:
    """Return the immutable Hub revision selected by from_pretrained, if recorded."""
    hub_home = Path(os.environ.get("HF_HOME", Path.home() / ".cache" / "huggingface"))
    repository_cache = "models--" + repository.replace("/", "--")
    main_ref = hub_home / "hub" / repository_cache / "refs" / "main"
    try:
        revision = main_ref.read_text().strip()
    except OSError:
        return None
    return revision or None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate narration with Chatterbox")
    parser.add_argument("--text")
    parser.add_argument("--text-file", type=Path)
    parser.add_argument("--reference", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--model", choices=("turbo", "multilingual-v3"), default="turbo")
    parser.add_argument("--language", default="en")
    parser.add_argument(
        "--consent-confirmed",
        action="store_true",
        help="Required when --reference is used; confirms the speaker authorized cloning.",
    )
    args = parser.parse_args()
    if bool(args.text) == bool(args.text_file):
        parser.error("provide exactly one of --text or --text-file")
    if args.reference and not args.consent_confirmed:
        parser.error("--reference requires --consent-confirmed")
    return args


def main() -> None:
    args = parse_args()
    text = args.text if args.text is not None else args.text_file.read_text().strip()
    device = "cuda" if torch.cuda.is_available() else "cpu"

    if args.model == "turbo":
        from chatterbox.tts_turbo import ChatterboxTurboTTS

        model = ChatterboxTurboTTS.from_pretrained(device=device)
        kwargs = {}
    else:
        from chatterbox.mtl_tts import ChatterboxMultilingualTTS

        model = ChatterboxMultilingualTTS.from_pretrained(device=device, t3_model="v3")
        kwargs = {"language_id": args.language}

    if args.reference:
        kwargs["audio_prompt_path"] = str(args.reference.resolve())
    waveform = model.generate(text, **kwargs)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    torchaudio.save(str(args.output), waveform.cpu(), model.sr)
    model_repository = MODEL_REPOSITORIES[args.model]
    sidecar = args.output.with_suffix(args.output.suffix + ".json")
    sidecar.write_text(
        json.dumps(
            {
                "schema": 1,
                "createdAt": datetime.now(timezone.utc).isoformat(),
                "model": args.model,
                "modelRepository": model_repository,
                "modelRevision": resolved_model_revision(model_repository),
                "language": args.language,
                "device": device,
                "sampleRate": model.sr,
                "reference": str(args.reference.resolve()) if args.reference else None,
                "consentConfirmed": bool(args.consent_confirmed),
                "text": text,
            },
            indent=2,
        )
        + "\n"
    )
    print(args.output)


if __name__ == "__main__":
    main()
