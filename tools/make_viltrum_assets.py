"""Compile supplied concept panels and regenerated Thragg scene to Civ V DDS.

This is deterministic asset extraction/atlas compilation, not illustration editing.
The supplied emblem pixels are the source of all civilization/flag masks.
"""
from pathlib import Path
import sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from PIL import Image,ImageOps
from make_psj_assets import circular
S=R/'art-source/ViltrumEmpire';O=R/'ViltrumEmpire/Art'
def dds(im,n):
 im=im.convert('RGBA')
 im.save(O/n,**({'pixel_format':'DXT5'} if im.width%4==0 and im.height%4==0 else {}))
def main():
 O.mkdir(parents=True,exist_ok=True)
 im=Image.open(S/'Concept.png').convert('RGB');leader=Image.open(S/'Thragg.png')
 # Supplied image is 1672 x 941. Exclude sheet labels and frames.
 emblem=im.crop((55,480,322,734))
 # Luminance selects the exact white symbol; this removes only the black backing.
 alpha=emblem.convert('L').point(lambda v:255 if v>180 else 0)
 symbol=Image.new('RGBA',emblem.size,'white');symbol.putalpha(alpha)
 civ=Image.new('RGBA',emblem.size,(100,5,14,255));civ.alpha_composite(symbol)
 portrait=leader.crop((640,45,960,365))
 warrior=im.crop((799,477,1177,735));complex=im.crop((1195,476,1660,735))
 conquest=im.crop((383,476,786,735));virus=im.crop((598,779,906,917))
 momentum=im.crop((1200,779,1425,900));dominion=im.crop((1448,780,1634,900))
 # Existing art panels are shared for related promotions; every slot has real art.
 objects=[warrior,complex,conquest,virus,momentum,dominion,portrait,warrior]
 # Reuse the repo's circular packing style, but save in this civ's directory.
 for size in (256,128,80,64,48,45,32,24,16):
  atlas=Image.new('RGBA',(size*2,size))
  for i,src in enumerate([civ,portrait]):atlas.alpha_composite(circular(src,size),(size*i,0))
  dds(atlas,f'ViltrumIcon{size}.dds')
  dds(ImageOps.contain(symbol,(size,size),Image.Resampling.LANCZOS).resize((size,size),Image.Resampling.LANCZOS),f'ViltrumAlpha{size}.dds')
  atlas=Image.new('RGBA',(size*4,size*2))
  for i,src in enumerate(objects):atlas.alpha_composite(circular(src,size),((i%4)*size,(i//4)*size))
  dds(atlas,f'ViltrumObjects{size}.dds')
 dds(ImageOps.fit(symbol,(32,32),Image.Resampling.LANCZOS),'ViltrumUnitFlag32.dds')
 dds(ImageOps.fit(leader,(1600,900),Image.Resampling.LANCZOS),'ViltrumLeader.dds')
 dds(ImageOps.fit(leader,(1024,768),Image.Resampling.LANCZOS),'ViltrumDawn.dds')
 dds(ImageOps.fit(im.crop((997,53,1665,430)),(360,412),Image.Resampling.LANCZOS),'ViltrumMap.dds')
 (O/'ViltrumLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="ViltrumLeader.dds" />\n')
 preview=Image.new('RGBA',(1024,512))
 for i,src in enumerate(objects):preview.alpha_composite(circular(src,256),((i%4)*256,(i//4)*256))
 preview.save(S/'AtlasPreview.png')
 print('Compiled 31 DDS textures, leader scene and atlas preview')
if __name__=='__main__':main()
