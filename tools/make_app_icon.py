"""Renders the ClipForge mark (a hand-drawn-feeling infinity loop) to PNG.

The geometry here is the same as `lib/widgets/brand/clipforge_logo.dart`
(`InfinityMarkGeometry`) — keep the two in sync if you change one.

  python tools/make_app_icon.py preview out.png    # 1024 px preview on ink
  python tools/make_app_icon.py android            # writes mipmap-*/ic_launcher.png

Why it looks "drawn": the stroke is one open pen line (it starts and ends with a
taper and does not quite close), it is thicker on the down-strokes, the right
loop is a little bigger than the left, the whole thing leans a few degrees, and
the crossing is an over/under (one strand passes on top with a small gap).
"""
import math
import os
import sys

from PIL import Image, ImageDraw

INK = (16, 17, 20)
EMBER = (255, 122, 69)
CREAM = (242, 238, 232)

T_START = 0.32           # where the pen lands (just below the right tip)
T_END = 2 * math.pi + 0.10  # where it lifts (a hair past the right tip again)
TAPER = 0.85             # radians of taper at each end
TILT = math.radians(-5)
RIGHT_SCALE = 1.10       # right loop bigger than the left
STEPS = 900


def point(t):
    """Unit-size lemniscate of Bernoulli, x in about [-1, 1], with the tweaks."""
    s = math.sin(t)
    d = 1 + s * s
    x = math.cos(t) / d
    y = s * math.cos(t) / d
    if x > 0:
        x *= RIGHT_SCALE
        y *= RIGHT_SCALE
    # lean
    cx, sx = math.cos(TILT), math.sin(TILT)
    return x * cx - y * sx, x * sx + y * cx


def width(t):
    """Relative stroke width: heavier on down-strokes, tapered pen ends."""
    w = 1.0 + 0.32 * math.cos(t - 0.9)
    a = min(t - T_START, T_END - t) / TAPER
    if a < 1:
        a = max(a, 0)
        w *= 0.18 + 0.82 * (a * a * (3 - 2 * a))
    return w


def render(size, bg, fg, scale=0.39, stroke=0.072, gap_color=None, supersample=4):
    S = size * supersample
    img = Image.new("RGBA", (S, S), bg if bg else (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    cx = cy = S / 2
    R = S * scale
    base = S * stroke
    gap_color = gap_color or bg

    def P(t):
        x, y = point(t)
        return cx + x * R, cy + y * R

    def stamp(t0, t1, col, extra=0.0):
        n = max(2, int(STEPS * (t1 - t0) / (2 * math.pi)))
        for i in range(n + 1):
            t = t0 + (t1 - t0) * i / n
            x, y = P(t)
            r = base * width(t) / 2 + extra
            dr.ellipse((x - r, y - r, x + r, y + r), fill=col)

    stamp(T_START, T_END, fg)
    # Over/under: the strand through the crossing at t = 3*pi/2 goes on top.
    # Lay down a gap (background colour) along a short piece of it, then
    # redraw a slightly longer piece in the stroke colour.
    over = 3 * math.pi / 2
    if gap_color:
        stamp(over - 0.20, over + 0.20, gap_color, extra=base * 0.30)
    stamp(over - 0.42, over + 0.42, fg)
    return img.resize((size, size), Image.LANCZOS)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "preview"
    if mode == "preview":
        out = sys.argv[2] if len(sys.argv) > 2 else "icon_preview.png"
        render(1024, INK, EMBER).save(out)
        print("wrote", out)
    elif mode == "android":
        root = os.path.join(os.path.dirname(__file__), "..", "android", "app", "src", "main", "res")
        sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
        for name, px in sizes.items():
            # Legacy launcher icon: rounded ink square with the mark.
            icon = render(px, INK, EMBER, scale=0.33, stroke=0.066)
            mask = Image.new("L", (px * 4, px * 4), 0)
            ImageDraw.Draw(mask).rounded_rectangle((0, 0, px * 4 - 1, px * 4 - 1), radius=px * 4 * 0.23, fill=255)
            mask = mask.resize((px, px), Image.LANCZOS)
            out = Image.new("RGBA", (px, px), (0, 0, 0, 0))
            out.paste(icon, (0, 0), mask)
            path = os.path.join(root, f"mipmap-{name}", "ic_launcher.png")
            out.save(path)
            print("wrote", os.path.normpath(path), px)
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
