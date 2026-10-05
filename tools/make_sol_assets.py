"""Compile original Sol paintings and a matching native geometric glyph to Civ V DDS."""
from pathlib import Path
import math
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools/python"))
from PIL import Image, ImageDraw, ImageFont, ImageOps

SRC = REPO / "art-source/SolIntellect"
OUT = REPO / "SolIntellect/Art"
GOLD, NAVY, IVORY = (244, 193, 81, 255), (7, 16, 38, 255), (247, 242, 220, 255)
SIZES = (256, 128, 80, 64, 45, 32)
ALPHA_SIZES = (128, 64, 48, 32, 24, 16)


def dds(image, name):
    rgba = image.convert("RGBA")
    path = OUT / (name + ".dds")
    if rgba.width % 4 == 0 and rgba.height % 4 == 0:
        rgba.save(path, pixel_format="DXT5")
    else:
        rgba.save(path)


def glyph(edge, color, compact=False):
    """Sunlight + nested reasoning layers + branching neural paths."""
    image = Image.new("RGBA", (edge, edge), (255, 255, 255, 0))
    draw = ImageDraw.Draw(image)
    center = edge / 2
    width = max(2, round(edge * (0.040 if compact else 0.025)))
    for r in (0.19, 0.30):
        draw.ellipse((center-edge*r, center-edge*r, center+edge*r, center+edge*r), outline=color, width=width)
    draw.ellipse((edge*.42, edge*.42, edge*.58, edge*.58), fill=color)
    for i in range(8):
        a = math.tau * i / 8
        def p(r): return (center + edge*r*math.cos(a), center + edge*r*math.sin(a))
        draw.line((p(.30), p(.41)), fill=color, width=width)
        x, y = p(.41)
        nr = edge * .027
        draw.ellipse((x-nr, y-nr, x+nr, y+nr), fill=color)
        if not compact and i % 2 == 0:
            draw.line((p(.10), p(.19)), fill=color, width=width)
            for offset in (-.20, .20):
                end = (center + edge*.25*math.cos(a+offset), center + edge*.25*math.sin(a+offset))
                draw.line((p(.19), end), fill=color, width=width)
    return image


def circle(source, size):
    edge = size * 4
    image = Image.new("RGBA", (edge, edge), (0, 0, 0, 0))
    inset = round(edge * .05)
    inner = edge - 2 * inset
    art = ImageOps.fit(source, (inner, inner), method=Image.Resampling.LANCZOS)
    mask = Image.new("L", art.size)
    ImageDraw.Draw(mask).ellipse((0, 0, inner-1, inner-1), fill=255)
    art.putalpha(mask)
    image.alpha_composite(art, (inset, inset))
    ImageDraw.Draw(image).ellipse((inset, inset, edge-inset-1, edge-inset-1), outline=GOLD, width=max(3, round(edge*.018)))
    return image.resize((size, size), Image.Resampling.LANCZOS)


def font(size):
    return ImageFont.truetype("C:/Windows/Fonts/georgia.ttf", size)


