"""Compile original Paradise paintings and vector-style emblems to finished DDS.

DirectXTex supplies legacy headers and full mip chains. Odd-sized icon atlases
use uncompressed RGBA, as in the collection; divisible-by-four textures use BC3.
"""
from pathlib import Path
import math
import shutil
import subprocess
import sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from PIL import Image,ImageDraw,ImageFont,ImageOps
S=R/'art-source/TheBoyWhoTouchedParadise';D=R/'TheBoyWhoTouchedParadise/Art'
TMP=R/'.tools/paradise-art'
SKY=(91,184,232,255);WHITE=(247,248,242,255);GOLD=(236,196,93,255);NAVY=(14,36,63,255)

def font(size):return ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',size)
def symbol(kind,alpha=False):
    im=Image.new('RGBA',(512,512));d=ImageDraw.Draw(im)
    color=WHITE if alpha else GOLD
    if not alpha:d.ellipse((16,16,496,496),fill=NAVY,outline=GOLD,width=12)
    if kind in ('civ','memorial'):
        if not alpha:
            d.rectangle((80,130,432,200),fill=SKY);d.rectangle((80,200,432,275),fill=WHITE)
            d.rectangle((80,275,432,345),fill=SKY)
        for angle in range(0,360,20):
            a=math.radians(angle);d.line((256+118*math.cos(a),210+118*math.sin(a),256+155*math.cos(a),210+155*math.sin(a)),fill=color,width=8)
        d.ellipse((173,127,339,293),fill=color)
        d.text((256,202),'10',anchor='mm',font=font(90),fill=NAVY if not alpha else (0,0,0,0))
        if kind=='memorial':
            for side in [-1,1]:
                for i in range(7):
                    x=256+side*(145-i*10);y=390-i*19
                    d.ellipse((x-16,y-11,x+16,y+11),fill=color)
    elif kind=='potrero':
        d.rounded_rectangle((80,230,432,420),radius=18,fill=(72,119,101,255),outline=WHITE,width=8)
        d.line((256,235,256,416),fill=WHITE,width=6);d.ellipse((212,288,300,366),outline=WHITE,width=6)
        d.rectangle((120,120,340,250),outline=GOLD,width=12)
        for x in range(135,340,30):d.line((x,130,x,245),fill=WHITE,width=3)
        for y in range(145,245,25):d.line((125,y,335,y),fill=WHITE,width=3)
        d.ellipse((325,295,382,352),fill=WHITE,outline=NAVY,width=5)
    elif kind=='dance':
        d.ellipse((160,65,350,255),fill=GOLD,outline=WHITE,width=8)
        d.polygon([(214,235),(296,235),(280,345),(332,401),(180,401),(232,345)],fill=GOLD)
        d.arc((100,170,415,340),0,180,fill=WHITE,width=13)
        d.rectangle((166,408,346,443),fill=WHITE)
    elif kind=='pass':
        d.line([(94,357),(193,196),(299,320),(419,126)],fill=SKY,width=22,joint='curve')
        for x,y in [(94,357),(193,196),(299,320)]:d.ellipse((x-26,y-26,x+26,y+26),fill=WHITE,outline=GOLD,width=6)
        d.polygon([(419,126),(354,145),(420,193)],fill=GOLD)
    elif kind=='hope':
        d.polygon([(256,85),(406,155),(376,327),(256,433),(136,327),(106,155)],fill=SKY,outline=GOLD,width=8)
        d.line((180,280,238,335,335,193),fill=WHITE,width=27)
    elif kind=='beauty':
        for x,y,r in [(256,216,111),(140,365,45),(375,365,45)]:
            points=[]
            for i in range(10):
                a=-math.pi/2+i*math.pi/5;radius=r if i%2==0 else r*.43
                points.append((x+radius*math.cos(a),y+radius*math.sin(a)))
            d.polygon(points,fill=GOLD)
    else:
        d.polygon([(256,155),(218,112),(141,110),(90,170),(93,235),(256,405),(419,235),(422,170),(371,110),(294,112)],fill=SKY)
        d.line([(275,131),(232,206),(286,260),(237,315),(264,384)],fill=NAVY,width=17)
    return im

def circle(source,size,center=(.5,.5)):
    edge=size*4;im=Image.new('RGBA',(edge,edge));inner=int(edge*.88)
    pic=ImageOps.fit(source.convert('RGBA'),(inner,inner),Image.Resampling.LANCZOS,centering=center)
    mask=Image.new('L',(inner,inner));ImageDraw.Draw(mask).ellipse((0,0,inner-1,inner-1),fill=255)
    pic.putalpha(mask);off=(edge-inner)//2;im.alpha_composite(pic,(off,off))
    ImageDraw.Draw(im).ellipse((off,off,off+inner-1,off+inner-1),outline=GOLD,width=max(4,int(edge*.022)))
    return im.resize((size,size),Image.Resampling.LANCZOS)

