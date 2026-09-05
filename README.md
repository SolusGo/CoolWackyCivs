# The Rou'ls Ascendancy

A complete Civilization V: Brave New World civilization for the Community Patch, led by Trent Rou'ls, the Unbodied.

The Rou'ls harvest Anima from military kills, spend it to reconstruct fallen land units, exchange distant armies through TRANSMIGRATION, and eventually consume an enemy vessel through THE GREAT MIGRATION. Their roster includes the Hollowhound Rifleman, Somatic Lattice Hospital, Matriarch of the Choir Great General, The Choir Eternal national wonder, and the unique flagship Buddy, Everlasting.

## Requirements

- Civilization V: Brave New World
- Community Patch version 151 / release 5.4.2 or newer
- Single-player game. Multiplayer and hotseat are intentionally disabled because the custom UI actions and save-backed transactions have not been network synchronized.

## Install

Run `python tools/build_mod.py`, then use `dist/The Rouls Ascendancy (v 1).civ5mod` or copy the unpacked `dist/The Rouls Ascendancy (v 1)` directory into Civilization V's `MODS` directory. Enable `(1) Community Patch` and `The Rou'ls Ascendancy`, then begin a new game.

The project can also be opened directly in ModBuddy through `RoulsAscendancy.civ5sln`. Its database actions, VFS flags, dependencies, and UI entry point are already configured.

## Build and validate

Install the development packages into `.tools/python`, then run:

```powershell
python -m pip install --target .tools/python -r requirements-dev.txt
python tools/validate_mod.py
python tools/test_actions.py
python tools/build_mod.py
```

`validate_mod.py` checks the ModBuddy project and manifest, compiles every Lua file with Lua 5.1, parses every XML file, validates DDS headers and dimensions, and executes all SQL against a disposable clone of a real BNW cache augmented with the installed Community Patch schema. `test_actions.py` executes swap and Great Migration transactions in a mocked Civ V Lua runtime.

ModBuddy's native builder can be invoked on the project itself:

```powershell
& 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe' `
  'RoulsAscendancy\RoulsAscendancy.civ5proj' /t:Package `
  '/p:Civ5Path=C:\Program Files (x86)\Steam\steamapps\common\Sid Meier''s Civilization V SDK' `
  '/p:Civ5UserPath=C:\Users\YourName\Documents\My Games\Sid Meier''s Civilization 5'
```

The portable builder emits an unpacked mod, ZIP, and Civ V-compatible LZMA `.civ5mod` under `dist/`. ModBuddy emits its package under `Packages/`.

## Design interpretation

The source brief says the civilization starts with “Mining as normal,” while standard Civ V starts with Agriculture. The implementation follows the accompanying requirement of no additional starting technology: the Rou'ls receive the normal Agriculture start and no Mining bonus.

The full supplied design is preserved in [docs/OriginalDesign.md](docs/OriginalDesign.md). Runtime decisions and smoke-test cases are documented in [docs/ImplementationNotes.md](docs/ImplementationNotes.md).
