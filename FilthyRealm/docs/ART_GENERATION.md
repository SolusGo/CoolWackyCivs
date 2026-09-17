# Filthy Realm art generation

The user-supplied concept sheet is stored at `art-source/FilthyRealm/FilthyConcept.png`. It directly supplies the civilization face mark, leader portrait, Peace Lord, and Filthy Kitchen subjects.

OpenAI's built-in ImageGen tool produced three dedicated sources where the poster panel was too small or the wrong aspect ratio:

- `FilthyLeader.png`: standalone 16:9 bedroom diplomacy scene.
- `FilthyDawn.png`: standalone 16:9 Dawn of Man scene over the Rice Fields.
- `FilthyMap.png`: portrait realm overview for the 360x412 setup image.
- `SalamanderMan.png`: dedicated square unit portrait because the concept sheet did not include this unit.

The production prompts preserved the supplied warm sepia/painterly language, hot-pink accents, face-symbol banners, mountain rice fields, and the leader's concept-sheet appearance. They prohibited text, UI frames, watermarks, cropped heads, duplicate leaders, and malformed hands. The leader prompt reserved dark negative space on the right for Civ V diplomacy UI.

Run:

```powershell
python tools/make_filthy_assets.py
```

The script crops and reframes the concept art, builds two-slot civilization/leader atlases, creates a monochrome face flag, composes a nine-slot object atlas, and converts the large images to exact Civ V dimensions. Pillow writes legacy DXT5 DDS for block-aligned textures and uncompressed DDS for 45px rows. `art-source/FilthyRealm/FilthyArtPreview.png` is the human-reviewable contact sheet and is not shipped.
