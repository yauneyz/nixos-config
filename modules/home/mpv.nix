{ ... }:
{
  programs.mpv = {
    enable = true;

    config = {
      # --- Decoding / output ---
      hwdec = "auto-safe"; # GPU decode when it's known-good, else CPU
      keep-open = "yes"; # don't close the window at end of file

      # --- Precise scrubbing ---
      # Exact (frame-accurate) seeking instead of snapping to keyframes, so
      # dragging / tapping through a clip lands where you expect.
      hr-seek = "yes";
      hr-seek-framedrop = "no";
      osd-fractions = "yes"; # show fractional seconds in the OSD timer

      # --- Caches sized for reverse playback ---
      # Reverse playback replays decoded frames out of RAM. The demuxer cache
      # holds cheap compressed data; the reversal buffers hold expensive decoded
      # frames and set how long a window you can watch backwards before it runs
      # out. Sized generously for 64GiB of RAM (only fills as needed) so even
      # high-bitrate 4K gives a long reverse window.
      cache = "yes";
      demuxer-max-bytes = "8GiB";
      demuxer-max-back-bytes = "8GiB";
      demuxer-seekable-cache = "yes";
      video-reversal-buffer = "8GiB";
      audio-reversal-buffer = "1GiB";
    };

    bindings = {
      # --- Forward/back scrubbing (exact) ---
      RIGHT = "seek  5 exact";
      LEFT = "seek -5 exact";
      "Shift+RIGHT" = "seek  1 exact"; # fine scrub
      "Shift+LEFT" = "seek -1 exact";
      "Ctrl+RIGHT" = "seek  30 exact"; # coarse scrub
      "Ctrl+LEFT" = "seek -30 exact";

      # Mouse wheel scrubs the timeline
      WHEEL_UP = "seek  5 exact";
      WHEEL_DOWN = "seek -5 exact";

      # Frame-by-frame ( , and . are mpv's defaults, listed here for clarity )
      "." = "frame-step";
      "," = "frame-back-step";

      # --- Reverse playback ---
      # Toggle "watch it backwards". Combine with [ / ] to slow down / speed up
      # the reverse (fast-rewind), and Backspace to reset speed.
      "Ctrl+r" = ''cycle-values play-dir "backward" "forward"; show-text "play-dir: ''${play-dir}"'';
    };
  };
}
