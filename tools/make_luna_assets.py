"""Build Luna's Civ V leader scene and 1x1 icon atlases from source PNGs."""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

REPO = Path(__file__).resolve().parents[1]
LEADER_SOURCE = REPO / "art-source/LunaLeader.png"
EMBLEM_SOURCE = REPO / "art-source/LunaEmblem.png"
OUTPUT = REPO / "LunaNetwork/Art"
SIZES = (256, 128, 80, 64, 45, 32)

OUTPUT.mkdir(parents=True, exist_ok=True)

leader = Image.open(LEADER_SOURCE).convert("RGBA")
leader = ImageOps.fit(leader, (1600, 900), method=Image.Resampling.LANCZOS)
leader.save(OUTPUT / "LunaLeader.dds")

source = Image.open(EMBLEM_SOURCE).convert("RGBA")
rgb = source.convert("RGB")
maximum = Image.new("L", source.size)
pixels = rgb.get_flattened_data() if hasattr(rgb, "get_flattened_data") else rgb.getdata()
maximum.putdata([max(pixel) for pixel in pixels])
mask = maximum.point(lambda value: max(0, min(255, (value - 24) * 5)))
mask = mask.filter(ImageFilter.GaussianBlur(max(1, source.width // 512)))
bounds = mask.getbbox()
if not bounds:
    raise ValueError("Luna emblem source contains no visible symbol")
source = source.crop(bounds)
mask = mask.crop(bounds)

for size in SIZES:
    inner = max(1, int(size * 0.78))
    fitted = source.copy()
    fitted.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    fitted_mask = mask.copy()
    fitted_mask.thumbnail(fitted.size, Image.Resampling.LANCZOS)
    fitted.putalpha(fitted_mask)
    x, y = (size - fitted.width) // 2, (size - fitted.height) // 2

    alpha = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    white = Image.new("RGBA", fitted.size, (255, 255, 255, 255))
    white.putalpha(fitted_mask)
    alpha.alpha_composite(white, (x, y))
    alpha.save(OUTPUT / f"LunaAlpha{size}.dds")

    color = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(color)
    inset = max(1, round(size * 0.035))
    draw.ellipse(
        (inset, inset, size - inset - 1, size - inset - 1),
        fill=(6, 14, 38, 255), outline=(116, 224, 245, 255),
        width=max(1, round(size * 0.045)),
    )
    color.alpha_composite(fitted, (x, y))
    color.save(OUTPUT / f"LunaIcon{size}.dds")

print(f"Built Luna leader and {len(SIZES) * 2} icon atlases")
