"""Render the home-screen SwingingRobot animation to a GIF.

Mirrors RobotPainter in lib/screens/home_screen.dart so the README can show
the actual animation without a screen recording. If you tweak the painter,
re-run: `python3 scripts/render_robot_gif.py`.
"""

import math
import os
from PIL import Image, ImageDraw

SCALE = 4
W, H = 100 * SCALE, 120 * SCALE
PIVOT_X, PIVOT_Y = 50 * SCALE, 0
PRIMARY = (0x8A, 0x48, 0xF0)
GREY_400 = (189, 189, 189)
WHITE = (255, 255, 255)
STROKE = 2 * SCALE

FPS = 20
LOOP_SECONDS = 6.0  # swing controller is 3s with reverse:true → full cycle 6s
TOTAL_FRAMES = int(FPS * LOOP_SECONDS)

OUT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "screenshots", "swinging_robot.gif"
)


def ease_in_out_cubic(t: float) -> float:
    """Approximation of Flutter's Curves.easeInOut (Cubic(0.42, 0, 0.58, 1))."""
    if t < 0.5:
        return 4 * t * t * t
    p = 2 * t - 2
    return 0.5 * p * p * p + 1


def render_body_layer(blink_value: float) -> Image.Image:
    """Cable, body, accent, head, eyes — axis-aligned, pivot at top center."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    px, py = PIVOT_X, PIVOT_Y

    d.line([(px, py), (px, py + 40 * SCALE)], fill=GREY_400, width=STROKE)

    bx0, by0 = px - 20 * SCALE, py + 45 * SCALE
    bx1, by1 = px + 20 * SCALE, py + 95 * SCALE
    d.rounded_rectangle(
        [bx0, by0, bx1, by1],
        radius=8 * SCALE,
        fill=WHITE,
        outline=GREY_400,
        width=STROKE,
    )

    accent = (*PRIMARY, int(255 * 0.1))
    ax, ay, ar = px, py + 70 * SCALE, 10 * SCALE
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(overlay).ellipse(
        [ax - ar, ay - ar, ax + ar, ay + ar], fill=accent
    )
    img = Image.alpha_composite(img, overlay)
    d = ImageDraw.Draw(img)

    hx0, hy0 = px - 15 * SCALE, py + int((40 - 12.5) * SCALE)
    hx1, hy1 = px + 15 * SCALE, py + int((40 + 12.5) * SCALE)
    d.rounded_rectangle(
        [hx0, hy0, hx1, hy1],
        radius=6 * SCALE,
        fill=WHITE,
        outline=GREY_400,
        width=STROKE,
    )

    eye_alpha = 0.3 + 0.7 * blink_value
    eye_color = (*PRIMARY, int(255 * eye_alpha))
    er = 3 * SCALE
    eye_overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    eod = ImageDraw.Draw(eye_overlay)
    for dx in (-7, 7):
        ex = px + dx * SCALE
        ey = py + 40 * SCALE
        eod.ellipse([ex - er, ey - er, ex + er, ey + er], fill=eye_color)
    return Image.alpha_composite(img, eye_overlay)


def _world(lx: float, ly: float, swing: float) -> tuple[float, float]:
    """Apply translate(pivot) + rotate(swing) to a robot-local point."""
    c, s = math.cos(swing), math.sin(swing)
    return (PIVOT_X + lx * c - ly * s, PIVOT_Y + lx * s + ly * c)


def draw_limb(
    canvas: ImageDraw.ImageDraw,
    ox: float,
    oy: float,
    length: float,
    local_angle: float,
    swing: float,
) -> None:
    """Limb drawn as `translate(ox,oy) → rotate(local) → line((0,0)→(0,length))`,
    then rotated by the global swing around the pivot."""
    end_lx = ox - length * math.sin(local_angle)
    end_ly = oy + length * math.cos(local_angle)
    p1 = _world(ox, oy, swing)
    p2 = _world(end_lx, end_ly, swing)
    canvas.line([p1, p2], fill=GREY_400, width=STROKE)


def render_frame(swing: float, blink: float) -> Image.Image:
    body = render_body_layer(blink)
    rotated = body.rotate(
        -math.degrees(swing),
        center=(PIVOT_X, PIVOT_Y),
        resample=Image.BICUBIC,
    )

    arm_angle = swing * 0.5
    leg_angle = swing * 1.2
    d = ImageDraw.Draw(rotated)
    draw_limb(d, -20 * SCALE, 60 * SCALE, 20 * SCALE, 0.5 + arm_angle, swing)
    draw_limb(d, 20 * SCALE, 60 * SCALE, 20 * SCALE, -0.5 + arm_angle, swing)
    draw_limb(d, -10 * SCALE, 95 * SCALE, 15 * SCALE, leg_angle, swing)
    draw_limb(d, 10 * SCALE, 95 * SCALE, 15 * SCALE, leg_angle * 0.8, swing)

    return rotated.resize((W // SCALE, H // SCALE), Image.LANCZOS)


def main() -> None:
    frames: list[Image.Image] = []
    for i in range(TOTAL_FRAMES):
        t = i / TOTAL_FRAMES
        # Controller runs 0→1 over first 3s, 1→0 over next 3s. With easeInOut both ways.
        controller = (
            ease_in_out_cubic(t * 2) if t < 0.5 else ease_in_out_cubic((1 - t) * 2)
        )
        swing = -0.2 + 0.4 * controller

        # Blink: 1.5s each direction, full cycle 3s → two cycles per 6s loop.
        blink_t = (t * LOOP_SECONDS) % 3.0
        blink = blink_t / 1.5 if blink_t < 1.5 else (3.0 - blink_t) / 1.5

        rgba = render_frame(swing, blink)
        bg = Image.new("RGB", rgba.size, (255, 255, 255))
        bg.paste(rgba, mask=rgba.split()[3])
        frames.append(bg)

    out = os.path.normpath(OUT_PATH)
    frames[0].save(
        out,
        save_all=True,
        append_images=frames[1:],
        duration=int(1000 / FPS),
        loop=0,
        optimize=True,
        disposal=2,
    )
    print(f"wrote {out} ({len(frames)} frames, {LOOP_SECONDS}s loop)")


if __name__ == "__main__":
    main()