def main():
    texconv=shutil.which('texconv.exe')
    if not texconv:raise RuntimeError('Rebuilding art requires DirectXTex texconv; finished DDS are included for installation.')
    TMP.mkdir(parents=True,exist_ok=True);D.mkdir(parents=True,exist_ok=True)
    files=[]
    def queue(im,name):
        path=TMP/(name+'.png');im.save(path);files.append((path,im.width%4==0 and im.height%4==0))
    leader=Image.open(S/'Leader.png').convert('RGBA');journey=Image.open(S/'Journey.png').convert('RGBA')
    heartbreak=Image.open(S/'Heartbreak.png').convert('RGBA');final=Image.open(S/'FinalPeak.png').convert('RGBA')
    for name,im in [('ParadiseLeader',leader),('ParadiseDawn',journey),('ParadiseHeartbreak',heartbreak),('ParadiseFinalPeak',final)]:
        queue(ImageOps.fit(im,(1600,900),Image.Resampling.LANCZOS),name)
    for name,im,center in [('ParadiseJourney',journey,(.5,.5)),('ParadiseWeight',heartbreak,(.5,.5)),('ParadiseEpilogue',final,(.5,.5))]:
        queue(ImageOps.fit(im,(280,420),Image.Resampling.LANCZOS,centering=center),name)
    # Original Argentine silhouette/loading map rather than duplicating a portrait.
    mapim=Image.new('RGBA',(360,412),NAVY);d=ImageDraw.Draw(mapim)
    argentina=[(169,28),(218,34),(241,72),(228,122),(251,164),(215,187),(208,231),(181,266),(166,313),(149,365),(130,350),(131,302),(111,266),(111,221),(119,181),(103,147),(124,119),(139,76)]
    d.polygon(argentina,fill=SKY,outline=GOLD,width=3)
    d.text((180,16),'ARGENTINA',anchor='mt',font=font(22),fill=WHITE)
    for x,y,label in [(199,178,'Buenos Aires'),(175,147,'Rosario')]:
        d.ellipse((x-4,y-4,x+4,y+4),fill=GOLD);d.text((x+9,y-9),label,font=font(12),fill=WHITE)
    d.text((180,387),'THE JOURNEY',anchor='mm',font=font(20),fill=GOLD)
    queue(mapim,'ParadiseMap')
    for size in [256,128,80,64,48,45,32,24,16]:
        queue(circle(symbol('civ'),size),'ParadiseIcon'+str(size))
        queue(symbol('civ',True).resize((size,size),Image.Resampling.LANCZOS),'ParadiseAlpha'+str(size))
    queue(symbol('civ',True).resize((32,32),Image.Resampling.LANCZOS),'ParadiseUnitFlag32')
    for size in [256,128,64]:queue(circle(leader,size,(.5,.28)),'ParadiseLeader'+str(size))
    sources=[leader,symbol('potrero'),symbol('dance'),symbol('memorial'),symbol('pass'),symbol('hope'),symbol('beauty'),symbol('heartbreak')]
    for size in [256,128,80,64,48,45,32,24,16]:
        atlas=Image.new('RGBA',(8*size,size))
        for i,im in enumerate(sources):atlas.alpha_composite(circle(im,size,(.5,.28) if i==0 else (.5,.5)),(i*size,0))
        queue(atlas,'ParadiseObjects'+str(size))
    for bc3 in [True,False]:
        paths=[str(path) for path,compress in files if compress==bc3]
        if paths:
            result=subprocess.run([texconv,'-nologo','-y','-m','0','-f','BC3_UNORM' if bc3 else 'R8G8B8A8_UNORM','-o',str(D),*paths],capture_output=True,text=True)
            if result.returncode:raise RuntimeError(result.stdout+result.stderr)
    preview=Image.new('RGB',(1280,1050),NAVY[:3])
    for i,im in enumerate([leader,journey,heartbreak,final]):preview.paste(ImageOps.fit(im,(640,360),Image.Resampling.LANCZOS),(i%2*640,i//2*360))
    for i,im in enumerate(sources):preview.paste(circle(im,140,(.5,.28) if i==0 else (.5,.5)),(10+i*158,750),circle(im,140,(.5,.28) if i==0 else (.5,.5)))
    preview.paste(mapim.resize((110,126)),(14,911));preview.save(S/'ParadiseArtPreview.png')
    (D/'ParadiseLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="ParadiseLeader.dds" />\n',encoding='utf-8')
    print(f'Built {len(files)} game-ready Paradise DDS textures, each with a mip chain, and leader scene.')

if __name__=='__main__':main()
