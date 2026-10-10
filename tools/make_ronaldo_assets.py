"""Compile original CR7 artwork and code-drawn emblems into Civ V DDS atlases."""
from pathlib import Path
import math
import sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from PIL import Image,ImageDraw,ImageFont,ImageOps
S=R/'art-source/CristianoRonaldo';O=R/'CristianoRonaldo/Art'
RED=(123,6,20,255);GOLD=(240,189,61,255);GREEN=(25,112,68,255);WHITE=(249,246,232,255)
SIZES=(256,128,80,64,48,45,32,24,16)

def font(n):return ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',n)
def label(draw,string,y,n,color=GOLD):
    draw.text((512,y),string,font=font(n),fill=color,anchor='mm')
def emblem(alpha=False):
    im=Image.new('RGBA',(1024,1024));d=ImageDraw.Draw(im)
    if alpha:
        label(d,'7',510,680,WHITE)
        d.line([(315,816),(512,712),(710,816)],fill=WHITE,width=46)
        return im
    d.ellipse((34,34,990,990),fill=RED,outline=GREEN,width=32)
    for i in range(7):
        a=-math.pi/2+i*2*math.pi/7
        d.line([(512+math.cos(a)*340,512+math.sin(a)*340),(512+math.cos(a)*425,512+math.sin(a)*425)],fill=(178,80,40,255),width=19)
    label(d,'7',488,680)
    d.line([(320,828),(512,730),(704,828)],fill=WHITE,width=43)
    return im

def symbol(index):
    im=Image.new('RGBA',(1024,1024));d=ImageDraw.Draw(im)
    d.ellipse((40,40,984,984),fill=RED,outline=GOLD,width=32)
    if index==0: # horse head: standard Cavalry world model, custom portrait/flag
        d.polygon([(340,760),(385,492),(350,325),(448,213),(496,337),(600,291),(754,500),(681,579),(569,484),(529,760)],fill=GOLD)
        d.ellipse((567,360,600,393),fill=RED)
    elif index==1:
        d.polygon([(210,374),(512,210),(814,374)],fill=GOLD)
        for x in (280,450,620):d.rectangle((x,420,x+92,740),fill=WHITE)
        d.rectangle((210,770,814,820),fill=GOLD)
    elif index in (2,3,22):
        d.line([(258,726),(482,475),(603,590),(774,325)],fill=WHITE,width=57)
        d.polygon([(654,302),(810,284),(788,462)],fill=GOLD)
        if index==22:label(d,'7',760,160)
    elif index in (4,5):
        d.polygon([(250,275),(450,275),(468,579),(778,678),(758,780),(235,750)],fill=GOLD)
        d.ellipse((640,200,830,390),fill=WHITE,outline=GREEN,width=20)
        if index==5:d.line((280,560,400,630,650,400),fill=WHITE,width=35)
    elif 6<=index<=9:
        d.arc((180,180,844,844),30,330,fill=WHITE,width=40)
        label(d,['I','II','III','IV'][index-6],510,300)
    elif index==10:
        d.polygon([(546,180),(298,550),(480,550),(412,844),(740,417),(559,417)],fill=GOLD)
    elif index==11:
        for x,h in [(285,220),(447,390),(609,550)]:d.rectangle((x,800-h,x+125,800),fill=GOLD)
    elif index==12:
        d.polygon([(256,264),(512,185),(768,264),(704,667),(512,845),(320,667)],fill=GREEN,outline=GOLD,width=22)
        label(d,'7',482,330,WHITE)
    elif index==13:
        d.line((262,512,427,699,768,327),fill=GOLD,width=76)
    elif index==14:
        d.ellipse((200,330,824,690),outline=GOLD,width=50)
        d.ellipse((402,400,622,620),fill=WHITE)
    elif 15<=index<=21:
        n=index-14
        label(d,['I','II','III','IV','V','VI','VII'][n-1],490,250)
        for i in range(n):
            x=512+(i-(n-1)/2)*68
            d.ellipse((x-18,745,x+18,781),fill=WHITE)
        d.arc((155,155,869,869),190,350,fill=GREEN,width=35)
    else:d.arc((200,200,824,824),0,330,fill=GOLD,width=65)
    return im

def dds(im,path):
    im=im.convert('RGBA')
    im.save(path,**({'pixel_format':'DXT5'} if im.width%4==0 and im.height%4==0 else {}))
def main():
    O.mkdir(parents=True,exist_ok=True)
    original=Image.open(S/'RelentlessJourney.png').convert('RGBA')
    # Cropping/resizing and DDS compilation of the original generated artwork.
    hero=ImageOps.fit(original,(1600,900),Image.Resampling.LANCZOS)
    dds(hero,O/'CR7Leader.dds');dds(hero,O/'CR7Dawn.dds')
    portrait=original.crop((530,10,1150,630))
    for n in (256,128,64):dds(portrait.resize((n,n),Image.Resampling.LANCZOS),O/f'CR7Leader{n}.dds')
    for n in SIZES:
        for name,im in [('Icon',emblem()),('Alpha',emblem(True))]:
            dds(im.resize((n,n),Image.Resampling.LANCZOS),O/f'CR7{name}{n}.dds')
        atlas=Image.new('RGBA',(6*n,4*n))
        for i in range(24):atlas.alpha_composite(symbol(i).resize((n,n),Image.Resampling.LANCZOS),((i%6)*n,(i//6)*n))
        dds(atlas,O/f'CR7Objects{n}.dds')
    dds(emblem(True).resize((32,32),Image.Resampling.LANCZOS),O/'CR7Flag32.dds')
    # Original decorative route map; geography is deliberately illustrative.
    mapim=Image.new('RGBA',(720,824),(24,42,48,255));d=ImageDraw.Draw(mapim)
    d.polygon([(320,115),(440,72),(600,156),(605,442),(455,507),(349,342)],fill=(100,100,73,255))
    d.polygon([(272,437),(503,432),(576,737),(327,778),(209,580)],fill=(86,95,69,255))
    points=[(158,486),(331,320),(360,158),(394,349),(331,320),(462,292),(612,585)]
    d.line(points,fill=GOLD,width=5)
    for (x,y),name in zip(points,['Madeira','Lisbon','Manchester','Madrid','Portugal','Turin','Riyadh']):
        d.ellipse((x-8,y-8,x+8,y+8),fill=WHITE)
        d.text((x+12,y+12),name,font=font(23),fill=WHITE)
    d.text((48,44),'THE RELENTLESS SEVEN',font=font(34),fill=GOLD)
    dds(mapim.resize((360,412),Image.Resampling.LANCZOS),O/'CR7Map.dds')
    (O/'CR7LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="CR7Leader.dds" />\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGBA',(1200,1040),(28,19,19,255))
    preview.alpha_composite(hero.resize((1200,675)))
    for i in range(24):preview.alpha_composite(symbol(i).resize((120,120)),((i%8)*150,(i//8)*120+675))
    preview.convert('RGB').save(S/'ArtPreview.png')
    print('Built CR7 original leader, dawn, route map, 24 icon slots, flag and all DDS atlases')
if __name__=='__main__':main()
