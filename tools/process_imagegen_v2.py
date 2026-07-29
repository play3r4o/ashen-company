"""Convert approved ImageGen source sheets into native runtime pixel assets.

Run the imagegen skill's chroma-key helper first, placing alpha PNGs in
tmp/imagegen_v2. This script only crops, normalizes and nearest-neighbour
resizes approved art; it does not draw replacement artwork.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ALPHA = ROOT / "tmp" / "imagegen_v2"
SOURCE = ROOT / "assets" / "foundation" / "sources" / "imagegen_v2"
OUT = ROOT / "assets" / "generated" / "reference_v2"
HERO_OUT = OUT / "heroes"
ENEMY_OUT = OUT / "enemies"
UI_OUT = OUT / "ui"


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Generated cell has no visible subject")
    return bbox


def fit_subject(subject: Image.Image, canvas: tuple[int, int], inset: int = 2) -> Image.Image:
    width, height = canvas
    bbox = alpha_bbox(subject)
    cropped = subject.crop(bbox)
    scale = min((width - inset * 2) / cropped.width, (height - inset * 2) / cropped.height)
    target = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    resized = cropped.resize(target, Image.Resampling.NEAREST)
    result = Image.new("RGBA", canvas)
    result.alpha_composite(resized, ((width - target[0]) // 2, height - inset - target[1]))
    return result


def grid_cell(sheet: Image.Image, columns: int, rows: int, column: int, row: int) -> Image.Image:
    left = round(column * sheet.width / columns)
    right = round((column + 1) * sheet.width / columns)
    top = round(row * sheet.height / rows)
    bottom = round((row + 1) * sheet.height / rows)
    return sheet.crop((left, top, right, bottom))


def build_heroes() -> None:
    HERO_OUT.mkdir(parents=True, exist_ok=True)
    directions = ("down", "left", "right", "up")
    for class_id in ("warrior", "hunter", "mage", "rogue"):
        source = Image.open(ALPHA / f"{class_id}_sheet_alpha.png").convert("RGBA")
        for row, direction in enumerate(directions):
            frames = [fit_subject(grid_cell(source, 4, 4, column, row), (56, 64)) for column in range(4)]
            ordered = (frames[0], frames[1], frames[2], frames[3], frames[2], frames[3])
            strip = Image.new("RGBA", (56 * 6, 64))
            for index, frame in enumerate(ordered):
                strip.alpha_composite(frame, (index * 56, 0))
            strip.save(HERO_OUT / f"{class_id}_{direction}.png", optimize=True)


def build_enemies() -> None:
    ENEMY_OUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(ALPHA / "enemy_atlas_alpha.png").convert("RGBA")
    entries = (
        ("wolf", 0, 0, (60, 48)), ("raider", 1, 0, (56, 64)), ("archer", 2, 0, (60, 64)),
        ("reaver", 0, 1, (60, 68)), ("blighted", 1, 1, (56, 68)), ("crow", 2, 1, (68, 56)),
        ("houndmaster", 0, 2, (64, 72)), ("grave_guard", 1, 2, (68, 76)), ("barrow_knight", 2, 2, (80, 88)),
    )
    for enemy_id, column, row, canvas in entries:
        base = fit_subject(grid_cell(source, 3, 3, column, row), canvas)
        strip = Image.new("RGBA", (canvas[0] * 4, canvas[1]))
        offsets = ((-1, 0), (0, -1), (1, 0), (0, 0))
        for frame, offset in enumerate(offsets):
            strip.alpha_composite(base, (frame * canvas[0] + offset[0], offset[1]))
        strip.save(ENEMY_OUT / f"{enemy_id}.png", optimize=True)


def build_ui() -> None:
    UI_OUT.mkdir(parents=True, exist_ok=True)
    rail = Image.open(ALPHA / "hud_rail_alpha.png").convert("RGBA")
    rail = rail.crop(alpha_bbox(rail)).resize((390, 52), Image.Resampling.NEAREST)
    rail.save(UI_OUT / "resource_rail.png", optimize=True)

    controls = Image.open(ALPHA / "controls_alpha.png").convert("RGBA")
    upper = controls.crop((0, 0, controls.width, controls.height // 2))
    lower = controls.crop((0, controls.height // 2, controls.width, controls.height))
    button = upper.crop(alpha_bbox(upper)).resize((160, 56), Image.Resampling.NEAREST)
    cog = lower.crop(alpha_bbox(lower)).resize((56, 56), Image.Resampling.NEAREST)
    button.save(UI_OUT / "action_button.png", optimize=True)
    cog.save(UI_OUT / "settings_cog.png", optimize=True)

    icons = Image.open(ALPHA / "hud_icons_alpha.png").convert("RGBA")
    icon_entries = (
        ("level", 0, 0), ("heart", 1, 0), ("silver", 2, 0),
        ("provisions", 0, 1), ("key", 1, 1), ("dread", 2, 1),
    )
    for icon_id, column, row in icon_entries:
        icon = fit_subject(grid_cell(icons, 3, 2, column, row), (24, 24), 1)
        icon.save(UI_OUT / f"{icon_id}_icon.png", optimize=True)


def build_environment() -> None:
    master = Image.open(SOURCE / "refuge_master.png").convert("RGBA")
    # Runtime version remains large enough for pixel-snapped world movement;
    # it is mapped to camp geometry without destructive painterly filtering.
    target_width = 780
    target_height = round(master.height * target_width / master.width)
    master.resize((target_width, target_height), Image.Resampling.NEAREST).save(OUT / "refuge_master_runtime.png", optimize=True)


def main() -> None:
    build_heroes()
    build_enemies()
    build_ui()
    build_environment()


if __name__ == "__main__":
    main()
