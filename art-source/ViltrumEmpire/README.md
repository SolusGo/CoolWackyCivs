# Viltrum art sources

- `Concept.png`: supplied 1672×941 sheet, preserved unchanged.
- `Thragg.png`: built-in imagegen scene. Black-haired Grand Regent Thragg replaces the sheet's gray-haired leader likeness, retaining its comic style, white uniform, crimson cape, alien citadel, banners, planet and fleet.
- `AtlasPreview.png`: deterministic atlas compilation preview, not shipped to the game.

The supplied white circular emblem panel supplies the actual civilization, city alpha and unit-flag identity. Compilation extracts its white pixels instead of drawing a replacement emblem. UA, Warrior, Complex, Virus, Momentum and Dominion use the supplied panels. Purge/Flight/Execution/Planetbreaker/survivor/Genome/Conditioning art shares these panels; each slot has an actual DDS texture.

`tools/make_viltrum_assets.py` only extracts panels, crops/resizes portraits and images, produces alpha masks and packs Civ V medallion atlases. DDS files use DXT5 at block-aligned dimensions and RGBA at 45-pixel sizes, following this repository's existing pipeline.

Built-in generation prompt:

> Create a single complete landscape leader diplomacy scene for Civilization V showing Grand Regent Thragg of the Viltrum Empire. Use the attached concept sheet as art reference only: detailed cinematic comic painting, crimson cape, white fitted uniform, grey waist band, dark moustache, imposing muscular mature Viltrumite regent. Correct Thragg to short black hair, no grey temples. He faces the viewer in a commanding pose in a grand alien citadel with red banners, gold sunset through tall windows, distant warships and a planet visible in the sky. One cohesive landscape scene, no panels, borders, words, captions, UI or typography. Keep the provided white circular Viltrum emblem on banners and clasp: copy that identity faithfully, never substitute another insignia. High quality art, wide composition with leader centered.

The built-in output was copied into this repository; the game references only packaged workspace DDS files.
