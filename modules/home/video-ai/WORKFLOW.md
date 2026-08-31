# Short-Form Video Workflow — Human Taste, Machine Throughput

This is the production guide. Run `workflow-guide` when making a Short and
`video-guide` for installation, maintenance, and individual tool details.

The pipeline has one governing rule:

> Audio establishes time; humans establish editorial beats; AI generates
> candidates; Resolve establishes the final experience.

The system deliberately does **not** automate taste. It makes timing, file
handling, generation, provenance, and packaging cheap enough that you can spend
your attention on performance, pacing, visual metaphor, selection, typography,
humor, and rhythm.

## The production graph

```text
creative brief (your taste)
  → original locked script
  → Chatterbox takes
  → HUMAN VOICE APPROVAL
  → narration_master.wav                         [master clock]
  → WhisperX words + deterministic captions
  → machine-proposed visual beats
  → HUMAN TIMELINE EDIT
  → timeline.csv                                 [master edit]
  → LLM storyboard constrained to that timeline
  → still / real / graphic / motion routing
  → FLUX.2 Klein candidate stills
  → HUMAN STILL SELECTION
  → Wan 2.2 I2V only where motion earns its cost
  → HUMAN TAKE SELECTION
  → normalized, checksum-backed editor package
  → DaVinci Resolve taste work
  → 1080×1920 master
```

`video-ai project next` always tells you the next gate. `video-ai project
status` shows what is approved, ready, waiting, or stale.

## 0. One-time machine setup

After rebuilding this NixOS configuration, install the commercial-first stack:

```sh
video-ai sync production
video-ai doctor
```

That profile installs:

- ComfyUI with FLUX.2 Klein 4B and Wan 2.2 TI2V-5B workflows/models;
- Chatterbox Turbo/Multilingual V3, WhisperX, and ACE-Step environments;
- Practical-RIFE and the Nix-provided Real-ESRGAN/ffmpeg/Resolve tools.

It excludes Ovi's restricted audio dependency and skips WanGP experiments.
Those remain available as explicit optional profiles.

## 1. Create a project and write the taste contract

```sh
video-ai new desert-water-01
cd ~/Games/VideoAI/projects/desert-water-01
video-ai project next
```

The numbered project tree encodes authority and handoff order:

```text
00_admin/       creative brief, rights, logs, environment snapshot
01_script/      locked narration and pronunciation notes
02_voice/       raw takes and the one narration master
03_alignment/   word timing, captions, alignment QA
04_timeline/    machine suggestion, human timeline, edit plan
05_stills/      generated candidates and human-approved stills
06_video/       generated candidates, approved clips, normalized clips
07_audio/       music and SFX
08_workflows/   storyboard contract and API-format ComfyUI graphs
09_delivery/    clean package created for the editor
10_exports/     final master
```

Fill `00_admin/creative_brief.md`. Be concrete about audience, point of view,
delivery energy, palette, composition, visual grammar, evidence shots, motion
rules, anti-patterns, and what would make the piece unmistakably yours. This is
the binding taste contract for later assistants and models.

```sh
video-ai project approve brief
```

## 2. Study formats, then lock an original script

Study several successful references for abstract structure—not wording, jokes,
characters, stories, or a creator's signature look. Download captions without
downloading the reference video:

```sh
video-ai transcript \
  'https://www.youtube.com/shorts/REFERENCE_ID' \
  00_admin/reference-01.txt
```

Ask Claude or ChatGPT to describe the hook, beat order, escalation, payoff,
word count, and visual-change pattern. Then ask it for an original draft about
your topic under the creative brief. Verify claims and rewrite it until it
sounds like you.

Put only the final narration in `01_script/script_locked.md`. Add `|` between
phrases where **you** want a visual beat:

```text
Nobody expected | this to work.

In 1923, | two engineers tried a completely different material. |
Then the impossible part happened.
```

These markers are semantic decisions, not timestamps. The alignment stage will
resolve them against the spoken performance later.

```sh
video-ai project approve script
```

## 3. Make the voice the master clock

Render narration in semantic chunks so a bad name or line can be replaced
without regenerating everything:

```sh
video-ai-voice \
  --text 'Nobody expected this to work.' \
  --output 02_voice/narration_raw/take_001.wav

video-ai-voice \
  --text 'In 1923, two engineers tried a completely different material.' \
  --output 02_voice/narration_raw/take_002.wav
```

