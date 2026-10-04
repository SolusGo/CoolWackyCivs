"""Compile generated First Night illustrations into real Civ V DDS textures.

Only resizing, portrait cropping, atlas packing and UI rims are applied to the
authored illustrations. Alpha/flag/torch/book marks are native UI geometry.
"""
from pathlib import Path
import sys

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / '.tools/python'))
from PIL import Image, ImageDraw, ImageOps

SOURCE = REPO / 'art-source/PaulsoaresJr'
OUTPUT = REPO / 'PaulsoaresJr/Art'
SIZES = (256, 128, 80, 64, 48, 45, 32, 24, 16)
OBJECT_SIZES = (256, 128, 80, 64, 45, 32, 16)


def dds(image, name):
    image = image.convert('RGBA')
    if image.width % 4 == 0 and image.height % 4 == 0:
        image.save(OUTPUT / name, pixel_format='DXT5')
    else:
        image.save(OUTPUT / name)


def circular(source, size):
    edge = size * 4
    inner = round(edge * .86)
    picture = ImageOps.fit(source.convert('RGBA'), (inner, inner), Image.Resampling.LANCZOS)
    mask = Image.new('L', (inner, inner))
    ImageDraw.Draw(mask).ellipse((0, 0, inner - 1, inner - 1), fill=255)
    picture.putalpha(mask)
    canvas = Image.new('RGBA', (edge, edge))
    offset = (edge - inner) // 2
    canvas.alpha_composite(picture, (offset, offset))
    d = ImageDraw.Draw(canvas)
    bounds = (offset, offset, offset + inner - 1, offset + inner - 1)
    d.ellipse(bounds, outline=(90, 62, 20), width=max(3, round(edge * .035)))
    d.ellipse(tuple(v + (2 if i < 2 else -2) for i, v in enumerate(bounds)),
              outline=(225, 196, 105), width=max(2, round(edge * .023)))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def symbol(size, color='white', book=False, veteran=False):
    e = size * 4
    image = Image.new('RGBA', (e, e))
    d = ImageDraw.Draw(image)
    def points(values): return [(round(x * e), round(y * e)) for x, y in values]
    if veteran:
        d.ellipse((e*.22,e*.22,e*.78,e*.78), outline=color, width=round(e*.05))
        d.polygon(points(((.5,.15),(.58,.45),(.5,.85),(.42,.55))), fill=color)
        d.polygon(points(((.15,.5),(.45,.42),(.85,.5),(.55,.58))), fill=color)
    else:
        if book:
            d.polygon(points(((.16,.60),(.45,.63),(.5,.69),(.55,.63),(.84,.60),(.84,.84),(.53,.88),(.5,.92),(.47,.88),(.16,.84))),fill=color)
        else:
            d.line(points(((.22,.79),(.22,.47),(.5,.23),(.78,.47),(.78,.79))),fill=color,width=round(e*.08),joint='curve')
        d.rectangle((e*.46,e*.48,e*.55,e*.77),fill=color)
        d.polygon(points(((.5,.24),(.60,.40),(.57,.50),(.45,.50),(.40,.42),(.47,.36))),fill=color)
    return image.resize((size,size),Image.Resampling.LANCZOS)


def medallion(book=False, veteran=False):
    bg = Image.new('RGBA',(512,512),(10,32,49,255))
    mark = symbol(512,(246,184,61,255),book,veteran)
    bg.alpha_composite(mark)
    return bg


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    leader = Image.open(SOURCE/'Leader.png')
    dawn = Image.open(SOURCE/'Dawn.png')
    survivor = Image.open(SOURCE/'Survivor.png')
    house = Image.open(SOURCE/'House.png')
    # Coordinates are normalized against the generated leader scene.
    portrait = leader.crop((round(leader.width*.25),round(leader.height*.08),
                            round(leader.width*.72),round(leader.height*.90)))
    civ = medallion()
    objects = (survivor,house,medallion(book=True),medallion(veteran=True))
    for size in SIZES:
        atlas = Image.new('RGBA',(size*2,size))
        atlas.alpha_composite(circular(civ,size))
        atlas.alpha_composite(circular(portrait,size),(size,0))
        dds(atlas,f'PSJIcon{size}.dds')
        dds(symbol(size),f'PSJAlpha{size}.dds')
    for size in OBJECT_SIZES:
        atlas = Image.new('RGBA',(size*4,size))
        for i,source in enumerate(objects): atlas.alpha_composite(circular(source,size),(size*i,0))
        dds(atlas,f'PSJObjects{size}.dds')
    dds(symbol(32,book=True),'PSJUnitFlag32.dds')
    dds(ImageOps.fit(leader,(1600,900),Image.Resampling.LANCZOS),'PSJLeader.dds')
    dds(ImageOps.fit(dawn,(1600,900),Image.Resampling.LANCZOS),'PSJDawn.dds')
    dds(ImageOps.fit(dawn,(360,412),Image.Resampling.LANCZOS,centering=(.24,.5)),'PSJMap.dds')
    (OUTPUT/'PSJLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="PSJLeader.dds" />\n',encoding='utf-8')
    preview = Image.new('RGB',(1200,720),(10,32,49))
    preview.paste(leader.resize((800,450),Image.Resampling.LANCZOS),(0,0))
    preview.paste(dawn.resize((400,225),Image.Resampling.LANCZOS),(800,0))
    for i,source in enumerate((civ,portrait,*objects)):
        icon=circular(source,160)
        preview.paste(icon,(20+i*195,500),icon)
    preview.save(SOURCE/'ArtPreview.png')
    print('Built First Night DDS art and gold-rimmed atlases; preview in art-source/PaulsoaresJr.')


if __name__ == '__main__': main()
