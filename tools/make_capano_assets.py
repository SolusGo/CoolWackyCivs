"""Compile the supplied Capano concept and generated leader scene into Civ V DDS art.

The concept sheet supplies the civilization mark and the Route Setter, Coaching
Centre, Boulder Sector, and progression imagery. Pillow writes legacy DXT5 DDS
files, the compression/header combination accepted by Civ V's texture loader.
"""
from pathlib import Path
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps

SOURCE = REPO / "art-source" / "Capano"
OUTPUT = REPO / "CapanoCircuit" / "Art"
OUTPUT.mkdir(parents=True, exist_ok=True)

SIZES = (256, 128, 80, 64, 48, 45, 32, 24, 16)
OBJECT_SIZES = (256, 128, 80, 64, 45, 32, 16)
OBJECT_COUNT = 14

concept = Image.open(SOURCE / "CapanoConcept.png").convert("RGBA")
leader = Image.open(SOURCE / "CapanoLeader.png").convert("RGBA")


def save_dds(image: Image.Image, path: Path) -> None:
    """Write a legacy FourCC DXT5 texture, including non-multiple-of-four icons."""
    image.convert("RGBA").save(path, pixel_format="DXT5")


def crop_relative(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    """Crop coordinates authored against the 1536x1024 concept sheet."""
    sx, sy = image.width / 1536, image.height / 1024
    return image.crop(tuple(round(value * (sx if index % 2 == 0 else sy))
                            for index, value in enumerate(box)))


def circular_asset(source: Image.Image, size: int, ring=(153, 91, 193, 255)) -> Image.Image:
    scale = 4
    large = size * scale
    inner = round(large * 0.86)
    picture = ImageOps.fit(source, (inner, inner), method=Image.Resampling.LANCZOS)
    mask = Image.new("L", (inner, inner), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, inner - 3, inner - 3), fill=255)
    picture.putalpha(mask)
    canvas = Image.new("RGBA", (large, large))
    offset = (large - inner) // 2
    shadow = Image.new("RGBA", (large, large))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse((offset + 7, offset + 10, offset + inner + 5, offset + inner + 8),
                        fill=(0, 0, 0, 155))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(2, large // 80))))
    canvas.alpha_composite(picture, (offset, offset))
    draw = ImageDraw.Draw(canvas)
    width = max(4, round(large * 0.025))
    draw.ellipse((offset, offset, offset + inner - 1, offset + inner - 1), outline=ring, width=width)
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


# Full diplomacy/Dawn of Man scene and the setup portrait crop.
save_dds(ImageOps.fit(leader, (1600, 900), method=Image.Resampling.LANCZOS),
         OUTPUT / "CapanoLeader.dds")
save_dds(ImageOps.fit(leader, (360, 412), method=Image.Resampling.LANCZOS,
                      centering=(0.36, 0.43)), OUTPUT / "CapanoMap.dds")

# The concept poster's finished hold-and-fingertips mark.
civ_mark = crop_relative(concept, (422, 20, 572, 147))
for size in SIZES:
    save_dds(circular_asset(civ_mark, size, (225, 215, 181, 255)),
             OUTPUT / f"CapanoIcon{size}.dds")

# Leader portrait atlas sizes use a tighter face-and-torso crop from the generated scene.
w, h = leader.size
leader_portrait = leader.crop((round(w * 0.23), round(h * 0.015),
                              round(w * 0.57), round(h * 0.80)))
for size in SIZES:
    save_dds(circular_asset(leader_portrait, size, (225, 215, 181, 255)),
             OUTPUT / f"CapanoLeader{size}.dds")

# A clean monochrome version of the concept symbol for flags and strategic view.
def alpha_mark(size: int) -> Image.Image:
    scale = 4
    edge = size * scale
    canvas = Image.new("RGBA", (edge, edge))
    draw = ImageDraw.Draw(canvas)
    stroke = max(3, round(edge * 0.055))
    stone = [(edge * 0.18, edge * 0.60), (edge * 0.24, edge * 0.32),
             (edge * 0.45, edge * 0.17), (edge * 0.73, edge * 0.28),
             (edge * 0.84, edge * 0.56), (edge * 0.66, edge * 0.80),
             (edge * 0.34, edge * 0.83)]
    draw.line(stone + [stone[0]], fill="white", width=stroke, joint="curve")
    for x in (0.39, 0.51, 0.63):
        draw.line((edge * x, edge * 0.67, edge * (x + 0.10), edge * 0.38),
                  fill="white", width=stroke, joint="curve")
        draw.ellipse((edge * (x + 0.075), edge * 0.33,
                      edge * (x + 0.125), edge * 0.40), fill="white")
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


for size in SIZES:
    save_dds(alpha_mark(size), OUTPUT / f"CapanoAlpha{size}.dds")

save_dds(alpha_mark(32), OUTPUT / "CapanoUnitFlag32.dds")

# Fourteen object/promotion portraits, all derived from distinct regions of the supplied sheet.
icon_specs = (
    ((445, 375, 560, 630), (143, 87, 177, 255)),   # Route Setter
    ((726, 370, 998, 490), (143, 87, 177, 255)),   # Competition Coaching Centre
    ((1004, 370, 1267, 490), (143, 87, 177, 255)), # Boulder Sector
    ((466, 164, 560, 277), (88, 139, 195, 255)),   # Beta
    ((1004, 370, 1267, 490), (185, 67, 68, 255)),  # Awkward Sequence
    ((520, 690, 850, 835), (88, 139, 195, 255)),   # Read the Sequence
    ((890, 690, 1235, 835), (143, 87, 177, 255)),  # Competition Movement
    ((326, 292, 424, 587), (88, 139, 195, 255)),   # Footwork
    ((228, 94, 411, 442), (185, 67, 68, 255)),     # Body Position
    ((890, 690, 1235, 835), (143, 87, 177, 255)),  # Coordination
    ((1258, 480, 1438, 887), (29, 29, 31, 255)),   # Commit
    ((198, 40, 420, 445), (231, 207, 93, 255)),    # Complete Climber
    ((1004, 370, 1267, 490), (231, 207, 93, 255)), # Yellow Circuit
    ((1040, 22, 1288, 158), (225, 215, 181, 255)), # Ammagamma / Grampians
)

object_sources = []
for index, (box, ring) in enumerate(icon_specs):
    source = (leader.crop((round(leader.width * 0.55), round(leader.height * 0.12),
                           round(leader.width * 0.98), round(leader.height * 0.70)))
              if index == 13 else crop_relative(concept, box))
    if index == 0:
        # Keep the Setter's full silhouette; a direct square fit would crop the
        # tall character down to a pair of trousers at small atlas sizes.
        framed = Image.new("RGBA", (source.height, source.height), (22, 25, 29, 255))
        contained = ImageOps.contain(source, (source.height - 12, source.height - 12),
                                     method=Image.Resampling.LANCZOS)
        framed.alpha_composite(contained,
                               ((framed.width - contained.width) // 2,
                                (framed.height - contained.height) // 2))
        source = framed
    if index == 12:
        source = ImageEnhance.Color(source).enhance(0.65)
        overlay = Image.new("RGBA", source.size, (230, 190, 45, 58))
        source = Image.alpha_composite(source, overlay)
    object_sources.append((source, ring))

for size in OBJECT_SIZES:
    atlas = Image.new("RGBA", (size * OBJECT_COUNT, size))
    for index, (source, ring) in enumerate(object_sources):
        atlas.alpha_composite(circular_asset(source, size, ring), (index * size, 0))
    save_dds(atlas, OUTPUT / f"CapanoObjects{size}.dds")

# Human-reviewable source preview; this is not shipped in the mod package.
preview = Image.new("RGB", (1200, 760), (18, 18, 22))
preview.paste(ImageOps.fit(leader, (800, 450), method=Image.Resampling.LANCZOS), (0, 0))
preview.paste(circular_asset(civ_mark, 256, (225, 215, 181, 255)), (872, 64),
              circular_asset(civ_mark, 256, (225, 215, 181, 255)))
object_preview = Image.new("RGBA", (7 * 128, 2 * 128))
for index, (source, ring) in enumerate(object_sources):
    object_preview.alpha_composite(circular_asset(source, 128, ring),
                                   ((index % 7) * 128, (index // 7) * 128))
preview.paste(object_preview, (152, 480), object_preview)
preview.save(SOURCE / "CapanoArtPreview.png")

print(f"Built Capano leader scene, map image, flag, and {len(SIZES) * 3 + len(OBJECT_SIZES) + 1} atlas textures")
