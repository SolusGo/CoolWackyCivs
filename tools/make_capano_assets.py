"""Compile the Capano source illustrations into Civ V DDS art.

The concept sheet supplies the civilization mark while dedicated high-resolution
illustrations supply every gameplay portrait. Pillow writes legacy DXT5 DDS files,
the compression/header combination accepted by Civ V's texture loader.
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
    """Match the encoding rule used by proven in-game Civ V atlases."""
    rgba = image.convert("RGBA")
    if rgba.width % 4 == 0 and rgba.height % 4 == 0:
        rgba.save(path, pixel_format="DXT5")
    else:
        rgba.save(path)


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
    # Preserve strong silhouettes and material detail after Civ V downsizes and
    # DXT-compresses the atlas. This also improves the civilization/leader row.
    picture = ImageEnhance.Contrast(picture).enhance(1.08)
    picture = ImageEnhance.Color(picture).enhance(1.05)
    picture = ImageEnhance.Sharpness(picture).enhance(1.30)
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

# The concept poster's finished hold-and-fingertips mark. The leader portrait
# shares this atlas so Civ V has one fewer independently cached texture family.
civ_mark = crop_relative(concept, (422, 20, 572, 147))
w, h = leader.size
leader_portrait = leader.crop((round(w * 0.23), round(h * 0.015),
                              round(w * 0.57), round(h * 0.80)))
for size in SIZES:
    atlas = Image.new("RGBA", (size * 2, size))
    atlas.alpha_composite(circular_asset(civ_mark, size, (225, 215, 181, 255)), (0, 0))
    atlas.alpha_composite(circular_asset(leader_portrait, size, (225, 215, 181, 255)),
                          (size, 0))
    save_dds(atlas, OUTPUT / f"CapanoIcon{size}.dds")

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

# Fourteen purpose-built object/promotion portraits. Keeping the full-resolution
# sources separate avoids the unreadable poster crops used by the original atlas.
icon_specs = (
    ("RouteSetter.png", (143, 87, 177, 255)),       # Route Setter
    ("CompetitionCentre.png", (143, 87, 177, 255)), # Competition Coaching Centre
    ("BoulderSector.png", (143, 87, 177, 255)),     # Boulder Sector
    ("Beta.png", (88, 139, 195, 255)),              # Beta
    ("AwkwardSequence.png", (185, 67, 68, 255)),    # Awkward Sequence
    ("ReadSequence.png", (88, 139, 195, 255)),      # Read the Sequence
    ("CompetitionMovement.png", (143, 87, 177, 255)), # Competition Movement
    ("Footwork.png", (88, 139, 195, 255)),          # Footwork
    ("BodyPosition.png", (185, 67, 68, 255)),       # Body Position
    ("Coordination.png", (88, 139, 195, 255)),      # Coordination
    ("Commit.png", (185, 67, 68, 255)),             # Commit
    ("CompleteClimber.png", (231, 207, 93, 255)),   # Complete Climber
    ("YellowCircuit.png", (231, 207, 93, 255)),     # Yellow Circuit
    ("Grampians.png", (225, 215, 181, 255)),        # Ammagamma / Grampians
)

object_sources = []
for filename, ring in icon_specs:
    source = Image.open(SOURCE / "Icons" / filename).convert("RGBA")
    object_sources.append((source, ring))

for size in OBJECT_SIZES:
    atlas = Image.new("RGBA", (size * OBJECT_COUNT, size))
    for index, (source, ring) in enumerate(object_sources):
        atlas.alpha_composite(circular_asset(source, size, ring), (index * size, 0))
    save_dds(atlas, OUTPUT / f"CapanoObjects{size}.dds")

# Human-reviewable source preview; this is not shipped in the mod package.
preview = Image.new("RGB", (1200, 840), (18, 18, 22))
preview.paste(ImageOps.fit(leader, (800, 450), method=Image.Resampling.LANCZOS), (0, 0))
preview.paste(circular_asset(civ_mark, 256, (225, 215, 181, 255)), (872, 64),
              circular_asset(civ_mark, 256, (225, 215, 181, 255)))
object_preview = Image.new("RGBA", (7 * 128, 2 * 128))
for index, (source, ring) in enumerate(object_sources):
    object_preview.alpha_composite(circular_asset(source, 128, ring),
                                   ((index % 7) * 128, (index // 7) * 128))
preview.paste(object_preview, (152, 480), object_preview)

# Show the real 32px artwork at 2x nearest-neighbour scale for legibility QA.
# This reveals lost silhouettes and muddy crops that a 128px preview can hide.
tiny_preview = Image.new("RGBA", (OBJECT_COUNT * 32, 32))
for index, (source, ring) in enumerate(object_sources):
    tiny_preview.alpha_composite(circular_asset(source, 32, ring), (index * 32, 0))
tiny_preview = tiny_preview.resize((OBJECT_COUNT * 64, 64), Image.Resampling.NEAREST)
preview.paste(tiny_preview, (152, 768), tiny_preview)
preview.save(SOURCE / "CapanoArtPreview.png")

print(f"Built Capano leader scene, map image, flag, and {len(SIZES) * 2 + len(OBJECT_SIZES) + 1} active atlas textures")
