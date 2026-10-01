"""Fill BetterVR's Graphics pack resolution placeholders for a fixed eye size.

Port of GetNearestRulesCompatibleEyeResolution from the BetterVR launcher
(launcher/main.cpp), which does this at runtime on Windows.
"""

import math
import sys

ALIGNMENT = 8
SEARCH_RADIUS = 32
PREFERRED_MATCH_DISTANCE = 32.0
MIN_WIDTH, MIN_HEIGHT = 1280.0, 720.0

# (width, height, weight, heightBias)
REDEFINE_RULES = [
    (640, 368, 8.0, 0.49),
    (640, 360, 8.0, 0.0),
    (384, 192, 7.0, 0.0),
    (320, 192, 7.0, 0.0),
    (320, 180, 7.0, 0.0),
    (192, 96, 6.0, 0.0),
    (160, 96, 6.0, 0.0),
    (160, 90, 6.0, 0.0),
    (128, 48, 5.0, 0.0),
    (96, 48, 5.0, 0.0),
    (80, 45, 4.0, 0.0),
    (64, 64, 4.0, 0.0),
]

PRESETS = [
    ("05", 0.5),
    ("075", 0.75),
    ("10", 1.0),
    ("125", 1.25),
    ("15", 1.5),
    ("175", 1.75),
    ("20", 2.0),
    ("225", 2.25),
    ("30", 3.0),
]


def dist_to_int(v):
    return abs(v - round(v))


def penalty(w, h):
    total = 0.0
    for rw, rh, weight, bias in REDEFINE_RULES:
        ow = (w / 1280.0) * rw
        oh = (h / 720.0) * rh + bias
        total += (dist_to_int(ow) + dist_to_int(oh)) * weight
    return total


def nearest(width, height):
    scale = max(1.0, MIN_WIDTH / width, MIN_HEIGHT / height)
    width *= scale
    height *= scale

    def evaluate(cw, ch):
        return (cw, ch, math.hypot(cw - width, ch - height), penalty(cw, ch))

    tw = max(1, int(math.floor(width + 0.5)))
    th = max(1, int(math.floor(height + 0.5)))
    target = evaluate(tw, th)
    best = target

    def align_down(v):
        return v - v % ALIGNMENT

    sw = max(ALIGNMENT, align_down(tw - SEARCH_RADIUS if tw > SEARCH_RADIUS else ALIGNMENT))
    sh = max(ALIGNMENT, align_down(th - SEARCH_RADIUS if th > SEARCH_RADIUS else ALIGNMENT))
    for cw in range(sw, tw + SEARCH_RADIUS + 1, ALIGNMENT):
        for ch in range(sh, th + SEARCH_RADIUS + 1, ALIGNMENT):
            c = evaluate(cw, ch)
            if c[2] <= PREFERRED_MATCH_DISTANCE and (
                c[3] < best[3] or (c[3] == best[3] and c[2] < best[2])
            ):
                best = c

    if best[3] < target[3]:
        return best[0], best[1]
    return target[0], target[1]


def main():
    eye_w, eye_h, path = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    with open(path, encoding="utf-8") as f:
        contents = f.read()
    for key, mult in PRESETS:
        w, h = nearest(eye_w * mult, eye_h * mult)
        contents = contents.replace(f"__BETTERVR_{key}_NAME__", f"{w}x{h}")
        contents = contents.replace(f"__BETTERVR_{key}_WIDTH__", str(w))
        contents = contents.replace(f"__BETTERVR_{key}_HEIGHT__", str(h))
        print(f"BetterVR {mult}x preset: {w}x{h}")
    if "__BETTERVR_" in contents:
        sys.exit("unresolved BetterVR placeholders remain")
    with open(path, "w", encoding="utf-8") as f:
        f.write(contents)


if __name__ == "__main__":
    main()
