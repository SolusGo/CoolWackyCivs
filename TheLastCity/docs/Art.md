# Original Last City artwork — 2026-10-11

Fourteen original PNG sources were generated with the built-in imagegen tool following the [imagegen skill](C:/Users/ThatOneYi/.codex/skills/.system/imagegen/SKILL.md). Sources and the full final prompt set are retained in [art-source/TheLastCity](../../art-source/TheLastCity/Prompts.md). The refined beacon emblem supersedes its initial generation. The compiled [preview](../../art-source/TheLastCity/ArtPreview.png) shows the scene pair, emblem at multiple sizes, all ten object portraits and the five veteran tiers.

The earlier 1024×512 Dawn texture was wrong. The [Civ V Modder's Guide](https://kael.civfanatics.net/files/ModdersGuide.pdf) specifies 1024×768 for Dawn of Man. Static diplomacy uses 1600×900, as documented in the [2D leader-scene tutorial](https://forums.civfanatics.com/threads/g-k-how-to-replace-add-custom-2d-leader-scenes-for-your-diplo-screen.492696/). Conversion now fits the original composition to the destination aspect ratio rather than stretching it.

| Asset | Runtime size / layout | SQL reference |
|---|---|---|
| Last Light Dawn illustration | 1024×768, 4:3 | `Civilizations.DawnOfManImage` |
| Warden diplomacy scene | 1600×900, 16:9; imported static scene XML | `Leaders.ArtDefineTag` |
| Last Light selection map | 360×412 | `Civilizations.MapImage` |
| Civilization color emblem and alpha silhouette | 256/128/80/64/48/45/32/24/16, 1×1 | `LC_ICON_ATLAS`, `LC_ALPHA_ATLAS` |
| Warden circular portrait | 256/128/64, 1×1 | `LC_LEADER_ATLAS` |
| Last Watch flag | 32×32, 1×1 alpha | `LC_UNIT_FLAG_ATLAS` |
| Last Watch, Survival District, eight infrastructure portraits | 256/128/80/64/48/45/32/24/16 per cell, 4×3 | `LC_OBJECT_ATLAS`, slots 0–9 |
| Twenty-four promotions | Same cell sizes, 4×6 | `LC_PROMOTION_ATLAS`, slots 0–23 |

Each infrastructure building has separately generated imagery: guardhouse, residential refuge, underground shelter, infirmary, storehouse, logistics depot, waterworks and Dawn beacon. Promotion portraits derive from this original source art; veteran/training tiers have numbered badges. The Warden portrait derives from the same generated diplomacy scene, preserving identity.

`python tools/build_lastcity_art.py` packs the retained PNGs into 43 legacy DDS files plus `WardenLeaderScene.xml`. Block-aligned textures use DXT5; non-block-aligned textures use uncompressed RGBA. `03_LC_Art.sql` registers every custom atlas and replaces the former Washington/America/Spearman/Granary/promotion portrait references. All DDS files and the scene XML are VFS imports in both packages.

The Spearman's animated 3D unit mesh and ordinary city/building world models remain inherited. These generated images replace the 2D presentation; they do not create animated GR2 models. Actual rendering in Civ V has not been tested. Automated checks cover the exact dimensions, alpha, atlas slots, custom SQL references and package registration; DirectXTex decodes the compiled textures.
