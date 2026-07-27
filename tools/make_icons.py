from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / "assets" / "backgrounds" / "camp.png").convert("RGB")
side = min(source.size)
left = (source.width - side) // 2
top = int(source.height * 0.52 - side * 0.5)
top = max(0, min(top, source.height - side))
square = source.crop((left, top, left + side, top + side))

icons = ROOT / "assets" / "icons"
icons.mkdir(parents=True, exist_ok=True)
for size in (144, 180, 512):
    icon = square.resize((size, size), Image.Resampling.NEAREST)
    draw = ImageDraw.Draw(icon)
    border = max(2, size // 64)
    draw.rectangle((border, border, size - border - 1, size - border - 1), outline="#d38a36", width=border)
    icon.save(icons / f"icon-{size}.png", optimize=True)

