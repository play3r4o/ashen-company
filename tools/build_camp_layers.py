from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "camp_layers" / "sources"
OUTPUT = ROOT / "assets" / "camp_layers" / "buildings"
OUTLINES = OUTPUT / "outlines"
MAX_EDGE = 512
PADDING = 12


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 12 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("Sprite cell contains no opaque pixels")
    return bbox


def resize_canvas(image: Image.Image) -> Image.Image:
    longest = max(image.size)
    if longest <= MAX_EDGE:
        return image
    scale = MAX_EDGE / float(longest)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    return image.resize(size, Image.Resampling.NEAREST)


def save_outline(image: Image.Image, path: Path) -> None:
    alpha = image.getchannel("A")
    expanded = alpha.filter(ImageFilter.MaxFilter(13))
    edge = ImageChops.subtract(expanded, alpha)
    outline = Image.new("RGBA", image.size, (236, 174, 74, 0))
    outline.putalpha(edge)
    outline.save(path, optimize=True)


def split_progression(name: str, columns: int, rows: int, count: int) -> None:
    atlas = Image.open(SOURCE / f"{name}_tiers_alpha.png").convert("RGBA")
    cell_width = atlas.width // columns
    cell_height = atlas.height // rows
    subjects: list[Image.Image] = []
    for index in range(count):
        column = index % columns
        row = index // columns
        cell = atlas.crop((
            column * cell_width,
            row * cell_height,
            (column + 1) * cell_width,
            (row + 1) * cell_height,
        ))
        subjects.append(cell.crop(alpha_bbox(cell)))

    canvas_width = max(sprite.width for sprite in subjects) + PADDING * 2
    canvas_height = max(sprite.height for sprite in subjects) + PADDING * 2
    for index, sprite in enumerate(subjects):
        canvas = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
        x = (canvas_width - sprite.width) // 2
        y = canvas_height - PADDING - sprite.height
        canvas.alpha_composite(sprite, (x, y))
        final = resize_canvas(canvas)
        final.save(OUTPUT / f"{name}_{index}.png", optimize=True)
        save_outline(final, OUTLINES / f"{name}_{index}.png")
        print(f"{name}_{index}.png: {final.width}x{final.height}")


def split_landmarks() -> None:
    atlas = Image.open(SOURCE / "landmarks_alpha.png").convert("RGBA")
    cell_width = atlas.width // 2
    for index, name in enumerate(("veterans_hall", "campfire")):
        cell = atlas.crop((index * cell_width, 0, (index + 1) * cell_width, atlas.height))
        sprite = cell.crop(alpha_bbox(cell))
        canvas = Image.new("RGBA", (sprite.width + PADDING * 2, sprite.height + PADDING * 2), (0, 0, 0, 0))
        canvas.alpha_composite(sprite, (PADDING, PADDING))
        final = resize_canvas(canvas)
        final.save(OUTPUT / f"{name}.png", optimize=True)
        save_outline(final, OUTLINES / f"{name}.png")
        print(f"{name}.png: {final.width}x{final.height}")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    OUTLINES.mkdir(parents=True, exist_ok=True)
    split_progression("armory", 4, 1, 4)
    split_progression("blacksmith", 4, 1, 4)
    split_progression("quartermaster", 4, 1, 4)
    split_progression("training", 3, 2, 6)
    split_landmarks()


if __name__ == "__main__":
    main()
