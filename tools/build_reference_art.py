"""Build the native-pixel visual theme used by the reference-quality renderer.

The artwork is deliberately assembled from authored pixel clusters and the
project's existing native tiles.  No scaling filters, generative models or
copied reference pixels are used.
"""

from __future__ import annotations

from pathlib import Path
import random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
TERRAIN = ROOT / "assets" / "foundation" / "terrain"
TOWN = ROOT / "assets" / "foundation" / "town"
UI = ROOT / "assets" / "ui" / "reference"
HEROES = ROOT / "assets" / "foundation" / "heroes_v2"
ENEMIES = ROOT / "assets" / "foundation" / "enemies"

TILE = 32
KINDS = ["earth", "road", "mud", "moss", "water", "cobble", "thorn", "barrier", "gate"]
SOURCE_CELL = {
    "earth": (0, 0), "road": (0, 0), "mud": (0, 0), "moss": (0, 0),
    "water": (3, 0), "cobble": (0, 1), "thorn": (1, 1),
    "barrier": (2, 1), "gate": (3, 1),
}
TONE = {
    "earth": ((-10, -8, -4), (7, 5, 2)),
    "road": ((-8, -7, -5), (9, 7, 4)),
    "mud": ((-16, -11, -6), (2, 1, 0)),
    "moss": ((-10, -5, -9), (5, 10, 4)),
    "water": ((-9, -6, -3), (2, 5, 7)),
    "cobble": ((-8, -7, -6), (9, 8, 6)),
    "thorn": ((-12, -7, -9), (3, 5, 2)),
    "barrier": ((-8, -7, -5), (7, 5, 3)),
    "gate": ((-8, -6, -4), (8, 6, 3)),
}


def clamp(value: int) -> int:
    return max(0, min(255, value))


def tone_tile(tile: Image.Image, kind: str, variant: int) -> Image.Image:
    image = tile.copy().convert("RGBA")
    low, high = TONE[kind]
    blend = variant / 5.0
    shift = tuple(round(low[index] * (1.0 - blend) + high[index] * blend) for index in range(3))
    pixels = image.load()
    for y in range(TILE):
        for x in range(TILE):
            r, g, b, a = pixels[x, y]
            if a:
                pixels[x, y] = (clamp(r + shift[0]), clamp(g + shift[1]), clamp(b + shift[2]), a)
    draw = ImageDraw.Draw(image)
    rng = random.Random(41041 + KINDS.index(kind) * 1009 + variant * 97)
    if kind in {"earth", "road", "mud", "moss"}:
        dark = (47, 39, 29, 150) if kind != "moss" else (38, 48, 32, 170)
        light = (126, 101, 67, 120) if kind != "moss" else (87, 105, 62, 135)
        for _ in range(5 + variant % 3):
            x, y = rng.randrange(2, 30), rng.randrange(2, 30)
            draw.point((x, y), fill=light if rng.randrange(3) == 0 else dark)
            if rng.randrange(2):
                draw.point((x + 1, y), fill=dark)
    if kind == "moss":
        clusters = [
            ((-3, 17), (9, 10), (16, 19), (10, 30), (0, 34)),
            ((18, -2), (34, -2), (34, 13), (27, 17), (20, 10)),
        ] if variant % 2 == 0 else [
            ((-2, -2), (13, -2), (17, 7), (10, 15), (-2, 12)),
            ((19, 19), (34, 15), (34, 34), (14, 34), (13, 27)),
        ]
        for points in clusters:
            draw.polygon(points, fill=(47, 67, 39, 205))
            for _ in range(7):
                x, y = rng.randrange(1, 31), rng.randrange(1, 31)
                if image.getpixel((x, y))[1] > image.getpixel((x, y))[0]:
                    draw.point((x, y), fill=(83, 97, 51, 220))
    if kind == "road":
        # A compacted earthen road: brighter grit and shallow wheel wear, not
        # the old thorn tile that accidentally read as diagonal stakes.
        draw.line((3, 7 + variant % 3, 29, 7 + variant % 3), fill=(112, 88, 57, 55))
        draw.line((2, 25 - variant % 2, 30, 25 - variant % 2), fill=(42, 35, 27, 70))
        for _ in range(8):
            x, y = rng.randrange(2, 30), rng.randrange(3, 29)
            draw.rectangle((x, y, x + rng.randrange(1, 3), y + 1), fill=(128, 106, 73, 115))
    if kind == "mud":
        for _ in range(4):
            x, y = rng.randrange(3, 26), rng.randrange(3, 27)
            draw.ellipse((x, y, x + rng.randrange(3, 7), y + rng.randrange(2, 5)), fill=(45, 35, 27, 105))
    if kind == "cobble":
        for _ in range(3):
            x, y = rng.randrange(3, 29), rng.randrange(3, 29)
            draw.line((x, y, x + rng.randrange(2, 5), y), fill=(36, 33, 28, 150))
    if kind == "water":
        for y in (7 + variant, 20 - variant):
            draw.line((3, y, 12, y), fill=(104, 122, 119, 105))
            draw.line((18, y + 3, 27, y + 3), fill=(30, 48, 48, 145))
    return image


