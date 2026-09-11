# Cool Wacky Civs

Cool Wacky Civs is one Civilization V: Brave New World mod containing four civilizations built for the Community Patch. The repository has one ModBuddy solution, one project, one manifest, and one deployable package; each civilization keeps its own gameplay and implementation README.

## Civilizations

- [The Rou'ls Ascendancy](RoulsAscendancy/README.md) — Trent Rou'ls preserves experienced forces through Anima, reconstruction, and strategic body exchange.
- [The Luna Network](LunaNetwork/README.md) — GPT-5.6 Luna chains construction refunds, expands with Packet Settlers, and rapidly deploys newly trained forces.
- [The Terra Framework](TerraFramework/README.md) — GPT-5.6 Terra temporarily specializes cities, supports outgoing trade, and reconfigures Operatives for their terrain.
- [The Capano Circuit](CapanoCircuit/README.md) — Enrico Capano sets Boulder Sectors, projects difficult targets, and turns four failed attempts into a rewarding SEND.

All four civilizations are installed and enabled together. Rou'ls and Luna are human-only; Terra and Capano also support AI selection with design-specific flavors. The collection supports single-player games; multiplayer and hotseat remain disabled pending synchronization testing.

## Requirements

- Civilization V with Brave New World.
- Community Patch version 151, release 5.4.2, or newer.
- A new game after enabling or changing the mod.

## Build and validation

Install the repository-local development dependencies:

```powershell
python -m pip install --target .tools/python -r requirements-dev.txt
```

Validate all four civilizations and build the single collection package:

```powershell
python tools/validate_all.py
python tools/build_mod.py
```

Outputs are written under `dist/` as one unpacked directory, one ZIP archive, and one Civ V-compatible `.civ5mod`. The checked-in manifest uses forward-slash paths and exact `True`/`False` ModBuddy metadata; this prevents ModBuddy from silently turning art VFS imports off.

Open [CoolWackyCivs.civ5sln](CoolWackyCivs.civ5sln) in ModBuddy. It is the only solution and builds [CoolWackyCivs.civ5proj](CoolWackyCivs.civ5proj).
