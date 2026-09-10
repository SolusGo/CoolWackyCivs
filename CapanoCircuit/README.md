# The Capano Circuit

Enrico Capano leads an independent Civilization V: Brave New World + Community Patch v151 civilization built around setting terrain, studying difficult opponents, and turning repeated failure into a SEND. It is AI-playable and favors Science, Culture, military training, defense, reconnaissance, and tile improvement.

## Unique ability — Impossible Until It's Possible

When a Capano land combat unit attacks a unit or city without defeating it, that exact target becomes its Project. The unit gains one stack of Beta, up to four. Its next attacks against that Project receive +5%, +10%, +15%, then +20% attack strength. Attacking a different target abandons the old Project and starts again.

Defeating a Project with four Beta earns a SEND only when the target was at least as strong as the attacker when the Project began. A SEND heals 25 HP, awards 10 XP, and grants equal Science and Culture based on the target's strength and the later combatant era. Cities grant 2.5 times the normal reward. Units trained on a Yellow Circuit grant 15% more.

Each unit's qualifying SEND count unlocks one permanent technique:

- Footwork: +10% defense on Hills.
- Body Position: +10% strength while adjacent to at least two terrain types.
- Coordination: recover one movement point after a kill.
- Commit: +15% attack below 50 HP.
- Complete Climber: +1 Movement, +10% strength, and ignore enemy Zone of Control while on Hills.

The first SEND against a target whose effective strength was at least 1.5 times the attacker's original base strength completes Ammagamma once per player: 500 Science, 500 Culture, and a Golden Age.

## Unique unit — Route Setter

The Route Setter replaces the Worker, inherits its installed Community Patch actions, has 3 Movement, ignores Hill movement cost, and works 25% faster while actively building on a Hill. It can construct the Boulder Sector.

## Unique improvement — Boulder Sector

A Boulder Sector may be built on a land Hill or beside a Mountain, but not adjacent to another Boulder Sector. It starts with +1 Science, +1 Culture, and +1 Production, then progresses through the Circuit:

| Technology | Grade | Additional effect |
| --- | --- | --- |
| Guilds | Red | +1 Production |
| Education | — | +1 Science |
| Architecture | Purple | +1 Culture; enemy penalty becomes -12% |
| Scientific Theory | Black | +1 Science |
| Radio | — | +1 Culture |
| Plastics | Yellow | Units first trained here permanently gain +15% SEND rewards |

Friendly land units pay at most one movement point when entering an owned Sector. Hostile units pay up to one additional movement point and suffer -10% strength until their next turn, increasing to -12% at Architecture.

Once per era, a Capano land combat unit ending its turn on an owned Sector earns 5 XP and Read the Sequence, granting +10% strength in rough terrain for 10 turns. Its first post-Plastics training also marks it Yellow. Enemy first entry can show one of the cosmetic BlocHaus messages, including the rare “ENRICO.”

## Unique building — Competition Coaching Centre

The Competition Coaching Centre replaces and dynamically inherits the current Armory. It adds +2 Science and +2 Culture. Normally produced land combat units trained in its city receive Competition Movement: after moving at least two adjacent tiles during a turn, they gain +15% attack strength for the rest of that turn.

## AI and implementation

Enrico is AI-playable with the design's restrained expansion/offense and high Science, Culture, training, defense, recon, and improvement flavors. Community Patch diplomacy hooks add Respect the Send (+10), Abandoned Project (-10), and Strong Climbers (+5) when their stated thresholds are met.

Target identity, Beta, training era, Yellow status, SEND progression, Ammagamma, and diplomacy milestones persist through `Modding.OpenSaveData` or namespaced unit script data. Battle bonuses are temporary target-specific promotions applied only around the Community Patch battle callbacks. Unit-ID reuse is guarded with saved serials, and conversions clear foreign Projects while upgrades preserve same-owner progress.

The improvement uses the stock Fort world model with custom Capano UI art. The Route Setter uses Worker animations. UI and leader textures use Civ V-compatible legacy DXT5 DDS encoding. The generated static leader/loading scene is included; there is no animated 3D leader or custom music. Multiplayer and hotseat are disabled pending synchronization testing.

## Build and validation

From the repository root:

```powershell
python tools/make_capano_assets.py
python tools/validate_capano_mod.py
python tools/build_capano_mod.py
```

The validator applies all SQL to an in-memory copy of the installed game database with current Community Patch schema extensions. It checks exact unit/building inheritance, yields, promotions, localization, project/manifest parity, DDS geometry, Lua 5.1 syntax, and behavior tests for Projects, SEND/Ammagamma, target switching, Sector placement/movement/training, Competition Movement, and diplomacy modifiers.

The builder creates an unpacked mod, ZIP, and Civ V-compatible `.civ5mod` under `dist/`. Enable it before starting a new game. A final in-game smoke test is still required for setup/Civilopedia icons, combat-preview timing, city capture, save/reload, AI behavior, and world-model visuals.

The supplied design is preserved in [docs/OriginalDesign.md](docs/OriginalDesign.md). Art sources, extraction details, and the generation prompt are recorded in [docs/ART_GENERATION.md](docs/ART_GENERATION.md).
