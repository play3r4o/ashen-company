"""Build the modular Refuge runtime kit from approved ImageGen sources.

The generated art stays independent: terrain, Hall, wall pole, gate, props,
forest dressing, construction plot, and campfire frames are exported as
separate native-resolution textures. Nothing here composites a finished camp.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ALPHA = ROOT / "tmp" / "imagegen_v3"
SOURCE = ROOT / "assets" / "foundation" / "sources" / "imagegen_v3"
OUT = ROOT / "assets" / "generated" / "reference_v3"
TOWN_OUT = OUT / "town"
DECOR_OUT = TOWN_OUT / "decor"
FOREST_OUT = OUT / "forest"
TERRAIN_OUT = OUT / "terrain"
OUTLINE_OUT = TOWN_OUT / "outlines"


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Generated cell has no visible subject")
    return bbox


def grid_cell(sheet: Image.Image, columns: int, rows: int, column: int, row: int) -> Image.Image:
    return sheet.crop(
        (
            round(column * sheet.width / columns),
            round(row * sheet.height / rows),
            round((column + 1) * sheet.width / columns),
            round((row + 1) * sheet.height / rows),
        )
    )


def fit_subject(subject: Image.Image, canvas: tuple[int, int], inset: int = 2) -> Image.Image:
    subject = subject.crop(alpha_bbox(subject))
    scale = min((canvas[0] - inset * 2) / subject.width, (canvas[1] - inset * 2) / subject.height)
    target = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    subject = subject.resize(target, Image.Resampling.NEAREST)
    result = Image.new("RGBA", canvas)
    result.alpha_composite(subject, ((canvas[0] - target[0]) // 2, canvas[1] - inset - target[1]))
    return result


def fit_subjects_shared(
    subjects: list[Image.Image], canvas: tuple[int, int], inset: int = 2
) -> list[Image.Image]:
    """Keep every frame at a shared scale and on a shared ground baseline."""
    cropped = [subject.crop(alpha_bbox(subject)) for subject in subjects]
    max_width = max(subject.width for subject in cropped)
    max_height = max(subject.height for subject in cropped)
    scale = min(
        (canvas[0] - inset * 2) / max_width,
        (canvas[1] - inset * 2) / max_height,
    )
    frames: list[Image.Image] = []
    for subject in cropped:
        target = (
            max(1, round(subject.width * scale)),
            max(1, round(subject.height * scale)),
        )
        resized = subject.resize(target, Image.Resampling.NEAREST)
        result = Image.new("RGBA", canvas)
        result.alpha_composite(
            resized,
            ((canvas[0] - target[0]) // 2, canvas[1] - inset - target[1]),
        )
        frames.append(result)
    return frames


def fit_frames_shared_window(
    subjects: list[Image.Image], canvas: tuple[int, int], inset: int = 2
) -> list[Image.Image]:
    """Map every animation cell through one union crop and one transform.

    This preserves the generated motion while keeping fixed elements such as
    the benches, stone ring and ground contact on identical pixel anchors.
    """
    bboxes = [alpha_bbox(subject) for subject in subjects]
    union = (
        min(bbox[0] for bbox in bboxes),
        min(bbox[1] for bbox in bboxes),
        max(bbox[2] for bbox in bboxes),
        max(bbox[3] for bbox in bboxes),
    )
    union_width = union[2] - union[0]
    union_height = union[3] - union[1]
    scale = min(
        (canvas[0] - inset * 2) / union_width,
        (canvas[1] - inset * 2) / union_height,
    )
    target = (
        max(1, round(union_width * scale)),
        max(1, round(union_height * scale)),
    )
    frames: list[Image.Image] = []
    for subject in subjects:
        normalized = subject.crop(union).resize(target, Image.Resampling.NEAREST)
        result = Image.new("RGBA", canvas)
        result.alpha_composite(
            normalized,
            ((canvas[0] - target[0]) // 2, canvas[1] - inset - target[1]),
        )
        frames.append(result)
    return frames


def save_outline(image: Image.Image, destination: Path) -> None:
    alpha = image.getchannel("A")
    expanded = alpha.filter(ImageFilter.MaxFilter(5))
    ring = ImageChops.subtract(expanded, alpha)
    outline = Image.new("RGBA", image.size, (225, 183, 101, 0))
    outline.putalpha(ring)
    outline.save(destination, optimize=True)


def build_town() -> None:
    TOWN_OUT.mkdir(parents=True, exist_ok=True)
    DECOR_OUT.mkdir(parents=True, exist_ok=True)
    OUTLINE_OUT.mkdir(parents=True, exist_ok=True)

    hall = fit_subject(Image.open(ALPHA / "hall_alpha.png").convert("RGBA"), (132, 176), 2)
    hall.save(TOWN_OUT / "veterans_hall_0.png", optimize=True)
    save_outline(hall, OUTLINE_OUT / "veterans_hall_0.png")

    wall_sheet = Image.open(ALPHA / "palisade_gate_alpha.png").convert("RGBA")
    # The gate is wider than one half of the source sheet, so a logical 2-cell
    # split would cut off its left post. These authored source windows isolate
    # the two complete silhouettes before normalizing them independently.
    pole = fit_subject(wall_sheet.crop((180, 80, 430, 910)), (16, 64), 0)
    gate = fit_subject(wall_sheet.crop((520, 70, 1340, 920)), (112, 88), 1)
    pole.save(TOWN_OUT / "wall_pole.png", optimize=True)
    gate.save(TOWN_OUT / "town_gate.png", optimize=True)

    prop_sheet = Image.open(ALPHA / "props_alpha.png").convert("RGBA")
    props = (
        ("barrels", 0, 0, (58, 58)),
        ("crates", 1, 0, (64, 58)),
        ("weapon_rack", 2, 0, (68, 72)),
        ("banner", 0, 1, (72, 82)),
        ("firewood", 1, 1, (66, 54)),
        ("drying_rack", 2, 1, (72, 76)),
    )
    for prop_id, column, row, canvas in props:
        fit_subject(grid_cell(prop_sheet, 3, 2, column, row), canvas).save(
            DECOR_OUT / f"{prop_id}.png", optimize=True
        )

    plot = fit_subject(Image.open(ALPHA / "plot_alpha.png").convert("RGBA"), (108, 66), 1)
    plot.save(TOWN_OUT / "construction_plot.png", optimize=True)
    save_outline(plot, OUTLINE_OUT / "construction_plot.png")

    fire_sheet = Image.open(ALPHA / "campfire_alpha.png").convert("RGBA")
    generated_poses = fit_frames_shared_window(
        [grid_cell(fire_sheet, 6, 1, column, 0) for column in range(6)],
        (112, 96),
        1,
    )
    # Retain the approved benches and stone-ring anchor from the first pose,
    # then restore the genuinely generated flame motion from every pose. This
    # avoids any whole-object wobble without reducing the animation to shifted
    # copies of a single flame.
    stable_base = generated_poses[0]
    motion_box = (34, 0, 78, 70)
    frames: list[Image.Image] = []
    for pose in generated_poses:
        frame = stable_base.copy()
        frame.paste(Image.new("RGBA", (motion_box[2] - motion_box[0], motion_box[3] - motion_box[1])), motion_box[:2])
        frame.alpha_composite(pose.crop(motion_box), motion_box[:2])
        frames.append(frame)
    strip = Image.new("RGBA", (112 * len(frames), 96))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * 112, 0))
    strip.save(TOWN_OUT / "campfire_animation.png", optimize=True)
    frames[0].save(TOWN_OUT / "campfire.png", optimize=True)
    save_outline(frames[0], OUTLINE_OUT / "campfire.png")


def build_forest() -> None:
    FOREST_OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(ALPHA / "forest_alpha.png").convert("RGBA")
    entries = (
        ("tree_0", 0, 0, (88, 120)),
        ("tree_1", 1, 0, (94, 122)),
        ("tree_2", 2, 0, (86, 118)),
        ("shrub", 0, 1, (76, 50)),
        ("stump", 1, 1, (66, 58)),
        ("rocks", 2, 1, (68, 58)),
    )
    for asset_id, column, row, canvas in entries:
        fit_subject(grid_cell(sheet, 3, 2, column, row), canvas).save(
            FOREST_OUT / f"{asset_id}.png", optimize=True
        )


def shifted_tile(image: Image.Image, offset_x: int, offset_y: int, tint: tuple[float, float, float]) -> Image.Image:
    image = image.convert("RGB")
    image = ImageChops.offset(image, offset_x, offset_y)
    image = image.resize((32, 32), Image.Resampling.NEAREST)
    channels = image.split()
    channels = tuple(channel.point(lambda value, factor=factor: min(255, round(value * factor))) for channel, factor in zip(channels, tint))
    return Image.merge("RGB", channels).convert("RGBA")


def build_terrain() -> None:
    TERRAIN_OUT.mkdir(parents=True, exist_ok=True)
    old_atlas = Image.open(ROOT / "assets" / "foundation" / "terrain" / "blackthorn_tiles_reference.png").convert("RGBA")
    atlas = old_atlas.copy()
    forest = Image.open(SOURCE / "forest_floor.png").convert("RGBA")
    road = Image.open(SOURCE / "road.png").convert("RGBA")
    cobble = Image.open(SOURCE / "cobble.png").convert("RGBA")
    row_sources = {
        0: (forest, (0.92, 0.82, 0.70)),
        1: (road, (1.04, 0.92, 0.76)),
        2: (forest, (0.74, 0.64, 0.56)),
        3: (forest, (0.72, 0.82, 0.62)),
        5: (cobble, (1.00, 0.92, 0.80)),
    }
    offsets = ((0, 0), (173, 239), (347, 83), (521, 431), (701, 617), (887, 293))
    for row, (source, tint) in row_sources.items():
        for variant, (offset_x, offset_y) in enumerate(offsets):
            atlas.alpha_composite(shifted_tile(source, offset_x, offset_y, tint), (variant * 32, row * 32))
    atlas.save(TERRAIN_OUT / "blackthorn_tiles_modular.png", optimize=True)


def main() -> None:
    build_town()
    build_forest()
    build_terrain()


if __name__ == "__main__":
    main()
