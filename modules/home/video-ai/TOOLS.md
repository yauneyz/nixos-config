# Short-Form Video Toolkit — Everything Installed

This is the reference for every tool this NixOS config gives you for making
short-form (9:16) video: what it does, how to start it, and where its files
live. It describes the tools, not one fixed way of using them. For an
opinionated end-to-end method with approval gates, see `workflow-guide`.

Read it in the terminal with `video-guide`.

Hardware this is tuned for: RTX 4090 (24 GB), with `~/Games` as a separate
mounted volume.

---

## 1. Map of the toolkit

| Capability | Tool(s) | How you reach it |
|---|---|---|
| Image generation / editing | FLUX.2 Klein 4B, Z-Image Turbo (ComfyUI) | `systemctl --user start comfyui` → <http://127.0.0.1:8188> |
| Video generation (fast) | Wan 2.2 TI2V-5B (ComfyUI) | same |
| Video generation (quality) | Wan 2.2 I2V A14B + LightX2V 4-step (ComfyUI) | same |
| Video + synchronized audio | LTX-2.5 22B distilled INT8 (ComfyUI, opt-in `ltx` profile) | same |
| Video + audio (standalone GUI) | LTX Desktop (Lightricks; its own Python env + models in `~/Games/VideoAI/ltx-desktop`, stop the GPU services first) | `ltx-desktop` / app launcher |
| Video generation (experiments) | WanGP (many Wan/Hunyuan/LTX variants) | `systemctl --user start wangp` → <http://127.0.0.1:7861> |
| Joint audio+video generation | Ovi 1.1 (non-commercial dependency; currently blocked) | `systemctl --user start ovi` → <http://127.0.0.1:7891> |
| Narration / TTS | Chatterbox Turbo + Multilingual V3 (CLI) | `video-ai-voice` |
| Narration / TTS (voice design, cloning) | Qwen3-TTS 1.7B (web UI) | `systemctl --user start qwen-tts` → <http://127.0.0.1:7862> |
| Long-form TTS (Kokoro) | audiblez | `audiblez` |
| Word-level alignment / ASR | WhisperX large-v3 | `video-ai-caption`, `video-ai project align` |
| Music | ACE-Step 1.5 (HTTP API) | `systemctl --user start ace-step` → <http://127.0.0.1:8001> |
| Video upscaling | RelayVSR x2/x4 (ComfyUI) | ComfyUI workflows |
| Image upscaling | Real-ESRGAN (ncnn/Vulkan) | `realesrgan-ncnn-vulkan` |
| Frame interpolation | Practical-RIFE 4.25 | `video-ai-rife` |
| Project bookkeeping / automation | `video-ai` project controller | `video-ai new`, `video-ai project …` |
| Reference research | caption-only transcript grabber | `video-ai transcript` |
| Transcode / conform | ffmpeg, `video-ai normalize`, `video-ai proxy` | CLI |
| Inspect media | ffprobe, mediainfo | CLI |
| Edit / finish | DaVinci Resolve 21, Shotcut, Video Trimmer | app launcher |
| Audio editing / cleanup | Audacity, EasyEffects | app launcher |
| Still image touch-up | GIMP, swappy | app launcher |
| Screen / gameplay capture | OBS Studio, gpu-screen-recorder, wf-recorder | app launcher / CLI |
| Download source media | yt-dlp, Media Downloader | CLI / app |
| Local LLMs (scripts, prompts, storyboards) | Ollama (CUDA), llama.cpp, `llm-serve` (vLLM/llama.cpp) | CLI |
| Playback / review | mpv, imv, Loupe | CLI / app |

---

## 2. Where everything lives

Nix installs the launchers, CLI tools, services, manifests and guides.
Large, changing data lives on the `~/Games` volume. `video-ai` won't run
unless `~/Games` is its own mount.

