"""Compile RomanGladius Network source art into Civ V-compatible DDS textures."""
from pathlib import Path
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps

SOURCE = REPO / "art-source" / "RomanGladiusNetwork"
OUTPUT = REPO / "RomanGladiusNetwork" / "Art"
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


def circular_asset(source: Image.Image, size: int, ring=(224, 174, 57, 255),
                   centering=(0.5, 0.5), preserve=False) -> Image.Image:
    edge = size * SCALE
    inner = round(edge * 0.86)
    picture = ImageOps.fit(source.convert("RGBA"), (inner, inner), Image.Resampling.LANCZOS,
                           centering=centering)
    if not preserve:
        picture = ImageEnhance.Contrast(picture).enhance(1.09)
        picture = ImageEnhance.Color(picture).enhance(1.06)
        picture = ImageEnhance.Sharpness(picture).enhance(1.18)
    mask = Image.new("L", (inner, inner), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, inner - 3, inner - 3), fill=255)
    picture.putalpha(mask)
    canvas = Image.new("RGBA", (edge, edge))
    offset = (edge - inner) // 2
    shadow = Image.new("RGBA", (edge, edge))
    ImageDraw.Draw(shadow).ellipse((offset + 7, offset + 10, offset + inner + 5, offset + inner + 8),
                                   fill=(0, 0, 0, 155))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(2, edge // 80))))
    canvas.alpha_composite(picture, (offset, offset))
    ImageDraw.Draw(canvas).ellipse((offset, offset, offset + inner - 1, offset + inner - 1),
                                   outline=ring, width=max(4, round(edge * 0.025)))
    return canvas.resize((size, size), Image.Resampling.LANCZOS).filter(
        ImageFilter.UnsharpMask(radius=max(0.4, size / 160), percent=70, threshold=3))


concept = Image.open(SOURCE / "RomanGladiusConcept.png").convert("RGBA")
leader = Image.open(SOURCE / "RomanGladiusLeader.png").convert("RGBA")
network_map = Image.open(SOURCE / "RomanGladiusMap.png").convert("RGBA")
console = Image.open(SOURCE / "ServerConsole.png").convert("RGBA")

# Preserve the canonical gold block-castle crest from the supplied concept sheet.
sx, sy = concept.width / 1456, concept.height / 1092
crest_box = tuple(round(value * (sx if index % 2 == 0 else sy))
                  for index, value in enumerate((355, 7, 500, 126)))
civ_icon = concept.crop(crest_box)

# Crop the Server Owner and banner directly from the same canonical sheet.
owner_box = tuple(round(value * (sx if index % 2 == 0 else sy))
                  for index, value in enumerate((115, 72, 580, 1002)))
owner = concept.crop(owner_box)
banner_box = tuple(round(value * (sx if index % 2 == 0 else sy))
                   for index, value in enumerate((1233, 778, 1422, 1002)))
banner = concept.crop(banner_box)

save_dds(ImageOps.fit(leader, (1600, 900), Image.Resampling.LANCZOS, centering=(0.49, 0.49)),
         OUTPUT / "RomanGladiusLeader.dds")
save_dds(ImageOps.fit(network_map, (1600, 900), Image.Resampling.LANCZOS, centering=(0.54, 0.49)),
         OUTPUT / "RomanGladiusDawn.dds")
save_dds(ImageOps.fit(network_map, (360, 412), Image.Resampling.LANCZOS, centering=(0.58, 0.53)),
         OUTPUT / "RomanGladiusMap.dds")

for size in SIZES:
    save_dds(circular_asset(civ_icon, size, preserve=True), OUTPUT / f"RomanGladiusIcon{size}.dds")


def alpha_crest(size: int) -> Image.Image:
    edge = size * SCALE
    crop = ImageOps.fit(civ_icon.convert("RGB"), (edge, edge), Image.Resampling.LANCZOS)
    hsv = crop.convert("HSV")
    saturation = hsv.getchannel("S")
    value = hsv.getchannel("V")
    colored = saturation.point(lambda item: 255 if item > 72 else 0)
    bright = value.point(lambda item: 255 if item > 118 else 0)
    mask = ImageChops.multiply(colored, bright).filter(ImageFilter.MaxFilter(7))
    inner = Image.new("L", (edge, edge), 0)
    margin = round(edge * 0.13)
    ImageDraw.Draw(inner).ellipse((margin, margin, edge - margin, edge - margin), fill=255)
    mask = ImageChops.multiply(mask, inner)
    white = Image.new("RGBA", (edge, edge), (255, 255, 255, 255))
    white.putalpha(mask)
    return white.resize((size, size), Image.Resampling.LANCZOS)


for size in SIZES:
    save_dds(alpha_crest(size), OUTPUT / f"RomanGladiusAlpha{size}.dds")
save_dds(alpha_crest(32), OUTPUT / "RomanGladiusUnitFlag32.dds")
alpha_crest(256).save(SOURCE / "RomanGladiusAlphaPreview.png")

for size in LEADER_SIZES:
    save_dds(circular_asset(leader, size, centering=(0.31, 0.32)),
             OUTPUT / f"RomanGladiusLeader{size}.dds")

object_sources = (
    (owner, (224, 174, 57, 255), (0.50, 0.13)),
    (console, (224, 174, 57, 255), (0.50, 0.50)),
    (civ_icon, (126, 24, 25, 255), (0.50, 0.50)),
    (banner, (224, 174, 57, 255), (0.50, 0.47)),
)
for size in OBJECT_SIZES:
    atlas = Image.new("RGBA", (size * len(object_sources), size))
    for index, (source, ring, centering) in enumerate(object_sources):
        atlas.alpha_composite(circular_asset(source, size, ring, centering), (index * size, 0))
    save_dds(atlas, OUTPUT / f"RomanGladiusObjects{size}.dds")

preview = Image.new("RGB", (1280, 880), (35, 18, 15))
preview.paste(ImageOps.fit(leader, (800, 450), Image.Resampling.LANCZOS), (0, 0))
preview.paste(ImageOps.fit(network_map, (480, 270), Image.Resampling.LANCZOS), (800, 0))
preview.paste(ImageOps.fit(console, (300, 300), Image.Resampling.LANCZOS), (890, 295))
for index, (source, ring, centering) in enumerate(object_sources):
    icon = circular_asset(source, 128, ring, centering)
    preview.paste(icon, (55 + index * 205, 660), icon)
preview.save(SOURCE / "RomanGladiusArtPreview.png")

print(f"Built RomanGladius leader, Dawn of Man, map, flag, and {len(SIZES)*2 + len(LEADER_SIZES) + len(OBJECT_SIZES)} atlases")
