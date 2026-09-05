"""Build Civ V 1x1 color and alpha icon atlases from the generated emblem."""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO / "art-source/RoulsEmblem.png"
OUTPUT = REPO / "RoulsAscendancy/Art"
SIZES = (256, 128, 80, 64, 45, 32)

source = Image.open(SOURCE).convert("RGBA")
# The generated source is white-on-alpha. Combining alpha with luminance drops
# any transparent RGB residue before the small icon is resampled.
luminance = source.convert("L")
mask = ImageChops.multiply(source.getchannel("A"), luminance)
bounds = mask.getbbox()
if not bounds:
    raise ValueError("The emblem source contains no visible pixels")
mask = mask.crop(bounds)

OUTPUT.mkdir(parents=True, exist_ok=True)
for size in SIZES:
    inner = max(1, int(size * 0.78))
    fitted = mask.copy()
    fitted.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    x, y = (size - fitted.width) // 2, (size - fitted.height) // 2

    alpha = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    alpha.putalpha(Image.new("L", (size, size), 0))
    white = Image.new("RGBA", fitted.size, (255, 255, 255, 255))
    alpha.alpha_composite(white, (x, y), (0, 0, fitted.width, fitted.height))
    alpha_mask = Image.new("L", (size, size), 0)
    alpha_mask.paste(fitted, (x, y))
    alpha.putalpha(alpha_mask)
    alpha.save(OUTPUT / f"RoulsAlpha{size}.dds")

    color = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(color)
    inset = max(1, round(size * 0.035))
    draw.ellipse((inset, inset, size-inset-1, size-inset-1), fill=(45, 22, 66, 255),
                 outline=(105, 224, 207, 255), width=max(1, round(size * 0.045)))
    gold = Image.new("RGBA", fitted.size, (238, 220, 168, 255))
    gold.putalpha(fitted)
    color.alpha_composite(gold, (x, y))
    color.save(OUTPUT / f"RoulsIcon{size}.dds")

print(f"Built {len(SIZES) * 2} icon atlases from {SOURCE}")
