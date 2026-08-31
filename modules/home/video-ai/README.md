# Local-first short-form video stack

This Home Manager module provides the reproducible control plane for a
human-directed, local-first RTX 4090 video workflow.

The production architecture is:

```text
creative brief → script → approved voice master → WhisperX timing
→ deterministic captions/proposed beats → human timeline lock
→ constrained storyboard → FLUX.2 still candidates → human selection
→ selective Wan 2.2 I2V → human selection → media/package QA
→ DaVinci Resolve → final master
```

Nix owns launchers, system dependencies, user services, source revisions,
workflow manifests, model manifests, and guides. Large mutable content lives on
the guarded Games filesystem:

- `/home/zac/Games/VideoAI`: sources, venvs, caches, state, projects, exports;
- `/home/zac/Games/Models/VideoAI`: checksum-pinned model files.

No model downloads occur during activation. Explicit syncs are resumable and
preserve a 100 GiB disk reserve.

## Bootstrap

```sh
video-ai sync production
video-ai doctor
```

The `production` profile is the commercial-first union of core Wan/ComfyUI,
FLUX.2 Klein stills, audio/alignment, and enhancement. WanGP and Ovi remain
opt-in; restricted checkpoints are never silently pulled into production.

## Operator entry points

```sh
workflow-guide             # production method and taste checkpoints
video-guide                # technical operation and maintenance
video-ai new <slug>        # numbered, provenance-ready project
video-ai project next      # one actionable next gate
video-ai project status    # approval/staleness report
video-ai help              # complete command list
```

The project controller is standard-library Python packaged by Nix. Approval
hashes make changes visible and invalidate downstream gates without deleting
work. ComfyUI automation uses explicit API-workflow tokens; it queues and logs
candidates but never chooses them.

## Maintenance contract

- Source revisions live in `manifests/apps.json`.
- Model URLs, sizes, SHA-256 values, profiles, and licenses live in
  `manifests/models.json`.
- Pinned UI workflows live in `manifests/workflows.json`.
- Environment recipes and key suffixes live in `scripts/video-ai.sh`.
- Project orchestration lives in `python/pipeline.py` and `templates/`.

When changing any component, review licensing, bump its environment key when
dependencies change, rebuild, sync only the relevant profile, run `video-ai
doctor`, and perform a small end-to-end project smoke test.
