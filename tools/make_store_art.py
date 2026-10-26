"""Draws the Roblox store art for Reel Legends into store/:
game icon, thumbnails, game pass icons and developer product icons.

Usage: python3 tools/make_store_art.py
"""

import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "store")
FONT_BOLD = "/usr/share/fonts/opentype/inter/InterDisplay-ExtraBold.otf"
FONT_SEMI = "/usr/share/fonts/opentype/inter/Inter-SemiBold.otf"

RARITY = {
    "Common": (200, 200, 200),
    "Uncommon": (90, 200, 90),
    "Rare": (70, 140, 255),
    "Epic": (170, 80, 255),
    "Legendary": (255, 170, 0),
    "Mythic": (255, 60, 120),
}
GOLD = (255, 200, 40)
NAVY = (20, 32, 52)


def font(path, size):
    return ImageFont.truetype(path, size)


def gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        draw.line([(0, y), (w, y)], fill=color)
    return img


def fish_layer(length, color, angle=0, shiny=False):
    """A cartoon fish facing right, on a transparent layer, rotated by angle degrees."""
    w, h = int(length * 1.5), int(length * 0.9)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = w * 0.55, h / 2
    body_w, body_h = length * 0.8, length * 0.42
    dark = tuple(max(0, c - 60) for c in color)
    light = tuple(min(255, c + 70) for c in color)
    # tail
    tail_x = cx - body_w / 2 + length * 0.06
    d.polygon([(tail_x, cy), (tail_x - length * 0.32, cy - length * 0.25), (tail_x - length * 0.24, cy), (tail_x - length * 0.32, cy + length * 0.25)], fill=dark)
    # fins
    d.polygon([(cx - length * 0.12, cy - body_h / 2 + 4), (cx + length * 0.05, cy - body_h / 2 - length * 0.16), (cx + length * 0.14, cy - body_h / 2 + 6)], fill=dark)
    # body
    d.ellipse([cx - body_w / 2, cy - body_h / 2, cx + body_w / 2, cy + body_h / 2], fill=color, outline=dark, width=max(2, int(length * 0.02)))
    # belly highlight
    d.ellipse([cx - body_w * 0.3, cy, cx + body_w * 0.35, cy + body_h * 0.42], fill=light)
    # stripes
    for i in range(3):
        x = cx - body_w * 0.15 + i * body_w * 0.12
        d.arc([x - body_w * 0.1, cy - body_h / 2 + 4, x + body_w * 0.1, cy + body_h / 2 - 4], 270, 90, fill=dark, width=max(2, int(length * 0.015)))
    # eye
    ex, ey, er = cx + body_w * 0.3, cy - body_h * 0.1, length * 0.055
    d.ellipse([ex - er, ey - er, ex + er, ey + er], fill=(255, 255, 255))
    d.ellipse([ex - er * 0.55, ey - er * 0.55, ex + er * 0.55, ey + er * 0.55], fill=(15, 15, 20))
    if shiny:
        for _ in range(8):
            sx, sy = random.uniform(0, w), random.uniform(0, h)
            star(d, sx, sy, length * 0.05, (255, 250, 200))
    return layer.rotate(angle, resample=Image.BICUBIC, expand=True)


def star(d, x, y, r, color):
    pts = []
    for i in range(8):
        rr = r if i % 2 == 0 else r * 0.35
        a = math.pi / 4 * i
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    d.polygon(pts, fill=color)


def paste_center(base, layer, cx, cy):
    base.alpha_composite(layer, (int(cx - layer.width / 2), int(cy - layer.height / 2)))


def outlined_text(draw, xy, text, fnt, fill, outline=(10, 20, 40), width=6, anchor="mm"):
    draw.text(xy, text, font=fnt, fill=fill, anchor=anchor, stroke_width=width, stroke_fill=outline)


def waves(draw, w, y0, h, color, count=6, amp=10):
    for row in range(count):
        y = y0 + row * h / count
        pts = []
        for x in range(0, w + 20, 20):
            pts.append((x, y + math.sin(x / 60 + row) * amp))
        draw.line(pts, fill=color, width=3)


def splash(draw, cx, cy, r, color=(230, 250, 255)):
    for i in range(9):
        a = math.pi + math.pi * i / 8
        x2, y2 = cx + math.cos(a) * r, cy + math.sin(a) * r * 1.2
        draw.line([(cx, cy), (x2, y2)], fill=color, width=max(3, int(r / 10)))
        draw.ellipse([x2 - r / 10, y2 - r / 10, x2 + r / 10, y2 + r / 10], fill=color)


