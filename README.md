# The Rou'ls Ascendancy

The Rou'ls Ascendancy is a Civilization V: Brave New World civilization for the Community Patch. Trent Rou'ls, the Unbodied, leads a society that treats flesh as a temporary vessel and consciousness as the lasting identity.

The Rou'ls are designed for long wars. They begin without an economic shortcut or an early unique unit, then become harder to dislodge as enemy casualties build an Anima reserve. Anima preserves experienced units, enables strategic redeployment, and eventually lets the Rou'ls replace an enemy vessel with one of their own.

## Requirements and compatibility

- Civilization V with Brave New World installed.
- Community Patch version 151, release 5.4.2, or newer.
- A new game is recommended after changing the enabled mod set. Civ V caches database rows and does not reliably retrofit civilization definitions into an old save.
- Single-player only. Multiplayer and hotseat are disabled because the active ability panel and save-backed transactions have not been network synchronized.

The mod depends on the Community Patch for `UnitPrekill`, battle attribution, unit conversion hooks, expanded Lua unit methods, and database event switches. It does not require Vox Populi.

## Install the finished package

From the repository root, run `python tools/build_mod.py`. The command creates three equivalent outputs under `dist/`:

- `The Rouls Ascendancy (v 1)` — an unpacked mod directory for quick iteration;
- `The Rouls Ascendancy (v 1).zip` — a portable archive; and
- `The Rouls Ascendancy (v 1).civ5mod` — a Civ V-compatible LZMA package.

