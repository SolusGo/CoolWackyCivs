# File inventory

## New files

- `ViltrumEmpire/Art/ViltrumAlpha128.dds`
- `ViltrumEmpire/Art/ViltrumAlpha16.dds`
- `ViltrumEmpire/Art/ViltrumAlpha24.dds`
- `ViltrumEmpire/Art/ViltrumAlpha256.dds`
- `ViltrumEmpire/Art/ViltrumAlpha32.dds`
- `ViltrumEmpire/Art/ViltrumAlpha45.dds`
- `ViltrumEmpire/Art/ViltrumAlpha48.dds`
- `ViltrumEmpire/Art/ViltrumAlpha64.dds`
- `ViltrumEmpire/Art/ViltrumAlpha80.dds`
- `ViltrumEmpire/Art/ViltrumDawn.dds`
- `ViltrumEmpire/Art/ViltrumIcon128.dds`
- `ViltrumEmpire/Art/ViltrumIcon16.dds`
- `ViltrumEmpire/Art/ViltrumIcon24.dds`
- `ViltrumEmpire/Art/ViltrumIcon256.dds`
- `ViltrumEmpire/Art/ViltrumIcon32.dds`
- `ViltrumEmpire/Art/ViltrumIcon45.dds`
- `ViltrumEmpire/Art/ViltrumIcon48.dds`
- `ViltrumEmpire/Art/ViltrumIcon64.dds`
- `ViltrumEmpire/Art/ViltrumIcon80.dds`
- `ViltrumEmpire/Art/ViltrumLeader.dds`
- `ViltrumEmpire/Art/ViltrumLeaderScene.xml`
- `ViltrumEmpire/Art/ViltrumMap.dds`
- `ViltrumEmpire/Art/ViltrumObjects128.dds`
- `ViltrumEmpire/Art/ViltrumObjects16.dds`
- `ViltrumEmpire/Art/ViltrumObjects24.dds`
- `ViltrumEmpire/Art/ViltrumObjects256.dds`
- `ViltrumEmpire/Art/ViltrumObjects32.dds`
- `ViltrumEmpire/Art/ViltrumObjects45.dds`
- `ViltrumEmpire/Art/ViltrumObjects48.dds`
- `ViltrumEmpire/Art/ViltrumObjects64.dds`
- `ViltrumEmpire/Art/ViltrumObjects80.dds`
- `ViltrumEmpire/Art/ViltrumUnitFlag32.dds`
- `ViltrumEmpire/Lua/ViltrumRuntime.lua`
- `ViltrumEmpire/README.md`
- `ViltrumEmpire/SQL/00_Viltrum_Core.sql`
- `ViltrumEmpire/SQL/01_Viltrum_Inheritance.sql`
- `ViltrumEmpire/SQL/02_Viltrum_Effects.sql`
- `ViltrumEmpire/SQL/10_Viltrum_Text.sql`
- `ViltrumEmpire/UI/ViltrumPanel.lua`
- `ViltrumEmpire/UI/ViltrumPanel.xml`
- `ViltrumEmpire/docs/Files.md`
- `ViltrumEmpire/docs/OriginalDesign.md`
- `ViltrumEmpire/docs/Validation.md`
- `art-source/ViltrumEmpire/AtlasPreview.png`
- `art-source/ViltrumEmpire/Concept.png`
- `art-source/ViltrumEmpire/README.md`
- `art-source/ViltrumEmpire/Thragg.png`
- `tools/create_viltrum.py`
- `tools/make_viltrum_assets.py`
- `tools/tests/viltrum_assertions.lua`
- `tools/tests/viltrum_mock.lua`
- `tools/validate_viltrum_mod.py`

## Collection changes

- `CoolWackyCivs.civ5proj`
- `Cool Wacky Civs (v 14).modinfo (replaces v 13 manifest)`
- `README.md`
- `PATCHNOTES.md`
- `tools/validate_all.py`
- `tools/validate_mod.py`
- `tools/validate_capano_mod.py`

## Responsibilities

The four SQL files declare the civilization, active-ruleset inheritance, effects and English localization. The runtime owns every game mechanic and persisted timer/record. The UI only renders state and submits validated choices. Art is entirely packaged DDS plus the leader scene XML. Source art and its prompt stay outside the game package. Tests use the installed CP schema and explicit Lua 5.1 engine doubles. Collection changes add one civ, register files/actions, bump the package version and extend packaging validation; existing civilization gameplay files are unchanged.
