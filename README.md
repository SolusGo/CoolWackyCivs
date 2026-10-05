# Cool Wacky Civs

Cool Wacky Civs is one Civilization V: Brave New World mod containing twelve civilizations built for the Community Patch. The repository has one ModBuddy solution, one project, one manifest, and one deployable package; each civilization keeps its own gameplay and implementation README.

## Civilizations

- [The Rou'ls Ascendancy](RoulsAscendancy/README.md) — Trent Rou'ls preserves experienced forces through Anima, reconstruction, and strategic body exchange.
- [The Luna Network](LunaNetwork/README.md) — GPT-5.6 Luna chains construction refunds, expands with Packet Settlers, and rapidly deploys newly trained forces.
- [The Terra Framework](TerraFramework/README.md) — GPT-5.6 Terra temporarily specializes cities, supports outgoing trade, and reconfigures Operatives for their terrain.
- [The Capano Circuit](CapanoCircuit/README.md) — Enrico Capano sets Boulder Sectors, projects difficult targets, and turns four failed attempts into a rewarding SEND.
- [The Filthy Realm](FilthyRealm/README.md) — Filthy Frank contaminates foreign cities, converts disruption into Filthy Points, and spends them on four active abilities.
- [The Dual Order](DualOrder/README.md) — Grandmaster Severin balances Faith and military infrastructure, converts active wars into capped Balance Pressure, and fields Divided Templars.
- [The RomanGladius Network](RomanGladiusNetwork/README.md) — Lachlan grows Cities as multiplayer Servers, appoints staff, protects Reputation, resolves community incidents, and turns Players into Gold, Science, and Culture.
- [The Eternal Number Ten](EternalNumberTen/README.md) — Lionel Messi builds a persistent Legacy through Great People, Wonders, diplomacy, and coordinated Assists, unlocking six permanent Career Chapters from Rosario to immortality.
- [The Boy Beyond the Sky](MasayaBeyondSky/README.md) — child Masaya Hinata builds Joy of Flight through exploration, combat participation, promotions, and joyful practice before launching six-turn Beyond the Sky bursts.
- [The First Night](PaulsoaresJr/README.md) — PaulsoaresJr guides curious Survivors through first experiences whose permanent Memories become more precious as eras pass.
- [The Viltrum Empire](ViltrumEmpire/README.md) — Grand Regent Thragg conquers through Imperial Momentum and elite Viltrumites before a guaranteed Scourge forces quarantine or a desperate crusade.
- [The Tokenized Intelligence](TokenizedIntelligence/README.md) — Axiom, Keeper of Context, spends finite Tokens on cached Prompts, manages congestion, and grows its Context Window through eras and inference infrastructure.

Token hardening in version 17 preserves version 16 Token save keys. Clear Context restores Tokens and clears persistent Prompts/cache while Compute Saturation expires naturally; weaker saturation cannot prolong a stronger tier.

All twelve civilizations are installed and enabled together. Rou'ls and Luna are human-only; Terra, Capano, Filthy Frank, Grandmaster Severin, Lachlan, Lionel Messi, Masaya Hinata, PaulsoaresJr, Thragg, and Axiom also support AI selection with design-specific flavors and automated mechanics. The collection supports single-player games; multiplayer and hotseat remain disabled pending synchronization testing.

## Requirements

- Civilization V with Brave New World.
- Community Patch version 151, release 5.4.2, or newer.
- A new game after enabling or changing the mod.

## Build and validation

Install the repository-local development dependencies:

```powershell
python -m pip install --target .tools/python -r requirements-dev.txt
```

Validate all twelve civilizations and build the single collection package:

```powershell
python tools/validate_all.py
python tools/build_mod.py
```

Outputs are written under `dist/` as one unpacked directory, one ZIP archive, and one Civ V-compatible `.civ5mod`. The checked-in manifest uses forward-slash paths and exact `True`/`False` ModBuddy metadata; this prevents ModBuddy from silently turning art VFS imports off.

Open [CoolWackyCivs.civ5sln](CoolWackyCivs.civ5sln) in ModBuddy. It is the only solution and builds [CoolWackyCivs.civ5proj](CoolWackyCivs.civ5proj).
