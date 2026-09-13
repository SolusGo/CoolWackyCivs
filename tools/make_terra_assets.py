"""Compile Terra source art into the exact atlas slots Civ V requests."""
from pathlib import Path
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools/python"))
from PIL import Image, ImageDraw, ImageFilter, ImageOps

SRC = REPO / "art-source"
OUT = REPO / "TerraFramework/Art"
COLOR_SIZES = (256, 128, 80, 64, 45, 32)
ALPHA_SIZES = (128, 64, 48, 32, 24, 16)
LEADER_SIZES = (256, 128, 64)
UNIT_SIZES = (256, 128, 80, 64, 45)
BUILDING_SIZES = (256, 128, 64, 45)
SCALE = 4


def visible_source(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    return image.crop(bounds) if bounds else image


def finish(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.Resampling.LANCZOS).filter(
        ImageFilter.UnsharpMask(radius=max(0.4, size / 160), percent=60, threshold=3)
    )


def save_dds(image: Image.Image, path: Path) -> None:
    rgba = image.convert("RGBA")
    rgba.save(path, pixel_format="DXT5") if rgba.width % 4 == 0 and rgba.height % 4 == 0 else rgba.save(path)


def circular_atlas(source: Image.Image, sizes: tuple[int, ...], stem: str, centering=(0.5, 0.5)) -> None:
    for size in sizes:
        inner = round(size * SCALE * 0.88)
        portrait = ImageOps.fit(source, (inner, inner), method=Image.Resampling.LANCZOS, centering=centering)
        mask = Image.new("L", portrait.size, 0)
        ImageDraw.Draw(mask).ellipse((0, 0, inner - 1, inner - 1), fill=255)
        portrait.putalpha(mask)
        canvas = Image.new("RGBA", (size * SCALE, size * SCALE), (0, 0, 0, 0))
        canvas.alpha_composite(portrait, ((canvas.width - inner) // 2, (canvas.height - inner) // 2))
        save_dds(finish(canvas, size), OUT / f"Terra{stem}{size}.dds")


OUT.mkdir(parents=True, exist_ok=True)
leader = Image.open(SRC / "TerraLeader.png").convert("RGBA")
save_dds(ImageOps.fit(leader, (1600, 900), method=Image.Resampling.LANCZOS), OUT / "TerraLeader.dds")
save_dds(ImageOps.fit(leader, (360, 412), method=Image.Resampling.LANCZOS, centering=(0.5, 0.4)), OUT / "TerraMap.dds")

symbol = visible_source(SRC / "TerraIconRefined.png")
for size in COLOR_SIZES:
    canvas = Image.new("RGBA", (size * SCALE, size * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    inset = round(size * SCALE * 0.035)
    draw.ellipse(
        (inset, inset, size * SCALE - inset - 1, size * SCALE - inset - 1),
        fill=(16, 42, 40, 255), outline=(220, 204, 148, 255),
        width=max(SCALE, round(size * SCALE * 0.045)),
    )
    inner = round(size * SCALE * 0.74)
    fitted = symbol.copy()
    fitted.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    canvas.alpha_composite(fitted, ((canvas.width - fitted.width) // 2, (canvas.height - fitted.height) // 2))
    save_dds(finish(canvas, size), OUT / f"TerraIcon{size}.dds")

for size in ALPHA_SIZES:
    edge = size * SCALE
    canvas = Image.new("RGBA", (edge, edge), (255, 255, 255, 0))
    draw = ImageDraw.Draw(canvas)
    outer = (edge * 0.16, edge * 0.16, edge * 0.84, edge * 0.84)
    major = max(SCALE, round(edge * 0.060))
    minor = max(SCALE, round(edge * 0.038))
    draw.ellipse(outer, outline="white", width=major)
    draw.ellipse((edge * 0.34, edge * 0.16, edge * 0.66, edge * 0.84), outline="white", width=minor)
    draw.line((edge * 0.17, edge * 0.50, edge * 0.83, edge * 0.50), fill="white", width=minor)
    radius = edge * 0.050
    for x, y in ((0.50, 0.16), (0.84, 0.50), (0.50, 0.84), (0.16, 0.50)):
        draw.ellipse((edge*x-radius, edge*y-radius, edge*x+radius, edge*y+radius), fill="white")
    radius = edge * 0.085
    draw.ellipse((edge*0.5-radius, edge*0.5-radius, edge*0.5+radius, edge*0.5+radius), fill="white")
    save_dds(finish(canvas, size), OUT / f"TerraAlpha{size}.dds")

circular_atlas(Image.open(SRC / "TerraOperative.png").convert("RGBA"), UNIT_SIZES, "Operative")
circular_atlas(Image.open(SRC / "TerraHub.png").convert("RGBA"), BUILDING_SIZES, "Hub")
circular_atlas(leader, LEADER_SIZES, "Leader", centering=(0.5, 0.34))

count = len(COLOR_SIZES) + len(ALPHA_SIZES) + len(UNIT_SIZES) + len(BUILDING_SIZES) + len(LEADER_SIZES)
print(f"Built Terra leader scene, setup image, and {count} exact-size atlas textures")
