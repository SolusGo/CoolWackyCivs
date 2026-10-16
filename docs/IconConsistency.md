# Civilization icon framing

Version 26 finishes the existing artwork for all eighteen civilizations. It
preserves atlas filenames, SQL cell sizes, portrait indices and cell layouts.
No gameplay SQL, Lua or player-colour mask is changed.

- Leader portraits have a visible diameter of 75% of the cell: 96px in a 128px
  slot, with 16px transparent padding on each side. The installed base-game
  `Assets/UI/FrontEnd/GameSetup/SelectCivilization.xml` uses a 128px portrait
  control inside a 100px row; `SelectCivilization.lua` requests the 128px atlas.
- Civilization, unit, building and other colour cells use a 90% diameter.
- Colour medallions share a bronze outer edge, warm gold rim and pale bevel.
- Alpha atlases and unit flags remain monochrome for the engine to tint.
  Promotion tier overlays retain their existing gold frames and badge shapes.
- Each DDS measures exactly `IconSize * IconsPerRow` by
  `IconSize * IconsPerColumn`. Block-aligned textures use legacy DXT5 without a
  DX10 header; non-aligned textures, including 45px slots, use legacy RGBA.

`tools/standardize_icons.py` reads the ModBuddy project and atlas SQL, identifies
leader cells even when they share an atlas with civilization emblems, and
retains the original largest atlas under `art-source/IconAtlasMasters/`.
These lossless PNG masters prevent cumulative cropping or resizing. The
builder runs this finishing step before calculating manifest hashes. It needs
Pillow and Microsoft DirectXTex `texconv` on PATH or in its WinGet directory.

```powershell
python tools/standardize_icons.py --check
python tools/build_mod.py
```

After deliberately regenerating an original atlas, refresh only its master;
for example, regenerate Rou'ls' original art, then run:

```powershell
python tools/standardize_icons.py --refresh-sources ROULS_ICON_ATLAS ROULS_LEADER_ATLAS
```

Do not refresh masters from already finished output. The check mode decodes
every registered DDS, checks dimensions and centring, and samples gold pixels
around each finished medallion. The main validator includes the same checks.
Previews verify the texture appearance; the civilization-selection screen
still needs a live game check, particularly when another mod replaces that UI.
