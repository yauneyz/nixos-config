# ComfyUI on the desktop and laptop

Both machines use the same ComfyUI workspace. The desktop's RTX 4090 runs the
jobs and the desktop stores the models, workflows, uploads, and outputs. The
laptop only needs its browser and the existing Tailscale SSH connection.

## Open ComfyUI

**On the desktop**, start the user service and open
[http://127.0.0.1:8188](http://127.0.0.1:8188).

```sh
systemctl --user start comfyui
```

**On the laptop**, open **ComfyUI (Desktop GPU)** from the app launcher or run
`comfy-remote`. It starts ComfyUI on the desktop, creates a private SSH tunnel,
and opens [http://127.0.0.1:18188](http://127.0.0.1:18188) on the laptop.
Both machines must be on Tailscale, and the desktop needs to be awake.
Complete any Tailscale SSH sign-in prompt in the launcher's terminal.
The launcher is installed when you run `rebuild laptop` from the updated
checkout on the laptop.

If you need to connect before activating the laptop configuration, run this on
the laptop and leave the terminal open while you use port 18188.

```sh
ssh -o ExitOnForwardFailure=yes -L 127.0.0.1:18188:127.0.0.1:8188 desktop \
  'systemctl --user start comfyui.service && exec sleep infinity'
```

Run `comfy-remote --close` to disconnect the laptop. Jobs already queued on the
desktop keep running. Closing just the browser tab also leaves the queue intact.
Stop ComfyUI on the desktop with `systemctl --user stop comfyui` when its queue
is idle.

## Generate your first image

1. In the left sidebar, open **Workflows → video-ai → minimax-h3-image-t2i.json**.
2. Replace the example text in the large prompt field. Try *A wide shot of a
   greenhouse at blue hour, warm lamps glowing inside, raindrops on the glass,
   natural colors and realistic reflections*.
3. Start with the template's 4-megapixel setting. Pick an aspect ratio in
   **Resolution Selector**. Keep prompt enhancement off for the first run.
4. Click **Queue** in the top toolbar. Follow progress in the **Queue** sidebar.
   When the job finishes, the result appears in **Save Image** and in the output
   history. Open the preview to save a copy to the machine you're using.

For an edit, open `minimax-h3-image-edit.json`, upload a source image in
**Load Image**, and change **Text (user_prompt)**. Describe what to change and
what to preserve. For example, *Replace the blue umbrella with a red one.
Keep the person's pose, framing, and background*. The template resizes the
input to about 4 megapixels. If you want to skip the extra prompt-enhancement
pass, turn off **Enable PE?**.

## Generate a video with audio

| Workflow in **Workflows → video-ai** | What to supply |
|---|---|
| `minimax-h3-t2v.json` | A prompt. Describe the scene, action, camera movement, and desired sounds or dialogue. |
| `minimax-h3-i2v.json` | Upload the starting image in **Load Image**. Describe how it should move and what should be heard. The generation subgraph also has an optional last-frame input. |
| `minimax-h3-r2v.json` | Replace the two example images in **Load Image** and refer to them as `<Picture 1>` and `<Picture 2>` in **Input Text (Prompt)**. |

1. Start with a short clip and roughly 0.4 megapixels. The text-to-video
   template starts around 864 × 480 in widescreen. In image-to-video, the
   **ImageScaleToTotalPixels** node controls how large the uploaded image is
   made before generation. Try 0.4 there for a first run.
2. Use the workflow's duration control. In text-to-video and image-to-video,
   duration is exposed on the generation subgraph. In reference-to-video,
   look for **Float (Duration)**. Start at two seconds while checking a setup.
3. Enable **Lightning LoRA** if you want the template's faster sampling path.
   Keep the model dropdowns on the supplied quantized files.
4. Click **Queue**. **Save Video** writes the clip with the generated audio.
   Try *A slow dolly toward a greenhouse in rain. The leaves move in a light
   breeze. Hear rain on the roof and distant thunder. No music.*

For a vertical clip, select a 9:16 aspect ratio or use a vertical starting
image. Increase duration or resolution one at a time after a successful run.

## More workflows and files

- **FLUX.2 Klein** and **Z-Image Turbo** handle stills. **Wan 2.2** and
  **LTX-2.5** are other video workflows. **RelayVSR** upscales an existing
  video. Use the workflow files installed under **video-ai**. The built-in
  template library can list models outside your installed profiles.
- Use **Save As** or duplicate a workflow before editing it. A workflow sync can
  replace the managed originals.
- Uploaded inputs live on the desktop in
  `~/Games/VideoAI/state/comfyui/input`. Outputs live in
  `~/Games/VideoAI/exports/comfyui`. Use the browser preview to download a
  result or copy it from the desktop over SSH.
- Model files live under `~/Games/Models/VideoAI/comfy`. The `minimax`
  profile installs the W6A8 video models and W4A8 image model with a shared
  text encoder, VAEs, LoRAs, and the image prompt enhancer.
- See the [video AI tools reference](modules/home/video-ai/TOOLS.md) for
  narration, speech, captions, music, upscaling, interpolation, and editing
  outside ComfyUI.

## If a job fails

- **Missing model:** Wait for the desktop download to finish, then reload
  ComfyUI and reopen the managed workflow. Check the desktop with
  `video-ai doctor`. To refresh the workflow files on the desktop, use
  `video-ai workflows sync minimax`.
- **CUDA out of memory:** Run one job at a time. Lower video resolution or
  duration and close other GPU-heavy apps. Keep the image workflow near
  4 megapixels first. ComfyUI offloads weights to system memory as needed.
- **Laptop cannot connect:** Run `ssh desktop` to check Tailscale SSH. On the
  desktop, check `systemctl --user status comfyui`. For job and startup logs,
  run `journalctl --user -u comfyui -f` on the desktop.
