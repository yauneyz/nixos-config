# Short-Form Video Workflow — From Reference to Upload

This guide turns the five-step method from the reference video into a repeatable
workflow using your Claude/ChatGPT subscriptions and the local `video-ai`
toolchain. Run `video-guide` when you need the technical reference for the local
software; run `workflow-guide` when you want to make a video.

The method in the reference video is:

```
1. Find a successful format and extract its structure
2. Use an AI assistant to write an original script in your niche
3. Generate the voice-over
4. Generate a small set of meme-style images
5. Combine them with background footage, captions, and audio
```

Our version keeps that structure, adds project organization and rights checks,
and replaces OpenArt, ElevenLabs, and CapCut with tools already on this machine.

---

## 1. Tools you will use

| Job | Tool | Where it runs |
|---|---|---|
| Find reference Shorts | YouTube in Chrome | Web |
| Download a reference transcript | `video-ai transcript` | Local CLI |
| Analyze structure and write the script | Claude or ChatGPT | Subscription app/web |
| Write image prompts and a shot list | Claude or ChatGPT | Subscription app/web |
| Generate still images | ChatGPT image generation | Subscription app/web |
| Generate moving shots | ComfyUI + Wan 2.2, or WanGP | Local GPU |
| Generate narration | Chatterbox via `video-ai-voice` | Local GPU |
| Generate optional music | ACE-Step | Local GPU/API |
| Record original gameplay if wanted | OBS Studio | Local GUI |
| Generate captions | WhisperX via `video-ai-caption` | Local GPU |
| Upscale or smooth footage | Real-ESRGAN / Practical-RIFE | Local GPU |
| Assemble and export | DaVinci Resolve | Local GUI |

Use Claude or ChatGPT for the reasoning-heavy text work. Use ChatGPT's image
generator for the meme cards and starting frames; this avoids adding another
large local still-image model. A ChatGPT subscription is separate from API
billing, so this workflow assumes you generate and download the images manually
in the ChatGPT app or website. OpenAI's current image model documentation is at
<https://developers.openai.com/api/docs/models/gpt-image-2>.

---

## 2. Preflight and project setup

Check the local stack before committing to a production session:

```sh
video-ai doctor
video-ai status
```

Create one project per Short:

```sh
video-ai new gym-hierarchy-01
cd ~/Games/VideoAI/projects/gym-hierarchy-01
```

The project contains:

```
research/   reference transcripts, URLs, structure notes, rights records
assets/     generated still images and licensed supporting material
audio/      narration, music, and sound effects
shots/      generated or recorded video clips
captions/   WhisperX subtitle files
resolve/    proxies and Resolve project material
project.json
```

Keep `script.txt` and `shot-list.md` in the project root so they are easy to
find throughout the workflow.

---

## 3. Find a format—not a script to copy

Browse Shorts in and around the subject you want to cover. Choose a reference
with a clear structure you can describe independently of its exact wording:

- What happens in the first one or two seconds?
- How many beats or examples follow?
- How often does the visual change?
- How does tension, absurdity, or curiosity escalate?
- What is the final payoff?
- Approximately how many seconds and spoken words does it use?

Views show that the complete video connected with an audience; they do not
prove that a single structural trick caused the performance. Save more than one
reference when possible and look for patterns shared across them.

Download captions without downloading the reference video:

```sh
video-ai transcript \
  'https://www.youtube.com/shorts/REFERENCE_ID' \
  research/reference.txt
```

For another language, pass its language prefix as the third argument:

```sh
video-ai transcript URL research/reference-es.txt es
```

The command produces:

- `research/reference.txt` — clean text to paste into Claude or ChatGPT
- `research/reference.vtt` — original timed captions
- `research/reference.source.json` — source URL, channel, title, date, caption
  type, and language

It prefers creator-provided subtitles and falls back to automatic captions.
It refuses to overwrite an existing transcript set.

---

## 4. Extract the structure and write an original script