Chatterbox Turbo is the default English path. Use `--model multilingual-v3
--language es` when appropriate. A cloned reference voice requires both
authorization and `--consent-confirmed`; every take gets a provenance sidecar.

Choose performances yourself, then assemble them in accepted order:

```sh
video-ai project voice-master \
  02_voice/narration_raw/take_001.wav \
  02_voice/narration_raw/take_002.wav
```

This creates mono, 48 kHz, 24-bit PCM `02_voice/narration_master.wav`. Listen
from beginning to end for delivery, pronunciation, glitches, and unwanted
silence. This is the highest-leverage performance gate.

```sh
video-ai project approve voice
```

Do not change words, silence, playback speed, or this WAV after approval. If
you do, its hash changes and every timing-dependent downstream gate becomes
stale.

## 4. Align once; derive timing deterministically

```sh
video-ai project align
```

The command runs pinned WhisperX on the narration master and then creates:

- `03_alignment/words.json` — normalized word-level timing;
- `03_alignment/captions.srt` — plain 2–5-word caption events;
- `03_alignment/alignment_review.csv` — script/ASR differences;
- `04_timeline/suggested_shots.csv` — machine proposal only;
- `04_timeline/timeline.csv` — editable initial copy, all rows unlocked.

Synthetic speech still needs QA around numbers, names, acronyms, punctuation,
and text normalization. Inspect `alignment_review.csv`; set `reviewed` to
`true` on every difference only after deciding it is harmless or correcting
the timing. Inspect the SRT for awkward one-word captions and drift.

```sh
video-ai project approve alignment
```

Caption timing and shot timing are separate decisions. Captions answer “which
words appear together?” A shot answers “when does the visual idea change?”

## 5. Edit the authoritative timeline by feel

Open `04_timeline/timeline.csv`. Merge, split, and move proposed beats based on
meaning, surprise, breath, emphasis, and visual opportunity. A 0.7-second hook
or a quiet four-second hold can be right; a fixed cut interval cannot know.

For every row:

- keep millisecond precision;
- use unique zero-padded IDs (`shot_001`);
- prevent overlap and keep `duration = end - start`;
- ensure narration is covered by a deliberate visual strategy;
- set `locked` to `true` only after a human pacing pass.

```sh
video-ai project approve timeline
```

`timeline.csv` is now the only master edit. The storyboard, ComfyUI, captions,
and Resolve must not invent competing timings.

## 6. Route visuals before generating anything expensive

Use `08_workflows/storyboard_prompt.md` with the creative brief, script, and
locked timeline. Fill `04_timeline/edit_plan.csv` with exactly one record per
shot. The validator refuses any changed shot ID, time, duration, or narration.

Choose the cheapest medium that communicates the beat well:

| Asset type | Use it for |
|---|---|
| `text_graphic` | hook typography, numbers, labels, graphic emphasis in Resolve |
| `screenshot` / `stock` / `recorded` | reality, evidence, interfaces, original gameplay |
| `ai_still` | composition, setting, metaphor, character/reference consistency |
| `ai_i2v` | motion that adds meaning after a still is approved |
| `ai_t2v` | rare motion concepts that have no useful starting frame |

A strong 45-second piece might use 3–5 moving hero shots, 3–5 AI stills,
2–4 real/stock/graphic shots, and editor-native typography. This is a routing
heuristic, not a quota. Visual change does not imply new generated video.

For prompts, keep appearance in `image_prompt` and movement in
`motion_prompt`. Preserve the exact prompt and any rewritten version; a seed
alone is not reproducibility.

```sh
video-ai project approve storyboard
```

## 7. Establish the look with FLUX.2 Klein stills

```sh
systemctl --user start comfyui
# open http://127.0.0.1:8188
```

Use the installed `flux2-klein-4b-text-to-image.json` workflow for cheap
candidate compositions and `flux2-klein-4b-image-edit.json` for character,
object, environment, or style continuity from approved references. The 4B
distilled model is the four-step Apache-2.0 production default.

Generate several compositions before animating anything. A still should have a
single readable idea, strong silhouette, deliberate caption-safe negative
space, no generated typography, and a subject that survives 9:16 cropping.

You can work visually in ComfyUI, or export a known-good graph in API format,
replace values with the tokens documented in `08_workflows/README.md`, and set
that workflow path in `edit_plan.csv`:

```sh
video-ai project render shot_003
```

