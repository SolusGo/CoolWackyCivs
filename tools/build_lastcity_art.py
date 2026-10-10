"""Compile the original illustration into the game's DDS; no API calls."""
from pathlib import Path
import sys
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'.tools/python'))
from PIL import Image
if __name__=='__main__':
    art=R/'TheLastCity/Art'
    with Image.open(art/'LastLight.png') as im:
        im.resize((1024,512),Image.Resampling.LANCZOS).convert('RGBA').save(art/'LastLight.dds',pixel_format='DXT5')
    print(art/'LastLight.dds')
