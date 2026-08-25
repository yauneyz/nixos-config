# Video AI Pipeline — User Guide

This machine has a local, GPU-driven pipeline for producing short-form video:
image/video generation, voice and music generation, captioning, upscaling/
frame interpolation, and editing. Everything is declared in this NixOS config
(`modules/home/video-ai/`) and driven by one CLI, `video-ai`, plus a handful
of per-tool launchers it unlocks.

Run `workflow-guide` for the reference-to-upload production workflow. This
guide remains the technical manual for installing and operating the local
tools.

You don't need to know Nix to use this. You need to know: what each tool
does, what order they go in, and the commands below.

---

## 1. The big picture

Everything lives on a separate mounted volume at `~/Games/VideoAI` (source
code, Python environments, caches, your projects, exports) and
`~/Games/Models/VideoAI` (downloaded model weights, which are large — tens of
GB). This is on purpose: the tooling refuses to run at all if that volume
isn't actually mounted, so you never accidentally fill up your root disk.

The pipeline, in the order you'd typically use it for a short-form video:

```
 1. Generate visuals   → ComfyUI (Wan 2.2) or WanGP or Ovi
 2. Generate voice     → Chatterbox (TTS)
 3. Generate music/SFX → ACE-Step
 4. Caption/transcribe → WhisperX
 5. Upscale / smooth   → Real-ESRGAN / Practical-RIFE
 6. Edit & export      → DaVinci Resolve
```

You won't necessarily use every stage every time — e.g. Ovi generates
synced video+audio together, which skips steps 1–3 being separate.

---

## 2. What each tool does

| Tool | Role | Runs as |
|---|---|---|
| **ComfyUI** + Wan 2.2 (via WanVideoWrapper) | Primary image-to-video / text-to-video generator. Node-based workflow editor, most control and highest quality. | systemd service (web UI) |
| **WanGP** (Wan2GP) | Lighter, simpler Wan-based generation UI. Good for fast iteration/experiments instead of building ComfyUI graphs. | systemd service (web UI) |
| **Ovi** | Generates synchronized video *and* audio together in one pass (character-ai). Good when you want lip-synced or audio-reactive clips without stitching voice in separately. | systemd service (web UI) |
| **Chatterbox** | Text-to-speech narration, including optional voice cloning from a reference clip (consent-gated, see §6). | one-shot CLI (`video-ai-voice`) |
| **ACE-Step** | Local text-to-music generation — background music/score. | systemd service (API), driven via HTTP |
| **WhisperX** | Transcribes/aligns audio to generate captions/subtitles with word-level timing. | one-shot CLI (`video-ai-caption`) |
| **Real-ESRGAN** | Upscales generated footage (resolution boost). | CLI tool (`realesrgan-ncnn-vulkan`) |
| **Practical-RIFE** | Frame interpolation — smooths motion / raises frame rate. | one-shot CLI (`video-ai-rife`) |
| **DaVinci Resolve** | Final edit, color, and export. | GUI app |

Everything else (`video-ai apps sync`, `video-ai env sync`, `video-ai models
sync`) is plumbing to install/update these tools — see §4.

---

## 3. One-time setup

Check everything is healthy:

```sh
video-ai doctor
```

This confirms the Games volume is mounted, checks disk space, checks the
NVIDIA driver, and reports which tool environments are installed and whether
their CUDA imports work. Run this any time something seems broken.

Create the directory layout (also happens automatically, but explicit is
fine):

```sh
video-ai init
```

### Installing a tool for the first time

Each tool needs three things synced before it'll run: its **source code**,
an isolated **Python environment**, and its **model weights**. `video-ai`
groups tools into *profiles* so you can install related tools together:

- `core` — ComfyUI + Wan 2.2 (the default, main video generator)
- `audio` — Chatterbox, ACE-Step, WhisperX
- `experiments` — WanGP
- `ovi` — Ovi
- `enhancement` — Real-ESRGAN + Practical-RIFE
- `all` — everything

To install/update a whole profile at once:

