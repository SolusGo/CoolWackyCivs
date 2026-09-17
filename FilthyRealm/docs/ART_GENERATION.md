# Filthy Realm art generation

The user-supplied concept sheet is stored at `art-source/FilthyRealm/FilthyConcept.png`. It directly supplies the civilization face mark, leader portrait, Peace Lord, and Filthy Kitchen subjects.

OpenAI's built-in ImageGen tool produced three dedicated sources where the poster panel was too small or the wrong aspect ratio:

- `FilthyLeader.png`: standalone 16:9 bedroom diplomacy scene.
- `FilthyDawn.png`: standalone 16:9 Dawn of Man scene over the Rice Fields.
- `FilthyMap.png`: portrait realm overview for the 360x412 setup image.
- `SalamanderMan.png`: dedicated square unit portrait based on the user-supplied Salamander Man photo. It preserves the recognizable human face, neon-green creature hood, white clothing, recorder, crouched pose, and mischievous expression while translating the photograph into Civ V's realistic-painterly visual language.

The production prompts preserved the supplied warm sepia/painterly language, hot-pink accents, face-symbol banners, mountain rice fields, and the leader's concept-sheet appearance. They prohibited text, UI frames, watermarks, cropped heads, duplicate leaders, and malformed hands. The leader prompt reserved dark negative space on the right for Civ V diplomacy UI.

The revised Salamander Man prompt treated the supplied photograph as the definitive identity, costume, instrument, pose, and expression reference. It requested a centered square upper-body game portrait with safe crop margins, a subdued warm interior, and the original neon-green hood, white clothing, and dark-brown recorder. It explicitly prohibited turning him into an actual reptile or fantasy warrior, as well as weapons, armor, text, logos, and UI framing.

Run:

```powershell
python tools/make_filthy_assets.py
```

The script crops and reframes the concept art, builds two-slot civilization/leader atlases, creates a monochrome face flag, composes a nine-slot object atlas, and converts the large images to exact Civ V dimensions. Pillow writes legacy DXT5 DDS for block-aligned textures and uncompressed DDS for 45px rows. `art-source/FilthyRealm/FilthyArtPreview.png` is the human-reviewable contact sheet and is not shipped.
