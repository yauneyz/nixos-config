# Local short-form video stack

This desktop-only Home Manager module provides a reproducible control plane for
ComfyUI, Wan 2.2, WanGP, Ovi, Chatterbox, ACE-Step, WhisperX, Real-ESRGAN, and
DaVinci Resolve.

Nix owns launchers, system dependencies, user services, configuration, source
revisions, and download manifests. Large or mutable content stays on the Games
filesystem:

- Models: `/home/zac/Games/Models/VideoAI`
- Application sources and Python environments: `/home/zac/Games/VideoAI`
- Projects and generated media: `/home/zac/Games/VideoAI/projects` and
  `/home/zac/Games/VideoAI/exports`

No model is fetched during `nixos-rebuild`. Downloads are explicit, resumable,
checksum-verified, and subject to a 100 GiB free-space reserve.

## Bootstrap

After rebuilding the desktop configuration:

```sh
video-ai init
video-ai doctor
video-ai apps sync core
video-ai env sync core
video-ai workflows sync core
video-ai models sync core
```

`core` creates the native ComfyUI Wan 2.2 production path. The three required
files total about 18.1 GB.

Launch ComfyUI on demand:

```sh
systemctl --user start comfyui
systemctl --user status comfyui
```

The UI is available only on `http://127.0.0.1:8188`. Use the installed
`wan22-ti2v-5b-i2v.json` workflow as the production baseline.

Before a production run, check `nvidia-smi`. Desktop applications still share
the 4090 with the on-demand generation service. In particular, a Vicinae Qt
scene-graph failure can present as repeated `QSGRhiLayer: Unsupported size`
messages and retain many gigabytes of VRAM. If that occurs, close the launcher
and run `systemctl --user restart vicinae`; do not start a 24 GB generation job
until GPU memory has returned to its normal desktop baseline.

## Audio tools

```sh
video-ai env sync audio
systemctl --user start ace-step
video-ai-caption input.wav --output_dir captions
video-ai-voice --text-file copy.txt --output narration.wav
```

Voice cloning requires both `--reference` and `--consent-confirmed`:

```sh
video-ai-voice \
  --model multilingual-v3 \
  --language es \
  --text-file copy-es.txt \
  --reference approved-speaker.wav \
  --consent-confirmed \
  --output narration-es.wav
```

The voice command writes a JSON provenance sidecar next to the WAV file.

## Experiments and Ovi

WanGP is intentionally isolated from the ComfyUI environment:

```sh
video-ai apps sync experiments
video-ai env sync wangp
systemctl --user start wangp
```

WanGP binds to `http://127.0.0.1:7861`. Its source revision is pinned and its
automatic install/update scripts are not used.

Standalone Ovi is staged separately:

```sh
video-ai apps sync ovi
video-ai env sync ovi
video-ai models sync ovi
video-ai doctor
systemctl --user start ovi
```

Ovi requires a compatible FlashAttention build, which is deliberately not
compiled implicitly during a Nix activation. `video-ai doctor` reports whether
it is ready.

The official Ovi download path includes MMAudio-derived checkpoints whose
public terms may be non-commercial. The model sync therefore refuses those
artifacts unless `VIDEO_AI_ALLOW_RESTRICTED=1` is deliberately supplied after
license review. Do not use that override for commercial work without clearance.

## Enhancement

Real-ESRGAN's Vulkan CLI and model assets are installed directly by Nix. RIFE
uses the upstream-recommended Practical-RIFE 4.25 weights; its archive is
checksum-pinned and only the four required files are extracted.

```sh
video-ai apps sync enhancement
video-ai env sync enhancement
video-ai models sync enhancement

# Input may live anywhere, but generated media must remain on Games.
video-ai-rife input.mp4 \
  /home/zac/Games/VideoAI/exports/rife/input-2x.mp4 \
  2

realesrgan-ncnn-vulkan -i frame.png -o frame-4x.png -n realesrgan-x4plus
```

RIFE runs from a unique Games-backed working directory because its upstream
script manages a relative `temp` directory. The launcher enables FP16 on the
4090 and refuses output paths outside the Games filesystem.

## Projects and Resolve

Create a project tree with a provenance manifest:

```sh
video-ai new summer-product-ad
```

Generated H.264/H.265 media can be converted to a predictable Resolve
intermediate:

```sh
video-ai proxy generated.mp4 generated.dnxhr.mov
```

This creates DNxHR HQ video with 48 kHz PCM audio. Titles, logos, prices, CTA
copy, captions, grading, and final audio mixing belong in Resolve rather than
the generated footage.

## Updating

Updates are explicit:

1. Change a source revision in `manifests/apps.json`.
2. Review upstream dependency and license changes.
3. Increment the environment key suffix in `scripts/video-ai.sh` when the
   dependency recipe changes.
4. Rebuild NixOS.
5. Run the relevant `video-ai apps sync` and `video-ai env sync` command.
6. Run `video-ai doctor` and a small smoke generation before production use.

Old source and environment versions are retained for rollback. They are never
removed automatically.