```sh
video-ai apps sync core        # pull pinned source code
video-ai env sync core         # build the Python venv, install torch/deps
video-ai models sync core      # download checksum-verified model weights
video-ai workflows sync core   # install example ComfyUI workflow graphs
```

Swap `core` for `audio`, `experiments`, `ovi`, `enhancement`, or `all` to set
up the other tools. You can also sync a single named tool instead of a whole
profile, e.g. `video-ai env sync wangp` or `video-ai models sync ovi`.

Model downloads are checksum-verified and resumable — if a download is
interrupted, re-running the same `models sync` picks up where it left off.
There's also a 100 GiB free-space reserve baked in: it refuses to download
anything that would eat into that buffer, so you won't run the volume dry.

**Restricted models:** some model licenses (e.g. one of Ovi's audio
dependencies) are non-commercial. `video-ai models sync` refuses to fetch
those unless you explicitly set `VIDEO_AI_ALLOW_RESTRICTED=1`, after reading
the license terms it prints.

Check `video-ai doctor` again afterward — it'll show each environment as
`ready` and confirm CUDA/GPU imports work.

---

## 4. Launching the tools

### Generation UIs (ComfyUI, WanGP, Ovi)

These run as systemd user services with web UIs. **Only one runs at a
time** — they share the GPU and are configured to conflict with each other,
so starting one stops the others.

```sh
systemctl --user start comfyui     # then open http://127.0.0.1:8188
systemctl --user start wangp       # http://127.0.0.1:7861
systemctl --user start ovi         # port shown in its own logs
```

Stop with `systemctl --user stop <name>`, check logs with
`journalctl --user -u comfyui -f`, and check what's running with:

```sh
video-ai status
```

You can also run any of these in the foreground directly (useful for
debugging) with `video-ai-comfy`, `video-ai-wangp`, or `video-ai-ovi`.

ComfyUI workflow graphs installed via `video-ai workflows sync` show up
inside the ComfyUI UI's workflow browser under `video-ai/`.

### Reference transcripts

Download a YouTube video's creator-provided or automatic captions without
downloading the video itself:

```sh
video-ai transcript 'https://www.youtube.com/shorts/VIDEO_ID' research/reference.txt
```

The command prefers manual captions, falls back to automatic captions, and
selects English by default. Pass a language prefix as the third argument for a
different language, e.g. `video-ai transcript URL research/reference-es.txt es`.

It creates three provenance-friendly files and refuses to overwrite them:

- `reference.txt` — cleaned, de-duplicated plain text
- `reference.vtt` — the original timed captions
- `reference.source.json` — source URL, channel, video metadata, caption type,
  and selected language

Use transcripts to study an abstract format and pacing. Do not copy another
creator's distinctive wording, jokes, or story.

### ACE-Step (music)

Also a systemd service:

```sh
systemctl --user start ace-step
```

It exposes an HTTP API on `127.0.0.1:8001` (no built-in web UI) — drive it
with whatever ACE-Step API client/script you're using, or `curl`.

### Chatterbox (voice) — one-shot CLI

No service; just run it per line of narration you need:

```sh
video-ai-voice --text "Welcome back to the channel." --output narration.wav
```

Options:
- `--text-file some.txt` instead of `--text` for longer scripts
- `--model turbo` (default, fast) or `--model multilingual-v3`
- `--language en` (only meaningful for `multilingual-v3`)
- `--reference some_voice_sample.wav --consent-confirmed` to clone a voice
  from a reference clip — **only use this with a voice you have consent to
  clone.** The flag is mandatory; the script refuses without it.

Each output `.wav` gets a `.wav.json` sidecar recording the model, revision,
and whether consent was confirmed — useful provenance if you ever need to
show how a clip was made.

### WhisperX (captions) — one-shot CLI

```sh
video-ai-caption narration.wav --model large-v3 --output_dir captions/ --output_format srt
```

`video-ai-caption` is a thin wrapper that just sets up caches and execs the
real `whisperx` CLI, so any `whisperx` flag works — see `whisperx --help` or
its upstream docs for the full option list (alignment, diarization, output
formats, etc).

### Real-ESRGAN (upscale)