| Path | Contents |
|---|---|
| `~/Games/VideoAI/apps/<name>/<rev>` + `current` | pinned git checkouts of every app |
| `~/Games/VideoAI/envs/<name>/<key>` + `current` | isolated Python 3.11 venvs (uv) |
| `~/Games/VideoAI/cache` | HF hub, torch, triton, uv, CUDA caches |
| `~/Games/VideoAI/state/comfyui` | ComfyUI user dir, input dir, custom nodes, installed workflows |
| `~/Games/VideoAI/projects` | `video-ai new` projects (mode 700) |
| `~/Games/VideoAI/exports/{comfyui,wangp,ovi}` | generator outputs |
| `~/Games/Models/VideoAI/comfy/...` | checksum-pinned ComfyUI models |
| `~/Games/Models/VideoAI/{ace-step,ovi,rife}` | other model weights |
| `~/.config/video-ai/*.json` | the active manifests (read-only, from Nix) |

Source of truth in this repo: `modules/home/video-ai/`

- `manifests/apps.json`: app git URLs, pinned revisions, licenses
- `manifests/models.json`: model URLs at immutable revisions, sizes, SHA-256, licenses
- `manifests/workflows.json`: pinned ComfyUI workflow templates
- `scripts/`: the launchers; `scripts/video-ai.sh` also holds the environment recipes
- `python/`: the project controller, voice CLI and transcript cleaner
- `templates/`: files copied into new projects

---

## 3. Installing and maintaining the stack (`video-ai`)

Nix activation never downloads models or builds venvs. You do that
explicitly:

```sh
video-ai sync production      # sources + envs + models + workflows for the production profile
video-ai doctor               # mount, disk, GPU, every env, model sizes, CUDA imports
video-ai status               # pinned revisions, disk use, running services
```

Lower-level syncs take an app name or a profile:

```sh
video-ai apps sync      <name|profile>   # clone pinned sources
video-ai env sync       <name|profile>   # build venvs
video-ai models sync    <profile>        # resumable, SHA-256 verified downloads
video-ai workflows sync <profile>        # install pinned ComfyUI workflows
video-ai env repair                      # relink venvs whose Nix Python was garbage-collected
```

### Profiles

| Profile | Contains | In `production`? |
|---|---|---|
| `core` | ComfyUI, WanVideoWrapper, Wan 2.2 TI2V-5B + workflows | yes |
| `hq` | Wan 2.2 I2V A14B FP8 (high/low noise), LightX2V 4-step LoRAs, Wan 2.1 VAE, workflow | yes |
| `stills` | FLUX.2 Klein 4B FP8, Z-Image Turbo, encoders/VAEs, workflows | yes |
| `audio` | Chatterbox, Qwen3-TTS, ACE-Step, WhisperX envs (weights are cached from the Hub on first use) | yes |
| `enhancement` | Practical-RIFE + 4.25 model, RelayVSR x2/x4 + workflows | yes |
| `ltx` | LTX-2.5 distilled INT8 transformer, Gemma 4 12B INT8 encoder, video/audio VAEs, latent upscaler, optional prompt-enhancer model, workflows (≈45 GB, gated) | no |
| `minimax` | MiniMax H3 W6A8 video with audio, H3 Image W4A8 generation and editing, shared Qwen3-VL encoder, VAEs and workflows (≈71 GiB) | no |
| `experiments` | WanGP | no |
| `ovi` | Ovi + its weights (includes a CC-BY-NC checkpoint) | no |
| `all` | everything | — |

Downloads always leave at least 100 GiB free on `~/Games`. Override that with
`VIDEO_AI_MIN_FREE_GIB`. Any profile containing a non-commercial checkpoint
is refused unless you set `VIDEO_AI_ALLOW_RESTRICTED=1`. This is a reminder to
read the license, not commercial clearance. Gated Hugging Face downloads use
`HF_TOKEN`, or `~/Games/VideoAI/cache/huggingface/token` if it exists. The
token is only sent to huggingface.co.