def scene(size, title=True, tagline=None):
    """Sunset ocean with an island, a lighthouse and a leaping legendary fish."""
    w, h = size
    img = gradient(size, (255, 150, 90), (255, 215, 140)).convert("RGBA")
    d = ImageDraw.Draw(img)
    horizon = int(h * 0.55)
    d.ellipse([w * 0.62, horizon - h * 0.22, w * 0.62 + h * 0.3, horizon + h * 0.08], fill=(255, 235, 170))
    sea = gradient((w, h - horizon), (40, 150, 200), (15, 70, 120)).convert("RGBA")
    img.alpha_composite(sea, (0, horizon))
    d = ImageDraw.Draw(img)
    waves(d, w, horizon + 20, h - horizon, (90, 190, 230), count=8, amp=h * 0.008)
    # island with lighthouse and palm
    ix = int(w * 0.12)
    d.ellipse([ix - w * 0.16, horizon - h * 0.06, ix + w * 0.2, horizon + h * 0.06], fill=(240, 215, 150))
    d.ellipse([ix - w * 0.12, horizon - h * 0.09, ix + w * 0.15, horizon + h * 0.02], fill=(110, 190, 90))
    lx, lw = ix + w * 0.04, w * 0.03
    for i in range(5):
        y = horizon - h * 0.08 - i * h * 0.06
        d.rectangle([lx - lw / 2 + i * 2, y - h * 0.06, lx + lw / 2 - i * 2, y], fill=(240, 240, 240) if i % 2 == 0 else (200, 50, 50))
    d.ellipse([lx - lw * 0.6, horizon - h * 0.44, lx + lw * 0.6, horizon - h * 0.36], fill=(255, 245, 170))
    # dock with an angler silhouette
    dx = int(w * 0.32)
    d.rectangle([dx - w * 0.08, horizon + h * 0.06, dx + w * 0.06, horizon + h * 0.08], fill=(120, 80, 50))
    for px in range(int(dx - w * 0.07), int(dx + w * 0.06), int(w * 0.03)):
        d.rectangle([px, horizon + h * 0.08, px + w * 0.006, horizon + h * 0.13], fill=(90, 60, 40))
    ax, ay = dx + w * 0.03, horizon + h * 0.06
    d.ellipse([ax - h * 0.02, ay - h * 0.15, ax + h * 0.02, ay - h * 0.11], fill=(40, 30, 40))
    d.rectangle([ax - h * 0.018, ay - h * 0.11, ax + h * 0.018, ay - h * 0.03], fill=(40, 30, 40))
    d.rectangle([ax - h * 0.015, ay - h * 0.03, ax + h * 0.015, ay], fill=(40, 30, 40))
    tip = (ax + w * 0.12, ay - h * 0.28)
    d.line([(ax, ay - h * 0.08), tip], fill=(60, 40, 30), width=max(3, int(h * 0.006)))
    # big leaping fish on the line
    fx, fy = w * 0.62, horizon - h * 0.02
    d.line([tip, (fx - w * 0.02, fy)], fill=(255, 255, 255), width=2)
    splash(d, fx, horizon + h * 0.05, h * 0.09)
    paste_center(img, fish_layer(h * 0.42, RARITY["Legendary"], angle=25, shiny=True), fx, fy - h * 0.05)
    for sx in (0.82, 0.9):
        paste_center(img, fish_layer(h * 0.12, (90, 200, 220), angle=-30), w * sx, horizon + h * 0.04)
    if title:
        d = ImageDraw.Draw(img)
        outlined_text(d, (w * 0.5, h * 0.16), "REEL LEGENDS", font(FONT_BOLD, int(h * 0.15)), (255, 230, 120), width=max(4, int(h * 0.012)))
    if tagline:
        d = ImageDraw.Draw(img)
        outlined_text(d, (w * 0.5, h * 0.9), tagline, font(FONT_SEMI, int(h * 0.05)), (255, 255, 255), width=max(3, int(h * 0.006)))
    return img


def save(img, name, size=None):
    os.makedirs(OUT, exist_ok=True)
    if size:
        img = img.resize(size, Image.LANCZOS)
    img.convert("RGB").save(os.path.join(OUT, name), quality=95)
    print("wrote store/" + name)


