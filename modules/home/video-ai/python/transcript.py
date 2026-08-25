#!/usr/bin/env python3
"""Convert a WebVTT subtitle file into a readable plain-text transcript."""

from __future__ import annotations

import argparse
import html
import re
from pathlib import Path


TIMING_LINE = re.compile(r"\s*\S+\s+-->\s+\S+")
TAG = re.compile(r"<[^>]+>")
WHITESPACE = re.compile(r"\s+")
NON_WORD = re.compile(r"[^\w']+", re.UNICODE)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Clean a WebVTT transcript")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    return parser.parse_args()


def clean_payload(lines: list[str]) -> str:
    text = " ".join(lines)
    text = html.unescape(TAG.sub("", text))
    return WHITESPACE.sub(" ", text).strip()


def read_cues(path: Path) -> list[str]:
    content = path.read_text(encoding="utf-8-sig").replace("\r\n", "\n")
    cues: list[str] = []
    for block in re.split(r"\n\s*\n", content):
        lines = [line.strip() for line in block.splitlines() if line.strip()]
        timing_index = next(
            (index for index, line in enumerate(lines) if TIMING_LINE.match(line)),
            None,
        )
        if timing_index is None:
            continue
        payload = clean_payload(lines[timing_index + 1 :])
        if payload:
            cues.append(payload)
    return cues


def comparison_token(token: str) -> str:
    return NON_WORD.sub("", token).casefold()


def merge_rolling_cues(cues: list[str]) -> str:
    """Merge YouTube's overlapping rolling captions without repeating words."""
    merged: list[str] = []
    for cue in cues:
        incoming = cue.split()
        if not incoming:
            continue

        comparable_merged = [comparison_token(token) for token in merged]
        comparable_incoming = [comparison_token(token) for token in incoming]
        maximum = min(len(merged), len(incoming))
        overlap = 0
        for size in range(maximum, 0, -1):
            if comparable_merged[-size:] == comparable_incoming[:size]:
                overlap = size
                break
        merged.extend(incoming[overlap:])

    return " ".join(merged).strip()


def main() -> None:
    args = parse_args()
    transcript = merge_rolling_cues(read_cues(args.input))
    if not transcript:
        raise SystemExit(f"No caption cues found in {args.input}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(transcript + "\n", encoding="utf-8")
    print(args.output)


if __name__ == "__main__":
    main()
