"""Pack generated Kingdoms artwork into Civ V DDS atlases; no generation dependency."""
from pathlib import Path
import sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from PIL import Image,ImageOps,ImageDraw

def dds(im,path):
    im=im.convert('RGBA')
    if im.width%4==0 and im.height%4==0:im.save(path,pixel_format='DXT5')
    else:im.save(path)

def main():
    source=R/'art-source/TheKingdoms';out=R/'TheKingdoms/Art';out.mkdir(parents=True,exist_ok=True)
    sheet=Image.open(source/'IconSheet.png').convert('RGBA');w,h=sheet.size
    icons=[]
    for y in range(2):
        for x in range(2):
            icon=sheet.crop((x*w//2,y*h//2,(x+1)*w//2,(y+1)*h//2))
            box=icon.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
            icons.append(icon.crop(box) if box else icon)
    for size in (16,24,32,45,48,64,80,128,256):
        atlas=Image.new('RGBA',(size*2,size*2))
        for i,im in enumerate(icons):
            cell=ImageOps.contain(im,(size-4,size-4),Image.Resampling.LANCZOS)
            atlas.alpha_composite(cell,((i%2)*size+(size-cell.width)//2,(i//2)*size+(size-cell.height)//2))
        dds(atlas,out/f'KingdomsObjects{size}.dds')
        # An editable geometric crown/sword keeps alpha and unit flags readable,
        # instead of reducing a painted circular medallion to a solid white disk.
        glyph=Image.new('RGBA',(256,256));draw=ImageDraw.Draw(glyph)
        draw.polygon([(35,55),(74,83),(100,35),(128,76),(156,35),(182,83),(221,55),(202,135),(54,135)],fill='white')
        draw.rectangle((58,143,198,153),fill='white')
        draw.rectangle((119,162,137,218),fill='white')
        draw.polygon([(119,218),(137,218),(128,239)],fill='white')
        draw.rectangle((84,171,172,181),fill='white')
        alpha=glyph.resize((size,size),Image.Resampling.LANCZOS)
        dds(alpha,out/f'KingdomsAlpha{size}.dds')
    dds(Image.open(out/'KingdomsAlpha32.dds'),out/'KingdomsUnitFlag32.dds')
    dawn=ImageOps.fit(Image.open(source/'Dawn.png').convert('RGBA'),(1600,900),Image.Resampling.LANCZOS)
    dds(dawn,out/'KingdomsDawn.dds');dds(dawn,out/'KingdomsLeader.dds')
    mapimage=Image.new('RGBA',(360,360));cell=ImageOps.contain(icons[0],(352,352),Image.Resampling.LANCZOS)
    mapimage.alpha_composite(cell,((360-cell.width)//2,(360-cell.height)//2));dds(mapimage,out/'KingdomsMap.dds')
    (out/'KingdomsLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="KingdomsLeader.dds" />\n',encoding='utf-8')
    print('Packed 22 DDS textures and static leader scene')

if __name__=='__main__':main()
