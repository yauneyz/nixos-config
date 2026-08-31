# ComfyUI API workflows

Use ComfyUI visually to establish a known-good graph, then enable Developer
Mode and export it in **API format** into this directory. Replace selected
values with these exact tokens:

- `{{image_prompt}}`
- `{{motion_prompt}}`
- `{{negative_prompt}}`
- `{{seed}}` (the entire JSON value may be this string; it becomes an integer)
- `{{input_image}}`
- `{{output_prefix}}`

Set the relative API workflow path in `04_timeline/edit_plan.csv`. With ComfyUI
running, queue a locked shot with:

```sh
video-ai project render shot_007
```

The runner patches only those explicit tokens, submits through ComfyUI's local
HTTP API, waits for completion, copies results into the appropriate candidates
folder, and records workflow/input/prompt hashes plus the seed. You still choose
the take with `video-ai project select`.
