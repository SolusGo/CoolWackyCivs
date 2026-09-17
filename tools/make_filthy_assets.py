"""Compile Filthy Realm source art into Civ V-compatible DDS textures."""
from pathlib import Path
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps

SOURCE = REPO / "art-source" / "FilthyRealm"
OUTPUT = REPO / "FilthyRealm" / "Art"
OUTPUT.mkdir(parents=True, exist_ok=True)

SIZES = (256, 128, 80, 64, 48, 45, 32, 24, 16)
OBJECT_SIZES = (256, 128, 80, 64, 45, 32, 16)
SCALE = 4


def save_dds(image: Image.Image, path: Path) -> None:
    rgba = image.convert("RGBA")
    if rgba.width % 4 == 0 and rgba.height % 4 == 0:
        rgba.save(path, pixel_format="DXT5")
    else:
        rgba.save(path)


def rel_crop(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    """Crop coordinates authored against the supplied 1448x1086 concept sheet."""
    sx, sy = image.width / 1448, image.height / 1086
    return image.crop(tuple(round(value * (sx if index % 2 == 0 else sy))
                            for index, value in enumerate(box)))


def circular_asset(source: Image.Image, size: int, ring=(226, 55, 111, 255),
                   centering=(0.5, 0.5)) -> Image.Image:
    edge = size * SCALE
    inner = round(edge * 0.86)
    picture = ImageOps.fit(source.convert("RGBA"), (inner, inner), Image.Resampling.LANCZOS,
                           centering=centering)
    picture = ImageEnhance.Contrast(picture).enhance(1.09)
    picture = ImageEnhance.Color(picture).enhance(1.05)
    picture = ImageEnhance.Sharpness(picture).enhance(1.25)
    mask = Image.new("L", (inner, inner), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, inner - 3, inner - 3), fill=255)
    picture.putalpha(mask)
    canvas = Image.new("RGBA", (edge, edge))
    offset = (edge - inner) // 2
    shadow = Image.new("RGBA", (edge, edge))
    ImageDraw.Draw(shadow).ellipse((offset + 7, offset + 10, offset + inner + 5, offset + inner + 8),
                                   fill=(0, 0, 0, 160))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(2, edge // 80))))
    canvas.alpha_composite(picture, (offset, offset))
    ImageDraw.Draw(canvas).ellipse((offset, offset, offset + inner - 1, offset + inner - 1),
                                   outline=ring, width=max(4, round(edge * 0.025)))
    return canvas.resize((size, size), Image.Resampling.LANCZOS).filter(
        ImageFilter.UnsharpMask(radius=max(0.4, size / 160), percent=60, threshold=3))


def graphic_icon(kind: str, edge: int = 1024) -> Image.Image:
    image = Image.new("RGBA", (edge, edge), (35, 19, 26, 255))
    draw = ImageDraw.Draw(image)
    pink, pale, dark, red = (232, 55, 117, 255), (239, 220, 181, 255), (21, 15, 20, 255), (174, 44, 48, 255)
    if kind == "ravioli":
        draw.ellipse((edge*.19, edge*.57, edge*.81, edge*.82), fill=(92, 50, 35, 255), outline=pale, width=28)
        draw.arc((edge*.24, edge*.31, edge*.76, edge*.75), 190, 350, fill=pink, width=42)
        for x in (.34, .50, .66):
            cx, cy = edge*x, edge*.56
            draw.rounded_rectangle((cx-edge*.10, cy-edge*.08, cx+edge*.10, cy+edge*.08),
                                   radius=25, fill=(212, 154, 78, 255), outline=pale, width=16)
            draw.line((cx-edge*.06, cy, cx+edge*.06, cy), fill=(108, 62, 35, 255), width=14)
    elif kind == "stop":
        points = [(edge*.29,edge*.79),(edge*.22,edge*.48),(edge*.28,edge*.42),(edge*.36,edge*.57),
                  (edge*.34,edge*.25),(edge*.42,edge*.21),(edge*.48,edge*.51),(edge*.49,edge*.18),
                  (edge*.58,edge*.18),(edge*.61,edge*.50),(edge*.63,edge*.25),(edge*.72,edge*.27),
                  (edge*.75,edge*.59),(edge*.65,edge*.82)]
        draw.polygon(points, fill=red, outline=pale)
        draw.line(points + [points[0]], fill=pale, width=20, joint="curve")
    elif kind == "filth":
        for radius, alpha in ((.29,90),(.22,150),(.15,230)):
            draw.ellipse((edge*(.5-radius),edge*(.5-radius),edge*(.5+radius),edge*(.5+radius)),
                         outline=(232,55,117,alpha), width=max(16, int(edge*.045)))
        for angle in range(0, 360, 45):
            import math
            x, y = edge*.5 + math.cos(math.radians(angle))*edge*.33, edge*.5 + math.sin(math.radians(angle))*edge*.33
            draw.ellipse((x-edge*.045,y-edge*.045,x+edge*.045,y+edge*.045), fill=pale)
        draw.ellipse((edge*.43,edge*.43,edge*.57,edge*.57), fill=dark, outline=pink, width=20)
    return image


concept = Image.open(SOURCE / "FilthyConcept.png").convert("RGBA")
leader = Image.open(SOURCE / "FilthyLeader.png").convert("RGBA")
dawn = Image.open(SOURCE / "FilthyDawn.png").convert("RGBA")
realm_map = Image.open(SOURCE / "FilthyMap.png").convert("RGBA")
salamander = Image.open(SOURCE / "SalamanderMan.png").convert("RGBA")

# Exact non-atlas images requested by Civilization V.
save_dds(ImageOps.fit(leader, (1600, 900), Image.Resampling.LANCZOS), OUTPUT / "FilthyLeader.dds")
save_dds(ImageOps.fit(dawn, (1600, 900), Image.Resampling.LANCZOS), OUTPUT / "FilthyDawn.dds")
save_dds(ImageOps.fit(realm_map, (360, 412), Image.Resampling.LANCZOS, centering=(0.50, 0.55)),
         OUTPUT / "FilthyMap.dds")

# Finished panels from the concept sheet provide the civ, leader, UU and UB subjects.
civ_icon = rel_crop(concept, (1034, 130, 1328, 415))
leader_icon = rel_crop(concept, (642, 128, 932, 418))
peace_lord = rel_crop(concept, (574, 726, 820, 966))
kitchen = rel_crop(concept, (834, 724, 1068, 966))

for size in SIZES:
    atlas = Image.new("RGBA", (size * 2, size))
    atlas.alpha_composite(circular_asset(civ_icon, size), (0, 0))
    atlas.alpha_composite(circular_asset(leader_icon, size, (225, 199, 137, 255), (0.5, 0.43)), (size, 0))
    save_dds(atlas, OUTPUT / f"FilthyIcon{size}.dds")


def alpha_face(size: int) -> Image.Image:
    crop = ImageOps.fit(civ_icon.convert("RGB"), (size * SCALE, size * SCALE), Image.Resampling.LANCZOS)
    gray = ImageOps.grayscale(crop)
    # The source mark is black ink on pink; retain the ink while dropping its circular field.
    ink = gray.point(lambda value: 255 if value < 74 else 0)
    ink = ink.filter(ImageFilter.MaxFilter(5))
    white = Image.new("RGBA", ink.size, (255, 255, 255, 255))
    white.putalpha(ink)
    return white.resize((size, size), Image.Resampling.LANCZOS)


for size in SIZES:
    save_dds(alpha_face(size), OUTPUT / f"FilthyAlpha{size}.dds")
save_dds(alpha_face(32), OUTPUT / "FilthyUnitFlag32.dds")

object_sources = (
    (peace_lord, (225, 199, 137, 255), (0.5, 0.48)),
    (kitchen, (225, 199, 137, 255), (0.5, 0.5)),
    (salamander, (226, 55, 111, 255), (0.5, 0.42)),
    (civ_icon, (226, 55, 111, 255), (0.5, 0.5)),
    (ImageEnhance.Color(civ_icon).enhance(0.25).rotate(8, expand=False), (151, 71, 190, 255), (0.5, 0.5)),
    (graphic_icon("ravioli"), (226, 55, 111, 255), (0.5, 0.5)),
    (graphic_icon("stop"), (190, 53, 58, 255), (0.5, 0.5)),
    (graphic_icon("filth"), (226, 55, 111, 255), (0.5, 0.5)),
    (realm_map, (225, 199, 137, 255), (0.5, 0.55)),
)
for size in OBJECT_SIZES:
    atlas = Image.new("RGBA", (size * len(object_sources), size))
    for index, (source, ring, centering) in enumerate(object_sources):
        atlas.alpha_composite(circular_asset(source, size, ring, centering), (index * size, 0))
    save_dds(atlas, OUTPUT / f"FilthyObjects{size}.dds")

preview = Image.new("RGB", (1280, 880), (20, 15, 18))
preview.paste(ImageOps.fit(leader, (800, 450), Image.Resampling.LANCZOS), (0, 0))
preview.paste(ImageOps.fit(dawn, (480, 270), Image.Resampling.LANCZOS), (800, 0))
preview.paste(ImageOps.fit(realm_map, (240, 280), Image.Resampling.LANCZOS), (920, 280))
for index, (source, ring, centering) in enumerate(object_sources):
    icon = circular_asset(source, 128, ring, centering)
    preview.paste(icon, (16 + (index % 7) * 136, 580 + (index // 7) * 136), icon)
preview.save(SOURCE / "FilthyArtPreview.png")

print(f"Built Filthy Realm leader, Dawn of Man, map, flag, and {len(SIZES)*2 + len(OBJECT_SIZES)} atlases")
