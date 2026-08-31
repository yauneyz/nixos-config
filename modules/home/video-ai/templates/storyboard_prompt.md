# Storyboard prompt contract

Attach `00_admin/creative_brief.md`, `01_script/script_locked.md`, and
`04_timeline/timeline.csv` to your preferred reasoning model.

```text
Act as a short-form visual editor. The supplied timeline is authoritative.

Never alter shot_id, start, end, duration, or narration. Return exactly one
record for every supplied shot, in the same order, using the edit_plan.csv
columns below.

Choose the cheapest visual form that communicates each beat well:
- text_graphic for typography, numbers, and editor-native emphasis;
- screenshot/stock/recorded for evidence and reality;
- ai_still when composition plus an editor move is sufficient;
- ai_i2v only when actual subject/environment/camera motion adds meaning;
- ai_t2v only when no still reference is useful.

Use the creative brief as a binding taste contract. Vary editorial grammar;
do not make every beat a glossy synthetic shot. Keep appearance in image_prompt
and describe only movement in motion_prompt. Use exact local relative paths.
Do not silently rewrite prompts later.

Columns:
shot_id,start,end,duration,narration,visual_function,asset_type,input_path,
asset_path,image_prompt,motion_prompt,negative_prompt,seed,workflow,editor_note
```

Human review is required before `video-ai project approve storyboard`.