Copy the `.civ5mod` file into Civilization V's `MODS` directory, or copy the unpacked directory there. Enable `(1) Community Patch` first, then `The Rou'ls Ascendancy`, and start a new single-player game.

The package can be inspected before installation. The checked-in manifest is [The Rouls Ascendancy (v 1).modinfo](RoulsAscendancy/The%20Rouls%20Ascendancy%20(v%201).modinfo), and the ModBuddy project is [RoulsAscendancy.civ5sln](RoulsAscendancy.civ5sln).

## How to play the Rou'ls

The Rou'ls have no preferred religion, start bias, free settler, free resource, or bonus technology. Their normal start is the BNW Agriculture technology; see the design interpretation below for why the brief's Mining line is not applied as an extra technology.

In the Ancient and Classical eras, expand and build a normal defensive army. Do not expect the civilization to win through an opening yield bonus. Once wars begin, take favourable fights and protect experienced units. Enemy military deaths are the primary source of Anima, so a peaceful opening produces very little reserve.

The Renaissance unlocks the Hollowhound, a Rifleman replacement. The Industrial era brings the Somatic Lattice, which creates a sustainable reserve and makes veteran losses less final. The Choir Eternal raises the reserve ceiling and adds experience to new units. In the Modern Era, seven stored Anima enables THE GREAT MIGRATION, the strongest one-time offensive tool.

### Anima

Anima is displayed in the top-panel button as `Anima: current / maximum`.

- A Rou'ls military unit that destroys an enemy military unit gains 1 Anima.
- The normal reserve is capped at 5.
- The Choir Eternal raises the cap to 7.
- Anima gained from kills is attributed to the actual military attacker. City bombardment and administrative unit removal do not create a kill reward.
- Anima is shared by reconstruction, TRANSMIGRATION, Buddy's return, and THE GREAT MIGRATION. Spending it on mobility can leave too little for casualties.

### Nothing Is Lost

When a Rou'ls non-civilian land unit dies, the game records its consciousness and tries to return it after combat resolves. A successful return costs 1 Anima, restores it in the nearest legal friendly city, and gives it 50% health, the same level, experience, name, and valid promotions. A player can receive at most two reconstructions per turn.

Settlers, Workers, Great People, religious units, civilians, naval units, aircraft, and units already reconstructed during that turn are excluded. If there is no legal, unoccupied friendly city tile, the unit remains dead and no Anima is spent. The code never creates a Civ V unit at `(-1,-1)`, which can crash the DLL.

### Hollowhound: Second Skin

The Hollowhound replaces the Rifleman and costs 10% more while retaining Rifleman combat strength and two movement. It receives:

- Second Skin: the first eligible death every 15 turns is reconstructed for 0 Anima;
- Choir of Bodies: +3% combat strength per adjacent friendly Rou'ls military unit, up to +15%.

Second Skin's timer belongs to the consciousness. It follows a reconstructed unit through upgrades and saves. Choir of Bodies is recalculated from the unit's current neighbours and disappears when the Hollowhound upgrades.

### TRANSMIGRATION

Open the top-panel Rou'ls button and choose two eligible units. The base cost is 2 Anima and the action is available once every 8 turns. A Matriarch of the Choir within two tiles of either endpoint reduces the cost to 1.

The units must belong to the Rou'ls, use the same land or naval domain, be unembarked, outside enemy territory, out of combat, unloaded, and on different legal tiles. Aircraft, Fighters, missiles, nuclear weapons, and enemy-occupied tiles are rejected. Both units keep their unit IDs, XP, names, promotions, and other mod data while exchanging positions. Their movement and attack counters are exhausted until the next owner turn.

The selection is checked again when Confirm is pressed. If a movement hook or another mod interrupts the exchange, the code attempts to restore both units and does not spend Anima.

### Great Migration

THE GREAT MIGRATION is available once after entering the Modern Era when the player has 7 Anima. It consumes all 7 and targets a visible enemy military unit within three tiles of one of your military units.

The target cannot be a Great Person, civilian, aircraft, nuclear weapon, missile, loaded carrier, embarked unit, limited one-per-player/team/world class, or unit without a legal Rou'ls equivalent. The replacement is created on a safe owned staging tile, checked against the DLL's movement rules, then moved onto the victim's tile. It has 75% health, half the victim's XP capped at 60, and cannot move or attack until the next turn. If target removal or placement is vetoed, the transaction rolls back without spending Anima.

### Buildings and support units

| Rou'ls element | Replaces or unlocks | Effect |
| --- | --- | --- |
| Somatic Lattice | Hospital | Keeps Hospital food retention and prerequisites; adds +2 Science, +2 Production, and a 25% chance for 1 Anima when a normally produced military unit completes in the city. If the empire has zero Anima, one Lattice provides a 1 Anima fallback every 10 turns. |
| Matriarch of the Choir | Great General | Keeps Great General movement, citadel, and command effects; reduces TRANSMIGRATION cost near her. |
| The Choir Eternal | Heroic Epic | Keeps Heroic Epic effects and Barracks-everywhere requirement; adds +5 XP to units trained there, raises Anima maximum to 7, and has a 20% per-turn chance to gain 1 Anima when an enemy dies within three tiles. |
| Buddy, Everlasting | Unique Biology-era naval melee unit | Strength 45, movement 5, sight 3, production cost 350, no purchase, one per player. Friendly units within two tiles gain +10% strength and 5 extra healing in friendly territory; adjacent enemy naval units suffer -10% strength. With 3 Anima, Buddy returns to the Capital after three turns at 50% health. |

Buddy's pending return counts against his one-per-player limit. The code tries a legal Capital berth first, then a friendly coastal city and owned water beside it. If every berth is blocked, the consciousness waits and retries each turn without being lost.

## Interface and AI

The top-panel Anima counter is also the command button. The panel has separate TRANSMIGRATION and GREAT MIGRATION tabs, lists only eligible units, displays the exact current cost and failure reason, and revalidates all choices before activation. Escape and Close dismiss the panel without changing state.

The AI uses the same legality checks as the human panel. It prefers high-value Great Migration targets, then considers exchanges that pull damaged veterans away from threatened fronts or bring experienced reserves toward danger. AI resurrection choices are ordered by level, siege role, ranged role, Hollowhound status, and production cost.

## Build and validation

Install the development dependencies into the repository-local `.tools/python` directory:

```powershell
python -m pip install --target .tools/python -r requirements-dev.txt
```

Run the complete local checks:

```powershell
python tools/validate_mod.py
python tools/test_actions.py
python tools/build_mod.py
```

`validate_mod.py` verifies project content, VFS flags, ordered database actions, dependencies, manifest hashes, XML control references, DDS headers, Lua 5.1 syntax, and SQL against a disposable clone of a real BNW cache augmented with the installed Community Patch schema. `test_actions.py` runs swap and Great Migration transactions in a Lua 5.1 Civ API mock, including stale selections, cooldowns, Matriarch discounts, rollback-sensitive placement, XP/health, and cargo rejection.

ModBuddy's native package target can be run directly with the SDK's MSBuild:

```powershell
& 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe' `
  'RoulsAscendancy\RoulsAscendancy.civ5proj' /t:Package `
  '/p:Civ5Path=C:\Program Files (x86)\Steam\steamapps\common\Sid Meier''s Civilization V SDK' `
  '/p:Civ5UserPath=C:\Users\YourName\Documents\My Games\Sid Meier''s Civilization 5'
