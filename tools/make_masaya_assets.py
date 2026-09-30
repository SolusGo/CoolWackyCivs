"""Compile the supplied Masaya concept sheet into Civ V-compatible DDS art.

The reference sheet already contains finished leader, Dawn of Man, map, unit,
building, and promotion illustrations.  This script crops those authored
regions, builds the required atlas sizes, and redraws only the small white
wing/star silhouette needed by alpha, flag, and strategic-view-style uses.
"""
from pathlib import Path
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps

SOURCE = REPO / "art-source" / "MasayaBeyondSky"
OUTPUT = REPO / "MasayaBeyondSky" / "Art"
OUTPUT.mkdir(parents=True, exist_ok=True)

SIZES = (256, 128, 80, 64, 48, 45, 32, 24, 16)
OBJECT_SIZES = (256, 128, 80, 64, 45, 32, 16)
SCALE = 4


def save_dds(image: Image.Image, path: Path) -> None:
    """Use the legacy DXT5/32-bit encodings already proven by this project."""
    rgba = image.convert("RGBA")
    if rgba.width % 4 == 0 and rgba.height % 4 == 0:
        rgba.save(path, pixel_format="DXT5")
    else:
        rgba.save(path)


def crop(sheet: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    """Scale coordinates authored against the supplied 1448x1086 sheet."""
    sx, sy = sheet.width / 1448, sheet.height / 1086
    return sheet.crop(tuple(round(value * (sx if index % 2 == 0 else sy))
                            for index, value in enumerate(box)))


def polished(image: Image.Image) -> Image.Image:
    return (ImageEnhance.Color(ImageEnhance.Contrast(image).enhance(1.05)).enhance(1.04)
            .filter(ImageFilter.UnsharpMask(radius=1.1, percent=85, threshold=3)))


def circular_asset(source: Image.Image, size: int,
                   ring=(225, 196, 105, 255), centering=(0.5, 0.5)) -> Image.Image:
    edge = size * SCALE
    inner = round(edge * 0.86)
    picture = ImageOps.fit(source.convert("RGBA"), (inner, inner), Image.Resampling.LANCZOS,
                           centering=centering)
    picture = polished(picture)
    mask = Image.new("L", (inner, inner), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, inner - 3, inner - 3), fill=255)
    picture.putalpha(mask)
    canvas = Image.new("RGBA", (edge, edge))
    offset = (edge - inner) // 2
    shadow = Image.new("RGBA", (edge, edge))
    ImageDraw.Draw(shadow).ellipse(
        (offset + 8, offset + 11, offset + inner + 6, offset + inner + 9),
        fill=(0, 0, 0, 150))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(2, edge // 80))))
    canvas.alpha_composite(picture, (offset, offset))
    ImageDraw.Draw(canvas).ellipse(
        (offset, offset, offset + inner - 1, offset + inner - 1),
        outline=ring, width=max(4, round(edge * 0.025)))
    return canvas.resize((size, size), Image.Resampling.LANCZOS).filter(
        ImageFilter.UnsharpMask(radius=max(0.4, size / 160), percent=70, threshold=3))


def wing_mark(size: int) -> Image.Image:
    """Small-scale version of the sheet's star-and-wing civilization mark."""
    edge = size * SCALE
    image = Image.new("RGBA", (edge, edge))
    draw = ImageDraw.Draw(image)

    # Four sweeping feathers converge below the star.  Broad geometry is
    # deliberate: it stays legible after DXT compression at 16-32 pixels.
    feathers = (
        ((0.22, 0.69), (0.45, 0.58), (0.78, 0.29), (0.64, 0.66), (0.40, 0.80)),
        ((0.26, 0.78), (0.48, 0.67), (0.79, 0.48), (0.61, 0.76), (0.39, 0.87)),
        ((0.34, 0.85), (0.52, 0.75), (0.75, 0.67), (0.59, 0.86), (0.45, 0.91)),
    )
    for feather in feathers:
        draw.polygon([(round(x * edge), round(y * edge)) for x, y in feather], fill="white")
    draw.polygon([(round(x * edge), round(y * edge)) for x, y in
                  ((0.23, 0.69), (0.39, 0.47), (0.48, 0.73), (0.39, 0.87))], fill="white")

    cx, cy = round(edge * 0.36), round(edge * 0.31)
    long, short = round(edge * 0.17), round(edge * 0.065)
    star = [(cx, cy - long), (cx + short, cy - short), (cx + long, cy),
            (cx + short, cy + short), (cx, cy + long), (cx - short, cy + short),
            (cx - long, cy), (cx - short, cy - short)]
    draw.polygon(star, fill="white")
    return image.resize((size, size), Image.Resampling.LANCZOS)


sheet = Image.open(SOURCE / "MasayaConcept.png").convert("RGBA")

# Finished illustration regions from the supplied concept sheet.
leader_scene = crop(sheet, (10, 108, 752, 443))
dawn_scene = crop(sheet, (764, 108, 1438, 443))
map_strip = crop(sheet, (10, 474, 1438, 654))
civ_icon = crop(sheet, (22, 681, 190, 846))
leader_icon = crop(sheet, (211, 688, 373, 845))

leader_output = polished(ImageOps.fit(leader_scene, (1600, 900), Image.Resampling.LANCZOS,
                                      centering=(0.50, 0.50)))
dawn_output = polished(ImageOps.fit(dawn_scene, (1600, 900), Image.Resampling.LANCZOS,
                                    centering=(0.52, 0.50)))
save_dds(leader_output, OUTPUT / "MasayaLeader.dds")
save_dds(dawn_output, OUTPUT / "MasayaDawn.dds")

# The game setup map art is portrait-shaped, while the supplied environment is
# panoramic.  A blurred cover plus a crisp panoramic window preserves both the
# readable coastal setting and the authored boy-at-the-overlook composition.
map_background = ImageOps.fit(map_strip, (360, 412), Image.Resampling.LANCZOS,
                              centering=(0.80, 0.50)).filter(ImageFilter.GaussianBlur(9))
map_background = ImageEnhance.Brightness(map_background).enhance(0.72).convert("RGBA")
map_window = ImageOps.fit(map_strip, (336, 224), Image.Resampling.LANCZOS,
                          centering=(0.67, 0.50))
map_window = polished(map_window)
map_background.alpha_composite(map_window, (12, 94))
ImageDraw.Draw(map_background).rounded_rectangle((10, 92, 349, 319), radius=8,
                                                  outline=(235, 207, 116, 255), width=3)
save_dds(map_background, OUTPUT / "MasayaMap.dds")

for size in SIZES:
    atlas = Image.new("RGBA", (size * 2, size))
    atlas.alpha_composite(circular_asset(civ_icon, size), (0, 0))
    atlas.alpha_composite(circular_asset(leader_icon, size, centering=(0.50, 0.42)),
                          (size, 0))
    save_dds(atlas, OUTPUT / f"MasayaIcon{size}.dds")
    save_dds(wing_mark(size), OUTPUT / f"MasayaAlpha{size}.dds")

save_dds(wing_mark(32), OUTPUT / "MasayaUnitFlag32.dds")

# Atlas order: UA, unique unit, unique building, Joy, Can't Stop, Beyond,
# Just One More Flight, Natural Prodigy, Can't Put Them Down.
object_sources = (
    (crop(sheet, (401, 691, 572, 839)), (225, 196, 105, 255), (0.50, 0.50)),
    (crop(sheet, (608, 690, 774, 841)), (83, 174, 246, 255), (0.50, 0.48)),
    (crop(sheet, (807, 690, 969, 842)), (225, 196, 105, 255), (0.50, 0.50)),
    (crop(sheet, (48, 898, 189, 1005)), (83, 174, 246, 255), (0.50, 0.48)),
    (crop(sheet, (217, 898, 354, 1005)), (225, 196, 105, 255), (0.50, 0.50)),
    (crop(sheet, (386, 898, 520, 1005)), (225, 196, 105, 255), (0.50, 0.50)),
    (crop(sheet, (564, 898, 696, 1005)), (83, 174, 246, 255), (0.50, 0.50)),
    (crop(sheet, (736, 898, 868, 1005)), (108, 198, 132, 255), (0.50, 0.50)),
    (crop(sheet, (899, 898, 1037, 1005)), (225, 196, 105, 255), (0.50, 0.50)),
)
for size in OBJECT_SIZES:
    atlas = Image.new("RGBA", (size * len(object_sources), size))
    for index, (source, ring, centering) in enumerate(object_sources):
        atlas.alpha_composite(circular_asset(source, size, ring, centering),
                              (index * size, 0))
    save_dds(atlas, OUTPUT / f"MasayaObjects{size}.dds")

(OUTPUT / "MasayaLeaderScene.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<LeaderScene FallbackImage="MasayaLeader.dds" />\n', encoding="utf-8")

# Human-reviewable preview; source material and preview are not shipped.
preview = Image.new("RGB", (1280, 900), (7, 27, 45))
preview.paste(leader_output.resize((800, 450), Image.Resampling.LANCZOS), (0, 0))
preview.paste(dawn_output.resize((480, 270), Image.Resampling.LANCZOS), (800, 0))
preview.paste(map_background.resize((240, 275), Image.Resampling.LANCZOS), (920, 290))
for index, (source, ring, centering) in enumerate(object_sources):
    icon = circular_asset(source, 112, ring, centering)
    preview.paste(icon, (18 + (index % 9) * 138, 650), icon)
tiny = Image.new("RGBA", (len(object_sources) * 32, 32))
for index, (source, ring, centering) in enumerate(object_sources):
    tiny.alpha_composite(circular_asset(source, 32, ring, centering), (index * 32, 0))
tiny = tiny.resize((len(object_sources) * 64, 64), Image.Resampling.NEAREST)
preview.paste(tiny, (352, 812), tiny)
preview.save(SOURCE / "MasayaArtPreview.png")

print("Built Masaya leader/Dawn/map art, 18 civ/alpha atlases, 7 object atlases, and unit flag")
