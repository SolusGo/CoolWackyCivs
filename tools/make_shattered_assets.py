"""Compile original generated paintings and the collection's native icon style to DDS."""
from pathlib import Path
import sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from PIL import Image, ImageDraw, ImageFont, ImageOps
SRC=R/'art-source/TheShatteredEmpire';OUT=R/'TheShatteredEmpire/Art'
GOLD=(240,187,71,255);CRIMSON=(67,6,13,255)


def dds(im,name):
    rgba=im.convert('RGBA');path=OUT/(name+'.dds')
    if rgba.width%4==0 and rgba.height%4==0: rgba.save(path,pixel_format='DXT5')
    else: rgba.save(path)


def crown(edge,color):
    im=Image.new('RGBA',(edge,edge),(255,255,255,0));d=ImageDraw.Draw(im)
    p=lambda x,y:(round(x*edge),round(y*edge))
    d.polygon([p(.20,.35),p(.32,.47),p(.40,.29),p(.49,.40),p(.58,.23),p(.69,.47),p(.82,.33),p(.74,.67),p(.28,.67)],fill=color)
    d.rectangle((*p(.28,.72),*p(.74,.79)),fill=color)
    d.line([p(.54,.25),p(.49,.43),p(.56,.50),p(.49,.65),p(.54,.81)],fill=(0,0,0,0),width=max(1,round(edge*.04)))
    return im


def circle(source,size):
    e=size*4;im=Image.new('RGBA',(e,e));inner=round(e*.9);inset=(e-inner)//2
    art=ImageOps.fit(source,(inner,inner),method=Image.Resampling.LANCZOS)
    mask=Image.new('L',(inner,inner));ImageDraw.Draw(mask).ellipse((0,0,inner-1,inner-1),fill=255);art.putalpha(mask)
    im.alpha_composite(art,(inset,inset));ImageDraw.Draw(im).ellipse((inset,inset,e-inset-1,e-inset-1),outline=GOLD,width=max(3,round(e*.02)))
    return im.resize((size,size),Image.Resampling.LANCZOS)


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    leader=Image.open(SRC/'ImperialLeader.png').convert('RGBA');objects=Image.open(SRC/'ImperialLegionPalace.png').convert('RGBA')
    w,h=objects.size
    legion=objects.crop((0,0,w//2-5,h));palace=objects.crop((w//2+5,0,w,h))
    lw,lh=leader.size;portrait=leader.crop((round(lw*.23),round(lh*.02),round(lw*.55),round(lh*.67)))
    emblem=Image.new('RGBA',(1024,1024),CRIMSON);emblem.alpha_composite(crown(1024,GOLD))
    emblem.save(SRC/'ImperialEmblem.png')
    for size in [16,24,32,45,48,64,80,128,256]:
        atlas=Image.new('RGBA',(size*2,size*2))
        for n,painting in enumerate([emblem,portrait,legion,palace]): atlas.alpha_composite(circle(painting,size),((n%2)*size,(n//2)*size))
        dds(atlas,f'ImperialObjects{size}')
        dds(crown(size*4,(255,255,255,255)).resize((size,size),Image.Resampling.LANCZOS),f'ImperialAlpha{size}')
    dds(crown(128,(255,255,255,255)).resize((32,32),Image.Resampling.LANCZOS),'ImperialUnitFlag32')
    dds(ImageOps.fit(leader,(1600,900),method=Image.Resampling.LANCZOS),'ImperialLeader')
    dds(ImageOps.fit(leader,(1024,768),method=Image.Resampling.LANCZOS),'ImperialDawn')
    mapim=Image.new('RGBA',(720,824),(222,200,160,255));d=ImageDraw.Draw(mapim)
    d.rectangle((28,28,692,796),outline=CRIMSON,width=5)
    land=[(150,225),(248,188),(320,239),(410,204),(514,260),(558,355),(509,453),(553,553),(470,632),(359,600),(275,655),(187,591),(117,512),(135,396),(99,304)]
    d.polygon(land,fill=(175,133,99),outline=CRIMSON,width=4)
    d.line([(395,230),(365,320),(389,392),(350,458),(304,585)],fill=(71,123,149),width=7)
    font=ImageFont.truetype('C:/Windows/Fonts/georgia.ttf',29)
    d.text((360,96),'THE SHATTERED EMPIRE',font=font,anchor='mm',fill=CRIMSON)
    for x,y,label in [(352,355,'AETERNUM'),(221,280,'VALORIA'),(441,516,'VESPERA'),(253,543,'AQUILA')]:
        d.ellipse((x-9,y-9,x+9,y+9),fill=CRIMSON);d.text((x,y+18),label,font=ImageFont.truetype('C:/Windows/Fonts/georgia.ttf',18),anchor='mt',fill=CRIMSON)
    mapim.save(SRC/'ImperialMap.png');dds(mapim.resize((360,412),Image.Resampling.LANCZOS),'ImperialMap')
    (OUT/'ImperialLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="ImperialLeader.dds" />\n',encoding='utf-8')
    review=Image.new('RGB',(1200,920),CRIMSON[:3]);review.paste(ImageOps.fit(leader.convert('RGB'),(1200,600)),(0,0))
    for x,painting in [(40,emblem),(340,portrait),(640,legion),(940,palace)]:
        icon=circle(painting,220);review.paste(icon,(x,640),icon)
    review.save(SRC/'ImperialArtPreview.png')
    print('Compiled leader, dawn, map, four object portraits, alpha atlases and unit flag')


if __name__=='__main__': main()