```

The project is explicit: SQL is loaded through four ordered `OnModActivated` actions, Lua is imported into VFS for `include()`, the UI XML is the sole `InGameUIAddin` entry point, and the Community Patch dependency is version-gated at 151.

## Project layout

- `RoulsAscendancy/SQL/00_Rouls_Core.sql` — civilization, leader, units, buildings, promotions, colors, icon atlases, and event switches.
- `RoulsAscendancy/SQL/01_Rouls_Inheritance.sql` — companion rows that preserve BNW and Community Patch upgrade, yield, AI, resource, and prerequisite behaviour.
- `RoulsAscendancy/SQL/02_Rouls_UniqueEffects.sql` — flavors, city and spy names, Great General names, and diplomatic response coverage.
- `RoulsAscendancy/SQL/10_Rouls_Text.sql` — Civilopedia, tooltips, Dawn of Man, promotion, UI, and diplomacy localization.
- `RoulsAscendancy/Lua/RoulsCore.lua` — persistent state, kill attribution, reconstruction, Buddy, Lattice, cap management, and upgrade/save handling.
- `RoulsAscendancy/Lua/RoulsActions.lua` — active abilities, legality checks, AI decisions, action locks, and spatial auras.
- `RoulsAscendancy/UI/RoulsPanel.xml` and `.lua` — the top-panel counter and ability selection panel.
- `RoulsAscendancy/Art/` — leader scene, civilization emblem, and all six Civ V icon sizes.
- `tools/` — manifest/package builder, asset converters, database validator, and Lua transaction tests.

## Design interpretation

The source brief says “Mining as normal” and also says the Rou'ls receive no additional starting technology. Standard BNW starts with Agriculture, so the implementation preserves the explicit no-bonus requirement and gives the Rou'ls the normal Agriculture start rather than adding Mining.

The complete supplied design remains in [docs/OriginalDesign.md](docs/OriginalDesign.md). Detailed persistence, rollback, placement, Buddy berth, and in-game smoke-test notes are in [docs/ImplementationNotes.md](docs/ImplementationNotes.md). Art-generation prompts and source handling are in [docs/ArtAssets.md](docs/ArtAssets.md).

## Known testing boundary

The automated checks exercise database loading, Lua syntax, transaction logic, and package integrity. They cannot reproduce the Civ V executable's animation queue, combat timing, save UI, or FireTuner. The final executable smoke-test sequence is documented in `docs/ImplementationNotes.md`; it covers combat harvesting, two-loss limits, Second Skin, swaps, all building rolls, Great Migration eligibility, Buddy fallback berths, and save/reload at every cooldown state.
