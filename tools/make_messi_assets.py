"""Compile Eternal Number Ten source art into Civ V-compatible DDS textures."""
from pathlib import Path
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps

SOURCE = REPO / "art-source" / "EternalNumberTen"
OUTPUT = REPO / "EternalNumberTen" / "Art"
OUTPUT.mkdir(parents=True, exist_ok=True)

SIZES = (256, 128, 80, 64, 48, 45, 32, 24, 16)
OBJECT_SIZES = (256, 128, 80, 64, 45, 32, 16)
LEADER_SIZES = (256, 128, 64)
SCALE = 4
SKY = (91, 184, 232, 255)
NAVY = (18, 43, 75, 255)
GOLD = (247, 209, 56, 255)
WHITE = (245, 247, 242, 255)


def save_dds(image: Image.Image, path: Path) -> None:
    rgba = image.convert("RGBA")
    if rgba.width % 4 == 0 and rgba.height % 4 == 0:
        rgba.save(path, pixel_format="DXT5")
    else:
        rgba.save(path)


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = (
        Path("C:/Windows/Fonts/arialbd.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
    )
    for candidate in candidates:
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def star_points(cx: float, cy: float, outer: float, inner: float) -> list[tuple[float, float]]:
    import math
    points = []
    for index in range(10):
        radius = outer if index % 2 == 0 else inner
        angle = -math.pi / 2 + index * math.pi / 5
        points.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius))
    return points


