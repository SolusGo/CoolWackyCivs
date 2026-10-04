# Validation record — 5 October 2026

## Passed automatically

- All eleven existing/new civilization suites through `tools/validate_all.py`: full manifest/project matching, ordered activation, no VFS filename collisions, Lua 5.1 syntax, XML controls and installed CP SQL activation.
- DirectXTex decoded all 300 collection DDS textures, including all 31 Viltrum DDS files. Viltrum's 28 atlas rows have the declared dimensions and transparent corners. Atlas/leader source images were inspected visually; actual in-game UI was not.
- Viltrum database assertions: 1300/82/3 Warrior, Replaceable Parts, no resources; ordinary Auxiliary Infantry inherits current Infantry stats, cost/tech/upgrade and model; Complex inherits Academy and adds the requested values; persistent survivor markers, native flight columns, growth/crisis dummy policies, localized entries and unique IDs.
- Lua engine doubles exercise military/civilian/barbarian kills, temporary target thresholds and cleanup, personal capture healing, first conquest and recapture, Momentum activation/extension/cap, movement garrisons, Complex sale/rebuild, Conditioning, training XP and postdrop attack reset.
- Great Purge strong and preservation choices, permanent XP, same-turn General progress deduplication, AI stress decision and Culture formula.
- Scourge research and first-Warrior trigger, no-Warrior deadline, warnings, quarantine/Crusade effects, population floors/Complex protection, quarantine capture suppression and consumed history.
- Both casualty choices at 0, 1, 2, 3, 5, 10 and 30 Bloodline units: fourteen scenarios verify rounded losses, all survivor floors, conventional/civilian safety and synchronized RNG use.
- Genuine survivor markers/HP, new-unit Genome exclusion from survivor powers, native voluntary peace locks/expiry/pre-existing scenario flags, Last Pureblood conditional strength and original-capital full healing, crisis shortening, both recoveries, Golden Age cancellation, both extinction choices, General/XP/rebel spawns and Gold costs.
- Reload during Momentum, warnings, crises and post-event state; duplicate-listener guard; upgrade promotion continuity; unit-ID reuse; zero-city, elimination and revival safety. Quick/Standard/Epic/Marathon fallback timing survives reload.
- Final archive integrity and installed-file hashes are checked when packaging/deploying.

These tests execute the production Lua against explicit engine doubles. They do **not** prove native movement/AI/UI integration, actual combat damage or actual saved-game serialization.

## Fixes made during implementation

- Used named Colors columns after activation found the cache's additional ID column.
- Added Concepts.Advisor after the CP database rejected missing required metadata.
- Marked temporary policies IsDummy to avoid normal policy progression side effects.
- Restricted kill healing to melee/ranged battle participants so air interception cannot heal an uninvolved land defender.
- Confirmed BattleJoined is emitted inside CvCombatInfo::setUnit before strength/damage calculation; target modifiers are applied at the correct point and cleaned after combat/reload.
- Replaced an initially conservative no-recall fallback after auditing the actual CP RecallTrader(true) binding.
- Used native temporary war/peace flags after source inspection showed legacy peace-event declarations do not establish reliable dispatch in this release. Flags created by the mod have persistent ownership and expiry; existing scenario flags are preserved.
- Granted native Blitz directly to actual Crusade survivors instead of duplicating its active-ruleset effects in another promotion.
- Counted the Purge choice turn as the first General-progress tick, preventing a 19-of-20-turn off-by-one; a full twenty-turn fixture verifies the total.
- Added the civilization/leader Civilopedia section keys and combat concept headers; a pending popup now dequeues immediately after player elimination.
- Updated both collection packaging validators to recognize the new UI XML as a non-VFS add-in, retaining SQL/UI import requirements.

## Engine/IGE checklist — not run

The specification's 50 tests are the playtest acceptance checklist. None has been marked as an actual in-game pass in this delivery. In particular:

1. Start a new game as Viltrum; inspect setup portrait, leader scene, Dawn of Man, map, pedia, flags, popup layout and tooltips.
2. Use IGE for combat kills, <50 HP Execution, below-half-health Planetbreaker, 35 HP city capture and Last Pureblood capital full heal. Check combat preview and actual damage.
3. Traverse rough terrain, mountains and coasts; deploy exactly seven tiles from eligible territory, attack afterwards and test March. Inspect visual model compatibility.
4. Capture/lose/recapture/raze/refound/liberate cities; sell/rebuild Complexes; check exact Production, resistance, garrison strength and Happiness in the native UI.
5. Play both Purge choices, both Scourge choices and both extinction choices. Inspect actual growth, production, healing approximations, Settler/purchase gates, route recall, spies and peace negotiations.
6. Save and reload at every phase and pending choice. Verify survivor promotions survive real upgrades, IDs and serialization; verify no rewards repeat or crisis timers reset.
7. Play against AI Thragg with other civs; observe army composition, decisions, survivor preservation, Gold and long-term balance. Exercise capital loss, elimination/revival and externally forced peace.
8. Inspect Lua.log and Database.log with DEBUG enabled for Viltrum. Gameplay has no frame polling. Multiplayer remains unsupported.

## CP source audit

Installed Community Patch database changes and local 5.4.2/5.4.6 source references were inspected. Additional primary source checks used release 5.4.2:

- [CvCombatInfo participant dispatch](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvGameCoreStructs.cpp)
- [Combat calculation and resolution](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvUnitCombat.cpp)
- [Player Lua bindings](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/Lua/CvLuaPlayer.cpp)
- [Team flags and voluntary peace rules](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvTeam.cpp)
