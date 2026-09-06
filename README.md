# Cool Wacky Civs

Cool Wacky Civs is a collection of standalone Civilization V: Brave New World civilizations built for the Community Patch. Each civilization is packaged separately and has its own gameplay and implementation README.

## Civilizations

- [The Rou'ls Ascendancy](RoulsAscendancy/README.md) — Trent Rou'ls preserves experienced forces through Anima, reconstruction, and strategic body exchange.
- [The Luna Network](LunaNetwork/README.md) — GPT-5.6 Luna chains construction refunds, expands with Packet Settlers, and rapidly deploys newly trained forces.

Both civilizations are human-playable and explicitly unavailable for AI selection. They support single-player games; multiplayer and hotseat are disabled because their Lua state has not been network-synchronized.

## Requirements

- Civilization V with Brave New World.
- Community Patch version 151, release 5.4.2, or newer.
- A new game after enabling or changing these mods.

## Build and validation

Install the repository-local development dependencies:

```powershell
python -m pip install --target .tools/python -r requirements-dev.txt
```

Validate and build either civilization:

```powershell
python tools/validate_mod.py
python tools/build_mod.py
python tools/validate_luna_mod.py
python tools/build_luna_mod.py
```

Run `python tools/build_all.py` to build both. Outputs are written under `dist/` as unpacked directories, ZIP archives, and Civ V-compatible `.civ5mod` packages.

The ModBuddy solutions are [RoulsAscendancy.civ5sln](RoulsAscendancy.civ5sln) and [LunaNetwork.civ5sln](LunaNetwork.civ5sln).