Start a new Claude or ChatGPT conversation. Attach or paste
`research/reference.txt`, then use a prompt like this:

```text
Analyze this short-form transcript as a format reference.

First, describe only its abstract structure: hook, beat order, pacing,
escalation, transitions, payoff, approximate word count, tone, and visual
change points. Do not reuse its distinctive wording, jokes, examples,
characters, or story.

Then write an original script about [MY TOPIC] for [MY AUDIENCE]. Target
[DURATION] seconds. It should use the useful structural principles while
having a new premise, new examples, and my own point of view. Make every beat
factually defensible. Return:
1. the structure analysis;
2. the final voice-over only;
3. a table with timestamp, narration beat, visual purpose, and on-screen text.
```

Review the result yourself. Shorten weak setup, verify factual claims, replace
generic AI phrasing, and make sure the joke or insight belongs to your channel.
Save only the finished narration as `script.txt`; save the timing table as
`shot-list.md`.

A conversational delivery is usually around 130–170 words per minute. Generate
the voice early: its real duration becomes the timing source for everything
else.

---

## 5. Generate the voice-over

Create local narration with Chatterbox:

```sh
video-ai-voice \
  --text-file script.txt \
  --output audio/narration.wav
```

The default `turbo` model is the fast path. For another supported language:

```sh
video-ai-voice \
  --model multilingual-v3 \
  --language es \
  --text-file script.txt \
  --output audio/narration.wav
```

If you use a reference voice, it must be a voice you are authorized to clone;
the command requires both `--reference` and `--consent-confirmed`. Every WAV
gets a JSON sidecar recording its model and provenance.

Listen once before generating visuals. Fix pronunciation and pacing in the
script, regenerate, and treat the accepted WAV as locked.

---

## 6. Generate still images and moving shots

Ask Claude or ChatGPT to turn the locked narration and shot list into one image
prompt per beat:

```text
Using this final script and shot list, write one production-ready image prompt
per visual beat for ChatGPT image generation.

The Short is vertical 9:16. Keep the same visual language, lighting, character
design, lens feel, and color palette across every prompt. Each image must have
one immediately readable joke or idea, a strong silhouette, and uncluttered
space for captions. Do not imitate a living artist or use a real person's
likeness. Put any editor-added text in a separate field instead of rendering
it into the image.

Return a numbered table with filename, timestamp, prompt, negative constraints,
caption-safe area, and intended edit duration.
```

Generate the images in ChatGPT and download them into `assets/` with stable
names such as:

```
assets/01-hook.png
assets/02-treadmill.png
assets/03-chest-day.png
assets/04-payoff.png
```

Generate for a vertical composition when the interface allows it. A square 4K
image is not inherently better for a 1080×1920 Short; composition and readable
subjects matter more. Keep generated text out of the image when possible and
add exact copy in Resolve.

For motion, choose one of these paths:

- Import a generated still into the installed Wan 2.2 image-to-video workflow
  in ComfyUI.
- Use the Wan 2.2 text-to-video workflow for original background B-roll.
- Use WanGP for quicker experiments.
- Record your own gameplay in OBS if the split-screen gameplay format is part
  of the concept.

```sh
systemctl --user start comfyui
# Open http://127.0.0.1:8188 and render into the configured ComfyUI exports.
systemctl --user stop comfyui
```

Do not download a random video merely because its title says “copyright free.”
Use footage you created, public-domain material you verified, or material with
an explicit license that covers your use. Save the license or permission in
`research/`.

---

## 7. Music, captions, and enhancement

Music is optional. The voice and joke must remain clear without it. For local
music, start ACE-Step and drive its API on `127.0.0.1:8001`:

```sh
systemctl --user start ace-step
# Generate and save the accepted track under audio/.
systemctl --user stop ace-step
```

You can instead use the YouTube Audio Library and retain any required
attribution: <https://support.google.com/youtube/answer/3376882>. Generated
music may require an AI-content disclosure when you upload.

Generate captions from the locked narration:

