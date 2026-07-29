# mpv controls

Custom keybindings and playback config live in [`mpv.nix`](./mpv.nix).
This is the cheat sheet.

## Scrubbing (frame-accurate)

| Input                 | Action              |
| --------------------- | ------------------- |
| `→` / `←`             | seek ±5s            |
| `Shift+→` / `Shift+←` | seek ±1s (fine)     |
| `Ctrl+→` / `Ctrl+←`   | seek ±30s (coarse)  |
| mouse wheel up / down | seek ±5s            |
| `.` / `,`             | step one frame fwd / back |

Seeks are exact (`hr-seek=yes`), so you land on the frame you expect rather
than snapping to the nearest keyframe.

## Reverse playback ("watch it backwards")

| Input       | Action                                  |
| ----------- | --------------------------------------- |
| `Ctrl+r`    | toggle reverse ⇄ forward playback       |
| `]` / `[`   | speed up / slow down (fast/slow rewind) |
| `Backspace` | reset speed to 1×                       |

Workflow: hit `Ctrl+r` to start playing backward, then tap `]` a few times for
a fast rewind. `Ctrl+r` again returns to forward.

### Notes / gotchas

- Reverse replays decoded frames out of RAM. The buffers are sized for 64 GiB
  (`video-reversal-buffer=8GiB`), giving a long reverse window even on 4K.
- The **first** reverse after a seek may stutter while the cache fills, then
  smooths out. For a longer reverse run, bump `video-reversal-buffer` higher.
- If reverse glitches on a particular file, set `hwdec = "no"` — CPU decoding is
  more reliable playing backwards.

## Applying config changes

Edit `mpv.nix`, then:

```sh
sudo nixos-rebuild switch --flake .#desktop
```
