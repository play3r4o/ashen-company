from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "ui" / "sources"
OUTPUT = ROOT / "assets" / "ui" / "generated"
PADDING = 10


def alpha_crop(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").point(lambda value: 255 if value > 10 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("Generated UI source contains no visible pixels")
    return image.crop(bbox)


def padded(image: Image.Image, padding: int = PADDING) -> Image.Image:
    canvas = Image.new("RGBA", (image.width + padding * 2, image.height + padding * 2), (0, 0, 0, 0))
    canvas.alpha_composite(image, (padding, padding))
    return canvas


def build_title() -> None:
    source = Image.open(SOURCE / "camp_title_crest_alpha.png").convert("RGBA")
    crest = padded(alpha_crop(source), 8)
    width = 768
    height = round(crest.height * width / crest.width)
    crest.resize((width, height), Image.Resampling.NEAREST).save(OUTPUT / "camp_title_crest.png", optimize=True)


def build_resource_icons() -> None:
    source = Image.open(SOURCE / "resource_icons_alpha.png").convert("RGBA")
    half = source.width // 2
    cells = {
        "silver_icon.png": source.crop((0, 0, half, source.height)),
        "provisions_icon.png": source.crop((half, 0, source.width, source.height)),
    }
    for filename, cell in cells.items():
        subject = alpha_crop(cell)
        scale = min(108 / subject.width, 108 / subject.height)
        size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
        subject = subject.resize(size, Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        canvas.alpha_composite(subject, ((128 - subject.width) // 2, (128 - subject.height) // 2))
        canvas.save(OUTPUT / filename, optimize=True)


def build_settings_cog() -> None:
    source = Image.open(SOURCE / "settings_cog_alpha.png").convert("RGBA")
    subject = alpha_crop(source)
    scale = min(108 / subject.width, 108 / subject.height)
    size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    subject = subject.resize(size, Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    canvas.alpha_composite(subject, ((128 - subject.width) // 2, (128 - subject.height) // 2))
    canvas.save(OUTPUT / "settings_cog.png", optimize=True)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    build_title()
    build_resource_icons()
    build_settings_cog()


if __name__ == "__main__":
    main()
