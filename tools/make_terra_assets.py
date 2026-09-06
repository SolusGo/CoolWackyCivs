"""Compile source art into padded Civ V DDS atlases; no generated images are redrawn.

Pillow 12 required. Uncompressed RGBA preserves 45px icons on DX9/DX11.
The tiny monochrome strategic-view emblem is a code-native modular globe.
"""
from pathlib import Path
import sys
REPO=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(REPO/'.tools/python'))
from PIL import Image, ImageDraw, ImageOps
SRC=REPO/'art-source'
OUT=REPO/'TerraFramework/Art'
OUT.mkdir(parents=True,exist_ok=True)
sizes=(256,128,80,64,48,45,32,24,16)
leader=Image.open(SRC/'TerraLeader.png').convert('RGBA')
ImageOps.fit(leader,(1600,900),method=Image.Resampling.LANCZOS).save(OUT/'TerraLeader.dds')
# Setup uses a portrait frame; DOM uses the wide scene independently.
ImageOps.fit(leader,(360,412),method=Image.Resampling.LANCZOS,centering=(0.5,0.4)).save(OUT/'TerraMap.dds')
for name in ('Icon','Operative','Hub','Leader'):
    source=Image.open(SRC/('Terra'+name+'.png')).convert('RGBA')
    if name=='Leader':
        w,h=source.size
        source=source.crop((w*.34,h*.02,w*.66,h*.59))
    for size in sizes:
        inner=round(size*.88)
        pic=ImageOps.fit(source,(inner,inner),method=Image.Resampling.LANCZOS)
        mask=Image.new('L',(inner*4,inner*4),0)
        ImageDraw.Draw(mask).ellipse((0,0,inner*4-1,inner*4-1),fill=255)
        pic.putalpha(mask.resize((inner,inner),Image.Resampling.LANCZOS))
        canvas=Image.new('RGBA',(size,size))
        canvas.alpha_composite(pic,((size-inner)//2,(size-inner)//2))
        canvas.save(OUT/f'Terra{name}{size}.dds')
for size in sizes:
    scale=4
    mark=Image.new('RGBA',(size*scale,size*scale))
    d=ImageDraw.Draw(mark); a=size*scale
    bounds=(a*.16,a*.16,a*.84,a*.84)
    d.ellipse(bounds,outline='white',width=max(2,round(a*.045)))
    d.ellipse((a*.32,a*.16,a*.68,a*.84),outline='white',width=max(2,round(a*.025)))
    d.line((a*.16,a*.5,a*.84,a*.5),fill='white',width=max(2,round(a*.025)))
    d.ellipse((a*.43,a*.43,a*.57,a*.57),fill='white')
    mark.resize((size,size),Image.Resampling.LANCZOS).save(OUT/f'TerraAlpha{size}.dds')
print('Built Terra leader, setup image and 45 atlas textures')
