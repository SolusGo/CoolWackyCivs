# The Terra Framework

GPT-5.6 Terra leads a Civilization V: Brave New World + Community Patch v151 civilization included in the Cool Wacky Civs collection. Open `CoolWackyCivs.civ5sln` at the repository root in ModBuddy.

## Gameplay

- Adaptive Intelligence: Production-completed buildings activate a city Mode for 10 turns. Research gives +10% Science; Commerce +10% Gold; Creative +8% Culture and Faith; Execution +10% Production. A qualifying completion replaces or refreshes the existing Mode. Modes never stack.
- Multimodal Hub: inherits the current Market, adds +1 Science and +1 Culture, and grants its origin city +1 Production per outgoing domestic or international trade route.
- Adaptive Operative: inherits the current Musketman. At the beginning of a Terra turn it selects Recovery in its team's territory (+10 friendly healing), otherwise +15% Rough or Open attack/defense according to native terrain classification. Moving does not reconfigure it. Embarkation clears configurations; upgrading removes the unique system.

Only the 34 BuildingClasses explicitly listed in `SQL/00_Terra_Core.sql` trigger Modes. Purchases, free buildings, neutral infrastructure and world/team/national wonders do not. Normal notifications announce activation; there is no replacement city-screen or diplomacy overlay.

## Implementation

Core unit/building rows and BNW/CP companion tables are cloned at activation. The Hub retains Market specialist slots, maintenance, costs, prerequisites and yield effects; the Operative retains Musketman resources, movement, costs, promotions and upgrades. Starting units/technologies mirror the standard civilization package without adding an escort.

Modes persist through `Modding.OpenSaveData`, keyed by city plot and checked against owner, original owner and founding turn. Capture/founding explicitly invalidate old modes. Expiry runs on the Terra player's turn at `Game.GetGameTurn() >= completionTurn + 10`. Loading restores mode buildings without reconfiguring units or restarting timers.

Trade Production is an idempotent snapshot of `Player:GetTradeRoutes()` into a hidden dummy building. It refreshes on initialization, player turns, completion/pillage hooks, trade-unit movement/removal, Hub construction and capture. CP's route events can precede final removal; the following gameplay snapshot (at latest the turn boundary) reconciles the count. No yields depend on UI callbacks. The native passing-route table is deliberately not used: it would incorrectly reward destination/through cities.

Terra is AI-playable with the specified balanced flavors. Multiplayer/hotseat are disabled until a real synchronization test passes. This mod cannot retrofit Terra into an existing campaign: enable it before starting a new game.

## Art and scope

Custom leader/loading scene, setup portrait, civilization emblem, Operative and Hub icons are included, with separately sized 16–256px legacy RGBA DDS atlases. The 45px textures are uncompressed. The strategic-view monochrome globe is code-native. In-world unit animations use the stock Musketman; music uses the inherited stock soundtrack. No custom music recordings or animated 3D leader are supplied.

Imagegen produced the four source artworks in `art-source/Terra*.png`; prompts and provenance are in `art-source/Terra-Prompts.md`. Atlas compilation is reproducible with `python tools/make_terra_assets.py`. The original design is preserved in `SPECIFICATION.md`.

## Build and test

From the repository root:

```powershell
python tools/build_mod.py
python tools/validate_terra_mod.py
```

The builder reads the combined ModBuddy project and creates one collection folder, ZIP and native LZMA `.civ5mod` under `dist/`. Validation uses a read-only gameplay cache cloned into memory, with installed CP schema updates, plus Lua 5.1 behavior tests. It does not edit game saves, the live database, or installed mods.

Covered checks: exact scalar inheritance, resource/upgrade preservation, the 34-class mapping, localized keys, correct atlas sizes/hashes, mode refresh/switch/expiry, two independent cities, purchased/free/neutral/wonder exclusions, save-state reconstruction, capture/founding identity, 0/1/3 outgoing routes, teammate territory, rough/open selection, movement lock, embarkation and upgrade cleanup.

Still requires an in-game smoke test: choose Terra, check setup/Civilopedia/research-tree icons, construct each category, buy a mapped building, establish and pillage routes, save/reload midway through a Mode, and verify combat previews. Automated tests are not a claim of in-game validation.