```sh
realesrgan-ncnn-vulkan -i input.mp4frame.png -o output.png -n realesrgan-x4plus
```

(Real-ESRGAN's ncnn build works frame-by-frame on images; for full videos,
extract frames with `ffmpeg`, upscale, then reassemble — or check for a
video-specific ESRGAN wrapper if you're doing this often.)

### Practical-RIFE (frame interpolation)

```sh
video-ai-rife input.mp4 output.mp4 2
```

The third argument is the interpolation multiplier (minimum 2 = doubles the
frame rate). Output must be written somewhere under `~/Games` — the script
enforces this.

---

## 5. Projects and editing

Create a project directory to keep a generation's assets, audio, captions,
and provenance together:

```sh
video-ai new my-short-video
```

This creates `~/Games/VideoAI/projects/my-short-video/` with `research/`,
`assets/`, `audio/`, `captions/`, `resolve/`, and `shots/` subfolders plus a
`project.json` manifest. There's no requirement to use this structure, but
it's there if you want a consistent place to collect a project's outputs
before importing into Resolve.

When you're ready to edit generated footage in DaVinci Resolve, AI-generated
video often isn't in an edit-friendly codec. Convert it to a proxy first:

```sh
video-ai proxy generated_clip.mp4
# or specify the output path:
video-ai proxy generated_clip.mp4 generated_clip.dnxhr.mov
```

This produces a DNxHR/PCM intermediate that Resolve handles smoothly.
Launch `davinci-resolve` from your app launcher as normal, import your
proxies, narration, music, and captions, and edit/export from there.

---

## 6. A full example workflow

Putting it together, generating one short clip with narration, music,
captions, and smoothed motion:

```sh
# one-time, if not already synced:
video-ai apps sync core && video-ai env sync core && video-ai models sync core
video-ai apps sync audio && video-ai env sync audio && video-ai models sync audio
video-ai apps sync enhancement && video-ai env sync enhancement && video-ai models sync enhancement

# start a project
video-ai new my-short

# generate visuals
systemctl --user start comfyui
# ... build/run a workflow in the ComfyUI web UI at http://127.0.0.1:8188,
#     save output into ~/Games/VideoAI/exports/comfyui ...
systemctl --user stop comfyui

# generate narration
video-ai-voice --text-file script.txt \
  --output ~/Games/VideoAI/projects/my-short/audio/narration.wav

# generate music
systemctl --user start ace-step
# ... drive the API on 127.0.0.1:8001 ...
systemctl --user stop ace-step

# generate captions from the narration
video-ai-caption ~/Games/VideoAI/projects/my-short/audio/narration.wav \
  --output_dir ~/Games/VideoAI/projects/my-short/captions --output_format srt

# smooth the generated clip's motion
video-ai-rife raw_clip.mp4 ~/Games/VideoAI/projects/my-short/shots/clip_smooth.mp4 2

# make an edit-friendly proxy
video-ai proxy ~/Games/VideoAI/projects/my-short/shots/clip_smooth.mp4

# edit in Resolve: import the proxy, narration, music, and .srt captions,
# cut, color, export.
```

---

## 7. Quick reference

```sh
video-ai doctor                 # health check
video-ai status                 # pinned versions, disk use, running services
video-ai apps sync <profile>    # pull source code
video-ai env sync <profile>     # build Python environments
video-ai models sync <profile>  # download model weights
video-ai workflows sync <profile>  # install ComfyUI example workflows
video-ai new <slug>             # create a project folder
video-ai transcript <url> [out] [lang]  # download and clean captions
video-ai proxy <in> [out]       # make a Resolve-friendly proxy

systemctl --user start|stop comfyui|wangp|ace-step|ovi

video-ai-voice --text "..." --output out.wav       # Chatterbox TTS
video-ai-caption <audio> --output_dir <dir>         # WhisperX captions
video-ai-rife <in> <out> <multiplier>               # frame interpolation
realesrgan-ncnn-vulkan -i <in> -o <out> -n <model>  # upscaling
```

Profiles throughout: `core`, `audio`, `experiments`, `ovi`, `enhancement`,
`all`.