The MiniMax workflows use quantized weights with ComfyUI's normal VRAM offloading
on the RTX 4090. They appear under `video-ai` in the Workflows sidebar after
`video-ai workflows sync minimax`. The video templates start at about
480p. The image templates start at 4 megapixels. The weights use separate
[H3 video](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/LICENSE) and
[H3 Image](https://huggingface.co/MiniMaxAI/MiniMax-H3-Image/blob/main/LICENSE)
community licenses with territorial restrictions.

### Updating a component

1. Change the revision in `manifests/apps.json`, or add/replace a model entry
   with an immutable `resolve/<commit>` URL, its exact size and its SHA-256.
   The HF API's `tree/<commit>` listing reports both as `size` and `lfs.oid`.
2. If the dependencies change, bump the `env_key` suffix in `scripts/video-ai.sh`.
   A new key builds a new venv next to the old one, and `current` flips only
   when the build succeeds. Old venvs are kept for rollback.
3. Rebuild NixOS, sync the profile, then run `video-ai doctor`.

Each venv's `bin/python` points at a Nix-store Python 3.11. Every venv holds a
GC root (`.python-gcroot`) for its interpreter, so `nh clean` can't delete it.
If a venv predates that, or `doctor` reports `BROKEN`, run `video-ai env repair`.

---

## 4. Background GPU services

These are systemd user services. They conflict with each other, so starting
one stops whichever other one is running. Every service binds to 127.0.0.1
only.

| Service | Port | Foreground launcher | What it is |
|---|---|---|---|
| `comfyui` | 8188 (`COMFYUI_PORT`) | `video-ai-comfy` | node-graph UI + HTTP API for all image/video models |
| `wangp` | 7861 (`WANGP_PORT`) | `video-ai-wangp` | Wan2GP, a low-VRAM Gradio UI for many video models |
| `ace-step` | 8001 (`ACESTEP_API_PORT`) | `video-ai-ace-step` | music generation REST API |
| `qwen-tts` | 7862 (`QWEN_TTS_PORT`) | `video-ai-qwen-tts [MODEL]` | Qwen3-TTS Gradio UI |
| `ovi` | 7891 | `video-ai-ovi` | Ovi text/image → video with audio |

```sh
systemctl --user start comfyui
journalctl --user -u comfyui -f
systemctl --user stop comfyui
```

Desktop apps share the 4090. Check `nvidia-smi` before running a big job.

---

## 5. Image generation

All of these run in ComfyUI. Installed workflows show up in the sidebar under
**Workflows → video-ai/**.

| Workflow file | Model | Notes |
|---|---|---|
| `flux2-klein-4b-text-to-image.json` | FLUX.2 Klein 4B distilled FP8 + Qwen3-4B encoder | 4 steps, fast; the 4-step distilled branch is pre-enabled |
| `flux2-klein-4b-image-edit.json` | same | reference-based editing for consistent characters, objects and style |
| `z-image-turbo-text-to-image.json` | Z-Image Turbo 6B BF16 + Qwen3-4B encoder + FLUX.1 VAE | 8-step photoreal text-to-image with strong prompt following; renders legible text well |

Licenses: FLUX.2 Klein 4B and Z-Image Turbo are Apache-2.0. Both use the
same `qwen_3_4b.safetensors` text encoder, which is stored once on disk.

ComfyUI's built-in **Templates** browser lists many other models, such as
Qwen-Image, HunyuanVideo and LTX. Their weights aren't installed. The
template will offer to download them into ComfyUI's model folder, outside the
checksum manifests. To make one permanent, add it to `models.json`.

## 6. Video generation

| Workflow / tool | Model | Use it for |
|---|---|---|
| `wan22-ti2v-5b-i2v.json`, `wan22-ti2v-5b-t2v.json` | Wan 2.2 TI2V-5B FP16 | fast drafts; 704×1280 / 1280×704 at 24 fps |
| `wan22-14b-i2v.json` | Wan 2.2 I2V A14B FP8 (high-noise + low-noise experts) | best image-to-video quality installed; the template has both the LightX2V 4-step LoRA path and the full-step path (template notes on a 24 GB 4090D at 640×640: ≈97 s vs ≈536 s) |
| WanGP UI | anything Wan2GP supports; weights download to its own folders on first use | trying new open models before committing to a manifest entry |
| `ltx25-i2v.json`, `ltx25-t2v.json`, `ltx25-flf2v.json` | LTX-2.5 22B distilled INT8 + Gemma 4 12B INT8 | video **with synchronized audio** (speech, SFX, ambience), auto duration, multi-shot in one generation, first/last-frame transitions |
| Ovi UI | Ovi 1.1 FP8 | joint video + speech/SFX in one pass |

Notes:

- With FP8 weights and ComfyUI's model offloading, the A14B path fits in
  24 GB. The two experts load one after the other.
- `ComfyUI-WanVideoWrapper` (kijai) is installed as a custom node. It adds
  the Wan feature nodes: Animate, S2V, VACE, MultiTalk/InfiniteTalk, HuMo and
  LongCat. Each of those needs its own weights.
- **Ovi is blocked.** Standalone Ovi needs a FlashAttention build that isn't
  installed (`video-ai doctor` reports this). Its MMAudio checkpoint is
  CC-BY-NC.
- **LTX-2.5** is gated on Hugging Face under the LTX-2 Community License
  (free commercial use under US$10M annual revenue). Install it with
  `video-ai models sync ltx && video-ai workflows sync ltx`. That uses the
  token in `~/Games/VideoAI/cache/huggingface/token` from an account that has
  accepted the license. The transformer and encoder together are bigger than
  24 GB, so ComfyUI swaps them in and out; expect slower runs than Wan 5B.
  The `prompt_enhance` toggle needs the optional Gemma 4 E2B model, which is
  included. The DFR template isn't installed, because it needs the BF16
  encoders (26 GB + 10 GB).

## 7. Voice

### Chatterbox (`video-ai-voice`), scriptable

```sh
video-ai-voice --text 'One semantic chunk.' --output take_001.wav
video-ai-voice --text-file line.txt --output take.wav
video-ai-voice --model multilingual-v3 --language es --text '…' --output es.wav
video-ai-voice --reference me.wav --consent-confirmed --text '…' --output clone.wav
```

- `turbo` (default) is English. `multilingual-v3` covers 23+ languages.
  Both are MIT-licensed.
- Cloning needs both `--reference` and `--consent-confirmed`.
- Every WAV gets a `.wav.json` sidecar recording the model, the resolved Hub
  revision, language, device, sample rate, reference, consent and text.

### Qwen3-TTS (`video-ai-qwen-tts`), interactive

```sh
video-ai-qwen-tts                                    # CustomVoice: preset speakers + style instructions
video-ai-qwen-tts Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign   # describe a voice in text
video-ai-qwen-tts Qwen/Qwen3-TTS-12Hz-1.7B-Base          # clone from ~3 s of reference audio
```

It covers 10 languages, is Apache-2.0, and fetches weights from the Hub on
first use. It uses FlashAttention if the venv has it, and runs fine without
it. Only clone voices you're authorized to use.

### audiblez

`audiblez` is Kokoro-82M TTS for long-form text (EPUB → audio). It's handy for
quick scratch narration: `audiblez book.epub -v af_heart --cuda -o out/`.

## 8. Alignment, captions, transcripts

```sh
video-ai-caption narration.wav --model large-v3 --language en \
  --device cuda --compute_type float16 --output_dir out --output_format json
```

`video-ai-caption` is the WhisperX CLI, and all whisperx flags pass straight
through. It writes word-level timestamps as JSON, SRT, VTT, TXT or TSV.

Inside a project, `video-ai project align` runs WhisperX on the narration
master. `video-ai project derive` then regenerates `words.json`, a 2–5-word
caption SRT, a script-vs-ASR review CSV and proposed shot beats, without
running ASR again.

To get a reference video's captions without downloading the video:

```sh
video-ai transcript URL [out.txt] [lang]   # writes clean text, the raw VTT and source metadata
```

## 9. Music and sound

- **ACE-Step 1.5**: `systemctl --user start ace-step`, then use its REST API on
  :8001. `~/Games/Models/VideoAI/ace-step` holds the v1.5 turbo DiT, the
  1.7B 5 Hz LM, the Qwen3 embedding model and the VAE. The launcher's
  default LM is `acestep-5Hz-lm-0.6B`, which isn't on disk. To use the
  downloaded one, set `ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-1.7B`.
  MIT-licensed.
- **Audacity**: editing, noise reduction, loudness.
- **EasyEffects**: live PipeWire effects such as EQ and compression on a mic
  while recording.
- **Ovi** generates sound with picture (see §6).

## 10. Enhancement

| Tool | Command | Notes |
|---|---|---|
| RelayVSR x2 / x4 | ComfyUI → `relayvsr-video-x2-upscale.json` / `-x4-` | diffusion-based video super-resolution (INT8). Use x2 to bring 704×1280 Wan output to 1408×2560, then downscale to 1080×1920 for a sharper master |
| Practical-RIFE 4.25 | `video-ai-rife in.mp4 out.mp4 [N]` | N× frame interpolation, FP16. Output must be under `~/Games`; extra args go to `inference_video.py` |
| Real-ESRGAN | `realesrgan-ncnn-vulkan -i in.png -o out.png -n realesrgan-x4plus` | single images or extracted frames, via Vulkan |

## 11. Media utilities

```sh
video-ai normalize in.mp4 out.mp4   # 1080×1920 crop-fill, H.264 CRF18 yuv420p, AAC 48 kHz; keeps frame rate
video-ai proxy in.mp4 [out.mov]     # DNxHR HQ 4:2:2 + PCM24, an easy intermediate for Resolve
ffprobe -v error -show_streams in.mp4
mediainfo in.mp4
yt-dlp URL                          # download source media you're entitled to use
```

The FFmpeg build includes NVENC, so `-c:v h264_nvenc` / `hevc_nvenc` give fast
GPU encodes. Encoding a Resolve DNxHR master into an upload file:

```sh
ffmpeg -i master.mov -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p \
  -c:a aac -b:a 320k -ar 48000 -movflags +faststart master.mp4
```

## 12. Editing, capture and finishing apps

| App | Use |
|---|---|
| **DaVinci Resolve 21** (`davinci-resolve`, free edition) | main NLE: 9:16 timelines, Fusion titles, Fairlight audio, color. The free Linux build can't decode or encode H.264/H.265 or AAC. Import `video-ai proxy` files (DNxHR/PCM), export DNxHR or another intraframe codec, then make the upload file with ffmpeg (see below) |
| **Shotcut** | quick edits that don't need Resolve |
| **Video Trimmer** | lossless trims |
| **OBS Studio** | screen, webcam and gameplay recording with scenes |
| **gpu-screen-recorder**, `wf-recorder` | lightweight NVENC / Wayland screen capture |
| **GIMP**, **swappy** | still touch-ups, thumbnails, annotated screenshots |
| **Media Downloader** | GUI front end for yt-dlp |
| **mpv**, **imv**, **Loupe** | frame-accurate review and image viewing |

## 13. Ideation and prompting with local LLMs

- `ollama` (CUDA build) and `llama.cpp` (`llama-server`, `llama-cli`)
- `llm-serve`: named local model targets through vLLM or llama.cpp
  (`llm-serve --list`; see `modules/home/scripts/README-llm-serving.md`)
- Claude Desktop and ChatGPT desktop apps

Use them for script drafts, hooks, storyboard and edit-plan CSVs, and prompt
rewrites. New projects include `08_workflows/storyboard_prompt.md`, which is
a prompt contract that keeps an LLM from changing your timings.

## 14. The `video-ai` project controller (optional structure)

`video-ai new <slug>` creates a numbered project folder (`00_admin` …
`10_exports`) with templates. The `project` subcommands give you hash-locked
approval gates (`brief → script → voice → alignment → timeline → storyboard →
assets → package → master`), so any upstream change marks later stages as
stale.

```sh
video-ai project status | next | check
video-ai project approve <gate>
video-ai project voice-master [--project NAME] take1.wav take2.wav …   # 48 kHz/24-bit mono master
video-ai project align [--language xx] [--model large-v3]
video-ai project derive [--input words.json] [--force]
video-ai project render <shot_id> [--server URL] [--timeout S]       # queue a tokenized ComfyUI API workflow
video-ai project select <shot_id> <candidate>
video-ai project package [--force]                                    # clean, checksummed editor handoff
```

`project render` takes a ComfyUI workflow exported in API format and fills
these tokens: `{{image_prompt}}`, `{{motion_prompt}}`, `{{negative_prompt}}`,
`{{seed}}`, `{{input_image}}`, `{{output_prefix}}`. It reads them from the
shot's row in `04_timeline/edit_plan.csv`, submits the job to ComfyUI, copies
the outputs into the candidates folder and logs the hashes and seed.

The full method that uses these gates is in `workflow-guide`.

## 15. Model inventory (pinned, checksum-verified)

| File (under `~/Games/Models/VideoAI/comfy/`) | Size | Profile | License |
|---|---|---|---|
| `diffusion_models/wan2.2_ti2v_5B_fp16.safetensors` | 10.0 GB | core | Apache-2.0 |
| `text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors` | 6.7 GB | core, hq | Apache-2.0 |
| `vae/wan2.2_vae.safetensors` | 1.4 GB | core | Apache-2.0 |
| `diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors` | 14.3 GB | hq | Apache-2.0 |
| `diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors` | 14.3 GB | hq | Apache-2.0 |
| `loras/wan2.2_i2v_lightx2v_4steps_lora_v1_{high,low}_noise.safetensors` | 2 × 1.2 GB | hq | Apache-2.0 |
| `vae/wan_2.1_vae.safetensors` | 0.25 GB | hq | Apache-2.0 |
| `diffusion_models/flux-2-klein-4b-fp8.safetensors` | 4.1 GB | stills | Apache-2.0 |
| `text_encoders/qwen_3_4b.safetensors` | 8.0 GB | stills | Apache-2.0 (Qwen notice) |
| `vae/flux2-vae.safetensors` | 0.34 GB | stills | Apache-2.0 |
| `diffusion_models/z_image_turbo_bf16.safetensors` | 12.3 GB | stills | Apache-2.0 |
| `vae/ae.safetensors` | 0.34 GB | stills | Apache-2.0 |
| `diffusion_models/relayvsr_x{2_lightx2v,4}_int8_convrot.safetensors` | 2 × 5.2 GB | enhancement | Apache-2.0 |
| `vae/relayvsr_flash_vae_x{2,4}_fp32.safetensors` | 2 × 0.13 GB | enhancement | Apache-2.0 |

| `diffusion_models/ltx-2.5-22b-distilled-transformer-comfy-int8-convrot.safetensors` | 21.5 GB | ltx | LTX-2 Community |
| `text_encoders/gemma4-12b-with-proj-ltx-2.5-comfy-int8-convrot.safetensors` | 15.4 GB | ltx | LTX-2 Community |
| `vae/ltx-2.5-{video,audio}-vae-bf16.safetensors` | 1.5 + 0.36 GB | ltx | LTX-2 Community |
| `latent_upscale_models/ltx-2.5-latent-spatial-upscaler-x2-bf16-1.0.safetensors` | 1.0 GB | ltx | LTX-2 Community |
| `text_encoders/gemma4_e2b_it_int8_convrot.safetensors` | 5.2 GB | ltx | Apache-2.0 |

Also in the manifest: Practical-RIFE 4.25 (`rife/`, MIT) and the Ovi set
(`ovi/`: Ovi FP8, Wan T5, Wan VAE, MMAudio, of which MMAudio is CC-BY-NC).
Chatterbox, Qwen3-TTS, WhisperX and ACE-Step weights are cached from the Hub
on first use.

This is engineering bookkeeping, not legal advice. Check the current terms of
each model, voice, font, stock asset and platform before publishing.
