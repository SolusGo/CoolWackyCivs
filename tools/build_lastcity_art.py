"""Pack generated Last City sources into exact Civ V DDS slots; no API calls."""
from pathlib import Path
import sys

R = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(R / '.tools/python'))
from PIL import Image, ImageDraw, ImageFont, ImageOps

SOURCE = R / 'art-source/TheLastCity'
ART = R / 'TheLastCity/Art'
SIZES = (256, 128, 80, 64, 48, 45, 32, 24, 16)
LEADER_SIZES = (256, 128, 64)
OBJECT_NAMES = ('LastWatch', 'SurvivalDistrict', 'Barracks', 'Residential',
                'Shelter', 'Hospital', 'Storage', 'Depot', 'Water', 'DawnProject')
PROMOTIONS = ('SANCTUARY', 'NO_CONQUEST', 'WATCH', 'RESOLVE', 'INVADER',
              'BOSS', 'COMMAND', 'PLAGUE', 'ELITE') + tuple(
                  key + str(n) for n in range(1, 6)
                  for key in ('VETERAN_', 'VETERAN_ACTIVE_', 'TRAINING_'))


def dds(image, name):
    image = image.convert('RGBA')
    path = ART / name
    if image.width % 4 == 0 and image.height % 4 == 0:
        image.save(path, pixel_format='DXT5')
    else:
        image.save(path)  # 45px slots cannot use block compression.


def read(name):
    return Image.open(SOURCE / (name + '.png')).convert('RGBA')


def portrait(source, size, center=(0.5, 0.5), rank=None):
    edge = size * 4
    inner = round(edge * .86)
    picture = ImageOps.fit(source, (inner, inner), Image.Resampling.LANCZOS,
                           centering=center)
    mask = Image.new('L', (inner, inner))
    ImageDraw.Draw(mask).ellipse((0, 0, inner - 1, inner - 1), fill=255)
    picture.putalpha(mask)
    canvas = Image.new('RGBA', (edge, edge))
    offset = (edge - inner) // 2
    canvas.alpha_composite(picture, (offset, offset))
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((offset, offset, offset + inner - 1, offset + inner - 1),
                 outline=(199, 154, 82, 255), width=max(3, round(edge * .025)))
    if rank is not None:
        font = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', round(edge * .23))
        box = (round(edge * .61), round(edge * .61), round(edge * .90), round(edge * .90))
        draw.ellipse(box, fill=(20, 23, 29, 255), outline=(242, 189, 98, 255),
                     width=max(3, round(edge * .014)))
        draw.text((edge * .755, edge * .755), str(rank), font=font, anchor='mm',
                  fill=(255, 221, 163, 255))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def emblem_cell(symbol, size, color=False):
    edge = size * 4
    canvas = Image.new('RGBA', (edge, edge))
    if color:
        ImageDraw.Draw(canvas).ellipse((edge * .06, edge * .06, edge * .94, edge * .94),
            fill=(24, 29, 37, 255), outline=(210, 156, 70, 255),
            width=max(3, round(edge * .028)))
    fitted = ImageOps.contain(symbol, (round(edge * .69), round(edge * .69)), Image.Resampling.LANCZOS)
    colored = Image.new('RGBA', fitted.size, (249, 209, 137, 255) if color else (255, 255, 255, 255))
    colored.putalpha(fitted.getchannel('A'))
    canvas.alpha_composite(colored, ((edge - fitted.width) // 2, (edge - fitted.height) // 2))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def main():
    ART.mkdir(exist_ok=True)
    # Fit, rather than stretch: Dawn is 4:3, diplomacy is 16:9.
    dds(ImageOps.fit(read('LastLight'), (1024, 768), Image.Resampling.LANCZOS), 'LastLight.dds')
    dds(ImageOps.fit(read('Warden'), (1600, 900), Image.Resampling.LANCZOS), 'WardenLeader.dds')
    dds(ImageOps.fit(read('LastLightMap'), (360, 412), Image.Resampling.LANCZOS), 'LastLightMap.dds')
    (ART / 'WardenLeaderScene.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="WardenLeader.dds" />\n', encoding='utf-8')
    symbol = read('BeaconEmblem')
    bounds = symbol.getchannel('A').point(lambda a: 255 if a > 32 else 0).getbbox()
    assert bounds, 'Generated emblem has no visible alpha'
    symbol = symbol.crop(bounds)
    sources = [read(name) for name in OBJECT_NAMES]
    # Promotions derive from original painted sources, with visible tier badges.
    promo_sources = [sources[4], sources[0], sources[0], read('Warden'), sources[0],
                     read('Warden'), read('Warden'), sources[5], sources[0]]
    promo_sources += [sources[0] for _ in range(15)]
    for size in SIZES:
        dds(emblem_cell(symbol, size, True), f'LastCityIcon{size}.dds')
        dds(emblem_cell(symbol, size), f'LastCityAlpha{size}.dds')
        objects = Image.new('RGBA', (size * 4, size * 3))
        for i, source in enumerate(sources):
            objects.alpha_composite(portrait(source, size), ((i % 4) * size, (i // 4) * size))
        dds(objects, f'LastCityObjects{size}.dds')
        promos = Image.new('RGBA', (size * 4, size * 6))
        for i, source in enumerate(promo_sources):
            rank = int(PROMOTIONS[i][-1]) if i >= 9 else None
            promos.alpha_composite(portrait(source, size, rank=rank), ((i % 4) * size, (i // 4) * size))
        dds(promos, f'LastCityPromotions{size}.dds')
    dds(emblem_cell(symbol, 32), 'LastCityUnitFlag32.dds')
    for size in LEADER_SIZES:
        warden = read('Warden')
        face = warden.crop((round(warden.width * .29), 0,
                            round(warden.width * .61), round(warden.height * .58)))
        dds(portrait(face, size), f'WardenPortrait{size}.dds')
    preview = Image.new('RGB', (1280, 1000), (18, 22, 29))
    preview.paste(ImageOps.fit(read('LastLight'), (640, 480), Image.Resampling.LANCZOS), (0, 0))
    preview.paste(ImageOps.fit(read('Warden'), (640, 360), Image.Resampling.LANCZOS), (640, 0))
    for i, source in enumerate(sources):
        icon = portrait(source, 128)
        preview.paste(icon, (32 + (i % 5) * 250, 505 + (i // 5) * 170), icon)
    for i, size in enumerate((128, 64, 32, 16)):
        icon = emblem_cell(symbol, size, True)
        preview.paste(icon, (670 + i * 145, 385), icon)
    for i in range(5):
        icon = portrait(sources[0], 64, rank=i + 1)
        preview.paste(icon, (390 + i * 100, 910), icon)
    preview.save(SOURCE / 'ArtPreview.png')
    print(f'Packed {len(list(ART.glob("*.dds")))} DDS textures and the custom Warden leader scene')


if __name__ == '__main__':
    main()
