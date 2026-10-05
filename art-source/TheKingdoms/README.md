# Kingdoms art source

Generated with the built-in imagegen tool for this implementation. Original crimson/gold medieval fantasy; no named characters or heraldry from Game of Thrones were used. The supplied concept sheet established the direction. `IconSheet.png` is one 2×2 icon-atlas source; `Dawn.png` supplies the static citadel scene. `CrownSword.svg` is the editable geometric identity used by alpha/Guard flags.

Final assets are saved in `TheKingdoms/Art`. `python tools/prepare_kingdoms_art.py` packs and resizes the source into Civ V DDS textures. Sizes divisible by four use DXT5; other atlas sizes use legacy RGBA DDS. Every final texture is readable by Pillow and DirectXTex.

Icon atlas prompt (built-in tool):

> Civilization V game icon atlas, one single square sprite-sheet image. A 2 by 2 grid of four painted medieval fantasy medallions with transparent background. Same-size circular medallions, gold rims, broad padding. Top left: crimson heraldic shield with gold crowned lion and fleur-de-lis. Top right: blue, crimson and ivory noble shields united beneath a gold crown. Bottom left: crimson-cloaked armored knight with sword and lion shield. Bottom right: fortified stone gate with orange-red roofs and crimson/gold banner. Original regal art, readable at small sizes; no text, labels, sheet frame or watermark. Palette crimson, gold and stone.

Dawn/leader prompt (built-in tool):

> Panoramic 16:9 Civilization V Dawn of Man and generic throne diplomacy illustration. Kings Throne, an enormous stone fortress on an alpine spur, forested waterfall gorge, long fortified arched bridges, crenellated towers with crimson/orange-red roofs, gold crowned-lion banners, sunrise through atmospheric clouds. United noble Houses beneath one Crown. Original painted strategy-game realism, warm gold light and blue-grey mountains. Full bleed; no human leader protagonist, border, lettering, labels or watermark. Fortress central in upper third, bridge entering from the left foreground.