def build_terrain() -> None:
    source = Image.open(TERRAIN / "blackthorn_tiles_32.png").convert("RGBA")
    atlas = Image.new("RGBA", (6 * TILE, len(KINDS) * TILE))
    for row, kind in enumerate(KINDS):
        sx, sy = SOURCE_CELL[kind]
        if kind == "moss":
            sx, sy = SOURCE_CELL["earth"]
        base = source.crop((sx * TILE, sy * TILE, (sx + 1) * TILE, (sy + 1) * TILE))
        for variant in range(6):
            atlas.alpha_composite(tone_tile(base, kind, variant), (variant * TILE, row * TILE))
    atlas.save(TERRAIN / "blackthorn_tiles_reference.png", optimize=True)

    overlays = Image.new("RGBA", (6 * TILE, TILE))
    cells = [Image.new("RGBA", (TILE, TILE)) for _ in range(6)]
    # Pebbles and cracks.
    d = ImageDraw.Draw(cells[0]); d.ellipse((5, 21, 8, 23), fill=(42, 38, 31, 190)); d.point((6, 21), fill=(145, 125, 91, 180)); d.line((20, 8, 24, 12), fill=(42, 35, 29, 155))
    d = ImageDraw.Draw(cells[1]); d.line((4, 19, 11, 17, 17, 21, 26, 18), fill=(31, 29, 26, 125)); d.point((17, 20), fill=(151, 132, 98, 120))
    # Weeds.
    d = ImageDraw.Draw(cells[2]);
    for x, y in ((6, 27), (21, 25), (25, 29)):
        d.line((x, y, x - 2, y - 5), fill=(62, 78, 45, 215)); d.line((x, y, x + 2, y - 6), fill=(84, 95, 52, 220))
    # Flowers and lush moss.
    d = ImageDraw.Draw(cells[3]); d.ellipse((3, 24, 13, 30), fill=(48, 70, 37, 175)); d.ellipse((18, 21, 30, 29), fill=(48, 68, 37, 170))
    for x, y, c in ((8, 23, (168, 118, 142, 255)), (24, 21, (211, 177, 102, 255)), (28, 25, (150, 121, 174, 255))):
        d.point((x, y), fill=c); d.point((x + 1, y), fill=c); d.point((x, y + 1), fill=c)
    # Roots and leaf litter.
    d = ImageDraw.Draw(cells[4]); d.line((2, 26, 10, 20, 19, 22, 30, 15), fill=(75, 58, 35, 210), width=2)
    for x, y in ((7, 12), (14, 27), (25, 9), (29, 25)):
        d.point((x, y), fill=(119, 83, 42, 190))
    # Moss intrusion for the town edge.
    d = ImageDraw.Draw(cells[5]); d.polygon(((0, 0), (32, 0), (32, 5), (25, 4), (20, 8), (13, 5), (7, 9), (0, 6)), fill=(40, 62, 38, 155))
    for index, cell in enumerate(cells):
        overlays.alpha_composite(cell, (index * TILE, 0))
    overlays.save(TERRAIN / "blackthorn_overlays_reference.png", optimize=True)


