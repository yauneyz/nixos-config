# Video AI Pipeline — Technical Guide

This machine has a reproducible, local-first short-form production stack built
for a 24 GB RTX 4090. Run `workflow-guide` for the human production method. This
guide explains the installed control plane, commands, models, and maintenance.

## What changed and why

The stack is no longer just a set of generators. `video-ai` now enforces a
project contract around:

- a 48 kHz/24-bit mono narration master as the timing source;
- deterministic word/caption/beat derivation;
- a human-locked `timeline.csv` as the only edit authority;
- a constrained storyboard that cannot modify timing;
- still-first FLUX.2 generation and selective Wan I2V;
- explicit human candidate promotion;
- hash-backed approval gates and clean editor packaging;
- prompts, seeds, workflows, source revisions, licenses, and media checksums.

If an approved upstream artifact changes, downstream gates report `stale`.
This makes iteration safe without pretending it never happens.

## Storage and safety

Large/mutable state lives off the root disk:

| Purpose | Path |
|---|---|
| Sources, environments, caches, projects | `~/Games/VideoAI` |
| Model checkpoints | `~/Games/Models/VideoAI` |
| ComfyUI outputs | `~/Games/VideoAI/exports/comfyui` |
| ComfyUI input/state | `~/Games/VideoAI/state/comfyui` |

The launcher refuses to operate unless `~/Games` is its own mounted filesystem.
Model syncs are resumable, SHA-256 verified, and preserve at least 100 GiB free.
Nix activation never downloads models.

## Installed roles

| Role | Default | Notes |
|---|---|---|
| Still generation/editing | FLUX.2 Klein 4B FP8 | Apache-2.0 4B distilled path; fast candidate/reference iteration |
| Video generation | Wan 2.2 TI2V-5B | Apache-2.0; T2V/I2V; 704×1280/24 fps production path |
| Generation UI/API | ComfyUI | pinned source; native model offload; local HTTP API |
| Narration | Chatterbox Turbo / Multilingual V3 | semantic takes; consent-gated cloning; provenance sidecars |
| Alignment | WhisperX | pinned environment; known-script mismatch review |
| Captions/beats/gates | `pipeline.py` | deterministic standard-library code |
| Music | ACE-Step 1.5 | optional local API |
| Enhancement | Real-ESRGAN / Practical-RIFE | use only for visible problems |
| Finish | DaVinci Resolve | typography, pacing, sound, grading, export |

WanGP and Ovi remain isolated experiments. Ovi includes an MMAudio-derived
checkpoint with non-commercial terms and is never part of `production`.

## Bootstrap and profiles

The normal one-command setup is:

```sh
video-ai sync production
video-ai doctor
```

`production` means core video + stills + audio + enhancement. It intentionally
excludes experimental/restricted tools. The command performs pinned source,
environment, model, and workflow syncs in the correct order.

Lower-level commands remain available:

```sh
video-ai apps sync core
video-ai env sync audio
video-ai models sync stills
video-ai workflows sync stills
```

Profiles:

- `core`: ComfyUI, Wan wrapper, Wan 2.2 checkpoints/workflows;
- `stills`: FLUX.2 Klein 4B model, encoder, VAE, and workflows;
- `audio`: Chatterbox, ACE-Step, WhisperX environments (their Hub weights are
  cached lazily on first use);
- `enhancement`: Practical-RIFE plus Nix-provided Real-ESRGAN;
- `experiments`: WanGP;
- `ovi`: Ovi, explicitly restricted where its dependency terms require it;
- `production`: commercial-first union;
- `all`: everything, including items that require a license override.

Use `VIDEO_AI_ALLOW_RESTRICTED=1` only after reviewing the printed terms and
intended use. It is not a commercial-clearance switch.

## Daily project commands

```sh
video-ai new my-short
cd ~/Games/VideoAI/projects/my-short

video-ai project status
video-ai project next
video-ai project approve brief
video-ai project approve script
video-ai project voice-master 02_voice/narration_raw/*.wav
video-ai project approve voice
video-ai project align
video-ai project approve alignment
video-ai project approve timeline
video-ai project approve storyboard
video-ai project render shot_003
video-ai project select shot_003 05_stills/candidates/shot_003_take_02.png
video-ai project approve assets
video-ai project package
video-ai project approve package
video-ai project approve master
```

Pass `--project NAME` to project commands when not inside its directory. The
`voice-master` command expects `--project` before input files.

### Approval semantics

The ordered gates are:

```text
brief → script → voice → alignment → timeline → storyboard
      → assets → package → master
```

Approval validates the artifact, hashes every file belonging to the gate, and
records the timestamp/hash in `project.json` and `00_admin/build_log.csv`.
Changing a file makes that gate and every downstream gate stale. Re-review and
approve from the first changed gate; nothing is deleted automatically.

### Alignment and deterministic derivation

