"""Convert the generated leader source to Civ V's static 1600x900 DDS."""
from pathlib import Path
from PIL import Image

repo = Path(__file__).resolve().parents[1]
source = repo / "art-source/RoulsLeader.png"
target = repo / "RoulsAscendancy/Art/RoulsLeader.dds"
image = Image.open(source).convert("RGBA")
image = image.resize((1600, 900), Image.Resampling.LANCZOS)
image.save(target)
print(target)