def badge(bg_top, bg_bottom, draw_fn, label):
    """512x512 square icon with a rounded tile, a picture and a label."""
    s = 1024
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    tile = gradient((s, s), bg_top, bg_bottom).convert("RGBA")
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s, s], radius=180, fill=255)
    img.paste(tile, (0, 0), mask)
    d = ImageDraw.Draw(img)
    draw_fn(img, d, s)
    if label:
        outlined_text(d, (s / 2, s * 0.86), label, font(FONT_BOLD, 120), (255, 255, 255), width=10)
    return img


def crown(img, d, s):
    cx, cy, r = s / 2, s * 0.42, s * 0.3
    pts = [(cx - r, cy + r * 0.5), (cx - r, cy - r * 0.4), (cx - r * 0.5, cy), (cx, cy - r * 0.7), (cx + r * 0.5, cy), (cx + r, cy - r * 0.4), (cx + r, cy + r * 0.5)]
    d.polygon(pts, fill=GOLD, outline=(150, 100, 0), width=12)
    d.rectangle([cx - r, cy + r * 0.45, cx + r, cy + r * 0.7], fill=(230, 170, 20))
    for x in (cx - r * 0.5, cx, cx + r * 0.5):
        d.ellipse([x - 28, cy + r * 0.12, x + 28, cy + r * 0.12 + 56], fill=(220, 40, 90))


def coins_arrow(img, d, s):
    for i, (x, y) in enumerate([(0.38, 0.5), (0.5, 0.4), (0.62, 0.5)]):
        r = s * 0.14
        d.ellipse([s * x - r, s * y - r, s * x + r, s * y + r], fill=GOLD, outline=(160, 110, 0), width=14)
        outlined_text(d, (s * x, s * y), "$", font(FONT_BOLD, 150), (255, 240, 170), outline=(160, 110, 0), width=4)
    d.arc([s * 0.18, s * 0.18, s * 0.82, s * 0.78], 200, 340, fill=(255, 255, 255), width=26)
    d.polygon([(s * 0.8, s * 0.36), (s * 0.86, s * 0.24), (s * 0.7, s * 0.27)], fill=(255, 255, 255))


def big_bag(img, d, s):
    cx = s / 2
    d.rounded_rectangle([cx - s * 0.27, s * 0.3, cx + s * 0.27, s * 0.7], radius=70, fill=(150, 100, 60), outline=(90, 55, 30), width=14)
    d.arc([cx - s * 0.15, s * 0.16, cx + s * 0.15, s * 0.42], 180, 360, fill=(90, 55, 30), width=22)
    for i, color in enumerate([RARITY["Rare"], RARITY["Epic"], RARITY["Legendary"]]):
        paste_center(img, fish_layer(s * 0.26, color, angle=70 - i * 30), cx - s * 0.12 + i * s * 0.12, s * 0.3)
    outlined_text(d, (cx, s * 0.55), "60", font(FONT_BOLD, 150), (255, 255, 255), outline=(90, 55, 30), width=8)


def portal(img, d, s):
    cx, cy = s / 2, s * 0.43
    for i in range(10, 0, -1):
        r = s * 0.032 * i
        color = (int(80 + 15 * i), int(40 + 10 * i), 255)
        d.ellipse([cx - r, cy - r * 1.15, cx + r, cy + r * 1.15], outline=color, width=18)
    star(d, cx, cy, s * 0.08, (255, 255, 255))


def rod_icon(color):
    def draw(img, d, s):
        d.line([(s * 0.25, s * 0.72), (s * 0.78, s * 0.18)], fill=color, width=40)
        d.ellipse([s * 0.3 - 50, s * 0.62 - 50, s * 0.3 + 50, s * 0.62 + 50], fill=(60, 60, 70), outline=color, width=14)
        d.line([(s * 0.78, s * 0.18), (s * 0.8, s * 0.55)], fill=(255, 255, 255), width=6)
        d.ellipse([s * 0.8 - 30, s * 0.55, s * 0.8 + 30, s * 0.55 + 60], fill=(230, 60, 60))
        for _ in range(6):
            star(d, random.uniform(s * 0.2, s * 0.8), random.uniform(s * 0.15, s * 0.6), 26, (255, 250, 210))
    return draw


def trail_icon(colors):
    def draw(img, d, s):
        for i, color in enumerate(colors):
            y = s * 0.28 + i * (s * 0.36 / max(1, len(colors) - 1))
            pts = [(x, y + math.sin(x / 90) * 40) for x in range(int(s * 0.1), int(s * 0.9), 10)]
            d.line(pts, fill=color, width=46)
    return draw