`video-ai project align` runs the pinned WhisperX CLI with CUDA float16,
`large-v3`, batch size 8, and project language. It then compares recognized
tokens against the known locked script and produces plain SRT plus proposed
visual beats. All non-equal rows in `alignment_review.csv` begin with
`reviewed=false`, which blocks approval until a human resolves them.

Rerun derivation from an existing WhisperX JSON without ASR:

```sh
video-ai project derive --input 03_alignment/narration_master.json --force
```

Human `|` markers in the locked script take precedence when they map cleanly to
aligned words. Otherwise the beat suggester uses punctuation and duration as a
low-authority fallback. It never feeds expensive generation directly.

### ComfyUI automation without surrendering graph control

ComfyUI stays useful as a visual workflow editor. Once a graph works, export it
in API format under `08_workflows/` and replace selected values with documented
tokens (`{{image_prompt}}`, `{{motion_prompt}}`, `{{negative_prompt}}`,
`{{seed}}`, `{{input_image}}`, `{{output_prefix}}`).

`video-ai project render SHOT`:

1. refuses an unlocked/stale storyboard;
2. reads only that shot's edit-plan record;
3. patches explicit tokens and stages the input image;
4. submits to `http://127.0.0.1:8188/prompt`;
5. waits for history completion;
6. copies outputs into the project candidates folder;
7. logs the workflow, input, prompt hashes and seed.

The human then promotes a take with `project select`; automation never chooses
the aesthetically “best” output.

## Services and manual launchers

Only one large GPU service runs at a time:

```sh
systemctl --user start comfyui    # http://127.0.0.1:8188
systemctl --user start wangp      # http://127.0.0.1:7861
systemctl --user start ace-step   # API at http://127.0.0.1:8001
systemctl --user start ovi
```

The services conflict intentionally to avoid VRAM contention. Stop and inspect:

```sh
systemctl --user stop comfyui
journalctl --user -u comfyui -f
video-ai status
```

Foreground launchers are `video-ai-comfy`, `video-ai-wangp`,
`video-ai-ace-step`, and `video-ai-ovi`.

## Tool reference

### Reference transcript

```sh
video-ai transcript URL output.txt [language-prefix]
```

This downloads captions, not the reference video. It prefers manual captions,
falls back to automatic captions, refuses overwrites, and saves cleaned text,
original VTT, and source metadata.

### Chatterbox

```sh
video-ai-voice --text 'A semantic chunk.' --output take.wav
video-ai-voice --model multilingual-v3 --language es \
  --text-file line.txt --output take-es.wav
```

Voice cloning requires `--reference FILE --consent-confirmed`. Use only an
authorized voice. The `.wav.json` sidecar records model, resolved revision,
language, device, sample rate, reference, consent, and text.

### Media normalization and proxies

```sh
video-ai normalize input.mp4 output.mp4
video-ai proxy input.mp4 output.dnxhr.mov
```

`normalize` makes H.264/yuv420p at 1080×1920 and deliberately preserves native
cadence. `proxy` makes DNxHR HQ/PCM24. Neither is an aesthetic enhancement.

### Enhancement

```sh
video-ai-rife input.mp4 output.mp4 2
realesrgan-ncnn-vulkan -i input.png -o output.png -n realesrgan-x4plus
```

RIFE output must remain under `~/Games`; the launcher isolates upstream's temp
directory and uses FP16. Real-ESRGAN works frame-by-frame.

## Model set and licenses

The default still path consists of:

```text
models/comfy/diffusion_models/flux-2-klein-4b-fp8.safetensors
models/comfy/text_encoders/qwen_3_4b.safetensors
models/comfy/vae/flux2-vae.safetensors
```

The default video path consists of:

```text
models/comfy/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors
models/comfy/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors
models/comfy/vae/wan2.2_vae.safetensors
```

Every URL contains an immutable repository revision and every file has an
expected size and SHA-256 in `manifests/models.json`. FLUX.2 Klein 4B and Wan
2.2 are the clear production defaults; do not casually substitute FLUX 9B/dev,
Ovi's restricted dependency, or a territorially restricted video checkpoint
into monetized/global work.

## Doctor, diagnosis, and updating

```sh
video-ai doctor
video-ai status
nvidia-smi
```

`doctor` checks the Games mount, free space, NVIDIA, environments, CUDA imports,
and special dependencies. Desktop applications share the 4090; clear abnormal
VRAM use before a 24 GB generation job.

Updates are explicit:

1. Change a pinned revision in `manifests/apps.json`.
2. Review upstream requirements and license changes.
3. Increment the relevant `env_key` suffix when dependency recipes change.
4. Update model/workflow manifests with immutable URLs and checksums.
5. Rebuild NixOS, sync the affected profile, run `doctor`, and smoke-test.

Old source/environment versions remain for rollback and are never removed
automatically.
