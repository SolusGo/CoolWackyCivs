"""Build Rou'ls' exact Civ V color, alpha, and leader atlas slots."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps

REPO = Path(__file__).resolve().parents[1]
EMBLEM_SOURCE = REPO / "art-source/RoulsEmblemRefined.png"
LEADER_SOURCE = REPO / "art-source/RoulsLeader.png"
OUTPUT = REPO / "RoulsAscendancy/Art"
COLOR_SIZES = (256, 128, 80, 64, 45, 32)
ALPHA_SIZES = (128, 64, 48, 32, 24, 16)
LEADER_SIZES = (256, 128, 64)
SCALE = 4


def visible_source(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if not bounds:
        raise ValueError(f"{path.name} contains no visible pixels")
    return image.crop(bounds)


def fit_symbol(source: Image.Image, size: int, fraction: float) -> Image.Image:
    inner = max(1, round(size * SCALE * fraction))
    fitted = source.copy()
    fitted.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    return fitted


def finish(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.Resampling.LANCZOS).filter(
        ImageFilter.UnsharpMask(radius=max(0.4, size / 160), percent=65, threshold=3)
    )


def save_dds(image: Image.Image, path: Path) -> None:
    rgba = image.convert("RGBA")
    rgba.save(path, pixel_format="DXT5") if rgba.width % 4 == 0 and rgba.height % 4 == 0 else rgba.save(path)


OUTPUT.mkdir(parents=True, exist_ok=True)
symbol = visible_source(EMBLEM_SOURCE)

for size in COLOR_SIZES:
    canvas = Image.new("RGBA", (size * SCALE, size * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    inset = round(size * SCALE * 0.035)
    draw.ellipse(
        (inset, inset, size * SCALE - inset - 1, size * SCALE - inset - 1),
        fill=(42, 20, 62, 255),
        outline=(112, 230, 209, 255),
        width=max(SCALE, round(size * SCALE * 0.045)),
    )
    fitted = fit_symbol(symbol, size, 0.73)
    canvas.alpha_composite(fitted, ((canvas.width - fitted.width) // 2, (canvas.height - fitted.height) // 2))
    save_dds(finish(canvas, size), OUTPUT / f"RoulsIcon{size}.dds")

for size in ALPHA_SIZES:
    canvas = Image.new("RGBA", (size * SCALE, size * SCALE), (255, 255, 255, 0))
    fitted = fit_symbol(symbol, size, 0.78)
    white = Image.new("RGBA", fitted.size, (255, 255, 255, 255))
    white.putalpha(fitted.getchannel("A"))
    canvas.alpha_composite(white, ((canvas.width - fitted.width) // 2, (canvas.height - fitted.height) // 2))
    save_dds(finish(canvas, size), OUTPUT / f"RoulsAlpha{size}.dds")

leader = Image.open(LEADER_SOURCE).convert("RGBA")
save_dds(ImageOps.fit(leader, (1600, 900), method=Image.Resampling.LANCZOS), OUTPUT / "RoulsLeader.dds")
for size in LEADER_SIZES:
    inner = round(size * SCALE * 0.88)
    portrait = ImageOps.fit(
        leader, (inner, inner), method=Image.Resampling.LANCZOS, centering=(0.50, 0.36)
    )
    mask = Image.new("L", portrait.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, inner - 1, inner - 1), fill=255)
    portrait.putalpha(mask)
    canvas = Image.new("RGBA", (size * SCALE, size * SCALE), (0, 0, 0, 0))
    canvas.alpha_composite(portrait, ((canvas.width - inner) // 2, (canvas.height - inner) // 2))
    save_dds(finish(canvas, size), OUTPUT / f"RoulsLeader{size}.dds")

print(f"Built Rou'ls {len(COLOR_SIZES)} color, {len(ALPHA_SIZES)} alpha, and {len(LEADER_SIZES)} leader atlases")
