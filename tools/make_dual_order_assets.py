"""Compile Dual Order source art into Civ V-compatible DDS textures."""
from pathlib import Path
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps

SOURCE = REPO / "art-source" / "DualOrder"
OUTPUT = REPO / "DualOrder" / "Art"
OUTPUT.mkdir(parents=True, exist_ok=True)

SIZES = (256, 128, 80, 64, 48, 45, 32, 24, 16)
OBJECT_SIZES = (256, 128, 80, 64, 45, 32, 16)
LEADER_SIZES = (256, 128, 64)
SCALE = 4


def save_dds(image: Image.Image, path: Path) -> None:
    rgba = image.convert("RGBA")
    if rgba.width % 4 == 0 and rgba.height % 4 == 0:
        rgba.save(path, pixel_format="DXT5")
    else:
        rgba.save(path)


def circular_asset(source: Image.Image, size: int, ring=(205, 177, 120, 255),
                   centering=(0.5, 0.5), preserve=False) -> Image.Image:
    edge = size * SCALE
    inner = round(edge * 0.86)
    picture = ImageOps.fit(source.convert("RGBA"), (inner, inner), Image.Resampling.LANCZOS,
                           centering=centering)
    if not preserve:
        picture = ImageEnhance.Contrast(picture).enhance(1.08)
        picture = ImageEnhance.Color(picture).enhance(1.04)
        picture = ImageEnhance.Sharpness(picture).enhance(1.20)
    mask = Image.new("L", (inner, inner), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, inner - 3, inner - 3), fill=255)
    picture.putalpha(mask)
    canvas = Image.new("RGBA", (edge, edge))
    offset = (edge - inner) // 2
    shadow = Image.new("RGBA", (edge, edge))
    ImageDraw.Draw(shadow).ellipse((offset + 7, offset + 10, offset + inner + 5, offset + inner + 8),
                                   fill=(0, 0, 0, 150))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(2, edge // 80))))
    canvas.alpha_composite(picture, (offset, offset))
    ImageDraw.Draw(canvas).ellipse((offset, offset, offset + inner - 1, offset + inner - 1),
                                   outline=ring, width=max(4, round(edge * 0.025)))
    return canvas.resize((size, size), Image.Resampling.LANCZOS).filter(
        ImageFilter.UnsharpMask(radius=max(0.4, size / 160), percent=65, threshold=3))


concept = Image.open(SOURCE / "DualOrderConcept.png").convert("RGBA")
leader = Image.open(SOURCE / "GrandmasterSeverin.png").convert("RGBA")
templar = Image.open(SOURCE / "DividedTemplar.png").convert("RGBA")
hall = Image.open(SOURCE / "HallOfConcordance.png").convert("RGBA")
dawn = Image.open(SOURCE / "DualOrderDawn.png").convert("RGBA")
order_map = Image.open(SOURCE / "DualOrderMap.png").convert("RGBA")

# The supplied sheet is 1536x1024. This crop retains its canonical, unredrawn heraldry.
sx, sy = concept.width / 1536, concept.height / 1024
box = tuple(round(value * (sx if index % 2 == 0 else sy))
            for index, value in enumerate((397, 105, 617, 315)))
civ_icon = concept.crop(box)

save_dds(ImageOps.fit(leader, (1600, 900), Image.Resampling.LANCZOS, centering=(0.48, 0.48)),
         OUTPUT / "DualOrderLeader.dds")
save_dds(ImageOps.fit(dawn, (1600, 900), Image.Resampling.LANCZOS), OUTPUT / "DualOrderDawn.dds")
save_dds(ImageOps.fit(order_map, (360, 412), Image.Resampling.LANCZOS, centering=(0.5, 0.53)),
         OUTPUT / "DualOrderMap.dds")

for size in SIZES:
    save_dds(circular_asset(civ_icon, size, preserve=True), OUTPUT / f"DualOrderIcon{size}.dds")


def alpha_heraldry(size: int) -> Image.Image:
    edge = size * SCALE
    crop = ImageOps.fit(civ_icon.convert("RGB"), (edge, edge), Image.Resampling.LANCZOS)
    gray = ImageOps.grayscale(crop)
    saturation = crop.convert("HSV").getchannel("S")
    dark = gray.point(lambda value: 255 if value < 145 else 0)
    colored = saturation.point(lambda value: 255 if value > 85 else 0)
    mask = ImageChops.lighter(dark, colored)
    # Exclude the source's circular frame while retaining the cross, sword, and eagle shield.
    inner = Image.new("L", (edge, edge), 0)
    margin = round(edge * 0.16)
    ImageDraw.Draw(inner).ellipse((margin, margin, edge - margin, edge - margin), fill=255)
    mask = Image.composite(mask, Image.new("L", (edge, edge), 0), inner)
    mask = mask.filter(ImageFilter.MaxFilter(5))
    white = Image.new("RGBA", (edge, edge), (255, 255, 255, 255))
    white.putalpha(mask)
    return white.resize((size, size), Image.Resampling.LANCZOS)


for size in SIZES:
    save_dds(alpha_heraldry(size), OUTPUT / f"DualOrderAlpha{size}.dds")
save_dds(alpha_heraldry(32), OUTPUT / "DualOrderUnitFlag32.dds")
alpha_heraldry(256).save(SOURCE / "DualOrderAlphaPreview.png")

for size in LEADER_SIZES:
    save_dds(circular_asset(leader, size, centering=(0.43, 0.36)), OUTPUT / f"DualOrderLeader{size}.dds")

zeal = ImageEnhance.Color(civ_icon).enhance(1.25)
balance = ImageOps.grayscale(civ_icon).convert("RGBA")
schism = ImageEnhance.Contrast(templar).enhance(1.22)
object_sources = (
    (templar, (205, 177, 120, 255), (0.50, 0.43)),
    (hall, (205, 177, 120, 255), (0.50, 0.52)),
    (zeal, (184, 44, 42, 255), (0.50, 0.50)),
    (balance, (205, 177, 120, 255), (0.50, 0.50)),
    (schism, (184, 44, 42, 255), (0.58, 0.42)),
)
for size in OBJECT_SIZES:
    atlas = Image.new("RGBA", (size * len(object_sources), size))
    for index, (source, ring, centering) in enumerate(object_sources):
        atlas.alpha_composite(circular_asset(source, size, ring, centering), (index * size, 0))
    save_dds(atlas, OUTPUT / f"DualOrderObjects{size}.dds")

preview = Image.new("RGB", (1280, 880), (17, 16, 14))
preview.paste(ImageOps.fit(leader, (800, 450), Image.Resampling.LANCZOS), (0, 0))
preview.paste(ImageOps.fit(dawn, (480, 270), Image.Resampling.LANCZOS), (800, 0))
preview.paste(ImageOps.fit(order_map, (240, 280), Image.Resampling.LANCZOS), (920, 280))
for index, (source, ring, centering) in enumerate(object_sources):
    icon = circular_asset(source, 128, ring, centering)
    preview.paste(icon, (30 + index * 180, 610), icon)
preview.save(SOURCE / "DualOrderArtPreview.png")

print(f"Built Dual Order leader, Dawn of Man, map, flag, and {len(SIZES)*2 + len(LEADER_SIZES) + len(OBJECT_SIZES)} atlases")