def map_art():
    scale = 3
    image = Image.new("RGBA", (360*scale, 412*scale), NAVY)
    d = ImageDraw.Draw(image)
    for y in range(image.height):
        shade = int(12 * y / image.height)
        d.line((0, y, image.width, y), fill=(7+shade, 16+shade, 38+shade, 255))
    d.rectangle((18*scale, 18*scale, 342*scale, 394*scale), outline=GOLD, width=2*scale)
    d.text((180*scale, 42*scale), "THE SOL INTELLECT", fill=GOLD, font=font(19*scale), anchor="mm")
    land = [(75,125),(125,105),(163,124),(205,98),(258,128),(285,175),(266,215),
            (278,258),(238,291),(224,328),(184,312),(151,336),(121,292),(82,273),
            (60,229),(85,192),(54,157)]
    land = [(x*scale,y*scale) for x,y in land]
    d.polygon(land, fill=(30,45,66), outline=GOLD, width=2*scale)
    # Geographic-looking contour layers and a river, laid out as an intellectual atlas.
    for offset in range(3):
        d.line([(x*.78+180*scale*.22+offset*scale, y*.78+220*scale*.22) for x,y in land]+[(land[0][0]*.78+180*scale*.22,land[0][1]*.78+220*scale*.22)], fill=(84,95,99), width=scale)
    d.line([(205*scale,130*scale),(186*scale,170*scale),(196*scale,211*scale),(168*scale,248*scale),(150*scale,292*scale)], fill=(154,188,202), width=3*scale)
    for x,y,label in [(174,191,"SOL PRIME"),(108,151,"HELIOS"),(233,257,"AXIOM"),(131,275,"LUMEN")]:
        r = 4*scale
        d.ellipse((x*scale-r,y*scale-r,x*scale+r,y*scale+r),fill=GOLD)
        d.text((x*scale,y*scale+10*scale),label,fill=IVORY,font=font(9*scale),anchor="mt")
    emblem = glyph(56*scale, GOLD)
    image.alpha_composite(emblem,(258*scale,63*scale))
    d.text((180*scale,369*scale),"DEPTH  ·  PATIENCE  ·  INSIGHT",fill=GOLD,font=font(10*scale),anchor="mm")
    return image.resize((360,412),Image.Resampling.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    leader = Image.open(SRC / "SolLeader.png").convert("RGBA")
    dds(ImageOps.fit(leader,(1600,900),method=Image.Resampling.LANCZOS), "SolLeader")
    dds(ImageOps.fit(leader,(1024,768),method=Image.Resampling.LANCZOS), "SolDawn")
    w,h = leader.size
    portrait = leader.crop((round(w*.32), round(h*.01), round(w*.68), round(h*.66)))
    for size in (256,128,64): dds(circle(portrait,size),f"SolLeader{size}")
    for name, source in [("Archive","SolContextArchive.png"),("Institute","SolReasoningInstitute.png")]:
        painting=Image.open(SRC/source).convert("RGBA")
        for size in (256,128,64,45): dds(circle(painting,size),f"Sol{name}{size}")
    for size in SIZES:
        edge=size*4
        canvas=Image.new("RGBA",(edge,edge),(0,0,0,0))
        d=ImageDraw.Draw(canvas)
        d.ellipse((edge*.035,edge*.035,edge*.965,edge*.965),fill=NAVY,outline=GOLD,width=max(4,round(edge*.026)))
        canvas.alpha_composite(glyph(edge,GOLD,compact=size<=32))
        icon=canvas.resize((size,size),Image.Resampling.LANCZOS)
        dds(icon,f"SolIcon{size}")
        if size==256: icon.save(SRC/"SolEmblem.png")
    for size in ALPHA_SIZES:
        dds(glyph(size*4,(255,255,255,255),compact=size<=32).resize((size,size),Image.Resampling.LANCZOS),f"SolAlpha{size}")
    map_image=map_art()
    map_image.save(SRC/"SolMap.png")
    dds(map_image,"SolMap")
    (OUT/"SolLeaderScene.xml").write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="SolLeader.dds" />\n',encoding="utf-8")
    # Review sheet, kept with editable/master art rather than shipped into VFS.
    review=Image.new("RGB",(1200,860),NAVY[:3])
    review.paste(ImageOps.fit(leader.convert("RGB"),(1200,540)),(0,0))
    d=ImageDraw.Draw(review)
    for x,stem,label in [(30,"Icon","THE SOL INTELLECT"),(440,"Archive","CONTEXT ARCHIVE"),(850,"Institute","REASONING INSTITUTE")]:
        texture=Image.open(OUT/f"Sol{stem}256.dds").convert("RGBA")
        review.paste(texture,(x+20,560),texture)
        d.text((x+150,835),label,fill=GOLD,font=font(17),anchor="mm")
    review.save(SRC/"SolArtPreview.png")
    print(f"Compiled {len(list(OUT.glob('*.dds')))} legacy DDS textures, leader scene, map and review sheet")


if __name__ == "__main__":
    main()
