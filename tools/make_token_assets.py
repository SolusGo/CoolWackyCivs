"""Compile original oracle illustrations and native bronze/teal glyphs to DDS.

No generated illustrations are repainted: fit/crop, alpha masks and atlas packing
only. Icons are original deterministic geometric UI art, matching the collection.
"""
from pathlib import Path
import math, sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from PIL import Image, ImageDraw, ImageOps
from make_psj_assets import circular
S=R/'art-source/TokenizedIntelligence';O=R/'TokenizedIntelligence/Art'
SIZES=(256,128,80,64,48,45,32,24,16)
GOLD=(231,191,99,255);TEAL=(91,227,209,255)
def dds(im,name):
    im.convert('RGBA').save(O/name,**({'pixel_format':'DXT5'} if im.width%4==0 and im.height%4==0 else {}))
def mark(size=512,color='white'):
    im=Image.new('RGBA',(size,size));d=ImageDraw.Draw(im)
    def p(x):return round(x*size)
    for radius in (.16,.29):d.ellipse((p(.5-radius),p(.5-radius),p(.5+radius),p(.5+radius)),outline=color,width=p(.035))
    d.polygon([(p(.5),p(.39)),(p(.61),p(.5)),(p(.5),p(.61)),(p(.39),p(.5))],fill=color)
    for a in range(0,360,60):
        t=math.radians(a)
        points=[(p(.5+r*math.cos(t)),p(.5+r*math.sin(t))) for r in (.29,.40)]
        d.line(points,fill=color,width=p(.03));x,y=points[1]
        d.ellipse((x-p(.04),y-p(.04),x+p(.04),y+p(.04)),fill=color)
    return im
def glyph(slot):
    im=Image.new('RGBA',(512,512),(12,34,37,255));d=ImageDraw.Draw(im)
    # Engraved network backing.
    for x in range(40,500,72):
        d.line((x,0,512-x,512),fill=(22,62,63,255),width=2)
        d.line((0,x,512,512-x),fill=(25,58,54,255),width=2)
    if slot==0:
        for r in (174,140):d.ellipse((256-r,256-r,256+r,256+r),outline=GOLD,width=12)
        im.alpha_composite(mark(350,TEAL),(81,81))
    elif slot==1:
        d.rounded_rectangle((104,98,408,414),radius=28,outline=GOLD,width=16)
        im.alpha_composite(mark(290,TEAL),(111,111))
    elif slot in (2,3):
        towers=3 if slot==2 else 5
        for i in range(towers):
            x=90+i*(310//towers);y=180-(i%2)*50
            d.polygon([(x,y),(x+40,y-30),(x+65,y),(x+65,365),(x,390)],fill=(91,71,43),outline=GOLD,width=5)
            for j in range(3):d.line((x+14,y+40+j*42,x+49,y+27+j*42),fill=TEAL,width=8)
        d.polygon([(64,400),(256,448),(448,400),(256,364)],fill=(67,53,34),outline=GOLD,width=8)
    elif slot==4:
        d.polygon([(124,406),(150,260),(212,223),(300,223),(364,260),(388,406)],fill=(78,62,40),outline=GOLD,width=9)
        d.line((256,230,256,408),fill=TEAL,width=10)
        d.ellipse((186,91,326,231),fill=(28,51,49),outline=GOLD,width=12)
        d.line((209,161,303,161),fill=TEAL,width=18)
        d.polygon([(83,149),(105,97),(122,149),(110,422),(92,422)],fill=GOLD)
    elif slot in (5,6,8,9,11):
        d.polygon([(130,102),(382,102),(360,326),(256,421),(152,326)],fill=(29,66,62),outline=GOLD,width=13)
        if slot in (5,6,8):
            d.polygon([(256,143),(280,290),(256,350),(232,290)],fill=TEAL)
            d.line((190,290,322,290),fill=GOLD,width=18)
        elif slot==9:d.polygon([(256,168),(328,260),(256,344),(184,260)],outline=TEAL,width=18)
        else:
            for r in (42,88):d.ellipse((256-r,256-r,256+r,256+r),outline=TEAL,width=12)
            d.line((158,256,354,256),fill=GOLD,width=8);d.line((256,158,256,354),fill=GOLD,width=8)
    elif slot==7:
        d.polygon([(64,258),(154,174),(256,142),(358,174),(448,258),(358,340),(256,370),(154,340)],outline=GOLD,width=16)
        d.ellipse((196,196,316,316),outline=TEAL,width=17);d.ellipse((233,233,279,279),fill=GOLD)
    elif slot==10:
        for x in (120,240):d.line([(x,135),(x+115,256),(x,377)],fill=TEAL if x==120 else GOLD,width=29,joint='curve')
    elif slot in (12,14):
        d.arc((117,117,395,395),35,328,fill=GOLD,width=24)
        d.polygon([(351,100),(429,178),(325,187)],fill=TEAL)
        if slot==12:
            d.line((218,220,294,296),fill=TEAL,width=18);d.line((294,220,218,296),fill=TEAL,width=18)
        else:d.line([(195,251),(243,301),(322,207)],fill=TEAL,width=24,joint='curve')
    elif slot==13:
        d.polygon([(150,145),(362,145),(330,198),(320,331),(363,390),(149,390),(194,331),(182,198)],fill=(73,58,35),outline=GOLD,width=10)
        for x in range(210,310,24):d.line((x,195,x,336),fill=TEAL,width=7)
    else:
        d.polygon([(256,90),(438,400),(74,400)],outline=GOLD,width=20)
        d.line((256,185,256,295),fill=TEAL,width=24);d.ellipse((243,329,269,355),fill=TEAL)
    return im
def main():
    O.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
    leader=Image.open(S/'Axiom.png');dawn=Image.open(S/'Dawn.png');mapart=Image.open(S/'Map.png')
    civ=glyph(0);civ.alpha_composite(mark(350,TEAL),(81,81))
    # Central oracle head/torso, fit from the wide generated leader scene.
    portrait=leader.crop((int(leader.width*.32),int(leader.height*.05),int(leader.width*.68),int(leader.height*.85)))
    objects=[glyph(i) for i in range(16)]
    for size in SIZES:
        atlas=Image.new('RGBA',(size*2,size))
        for i,src in enumerate([civ,portrait]):atlas.alpha_composite(circular(src,size),(size*i,0))
        dds(atlas,f'TokenIcon{size}.dds')
        dds(mark().resize((size,size),Image.Resampling.LANCZOS),f'TokenAlpha{size}.dds')
        atlas=Image.new('RGBA',(size*4,size*4))
        for i,src in enumerate(objects):atlas.alpha_composite(circular(src,size),((i%4)*size,(i//4)*size))
        dds(atlas,f'TokenObjects{size}.dds')
    dds(mark().resize((32,32),Image.Resampling.LANCZOS),'TokenUnitFlag32.dds')
    dds(ImageOps.fit(leader,(1600,900),Image.Resampling.LANCZOS),'TokenLeader.dds')
    dds(ImageOps.fit(dawn,(1024,768),Image.Resampling.LANCZOS),'TokenDawn.dds')
    dds(ImageOps.fit(mapart,(360,412),Image.Resampling.LANCZOS),'TokenMap.dds')
    (O/'TokenLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="TokenLeader.dds" />\n',encoding='utf-8')
    preview=Image.new('RGBA',(1024,1024))
    for i,src in enumerate(objects):preview.alpha_composite(circular(src,256),((i%4)*256,(i//4)*256))
    preview.save(S/'AtlasPreview.png')
    print('Compiled 31 DDS textures, original UI glyphs and static leader scene')
if __name__=='__main__':main()
