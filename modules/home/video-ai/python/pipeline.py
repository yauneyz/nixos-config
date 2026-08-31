#!/usr/bin/env python3
"""Project orchestration for the local-first short-form video pipeline."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
from typing import Any, Iterable


PROJECT_DIRS = (
    "00_admin/environment",
    "01_script",
    "02_voice/narration_raw",
    "03_alignment",
    "04_timeline",
    "05_stills/candidates",
    "05_stills/approved",
    "06_video/candidates",
    "06_video/approved",
    "06_video/normalized",
    "07_audio/music",
    "07_audio/sfx",
    "08_workflows",
    "10_exports",
)

STAGES = (
    "brief",
    "script",
    "voice",
    "alignment",
    "timeline",
    "storyboard",
    "assets",
    "package",
    "master",
)

STAGE_LABELS = {
    "brief": "creative brief",
    "script": "locked script",
    "voice": "narration master",
    "alignment": "alignment and captions",
    "timeline": "human-edited timeline",
    "storyboard": "storyboard/edit plan",
    "assets": "selected assets",
    "package": "editor delivery package",
    "master": "final master",
}

NEXT_ACTIONS = {
    "brief": "Fill 00_admin/creative_brief.md with your taste, audience, visual grammar, and anti-patterns; then approve brief.",
    "script": "Write and perform a human edit of 01_script/script_locked.md; use | for intentional visual beat boundaries; then approve script.",
    "voice": "Generate takes in 02_voice/narration_raw/, assemble the accepted performance with `video-ai project voice-master`, listen end-to-end, then approve voice.",
    "alignment": "Run `video-ai project align`, inspect 03_alignment/alignment_review.csv and captions.srt, correct any timing errors, then approve alignment.",
    "timeline": "Edit 04_timeline/timeline.csv. Merge/split beats by meaning, set every locked cell to true, then approve timeline.",
    "storyboard": "Use 08_workflows/storyboard_prompt.md with your assistant, fill 04_timeline/edit_plan.csv without changing timing fields, then approve storyboard.",
    "assets": "Generate candidates, use `video-ai project select SHOT FILE` for each chosen asset, verify licenses, then approve assets.",
    "package": "Run `video-ai project package`, inspect 09_delivery in Resolve, then approve package.",
    "master": "Finish taste work in Resolve and export 10_exports/master.mp4; watch it with sound and muted, then approve master.",
}

TIMELINE_FIELDS = (
    "shot_id",
    "start",
    "end",
    "duration",
    "narration",
    "reason",
    "caption_first",
    "caption_last",
    "locked",
)

EDIT_PLAN_FIELDS = (
    "shot_id",
    "start",
    "end",
    "duration",
    "narration",
    "visual_function",
    "asset_type",
    "input_path",
    "asset_path",
    "image_prompt",
    "motion_prompt",
    "negative_prompt",
    "seed",
    "workflow",
    "editor_note",
)

ASSET_TYPES = {
    "ai_still",
    "ai_i2v",
    "ai_t2v",
    "stock",
    "screenshot",
    "recorded",
    "graphic",
    "text_graphic",
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def die(message: str) -> None:
    raise SystemExit(f"video-ai: {message}")


def projects_root() -> Path:
    return Path(os.environ.get("VIDEO_AI_PROJECTS", Path.home() / "Games/VideoAI/projects"))


def resolve_project(value: str | None) -> Path:
    if value:
        candidate = Path(value).expanduser()
        if not candidate.exists():
            candidate = projects_root() / value
        candidate = candidate.resolve()
    else:
        candidate = Path.cwd().resolve()
        while candidate != candidate.parent and not (candidate / "project.json").is_file():
            candidate = candidate.parent
    if not (candidate / "project.json").is_file():
        die("project not found; cd into one or pass --project NAME")
    return candidate


def load_project(project: Path) -> dict[str, Any]:
    try:
        return json.loads((project / "project.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        die(f"invalid project manifest: {error}")


def save_project(project: Path, data: dict[str, Any]) -> None:
    temporary = project / f"project.json.partial.{os.getpid()}"
    temporary.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    temporary.replace(project / "project.json")


def write_csv(path: Path, fields: Iterable[str], rows: Iterable[dict[str, Any]]) -> None:
    temporary = path.with_name(f"{path.name}.partial.{os.getpid()}")
    path.parent.mkdir(parents=True, exist_ok=True)
    with temporary.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(fields), extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(path)


def read_csv(path: Path) -> list[dict[str, str]]:
    try:
        with path.open(newline="") as handle:
            return list(csv.DictReader(handle))
    except OSError as error:
        die(f"cannot read {path}: {error}")


def append_csv(path: Path, fields: Iterable[str], row: dict[str, Any]) -> None:
    field_list = list(fields)
    exists = path.is_file() and path.stat().st_size > 0
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=field_list, extrasaction="ignore")
        if not exists:
            writer.writeheader()
        writer.writerow(row)


def copy_template(name: str, destination: Path, fallback: str) -> None:
    template_root_value = os.environ.get("VIDEO_AI_TEMPLATES")
    source = Path(template_root_value) / name if template_root_value else None
    if source is not None and source.is_file():
        shutil.copy2(source, destination)
    else:
        destination.write_text(fallback)


def snapshot_environment(project: Path) -> None:
    destination = project / "00_admin/environment"
    for environment_name, output_name in (
        ("VIDEO_AI_APPS_MANIFEST", "apps.json"),
        ("VIDEO_AI_MODELS_MANIFEST", "models.json"),
        ("VIDEO_AI_WORKFLOWS_MANIFEST", "workflows.json"),
    ):
        source_value = os.environ.get(environment_name)
        if source_value and Path(source_value).is_file():
            shutil.copy2(source_value, destination / output_name)

    models_manifest = destination / "models.json"
    models_root_value = Path(os.environ.get("VIDEO_AI_MODELS", Path.home() / "Games/Models/VideoAI"))
    if models_manifest.is_file():
        records = json.loads(models_manifest.read_text())
        rows = []
        for record in records:
            target = models_root_value / record["destination"]
            rows.append(
                {
                    "role": record.get("profile", ""),
                    "name": record.get("name", ""),
                    "revision": record.get("revision", ""),
                    "license": record.get("license", ""),
                    "sha256": record.get("sha256", ""),
                    "installed": str(target.is_file()).lower(),
                }
            )
        write_csv(
            destination / "models.csv",
            ("role", "name", "revision", "license", "sha256", "installed"),
            rows,
        )

    envs_root_value = Path(os.environ.get("VIDEO_AI_ENVS", Path.home() / "Games/VideoAI/envs"))
    environment_rows = []
    if envs_root_value.is_dir():
        for current in sorted(envs_root_value.glob("*/current")):
            python = current / "bin/python"
            if not python.is_file():
                continue
            resolved = current.resolve()
            environment_rows.append({"name": current.parent.name, "path": str(resolved)})
            try:
                frozen = subprocess.run(
                    [str(python), "-m", "pip", "freeze"],
                    check=True,
                    capture_output=True,
                    text=True,
                    timeout=30,
                ).stdout
            except (OSError, subprocess.SubprocessError):
                frozen = "# pip freeze unavailable\n"
            (destination / f"{current.parent.name}-pip-freeze.txt").write_text(frozen)
    write_csv(destination / "environments.csv", ("name", "path"), environment_rows)

    nodes_root = Path(os.environ.get("VIDEO_AI_STATE", Path.home() / "Games/VideoAI/state")) / "comfyui/custom_nodes"
    node_rows = []
    if nodes_root.is_dir():
        for node in sorted(nodes_root.iterdir()):
            if not node.is_dir():
                continue
            revision = ""
            try:
                revision = subprocess.run(
                    ["git", "-C", str(node.resolve()), "rev-parse", "HEAD"],
                    check=True,
                    capture_output=True,
                    text=True,
                    timeout=10,
                ).stdout.strip()
            except (OSError, subprocess.SubprocessError):
                pass
            node_rows.append({"name": node.name, "path": str(node.resolve()), "revision": revision})
    write_csv(destination / "custom_nodes.csv", ("name", "path", "revision"), node_rows)


def new_project(slug: str) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", slug):
        die("project slug must use lowercase letters, numbers, dots, underscores, or hyphens")
    project = projects_root() / slug
    if project.exists():
        die(f"project already exists: {project}")
    for relative in PROJECT_DIRS:
        (project / relative).mkdir(parents=True, exist_ok=True)

    copy_template(
        "creative_brief.md",
        project / "00_admin/creative_brief.md",
        "# Creative brief\n\nAudience:\nPromise:\nPoint of view:\nVisual grammar:\nNever do:\n\n## Taste notes\n",
    )
    copy_template(
        "script_locked.md",
        project / "01_script/script_locked.md",
        "# Locked narration\n\nWrite only accepted narration here. Use | where you want a visual beat.\n",
    )
    copy_template(
        "pronunciation.yaml",
        project / "01_script/pronunciation.yaml",
        "# spelling: spoken form\npronunciations: {}\n",
    )
    copy_template(
        "storyboard_prompt.md",
        project / "08_workflows/storyboard_prompt.md",
        "# Storyboard contract\n\nNever alter shot timing or narration. Return one edit-plan row per timeline row.\n",
    )
    copy_template(
        "comfy_api_workflow.md",
        project / "08_workflows/README.md",
        "# API workflows\n\nExport API-format ComfyUI workflows here.\n",
    )

    write_csv(project / "00_admin/build_log.csv", ("event", "started_at", "completed_at", "status", "artifact"), ())
    write_csv(project / "00_admin/licenses.csv", ("asset", "source", "license", "permission_record", "notes"), ())
    write_csv(
        project / "00_admin/generation_log.csv",
        ("asset", "shot_id", "model", "workflow_hash", "seed", "prompt_hash", "input_hash", "output_hash", "created_at", "status"),
        (),
    )
    write_csv(project / "04_timeline/timeline.csv", TIMELINE_FIELDS, ())
    write_csv(project / "04_timeline/edit_plan.csv", EDIT_PLAN_FIELDS, ())
    (project / "00_admin/results.md").write_text(
        "# Results\n\nPublished URL:\nPublished date:\nHook:\nLength:\nViews after 24h / 7d:\nViewed vs swiped away:\nAverage view duration:\nRetention drop points:\nWhat to preserve:\nWhat to change:\n"
    )
    manifest = {
        "schema": 2,
        "slug": slug,
        "createdAt": now(),
        "language": "en",
        "master": {"canvas": "1080x1920", "color": "Rec.709 SDR", "frameRate": "source-native"},
        "stages": {},
    }
    save_project(project, manifest)
    snapshot_environment(project)
    project.chmod(0o700)
    print(project)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def hash_artifacts(project: Path, paths: Iterable[Path]) -> str:
    digest = hashlib.sha256()
    files: list[Path] = []
    for path in paths:
        if path.is_file():
            files.append(path)
        elif path.is_dir():
            files.extend(item for item in path.rglob("*") if item.is_file())
    for path in sorted(files):
        digest.update(str(path.relative_to(project)).encode())
        digest.update(b"\0")
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    return digest.hexdigest()


def stage_hash(project: Path, stage: str) -> str:
    if stage == "storyboard":
        # asset_path is populated later by explicit human candidate selection.
        # It is downstream state, not part of the approved creative contract.
        rows = read_csv(project / "04_timeline/edit_plan.csv")
        canonical = [{field: row.get(field, "") for field in EDIT_PLAN_FIELDS if field != "asset_path"} for row in rows]
        return hashlib.sha256(json.dumps(canonical, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    return hash_artifacts(project, stage_artifacts(project, stage))


def stage_artifacts(project: Path, stage: str) -> list[Path]:
    mapping = {
        "brief": [project / "00_admin/creative_brief.md"],
        "script": [project / "01_script/script_locked.md", project / "01_script/pronunciation.yaml"],
        "voice": [project / "02_voice/narration_master.wav"],
        "alignment": [
            project / "03_alignment/words.json",
            project / "03_alignment/captions.srt",
            project / "03_alignment/alignment_review.csv",
        ],
        "timeline": [project / "04_timeline/timeline.csv"],
        "storyboard": [project / "04_timeline/edit_plan.csv"],
        "assets": [project / "05_stills/approved", project / "06_video/approved", project / "00_admin/licenses.csv"],
        "package": [project / "09_delivery"],
        "master": [project / "10_exports/master.mp4"],
    }
    return mapping[stage]


def validate_timeline(project: Path) -> tuple[bool, str]:
    rows = read_csv(project / "04_timeline/timeline.csv")
    if not rows:
        return False, "timeline has no shots"
    seen: set[str] = set()
    previous_end = -1.0
    for index, row in enumerate(rows, 1):
        shot_id = row.get("shot_id", "")
        if not shot_id or shot_id in seen:
            return False, f"row {index} has a missing or duplicate shot_id"
        seen.add(shot_id)
        try:
            start, end, duration = float(row["start"]), float(row["end"]), float(row["duration"])
        except (KeyError, TypeError, ValueError):
            return False, f"{shot_id} has invalid timing"
        if start < previous_end - 0.001 or end <= start or abs((end - start) - duration) > 0.005:
            return False, f"{shot_id} overlaps, runs backward, or has an incorrect duration"
        if row.get("locked", "").strip().lower() not in {"true", "yes", "1"}:
            return False, f"{shot_id} is not human-locked"
        previous_end = end
    return True, f"{len(rows)} locked shots"


def validate_storyboard(project: Path) -> tuple[bool, str]:
    timeline = read_csv(project / "04_timeline/timeline.csv")
    plan = read_csv(project / "04_timeline/edit_plan.csv")
    if len(plan) != len(timeline):
        return False, "edit plan must contain exactly one row per timeline shot"
    plan_by_id = {row.get("shot_id", ""): row for row in plan}
    if len(plan_by_id) != len(plan):
        return False, "edit plan has missing or duplicate shot IDs"
    for timing in timeline:
        shot_id = timing["shot_id"]
        row = plan_by_id.get(shot_id)
        if not row:
            return False, f"edit plan is missing {shot_id}"
        for field in ("start", "end", "duration"):
            try:
                if abs(float(row[field]) - float(timing[field])) > 0.001:
                    return False, f"{shot_id} changed authoritative {field}"
            except (KeyError, TypeError, ValueError):
                return False, f"{shot_id} has invalid {field}"
        if row.get("narration", "").strip() != timing.get("narration", "").strip():
            return False, f"{shot_id} changed authoritative narration"
        asset_type = row.get("asset_type", "")
        if asset_type not in ASSET_TYPES:
            return False, f"{shot_id} has unsupported asset_type {asset_type!r}"
        if asset_type.startswith("ai_") and not row.get("workflow", "").strip():
            return False, f"{shot_id} needs a workflow"
        if asset_type == "ai_still" and not row.get("image_prompt", "").strip():
            return False, f"{shot_id} needs an image prompt"
        if asset_type in {"ai_i2v", "ai_t2v"} and not row.get("motion_prompt", "").strip():
            return False, f"{shot_id} needs a motion prompt"
    return True, f"{len(plan)} storyboard records preserve the locked timeline"


def resolve_asset(project: Path, value: str) -> Path:
    candidate = (project / value).resolve() if not Path(value).is_absolute() else Path(value).resolve()
    try:
        candidate.relative_to(project.resolve())
    except ValueError:
        die(f"asset must be inside the project: {candidate}")
    return candidate


def validate_assets(project: Path) -> tuple[bool, str]:
    valid, message = validate_storyboard(project)
    if not valid:
        return valid, message
    missing = []
    checked = 0
    for row in read_csv(project / "04_timeline/edit_plan.csv"):
        if row["asset_type"] == "text_graphic":
            continue
        value = row.get("asset_path", "").strip()
        if not value or not resolve_asset(project, value).is_file():
            missing.append(row["shot_id"])
        else:
            checked += 1
    if missing:
        return False, "missing selected assets: " + ", ".join(missing)
    return True, f"{checked} selected files plus editor-native graphics"


def validate_stage(project: Path, stage: str) -> tuple[bool, str]:
    if stage == "script" and not normalized_tokens(script_text(project).replace("|", " ")):
        return False, "locked script contains no narration"
    if stage == "alignment":
        artifacts = stage_artifacts(project, stage)
        missing = [str(path.relative_to(project)) for path in artifacts if not path.exists()]
        if missing:
            return False, "missing " + ", ".join(missing)
        review = read_csv(project / "03_alignment/alignment_review.csv")
        unresolved = [row for row in review if row.get("reviewed", "").strip().lower() not in {"true", "yes", "1"}]
        if unresolved:
            return False, f"{len(unresolved)} script/alignment differences still need human review"
        return True, f"{len(review)} alignment spans reviewed"
    if stage == "timeline":
        return validate_timeline(project)
    if stage == "storyboard":
        return validate_storyboard(project)
    if stage == "assets":
        return validate_assets(project)
    artifacts = stage_artifacts(project, stage)
    missing = [str(path.relative_to(project)) for path in artifacts if not path.exists()]
    if missing:
        return False, "missing " + ", ".join(missing)
    if stage == "package" and not (project / "09_delivery/provenance/checksums.sha256").is_file():
        return False, "delivery checksums are missing"
    if stage == "master" and (project / "10_exports/master.mp4").stat().st_size == 0:
        return False, "master is empty"
    return True, "artifacts present"


def stage_state(project: Path, manifest: dict[str, Any], stage: str) -> tuple[str, str]:
    record = manifest.get("stages", {}).get(stage)
    dependency_index = STAGES.index(stage)
    for dependency in STAGES[:dependency_index]:
        dependency_state, _ = stage_state(project, manifest, dependency)
        if dependency_state != "approved":
            if record:
                return "stale", f"upstream {dependency} gate is {dependency_state}"
            return "waiting", f"upstream {dependency} gate is {dependency_state}"
    valid, detail = validate_stage(project, stage)
    if record:
        current_hash = stage_hash(project, stage) if valid else ""
        if valid and current_hash == record.get("artifactHash"):
            return "approved", record.get("approvedAt", "")
        return "stale", detail
    if valid:
        return "ready", detail
    return "waiting", detail


def status(project: Path) -> None:
    manifest = load_project(project)
    print(f"Project: {manifest.get('slug', project.name)}")
    print(f"Path:    {project}")
    for stage in STAGES:
        state, detail = stage_state(project, manifest, stage)
        print(f"{stage:12} {state:9} {detail}")


def next_action(project: Path) -> None:
    manifest = load_project(project)
    for stage in STAGES:
        state, detail = stage_state(project, manifest, stage)
        if state != "approved":
            print(f"Next gate: {stage} ({state})")
            if state == "stale":
                print(f"Changed after approval: {detail}. Re-review this gate; downstream approvals will remain blocked.")
            print(NEXT_ACTIONS[stage])
            return
    print("All production gates are approved. Record publishing results in 00_admin/results.md.")


def approve(project: Path, stage: str) -> None:
    manifest = load_project(project)
    index = STAGES.index(stage)
    for dependency in STAGES[:index]:
        state, _ = stage_state(project, manifest, dependency)
        if state != "approved":
            die(f"cannot approve {stage}: {dependency} is {state}")
    valid, detail = validate_stage(project, stage)
    if not valid:
        die(f"cannot approve {stage}: {detail}")
    artifact_hash = stage_hash(project, stage)
    manifest.setdefault("stages", {})[stage] = {
        "approvedAt": now(),
        "artifactHash": artifact_hash,
        "artifacts": [str(path.relative_to(project)) for path in stage_artifacts(project, stage)],
    }
    save_project(project, manifest)
    append_csv(
        project / "00_admin/build_log.csv",
        ("event", "started_at", "completed_at", "status", "artifact"),
        {"event": f"{stage}_approved", "started_at": now(), "completed_at": now(), "status": "pass", "artifact": artifact_hash},
    )
    print(f"Approved {STAGE_LABELS[stage]}: {artifact_hash}")


def extract_words(data: Any) -> list[dict[str, Any]]:
    candidates: list[Any] = []
    if isinstance(data, list):
        candidates = data
    elif isinstance(data, dict):
        if isinstance(data.get("word_segments"), list):
            candidates = data["word_segments"]
        elif isinstance(data.get("segments"), list):
            for segment in data["segments"]:
                if isinstance(segment, dict) and isinstance(segment.get("words"), list):
                    candidates.extend(segment["words"])
    words = []
    for candidate in candidates:
        if not isinstance(candidate, dict):
            continue
        text = str(candidate.get("word", candidate.get("text", ""))).strip()
        try:
            start, end = float(candidate["start"]), float(candidate["end"])
        except (KeyError, TypeError, ValueError):
            continue
        if text and end > start:
            words.append({"word": text, "start": round(start, 3), "end": round(end, 3), "score": candidate.get("score")})
    words.sort(key=lambda item: (item["start"], item["end"]))
    return words


def script_text(project: Path) -> str:
    text = (project / "01_script/script_locked.md").read_text()
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    lines = [line for line in text.splitlines() if not line.lstrip().startswith("#")]
    return "\n".join(lines).strip()


def normalized_tokens(text: str) -> list[str]:
    return [token.lower().replace("’", "'") for token in re.findall(r"[\w]+(?:['’][\w]+)?", text, flags=re.UNICODE)]


def alignment_review(project: Path, words: list[dict[str, Any]]) -> float:
    expected = normalized_tokens(script_text(project).replace("|", " "))
    actual = normalized_tokens(" ".join(word["word"] for word in words))
    matcher = SequenceMatcher(a=expected, b=actual, autojunk=False)
    rows = []
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        rows.append(
            {
                "status": tag,
                "script_start": i1,
                "script_end": i2,
                "script_text": " ".join(expected[i1:i2]),
                "aligned_start": j1,
                "aligned_end": j2,
                "aligned_text": " ".join(actual[j1:j2]),
                "reviewed": "false" if tag != "equal" else "true",
                "note": "",
            }
        )
    write_csv(
        project / "03_alignment/alignment_review.csv",
        ("status", "script_start", "script_end", "script_text", "aligned_start", "aligned_end", "aligned_text", "reviewed", "note"),
        rows,
    )
    return matcher.ratio()


def should_close_caption(chunk: list[dict[str, Any]]) -> bool:
    if len(chunk) >= 5 or chunk[-1]["end"] - chunk[0]["start"] >= 1.5:
        return True
    return len(chunk) >= 2 and chunk[-1]["word"].rstrip().endswith((".", "?", "!", ",", ";", ":"))


def caption_chunks(words: list[dict[str, Any]]) -> list[list[dict[str, Any]]]:
    chunks: list[list[dict[str, Any]]] = []
    current: list[dict[str, Any]] = []
    for word in words:
        current.append(word)
        if should_close_caption(current):
            chunks.append(current)
            current = []
    if current:
        if len(current) == 1 and chunks and len(chunks[-1]) < 5:
            chunks[-1].extend(current)
        else:
            chunks.append(current)
    return chunks


def srt_time(seconds: float) -> str:
    milliseconds = max(0, round(seconds * 1000))
    hours, remainder = divmod(milliseconds, 3_600_000)
    minutes, remainder = divmod(remainder, 60_000)
    secs, millis = divmod(remainder, 1000)
    return f"{hours:02}:{minutes:02}:{secs:02},{millis:03}"


def write_captions(project: Path, chunks: list[list[dict[str, Any]]]) -> None:
    lines = []
    for index, chunk in enumerate(chunks, 1):
        lines.extend(
            (
                str(index),
                f"{srt_time(chunk[0]['start'])} --> {srt_time(chunk[-1]['end'])}",
                " ".join(word["word"].strip() for word in chunk),
                "",
            )
        )
    (project / "03_alignment/captions.srt").write_text("\n".join(lines), encoding="utf-8")


def suggested_beats(words: list[dict[str, Any]], script: str) -> list[tuple[list[dict[str, Any]], str, float]]:
    marker_phrases = [phrase.strip() for phrase in script.split("|") if phrase.strip()]
    counts = [len(normalized_tokens(phrase)) for phrase in marker_phrases]
    if len(marker_phrases) > 1 and sum(counts) == len(normalized_tokens(" ".join(word["word"] for word in words))):
        beats = []
        cursor = 0
        for count in counts:
            beats.append((words[cursor : cursor + count], "human marker", 1.0))
            cursor += count
        return [beat for beat in beats if beat[0]]

    beats = []
    current: list[dict[str, Any]] = []
    for word in words:
        current.append(word)
        duration = current[-1]["end"] - current[0]["start"]
        punctuation = word["word"].rstrip().endswith((".", "?", "!", ";", ":"))
        if (punctuation and duration >= 1.2) or duration >= 3.5:
            beats.append((current, "semantic punctuation" if punctuation else "maximum duration", 0.85 if punctuation else 0.65))
            current = []
    if current:
        beats.append((current, "final phrase", 0.75))
    return beats


def caption_range(chunks: list[list[dict[str, Any]]], start: float, end: float) -> tuple[int, int]:
    hits = [index for index, chunk in enumerate(chunks, 1) if chunk[-1]["end"] >= start and chunk[0]["start"] <= end]
    return (hits[0], hits[-1]) if hits else (0, 0)


def derive(project: Path, input_value: str | None, force: bool) -> None:
    default_input = project / "03_alignment/narration_master.json"
    input_path = Path(input_value).expanduser().resolve() if input_value else default_input
    if not input_path.is_file():
        json_files = sorted((project / "03_alignment").glob("*.json"))
        json_files = [path for path in json_files if path.name != "words.json"]
        if len(json_files) == 1:
            input_path = json_files[0]
        else:
            die(f"WhisperX JSON not found: {input_path}")
    words = extract_words(json.loads(input_path.read_text()))
    if not words:
        die("alignment JSON contains no usable word timestamps")
    outputs = (
        project / "03_alignment/words.json",
        project / "03_alignment/captions.srt",
        project / "03_alignment/alignment_review.csv",
        project / "04_timeline/suggested_shots.csv",
    )
    if not force:
        existing = [path for path in outputs if path.exists()]
        if existing:
            die("derived artifacts already exist; review them or rerun with --force")

    (project / "03_alignment/words.json").write_text(json.dumps(words, indent=2) + "\n")
    ratio = alignment_review(project, words)
    chunks = caption_chunks(words)
    write_captions(project, chunks)
    beats = suggested_beats(words, script_text(project))
    rows = []
    timeline_rows = []
    for index, (beat, reason, confidence) in enumerate(beats, 1):
        start, end = beat[0]["start"], beat[-1]["end"]
        first_caption, last_caption = caption_range(chunks, start, end)
        common = {
            "shot_id": f"shot_{index:03}",
            "start": f"{start:.3f}",
            "end": f"{end:.3f}",
            "duration": f"{end - start:.3f}",
            "narration": " ".join(word["word"] for word in beat),
            "reason": reason,
            "caption_first": first_caption,
            "caption_last": last_caption,
        }
        rows.append({**common, "confidence": f"{confidence:.2f}"})
        timeline_rows.append({**common, "locked": "false"})
    write_csv(
        project / "04_timeline/suggested_shots.csv",
        (*TIMELINE_FIELDS[:-1], "confidence"),
        rows,
    )
    timeline_path = project / "04_timeline/timeline.csv"
    if not read_csv(timeline_path):
        write_csv(timeline_path, TIMELINE_FIELDS, timeline_rows)
    print(f"Derived {len(words)} words, {len(chunks)} captions, and {len(beats)} proposed beats.")
    print(f"Script/alignment token agreement: {ratio:.1%}; inspect alignment_review.csv before approval.")


def select_candidate(project: Path, shot_id: str, candidate_value: str) -> None:
    valid, message = validate_storyboard(project)
    if not valid:
        die(f"cannot select assets: {message}")
    candidate = Path(candidate_value).expanduser().resolve()
    if not candidate.is_file():
        die(f"candidate not found: {candidate}")
    rows = read_csv(project / "04_timeline/edit_plan.csv")
    matching = [row for row in rows if row.get("shot_id") == shot_id]
    if len(matching) != 1:
        die(f"shot not found exactly once in edit plan: {shot_id}")
    row = matching[0]
    still_extensions = {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff"}
    video_extensions = {".mp4", ".mov", ".mkv", ".webm", ".avi", ".mxf"}
    expected_extensions = still_extensions if row["asset_type"] in {"ai_still", "screenshot", "graphic"} else video_extensions
    if candidate.suffix.lower() not in expected_extensions:
        die(f"{candidate.name} does not look like a valid {row['asset_type']} candidate")
    target_dir = project / ("05_stills/approved" if row["asset_type"] in {"ai_still", "screenshot", "graphic"} else "06_video/approved")
    target = target_dir / f"{shot_id}{candidate.suffix.lower()}"
    if target.exists() and sha256_file(target) != sha256_file(candidate):
        die(f"approved target already exists with different content: {target}")
    shutil.copy2(candidate, target)
    row["asset_path"] = str(target.relative_to(project))
    write_csv(project / "04_timeline/edit_plan.csv", EDIT_PLAN_FIELDS, rows)
    print(f"Selected {candidate.name} as {row['asset_path']}")


def package_project(project: Path, force: bool) -> None:
    manifest = load_project(project)
    state, _ = stage_state(project, manifest, "assets")
    if state != "approved":
        die(f"assets gate must be approved and current before packaging (currently {state})")
    destination = project / "09_delivery"
    if destination.exists():
        if not force:
            die("09_delivery already exists; use --force to archive it and rebuild")
        archived = project / f"09_delivery.previous.{datetime.now().strftime('%Y%m%d%H%M%S')}"
        destination.replace(archived)
        print(f"Archived previous package as {archived.name}")
    temporary = project / f"09_delivery.partial.{os.getpid()}"
    if temporary.exists():
        die(f"temporary package already exists: {temporary}")
    for relative in ("video", "images", "audio/sfx", "provenance"):
        (temporary / relative).mkdir(parents=True, exist_ok=True)
    shutil.copy2(project / "02_voice/narration_master.wav", temporary / "narration_master.wav")
    shutil.copy2(project / "03_alignment/captions.srt", temporary / "captions.srt")
    shutil.copy2(project / "04_timeline/timeline.csv", temporary / "timeline.csv")
    shutil.copy2(project / "04_timeline/edit_plan.csv", temporary / "edit_plan.csv")

    for row in read_csv(project / "04_timeline/edit_plan.csv"):
        value = row.get("asset_path", "").strip()
        if not value:
            continue
        source = resolve_asset(project, value)
        folder = "images" if source.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff"} else "video"
        shutil.copy2(source, temporary / folder / source.name)
    for source in sorted((project / "07_audio").rglob("*")):
        if source.is_file():
            relative = source.relative_to(project / "07_audio")
            target = temporary / "audio" / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    for name in ("licenses.csv", "generation_log.csv"):
        shutil.copy2(project / "00_admin" / name, temporary / "provenance" / name)
    if (project / "00_admin/environment").is_dir():
        shutil.copytree(project / "00_admin/environment", temporary / "provenance/environment")

    checksums = []
    for path in sorted(item for item in temporary.rglob("*") if item.is_file()):
        checksums.append(f"{sha256_file(path)}  {path.relative_to(temporary)}")
    (temporary / "provenance/checksums.sha256").write_text("\n".join(checksums) + "\n")
    temporary.replace(destination)
    print(f"Built clean editor package: {destination}")


def substitute_tokens(value: Any, replacements: dict[str, Any]) -> Any:
    if isinstance(value, dict):
        return {key: substitute_tokens(item, replacements) for key, item in value.items()}
    if isinstance(value, list):
        return [substitute_tokens(item, replacements) for item in value]
    if isinstance(value, str):
        if value in replacements:
            return replacements[value]
        for token, replacement in replacements.items():
            value = value.replace(token, str(replacement))
    return value


def http_json(url: str, payload: dict[str, Any] | None = None) -> Any:
    body = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return json.loads(response.read())
    except (urllib.error.URLError, json.JSONDecodeError) as error:
        die(f"ComfyUI request failed ({url}): {error}")


def find_output_records(value: Any) -> list[dict[str, Any]]:
    records = []
    if isinstance(value, dict):
        if "filename" in value and value.get("type", "output") == "output":
            records.append(value)
        for nested in value.values():
            records.extend(find_output_records(nested))
    elif isinstance(value, list):
        for nested in value:
            records.extend(find_output_records(nested))
    return records


def find_model_names(value: Any) -> list[str]:
    names: set[str] = set()
    if isinstance(value, dict):
        for nested in value.values():
            names.update(find_model_names(nested))
    elif isinstance(value, list):
        for nested in value:
            names.update(find_model_names(nested))
    elif isinstance(value, str) and value.lower().endswith((".safetensors", ".ckpt", ".pth", ".pt", ".gguf")):
        names.add(Path(value).name)
    return sorted(names)


def render_shot(project: Path, shot_id: str, server: str, timeout: int) -> None:
    manifest = load_project(project)
    state, _ = stage_state(project, manifest, "storyboard")
    if state != "approved":
        die(f"storyboard must be approved and current before queueing renders (currently {state})")
    rows = read_csv(project / "04_timeline/edit_plan.csv")
    matching = [row for row in rows if row.get("shot_id") == shot_id]
    if len(matching) != 1:
        die(f"shot not found exactly once: {shot_id}")
    row = matching[0]
    workflow_value = row.get("workflow", "").strip()
    if not workflow_value:
        die(f"{shot_id} has no API workflow")
    workflow_path = resolve_asset(project, workflow_value)
    if not workflow_path.is_file():
        die(f"API workflow not found: {workflow_path}")
    workflow = json.loads(workflow_path.read_text())
    prompt = workflow.get("prompt", workflow)

    input_name = ""
    input_hash = ""
    input_value = row.get("input_path", "").strip()
    if input_value:
        input_path = resolve_asset(project, input_value)
        if not input_path.is_file():
            die(f"input image not found: {input_path}")
        comfy_input = Path(os.environ.get("VIDEO_AI_STATE", Path.home() / "Games/VideoAI/state")) / "comfyui/input"
        comfy_input.mkdir(parents=True, exist_ok=True)
        input_name = f"{project.name}_{shot_id}_{input_path.name}"
        shutil.copy2(input_path, comfy_input / input_name)
        input_hash = sha256_file(input_path)
    try:
        seed = int(row.get("seed", "") or int.from_bytes(os.urandom(4), "big"))
    except ValueError:
        die(f"invalid seed for {shot_id}")
    replacements: dict[str, Any] = {
        "{{image_prompt}}": row.get("image_prompt", ""),
        "{{motion_prompt}}": row.get("motion_prompt", ""),
        "{{negative_prompt}}": row.get("negative_prompt", ""),
        "{{seed}}": seed,
        "{{input_image}}": input_name,
        "{{output_prefix}}": f"{project.name}/{shot_id}",
    }
    prompt = substitute_tokens(prompt, replacements)
    model_names = find_model_names(prompt)
    client_id = str(uuid.uuid4())
    response = http_json(f"{server.rstrip('/')}/prompt", {"prompt": prompt, "client_id": client_id})
    prompt_id = response.get("prompt_id")
    if not prompt_id:
        die(f"ComfyUI did not return prompt_id: {response}")
    print(f"Queued {shot_id}: {prompt_id}")
    deadline = time.monotonic() + timeout
    history_record: Any = None
    while time.monotonic() < deadline:
        history = http_json(f"{server.rstrip('/')}/history/{prompt_id}")
        if isinstance(history, dict) and prompt_id in history:
            history_record = history[prompt_id]
            break
        time.sleep(2)
    if history_record is None:
        die(f"timed out waiting for {prompt_id} after {timeout}s")

    outputs_root = Path(os.environ.get("VIDEO_AI_EXPORTS", Path.home() / "Games/VideoAI/exports")) / "comfyui"
    candidate_dir = project / ("05_stills/candidates" if row["asset_type"] == "ai_still" else "06_video/candidates")
    copied = []
    for record in find_output_records(history_record.get("outputs", history_record)):
        source = outputs_root / record.get("subfolder", "") / record["filename"]
        if not source.is_file():
            continue
        existing = sorted(candidate_dir.glob(f"{shot_id}_take_*{source.suffix.lower()}"))
        target = candidate_dir / f"{shot_id}_take_{len(existing) + 1:02}{source.suffix.lower()}"
        shutil.copy2(source, target)
        copied.append(target)
        append_csv(
            project / "00_admin/generation_log.csv",
            ("asset", "shot_id", "model", "workflow_hash", "seed", "prompt_hash", "input_hash", "output_hash", "created_at", "status"),
            {
                "asset": str(target.relative_to(project)),
                "shot_id": shot_id,
                "model": ";".join(model_names) or "ComfyUI workflow",
                "workflow_hash": sha256_file(workflow_path),
                "seed": seed,
                "prompt_hash": hashlib.sha256(json.dumps(prompt, sort_keys=True).encode()).hexdigest(),
                "input_hash": input_hash,
                "output_hash": sha256_file(target),
                "created_at": now(),
                "status": "candidate",
            },
        )
    if not copied:
        die("render completed but no output files could be resolved; inspect ComfyUI history and output nodes")
    for target in copied:
        print(target)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Local-first short-form project controller")
    subparsers = parser.add_subparsers(dest="command", required=True)
    new_parser = subparsers.add_parser("new")
    new_parser.add_argument("slug")
    for command in ("status", "next", "check"):
        command_parser = subparsers.add_parser(command)
        command_parser.add_argument("--project")
    approve_parser = subparsers.add_parser("approve")
    approve_parser.add_argument("stage", choices=STAGES)
    approve_parser.add_argument("--project")
    derive_parser = subparsers.add_parser("derive")
    derive_parser.add_argument("--project")
    derive_parser.add_argument("--input")
    derive_parser.add_argument("--force", action="store_true")
    select_parser = subparsers.add_parser("select")
    select_parser.add_argument("shot_id")
    select_parser.add_argument("candidate")
    select_parser.add_argument("--project")
    package_parser = subparsers.add_parser("package")
    package_parser.add_argument("--project")
    package_parser.add_argument("--force", action="store_true")
    render_parser = subparsers.add_parser("render")
    render_parser.add_argument("shot_id")
    render_parser.add_argument("--project")
    render_parser.add_argument("--server", default="http://127.0.0.1:8188")
    render_parser.add_argument("--timeout", type=int, default=3600)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.command == "new":
        new_project(args.slug)
        return
    project = resolve_project(args.project)
    if args.command == "status":
        status(project)
    elif args.command == "next":
        next_action(project)
    elif args.command == "check":
        status(project)
        manifest = load_project(project)
        stale = [stage for stage in STAGES if stage_state(project, manifest, stage)[0] == "stale"]
        if stale:
            raise SystemExit(1)
    elif args.command == "approve":
        approve(project, args.stage)
    elif args.command == "derive":
        derive(project, args.input, args.force)
    elif args.command == "select":
        select_candidate(project, args.shot_id, args.candidate)
    elif args.command == "package":
        package_project(project, args.force)
    elif args.command == "render":
        render_shot(project, args.shot_id, args.server, args.timeout)


if __name__ == "__main__":
    main()