def emblem(edge: int = 1024) -> Image.Image:
    image = Image.new("RGBA", (edge, edge), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    margin = edge * 0.055
    draw.ellipse((margin, margin, edge - margin, edge - margin), fill=NAVY, outline=GOLD, width=round(edge * 0.035))
    inner = edge * 0.13
    draw.ellipse((inner, inner, edge - inner, edge - inner), fill=SKY, outline=WHITE, width=round(edge * 0.025))
    for x in (0.36, 0.50, 0.64):
        draw.polygon(star_points(edge * x, edge * 0.255, edge * 0.060, edge * 0.026), fill=GOLD)
    text = "10"
    number_font = font(round(edge * 0.45))
    box = draw.textbbox((0, 0), text, font=number_font, stroke_width=round(edge * 0.008))
    width, height = box[2] - box[0], box[3] - box[1]
    draw.text(((edge - width) / 2, edge * 0.52 - height / 2 - box[1]), text, font=number_font,
              fill=WHITE, stroke_width=round(edge * 0.012), stroke_fill=GOLD)
    ball_r = edge * 0.080
    draw.ellipse((edge * 0.5 - ball_r, edge * 0.77 - ball_r, edge * 0.5 + ball_r, edge * 0.77 + ball_r),
                 fill=GOLD, outline=NAVY, width=round(edge * 0.014))
    return image


def alpha_emblem(edge: int = 1024) -> Image.Image:
    source = emblem(edge)
    alpha = source.getchannel("A")
    white = Image.new("RGBA", source.size, (255, 255, 255, 255))
    white.putalpha(alpha)
    return white


def symbol(kind: str, edge: int = 1024) -> Image.Image:
    image = Image.new("RGBA", (edge, edge), NAVY)
    draw = ImageDraw.Draw(image)
    draw.ellipse((edge * 0.05, edge * 0.05, edge * 0.95, edge * 0.95), fill=(28, 68, 99, 255),
                 outline=GOLD, width=round(edge * 0.035))
    if kind == "number":
        number_font = font(round(edge * 0.50))
        box = draw.textbbox((0, 0), "10", font=number_font)
        draw.text(((edge - box[2]) / 2, edge * 0.48 - (box[3] - box[1]) / 2 - box[1]), "10",
                  font=number_font, fill=WHITE, stroke_width=round(edge * 0.012), stroke_fill=GOLD)
    elif kind == "legacy":
        draw.polygon(star_points(edge * 0.5, edge * 0.48, edge * 0.31, edge * 0.13), fill=GOLD)
        draw.ellipse((edge * 0.40, edge * 0.38, edge * 0.60, edge * 0.58), fill=WHITE, outline=NAVY, width=round(edge * 0.018))
    elif kind == "triangle":
        points = [(edge * 0.5, edge * 0.22), (edge * 0.22, edge * 0.72), (edge * 0.78, edge * 0.72)]
        draw.line(points + [points[0]], fill=GOLD, width=round(edge * 0.06), joint="curve")
        for x, y in points:
            draw.ellipse((x-edge*.07,y-edge*.07,x+edge*.07,y+edge*.07), fill=WHITE, outline=GOLD, width=round(edge*.018))
    elif kind == "shield":
        shield = [(edge*.5,edge*.18),(edge*.76,edge*.29),(edge*.70,edge*.65),(edge*.5,edge*.82),(edge*.30,edge*.65),(edge*.24,edge*.29)]
        draw.polygon(shield, fill=SKY, outline=GOLD)
        draw.line((edge*.34,edge*.55,edge*.45,edge*.66,edge*.67,edge*.38), fill=WHITE, width=round(edge*.055))
    elif kind == "stars":
        for x, y, radius in ((.5,.42,.23),(.28,.66,.14),(.72,.66,.14)):
            draw.polygon(star_points(edge*x, edge*y, edge*radius, edge*radius*.43), fill=GOLD)
    return image


def circular_asset(source: Image.Image, size: int, centering=(0.5, 0.5), preserve=False) -> Image.Image:
    edge = size * SCALE
    inner = round(edge * 0.86)
    picture = ImageOps.fit(source.convert("RGBA"), (inner, inner), Image.Resampling.LANCZOS, centering=centering)
    if not preserve:
        picture = ImageEnhance.Contrast(picture).enhance(1.08)
        picture = ImageEnhance.Color(picture).enhance(1.05)
    mask = Image.new("L", (inner, inner), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, inner - 3, inner - 3), fill=255)
    picture.putalpha(mask)
    canvas = Image.new("RGBA", (edge, edge))
    offset = (edge - inner) // 2
    shadow = Image.new("RGBA", (edge, edge))
    ImageDraw.Draw(shadow).ellipse((offset + 7, offset + 10, offset + inner + 5, offset + inner + 8), fill=(0, 0, 0, 150))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(2, edge // 80))))
    canvas.alpha_composite(picture, (offset, offset))
    ImageDraw.Draw(canvas).ellipse((offset, offset, offset + inner - 1, offset + inner - 1),
                                   outline=GOLD, width=max(4, round(edge * 0.025)))
    return canvas.resize((size, size), Image.Resampling.LANCZOS).filter(
        ImageFilter.UnsharpMask(radius=max(0.4, size / 160), percent=75, threshold=3))


leader = Image.open(SOURCE / "EternalLeader.png").convert("RGBA")
dawn = Image.open(SOURCE / "EternalDawn.png").convert("RGBA")
academy = Image.open(SOURCE / "FootballAcademy.png").convert("RGBA")
civ_icon = emblem()

save_dds(ImageOps.fit(leader, (1600, 900), Image.Resampling.LANCZOS, centering=(0.50, 0.50)), OUTPUT / "MessiLeader.dds")
save_dds(ImageOps.fit(dawn, (1600, 900), Image.Resampling.LANCZOS, centering=(0.50, 0.50)), OUTPUT / "MessiDawn.dds")
save_dds(ImageOps.fit(dawn, (360, 412), Image.Resampling.LANCZOS, centering=(0.67, 0.52)), OUTPUT / "MessiMap.dds")

for size in SIZES:
    save_dds(circular_asset(civ_icon, size, preserve=True), OUTPUT / f"MessiIcon{size}.dds")
    save_dds(alpha_emblem(size), OUTPUT / f"MessiAlpha{size}.dds")
save_dds(alpha_emblem(32), OUTPUT / "MessiUnitFlag32.dds")

for size in LEADER_SIZES:
    save_dds(circular_asset(leader, size, centering=(0.30, 0.36)), OUTPUT / f"MessiLeader{size}.dds")

object_sources = (
    (symbol("number"), (0.5, 0.5)),
    (academy, (0.5, 0.45)),
    (academy, (0.5, 0.64)),
    (symbol("legacy"), (0.5, 0.5)),
    (symbol("triangle"), (0.5, 0.5)),
    (symbol("shield"), (0.5, 0.5)),
    (symbol("stars"), (0.5, 0.5)),
)
for size in OBJECT_SIZES:
    atlas = Image.new("RGBA", (size * len(object_sources), size))
    for index, (source, centering) in enumerate(object_sources):
        atlas.alpha_composite(circular_asset(source, size, centering, preserve=index in (0, 3, 4, 5, 6)), (index * size, 0))
    save_dds(atlas, OUTPUT / f"MessiObjects{size}.dds")

preview = Image.new("RGB", (1280, 900), (13, 31, 53))
preview.paste(ImageOps.fit(leader, (800, 450), Image.Resampling.LANCZOS), (0, 0))
preview.paste(ImageOps.fit(dawn, (480, 270), Image.Resampling.LANCZOS), (800, 0))
preview.paste(ImageOps.fit(academy, (320, 320), Image.Resampling.LANCZOS), (880, 300))
for index, (source, centering) in enumerate(object_sources):
    icon = circular_asset(source, 112, centering, preserve=index in (0, 3, 4, 5, 6))
    preview.paste(icon, (24 + index * 174, 748), icon)
preview.save(SOURCE / "EternalNumberTenArtPreview.png")
print(f"Built Eternal Number Ten leader, Dawn, map, flag, and {len(SIZES)*2 + len(LEADER_SIZES) + len(OBJECT_SIZES)} atlases")