def title_icon(text, color):
    def draw(img, d, s):
        d.rounded_rectangle([s * 0.08, s * 0.3, s * 0.92, s * 0.6], radius=60, fill=(20, 32, 52), outline=color, width=16)
        size = 150 if len(text) < 10 else 110
        outlined_text(d, (s / 2, s * 0.45), text, font(FONT_BOLD, size), color, width=6)
    return draw


def main():
    random.seed(7)

    icon = scene((1024, 1024), title=False)
    d = ImageDraw.Draw(icon)
    outlined_text(d, (512, 150), "REEL", font(FONT_BOLD, 210), (255, 230, 120), width=14)
    outlined_text(d, (512, 330), "LEGENDS", font(FONT_BOLD, 150), (255, 255, 255), width=12)
    save(icon, "game_icon_512.png", (512, 512))

    save(scene((1920, 1080), tagline="Catch 43 fish  -  Fight every catch  -  Hunt the weekly legend"), "thumbnail_1_1920x1080.png")

    # Thumbnail 2: feature cards
    t2 = gradient((1920, 1080), (25, 90, 150), (10, 40, 80)).convert("RGBA")
    d = ImageDraw.Draw(t2)
    outlined_text(d, (960, 120), "REEL LEGENDS", font(FONT_BOLD, 130), (255, 230, 120), width=10)
    cards = [
        ("FIGHT EVERY CATCH", "Ease off when the line goes red!", RARITY["Epic"]),
        ("FILL YOUR FISH BOOK", "43 fish, 6 rarities, shiny variants", RARITY["Rare"]),
        ("WEEKLY LEGENDS", "New legend every Monday", RARITY["Legendary"]),
    ]
    for i, (head, sub, color) in enumerate(cards):
        x0 = 90 + i * 600
        d.rounded_rectangle([x0, 260, x0 + 540, 980], radius=40, fill=(20, 32, 52), outline=color, width=10)
        paste_center(t2, fish_layer(380, color, angle=15 - i * 15, shiny=i == 2), x0 + 270, 520)
        d = ImageDraw.Draw(t2)
        outlined_text(d, (x0 + 270, 800), head, font(FONT_BOLD, 46), (255, 255, 255), width=4)
        d.text((x0 + 270, 880), sub, font=font(FONT_SEMI, 32), fill=(190, 210, 235), anchor="mm")
    save(t2, "thumbnail_2_1920x1080.png")

    passes = [
        ("pass_vip.png", (255, 210, 80), (200, 120, 20), crown, "VIP"),
        ("pass_auto_sell.png", (90, 210, 120), (30, 120, 70), coins_arrow, "AUTO SELL"),
        ("pass_big_bag.png", (110, 170, 240), (40, 80, 160), big_bag, "BIG BAG"),
        ("pass_teleporter.png", (170, 110, 255), (70, 30, 150), portal, "TELEPORT"),
    ]
    for name, top, bottom, fn, label in passes:
        save(badge(top, bottom, fn, label), name, (512, 512))

    products = [
        ("product_skin_golden.png", rod_icon((255, 200, 40)), "GOLDEN"),
        ("product_skin_neon.png", rod_icon((255, 60, 200)), "NEON PINK"),
        ("product_skin_galaxy.png", rod_icon((130, 80, 255)), "GALAXY"),
        ("product_skin_candy.png", rod_icon((255, 120, 150)), "CANDY"),
        ("product_trail_ocean.png", trail_icon([(0, 170, 255), (0, 255, 200)]), "OCEAN"),
        ("product_trail_fire.png", trail_icon([(255, 220, 0), (255, 120, 0), (255, 40, 0)]), "FIRE"),
        ("product_trail_rainbow.png", trail_icon([(255, 0, 0), (255, 200, 0), (0, 220, 0), (0, 120, 255), (200, 0, 255)]), "RAINBOW"),
        ("product_title_bigcatch.png", title_icon("Big Catch", (120, 200, 255)), "TITLE"),
        ("product_title_whisperer.png", title_icon("Fish Whisperer", (160, 255, 160)), "TITLE"),
        ("product_title_sealegend.png", title_icon("Sea Legend", (255, 190, 60)), "TITLE"),
    ]
    for name, fn, label in products:
        save(badge((60, 80, 120), (20, 32, 52), fn, label), name, (512, 512))


if __name__ == "__main__":
    main()