The API runner queues only a locked storyboard record and saves candidate
files plus workflow/input/prompt hashes and seed. Either way, selection is
human:

```sh
video-ai project select shot_003 05_stills/candidates/shot_003_take_04.png
```

## 8. Generate motion selectively with Wan 2.2

For every `ai_i2v` shot, start from the approved FLUX still and use the
installed Wan 2.2 TI2V-5B image-to-video workflow. The normal production target
is portrait 704×1280 at the model's native 24 fps. Request limited, legible
movement: a controlled push, one subject action, restrained environmental
motion. Excess motion is where scenes melt.

Use two tiers:

- **Draft:** enough quality and one or two seeds to decide whether motion helps.
- **Final:** normal Wan quality, multiple seeds only for approved hero shots.

If motion adds nothing, keep the PNG and make the pan/zoom in Resolve. Use RIFE
only when interpolation solves a visible cadence problem; do not convert 24 to
30 fps merely because the video is vertical.

```sh
video-ai project select shot_007 06_video/candidates/shot_007_take_02.mp4
video-ai project approve assets
```

Save source/license/permission records in `00_admin/licenses.csv`, including
stock, music, fonts, screenshots, likenesses, and voice references.

## 9. Normalize exceptions and build the editor handoff

Inspect odd generated clips with `ffprobe` or `mediainfo`. When Resolve needs a
predictable delivery file:

```sh
video-ai normalize \
  06_video/approved/shot_007.mp4 \
  06_video/normalized/shot_007.mp4
```

This makes 1080×1920 H.264/yuv420p with AAC audio while preserving source
cadence. For a high-quality editing intermediate instead:

```sh
video-ai proxy input.mp4 output.dnxhr.mov
```

Update `asset_path` if the normalized file becomes authoritative, re-approve
assets, then build the clean package:

```sh
video-ai project package
video-ai project approve package
```

`09_delivery/` contains only approved images/video/audio, the narration master,
captions, timeline, edit plan, licenses, generation log, environment snapshot,
and SHA-256 checksums—not every failed generation.

## 10. Finish in DaVinci Resolve

1. Create a 1080×1920 Rec.709 SDR timeline. Choose 24 fps for predominantly
   Wan footage or 30 fps for a genuinely mixed 30 fps project.
2. Put `narration_master.wav` at 00:00.000 and lock it.
3. Import `captions.srt`; keep the upstream SRT boring and do typography here.
4. Place visuals using `timeline.csv`; longer source clips are trimmed to the
   authoritative intervals.
5. Animate stills here when a crop, push, or pan is enough.
6. Add music and SFX below the voice. Audition on phone speakers.
7. Keep faces, evidence, and text away from platform UI-heavy edges.
8. Watch without stopping for drift, dead stretches, repetitive synthetic
   composition, morphing, hidden text, and cadence problems.
9. Watch once muted: the visual logic should still read.
10. Export H.264/AAC to `10_exports/master.mp4` and watch the exported file.

```sh
video-ai project approve master
video-ai project status
```

## Rights, authenticity, and the feedback loop

The production default is Chatterbox + FLUX.2 Klein 4B + Wan 2.2 because their
upstream code/model terms are materially clearer for commercial work than the
restricted alternatives in this stack. This is workflow design, not legal
advice; verify every asset and current platform rule for the actual use.

Disclose realistic synthetic or altered content when required. A repeatable
format is useful; a mass-produced noun-swapping template is not. Keep real
point of view, evidence, performance, and editorial variation in every piece.

After publishing, fill `00_admin/results.md` with retention, viewed/swiped,
comments, confusion, and what to preserve/change. The compounding asset is the
loop between your taste and audience evidence—not a single copied format.

Current primary references:

- FLUX.2 models and licenses: <https://github.com/black-forest-labs/flux2>
- ComfyUI FLUX.2 Klein workflow/model layout:
  <https://docs.comfy.org/tutorials/flux/flux-2-klein>
- Wan 2.2 capabilities/license: <https://github.com/Wan-Video/Wan2.2>
- WhisperX alignment: <https://github.com/m-bain/whisperX>
- Chatterbox models: <https://github.com/resemble-ai/chatterbox>
- YouTube synthetic-content disclosure:
  <https://support.google.com/youtube/answer/14328491>
- YouTube monetization/originality:
  <https://support.google.com/youtube/answer/1311392>