```sh
video-ai-caption audio/narration.wav \
  --model large-v3 \
  --output_dir captions \
  --output_format srt
```

WhisperX supplies timing; Resolve supplies the final font, size, emphasis,
animation, and line breaks. Review every caption rather than publishing the raw
transcription.

Only enhance clips that need it:

```sh
# Double a generated clip's frame rate.
video-ai-rife shots/raw.mp4 shots/smooth.mp4 2

# Upscale an individual still or extracted frame.
realesrgan-ncnn-vulkan \
  -i assets/01-hook.png \
  -o assets/01-hook-4x.png \
  -n realesrgan-x4plus
```

---

## 8. Assemble in DaVinci Resolve

Convert generated clips when Resolve does not handle their delivery codec
smoothly:

```sh
video-ai proxy shots/smooth.mp4 resolve/smooth.dnxhr.mov
```

In Resolve:

1. Create a 1080×1920 vertical timeline.
2. Place `audio/narration.wav` first and do not retime it casually.
3. Put the background footage underneath the full narration.
4. Place each meme image or generated shot at its planned narration beat.
5. Change the visual whenever attention or meaning needs a reset—not merely on
   a fixed timer.
6. Import the SRT, correct it, and style captions inside the safe area.
7. Add music and SFX below the voice, then check the mix on phone speakers.
8. Add titles, logos, prices, and calls to action here rather than inside AI
   imagery.
9. Watch the full export once with sound and once muted before uploading.

Export an H.264 or H.265 vertical master appropriate for YouTube Shorts. Keep a
copy in the project's `resolve/` directory.

---

## 9. Rights, disclosure, and the feedback loop

Before upload, confirm:

- The script is original and makes meaningful changes beyond the reference.
- Every background clip, image, sound, font, and music track is yours, licensed,
  or otherwise cleared for the intended use.
- A synthetic likeness or cloned voice is not being used without permission.
- Realistic AI-generated scenes and AI-generated music are disclosed in
  YouTube Studio when required.
- The description contains any required attribution.

A Content ID claim, copyright strike, and reused-content monetization decision
are different systems. Permission also does not guarantee that a minimally
changed or mass-produced channel will qualify for monetization. Build a format
you can repeat, but give each video a distinct premise, substance, and creative
point of view.

Keep these current YouTube references with the workflow:

- Copyright and permissions:
  <https://support.google.com/youtube/answer/2797466>
- Copyright claims and strikes:
  <https://support.google.com/youtube/answer/2814000>
- Original, repetitive, and reused-content monetization rules:
  <https://support.google.com/youtube/answer/1311392>
- AI-content disclosure:
  <https://support.google.com/youtube/answer/14328491>

After publishing, record the result in `research/results.md`:

```text
Published URL:
Published date:
Hook:
Length:
Views after 24h / 7d:
Viewed vs swiped away:
Average view duration:
Retention drop points:
Comments or confusion:
What to preserve next time:
What to change next time:
```

The repeatable asset is not one copied script. It is the loop of finding a
pattern, making an original version, measuring audience behavior, and improving
the next one.

---

## 10. Fast-path checklist

Once the tools are installed and the visual style is established:

```sh
video-ai doctor
video-ai new my-short-01
cd ~/Games/VideoAI/projects/my-short-01
video-ai transcript URL research/reference.txt

# Claude/ChatGPT: structure → original script → shot list → image prompts
# ChatGPT: generate and download stills into assets/

video-ai-voice --text-file script.txt --output audio/narration.wav
video-ai-caption audio/narration.wav --output_dir captions --output_format srt

# Optional: ComfyUI/Wan, OBS, ACE-Step, RIFE, and Real-ESRGAN
# Resolve: assemble, caption-style, mix, export, review, upload
```

Fifteen minutes is plausible only for a templated edit with a finished script,
fast cloud image generations, and no local video renders. A polished original
Short will often take longer; the goal of this system is a dependable workflow,
not an arbitrary timer.