def tree_cluster(index: int) -> Image.Image:
    image = Image.new("RGBA", (64, 96))
    draw = ImageDraw.Draw(image)
    rng = random.Random(7321 + index * 173)
    trunk_x = 28 + (index % 3 - 1) * 3
    draw.polygon(((trunk_x - 5, 86), (trunk_x - 3, 43), (trunk_x + 5, 39), (trunk_x + 8, 87)), fill=(39, 29, 22, 255))
    draw.line((trunk_x - 2, 84, trunk_x, 46), fill=(98, 69, 39, 255), width=2)
    for cx, cy, radius in ((18, 45, 16), (42, 43, 17), (30, 29, 19), (12, 31, 12), (50, 29, 12)):
        cx += rng.randrange(-3, 4); cy += rng.randrange(-3, 4)
        dark = (24, 43, 29, 255); mid = (43, 67, 37, 255); light = (73, 91, 46, 255)
        # Stepped overlapping crowns avoid the flat hedge silhouette that a
        # rectangular fill creates while keeping a deliberate pixel edge.
        draw.ellipse((cx - radius, cy - radius // 2, cx + radius, cy + radius // 2 + 10), fill=dark)
        draw.ellipse((cx - radius + 4, cy - radius // 2 + 2, cx + radius - 5, cy + 5), fill=mid)
        draw.polygon(((cx - radius + 7, cy - 2), (cx - 3, cy - radius // 2 + 1), (cx + 8, cy - radius // 2 + 4), (cx + radius - 7, cy + 1), (cx + 5, cy + 5)), fill=(52, 76, 40, 255))
        draw.line((cx - radius + 7, cy - radius // 2 + 4, cx + 3, cy - radius // 2 + 2), fill=light, width=2)
    for _ in range(34):
        x, y = rng.randrange(4, 60), rng.randrange(12, 58)
        if image.getpixel((x, y))[3]:
            draw.point((x, y), fill=(92, 105, 52, 255) if rng.randrange(3) == 0 else (28, 50, 31, 255))
    draw.ellipse((trunk_x - 15, 84, trunk_x + 18, 91), fill=(15, 19, 16, 110))
    return image


def build_forest() -> None:
    for index in range(4):
        tree_cluster(index).save(TERRAIN / f"forest_cluster_{index}.png", optimize=True)


def build_fire() -> None:
    sheet = Image.new("RGBA", (6 * 24, 32))
    for frame in range(6):
        cell = Image.new("RGBA", (24, 32)); draw = ImageDraw.Draw(cell)
        sway = (-2, -1, 0, 1, 2, 0)[frame]
        draw.polygon(((4, 29), (7, 17), (10 + sway, 11), (12, 2 + frame % 3), (15, 13), (20, 20), (18, 29)), fill=(112, 45, 22, 255))
        draw.polygon(((7, 29), (9, 18), (12 + sway, 10), (16, 17), (18, 29)), fill=(218, 91, 28, 255))
        draw.polygon(((10, 29), (11, 20), (14 + sway // 2, 15), (16, 29)), fill=(255, 188, 66, 255))
        draw.rectangle((5, 29, 19, 31), fill=(61, 31, 21, 255))
        sheet.alpha_composite(cell, (frame * 24, 0))
    sheet.save(TOWN / "campfire_flames.png", optimize=True)

    glow = Image.new("RGBA", (96, 96)); draw = ImageDraw.Draw(glow)
    for radius, alpha in ((42, 8), (34, 12), (26, 18), (18, 24)):
        color = (238, 151, 55, alpha)
        draw.ellipse((48 - radius, 48 - radius, 48 + radius, 48 + radius), outline=color, width=5)
    glow.save(TOWN / "campfire_glow.png", optimize=True)


def build_hud() -> None:
    UI.mkdir(parents=True, exist_ok=True)
    rail = Image.new("RGBA", (390, 52), (15, 16, 15, 235)); d = ImageDraw.Draw(rail)
    d.rectangle((0, 2, 389, 49), fill=(24, 23, 20, 238), outline=(17, 14, 12, 255), width=2)
    d.rectangle((7, 6, 382, 45), fill=(36, 31, 24, 242), outline=(120, 91, 52, 255))
    d.line((10, 9, 379, 9), fill=(175, 128, 67, 155), width=2)
    d.line((10, 43, 379, 43), fill=(11, 12, 11, 230), width=2)
    for x in (4, 385):
        d.polygon(((x, 5), (x + (7 if x == 4 else -7), 14), (x + (7 if x == 4 else -7), 38), (x, 47)), fill=(73, 54, 37, 255), outline=(151, 111, 58, 255))
    for x in (54, 220, 304):
        d.line((x, 10, x, 42), fill=(11, 12, 11, 210)); d.line((x + 1, 10, x + 1, 42), fill=(112, 83, 48, 145))
    rail.save(UI / "resource_rail.png", optimize=True)

    button = Image.new("RGBA", (150, 52), (0, 0, 0, 0)); d = ImageDraw.Draw(button)
    d.polygon(((5, 0), (145, 0), (150, 6), (150, 46), (144, 52), (6, 52), (0, 46), (0, 6)), fill=(44, 39, 32, 246), outline=(164, 129, 75, 255))
    d.rectangle((5, 5, 144, 46), outline=(84, 66, 43, 255)); d.line((9, 8, 140, 8), fill=(211, 169, 96, 105))
    button.save(UI / "action_button.png", optimize=True)

    icons = {
        "heart": ((175, 41, 34), "heart"), "level": ((113, 72, 34), "shield"),
        "key": ((187, 142, 58), "key"), "dread": ((91, 139, 128), "eye"),
        "silver": ((175, 169, 153), "coins"), "provisions": ((144, 91, 42), "sack"),
    }
    for name, (color, kind) in icons.items():
        icon = Image.new("RGBA", (24, 24)); d = ImageDraw.Draw(icon)
        shadow = tuple(max(0, c - 55) for c in color) + (255,)
        fill = color + (255,)
        if kind == "heart":
            d.polygon(((3, 8), (6, 4), (11, 5), (12, 8), (14, 5), (19, 4), (22, 8), (21, 13), (12, 22), (3, 13)), fill=shadow)
            d.polygon(((5, 8), (7, 6), (11, 7), (12, 10), (14, 7), (18, 6), (20, 8), (19, 12), (12, 19), (5, 12)), fill=fill)
        elif kind == "shield":
            d.polygon(((4, 3), (20, 3), (20, 14), (12, 22), (4, 14)), fill=shadow); d.polygon(((6, 5), (18, 5), (18, 13), (12, 19), (6, 13)), fill=fill)
        elif kind == "key":
            d.ellipse((2, 3, 12, 13), outline=fill, width=3); d.line((10, 11, 21, 22), fill=fill, width=3); d.line((17, 18, 20, 15), fill=fill, width=2)
        elif kind == "coins":
            d.ellipse((3, 13, 18, 20), fill=shadow); d.rectangle((3, 15, 18, 18), fill=shadow); d.ellipse((3, 11, 18, 17), fill=fill)
            d.ellipse((8, 6, 22, 13), fill=shadow); d.rectangle((8, 8, 22, 11), fill=shadow); d.ellipse((8, 4, 22, 10), fill=fill); d.ellipse((12, 6, 18, 8), outline=(225, 215, 184, 255))
        elif kind == "sack":
            d.polygon(((8, 3), (16, 3), (15, 7), (20, 12), (19, 21), (5, 21), (4, 12), (9, 7)), fill=shadow)
            d.polygon(((9, 7), (15, 7), (18, 12), (17, 19), (7, 19), (6, 12)), fill=fill); d.line((8, 9, 16, 9), fill=(211, 157, 73, 255))
        else:
            d.polygon(((2, 12), (7, 7), (17, 7), (22, 12), (17, 17), (7, 17)), fill=shadow); d.ellipse((8, 8, 16, 16), fill=fill); d.ellipse((11, 10, 14, 14), fill=(22, 29, 28, 255))
        icon.save(UI / f"{name}_icon.png", optimize=True)


def build_actor_animation() -> None:
    hero_output = HEROES / "animated"
    enemy_output = ENEMIES / "animated"
    hero_output.mkdir(parents=True, exist_ok=True)
    enemy_output.mkdir(parents=True, exist_ok=True)
    hero_offsets = ((0, 0), (0, -1), (-1, 0), (0, -1), (1, 0), (0, 0))
    for path in HEROES.glob("*.png"):
        source = Image.open(path).convert("RGBA")
        sheet = Image.new("RGBA", (source.width * len(hero_offsets), source.height))
        for frame, (dx, dy) in enumerate(hero_offsets):
            sheet.alpha_composite(source, (frame * source.width + dx, dy))
        sheet.save(hero_output / path.name, optimize=True)
    enemy_offsets = ((-1, 0), (0, -1), (1, 0), (0, 0))
    for path in ENEMIES.glob("*.png"):
        source = Image.open(path).convert("RGBA")
        sheet = Image.new("RGBA", (source.width * len(enemy_offsets), source.height))
        for frame, (dx, dy) in enumerate(enemy_offsets):
            sheet.alpha_composite(source, (frame * source.width + dx, dy))
        sheet.save(enemy_output / path.name, optimize=True)


def main() -> None:
    TERRAIN.mkdir(parents=True, exist_ok=True)
    build_terrain()
    build_forest()
    build_fire()
    build_hud()
    build_actor_animation()


if __name__ == "__main__":
    main()
