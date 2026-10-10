# The Last City — Humanity's Final Refuge

**Leader:** The Warden · **Capital:** Last Light · **UA:** The Final Sanctuary

“When the world fell, one city refused to die.”

Last Light saves the survivors of a fallen world, feeds an expanding population and defends its walls against recurring invasions. The Sanctuary Council button above the map opens the survival dashboard. This is a playable source implementation with automated validation; native game smoke tests remain necessary. See [validation](docs/Validation.md) and [engine limitations](docs/Implementation.md).

## Installation

Requires Civilization V: Brave New World and `(1) Community Patch` mod version 151 or newer. The local validation schema is the installed CP v151 schema, with upstream 5.4.2/5.4.6 source references. Full Vox Populi is optional. Single-player only; multiplayer/hotseat are disabled.

Choose **one** installation:

- Collection: build `python tools/build_mod.py`, then install `dist/Cool Wacky Civs (v 21).civ5mod`, or extract the ZIP into your Civ V `MODS` directory.
- Standalone: build `python tools/build_lastcity_mod.py`, then install `dist/The Last City (v 1).civ5mod`, or extract its ZIP into `MODS`.
- Pure files: copy this directory, including `The Last City (v 1).modinfo`, into `MODS`. No ModBuddy is required.

Enable BNW, CP and the selected mod through the Mods menu. Start a new modded game and select The Warden. The standalone manifest blocks collection versions containing this civilization to prevent duplicate registration. Development dependencies are in `requirements-dev.txt`; the bundled repository `.tools/python` directory is supported by the builders/validators.

## Unique components

**The Final Sanctuary:** begin with the normal Settler. Founding Last Light permanently closes further city founding and Settler training/purchasing. Granted/captured Settlers cannot found another city and are removed on the following owner turn. Combat units receive a no-capture promotion, so additional cities cannot be obtained by ordinary conquest. Gifted cities are safely returned to a living previous/original owner on the next turn. There is no Lua city deletion or custom defeat state. An exceptional third-party gift with no living return recipient remains a puppet; this engine compromise is documented.

Combat units within three plots of Last Light have **+15% Defense**, refreshed on movement and turns. Every fifth successfully defeated invasion is a **Major Siege**, providing **+2% permanent City Defense**, capped at **+30%**. Units attacking distant cities gain no local defense bonus.

**Last Watch (Spearman):** retains the Spearman's database stats, art, upgrades and all companion effects. Its local +15% Defense is the same UA bonus, applied once. A Watch unit present within three plots during a Major Siege and still alive at its conclusion earns a persistent veteran rank: **+3% local Defense**, up to **five ranks (+15%)**. Units built after a siege do not inherit prior victories. The Watch identity and earned ranks survive normal upgrades.

**Sanctuary District (Granary):** inherits all Granary columns and companion tables, including resource Food yields. Adds **+6 Housing**, **+2 Provisions/turn**, enables quarantine and unlocks Sanctuary infrastructure.

## Provisions and rationing

Provisions are separate from Food and Gold. Start with **45**, capacity **200**, Morale **65**, Housing **12**. Global economics and scheduling are configured in `Lua/LastCityConfig.lua`; individual event costs/outcomes accompany the refugee/crisis tables. Native yield and promotion percentages are defined in `SQL/02_LC_Effects.sql`.

Income is **4/turn**, plus **2** from the District, **1** per completed, owned, unpillaged Farm/Fishing Boats in the native city plot radius, **2** per assigned Farmer, and **4** from Reclaimed Waterworks. Remote owned improvements outside the city radius do not produce Provisions. There is no world scan.

Consumption is `ceil(ceil(Population * 0.6 + owned combat units * 0.4) * ration multiplier)`. All combat units consume supplies, including free-maintenance and temporary troops. Civilians do not. Income/consumption remain sensible per-turn quantities across game speeds; lump costs and durations scale using native `TrainPercent`.

| Rations | Consumption | Morale/turn | Positive Food surplus adjustment |
|---|---:|---:|---:|
| Generous | 150% | +0.3 | +15% |
| Standard | 100% | 0 | 0 |
| Strict | 75% | −0.4 | −15% |
| Emergency | 50% | −0.9 | −35% |

Rations have a five Standard-turn cooldown and require preview/confirmation in the Council. Fractional Morale and Food adjustments persist. Growth uses a verified `FoodDifference`/`ChangeFood` alternative, adjusting stored Food rather than changing a DLL growth modifier. Negative adjustments cannot remove more than the existing growth stockpile; native city turn ordering can make them weaker when that stockpile is empty.

At zero Provisions, shortages build progressively: growing Morale losses, another −60% positive Food surplus adjustment, and a bounded probability of Population loss after four scaled turns. Population loss stops at one. Physicians and the hospital reduce mortality. Adequate supplies reduce shortage progression by two per turn; lingering shortages temporarily retain a smaller growth penalty. Stockpiles are clamped to capacity and cannot go negative.

## Refugees and the Council

Twelve narrated caravan templates select survivor descriptions, Population contributions (1–3), expertise, supply costs and pre-rolled consequences. Arrivals begin after founding, about every 8–14 Standard turns, with one pending caravan at a time.

- **Accept:** Population and one available expert, full supply cost, +3 Morale, possible complication.
- **Quarantine:** half the supply cost now, a three-scaled-turn delay, roughly one third complication chance; pay the remainder if accepting afterwards. Requires the District/Barracks and temporary shelter capacity. Caravans can leave after the final decision expires.
- **Refuse:** preserve supplies, gain no Population/expertise, lose 10 Morale. Repeated refusals increase unrest and influence later protests.

Consequences include disease, smuggling, infiltration, overcrowding, unrest, theft, leadership, medical/scientific talent, a former commander and rare supplies. Accepted groups are remembered: the Engineers of Ash reduce gate and water repair costs. Every decision is consumed before native rewards are applied. Quarantine and risks survive save/load.

| Expertise | Assigned benefit (maximum five each) |
|---|---|
| Engineers | +3% Production each (maximum +15%) |
| Scientists | +3% Science each (maximum +15%) |
| Physicians | Lower illness risk, treatment costs/severity and shortage mortality |
| Veterans | +2% local defender strength each (maximum +10%) |
| Farmers | +2 Provisions/turn each (maximum +10) |
| Scholars | +3% Culture each (maximum +15%), plus peaceful Morale recovery |

Available experts and assignments are separate; reserve expertise is capped at 50 per category. They do not use native specialist slots. Assign/unassign through the Experts tab. Accidents or medical disasters can reduce expertise and automatically reduce assignments to a legal value.

## Housing, Morale and crises

Overcrowding subtracts 0.4 Morale/turn for 1–2 excess Population, 1.2 for 3–5, and 2.5 for 6+. Disease pressure increases but is bounded. Housing damage is capped at four and persists until repaired.

| Morale | State | Production |
|---|---|---:|
| 80–100 | United | +10%; also +5% local defender strength |
| 60–79 | Stable | unchanged |
| 40–59 | Anxious | −5% |
| 20–39 | Unrest | −15% |
| 0–19 | Breaking Point | −30% |

Morale is independent of Happiness and remains between 0 and 100. Actual dummy-building modifiers are reconciled with exactly the correct counts, without accumulating duplicates. City damage, new pillages and military losses damage Morale. A peaceful, undamaged, adequately supplied and housed city recovers gradually, improved by Scholars.

Fifteen state-weighted crises have three decisions each. They cover outbreaks, gate failure, theft, desertion, protests, missing scientists, broken waterworks, desperate caravans, the last hospital, conspiracy, heroism, supply discoveries, expert accidents, reconstruction and a siege-born child. Crisis frequency has a cooldown, and new crises do not arrive over an unresolved caravan. Ignored crises resolve their least interventionist choice after five scaled turns. Low Morale drives desertion and conspiracy; shortages drive theft; crowding, late invaders and pillaging drive illness.

Gate reinforcement requires both Provisions and **stored Production in the current order**. The verified `ChangeProduction` operation subtracts this investment safely. Emergency militia consume one Population, spawn on an empty owned land plot and expire after six scaled turns; they consume supplies until departure. Abandoning the wall temporarily reduces City Defense and damages Housing.

## Infrastructure investments

These are one-time unique buildings in the normal Production queue. Native game-speed Production scaling applies. They require the District and the listed technology; other civilizations cannot construct them.

| Investment | Base Production | Technology | Benefit |
|---|---:|---|---|
| Refugee Barracks | 100 | Masonry | +4 Housing |
| Expanded Residential Quarter | 220 | Engineering | +8 Housing |
| Underground Shelter | 400 | Dynamite | +10 Housing |
| Emergency Field Hospital | 300 | Biology | Medical mitigation equivalent to two Physicians |
| Protected Storehouses | 240 | Metal Casting | +75 capacity |
| Deep Supply Depot | 450 | Railroad | +100 capacity |
| Reclaimed Waterworks | 300 | Chemistry | +4 Provisions/turn |
| The Dawn Initiative | 900 | Atomic Theory | Final Night sequence |

## The Endless Siege

First wave: about 24 Standard turns after founding. Subsequent waves: 20–24 turns, shortened by up to four in later eras. Warnings arrive three scaled turns in advance. Threat includes era, victories, difficulty and a **bounded** adjustment from the highest historical military unit count, so deleting units cannot erase it. Threat never exceeds 18 invaders per wave.

Forces evolve from Scavengers through Marauders, Siege Cults, the Plaguebound, Iron Reavers, Remnants and Harbingers. Actual unit choices respect the sanctuary's researched prerequisites, falling back to earlier roles. Hostile ships have their stock ocean-impassable promotions removed so open-water spawn routes remain usable; captured ships regain their normal restrictions. Tiny island starts use naval forces. Spawn candidates are empty neutral passable plots four to eight tiles away, with a bounded flood-fill route to the capital or its nearby connected coastal water. Foreign territory, mountains, ice, impassable terrain and cities are excluded. Occupied approaches can postpone a wave indefinitely rather than spawn invalid armies or fabricate victories.

An existing hostile AI major may own the force, allowing normal native city capture. Otherwise invaders are barbarians. **CP-only barbarians ransom cities at 1 HP rather than capture them**; full VP allows capture. The mod preserves the engine's ordinary elimination rules. It does not reserve an extra civilization slot, force diplomacy, create a second defeat state or claim to control custom tactical AI. Each force receives a single ordinary move mission toward a sanctuary approach; native AI may replace it and pursue other targets, and ships can be ineffective on unusual coasts. See limitations.

Every fifth wave has the named **Harrower**: +25% strength, +35% City Attack, and a +10% strength aura for tagged troops within two plots, reconciled on sanctuary turns. The Final Night adds elite strength. Wave tags combine owner, unit ID, creation turn and script-data identity; supported upgrades preserve records. Reused IDs cannot become invaders accidentally.

Only confirmed combat destruction of every spawned unit awards victory. Ransom removals, capture/conversion without confirmed kill attribution, missing tags, ownership changes, failed spawns and timeouts grant no victory. After 18 scaled turns, unresolved forces withdraw and the next encounter is scheduled. Withdrawn troops are removed only when their saved identity matches. This bounds stuck waves without affecting unrelated armies. A failed Final Night is retried.

## Dawn Initiative and Endless Survival

Unlock with Atomic Era, Atomic Theory, **12 confirmed invasion victories**, **55 Morale**, **150 Provisions**, the District and **900 base Production**. Completion consumes 150 Provisions and schedules the Final Night. If resources drop during construction, the completed Initiative waits for adequate supplies and Morale. Existing waves finish before the final warning.

Defeat the Final Night to receive the **HUMANITY ENDURES** Council aftermath, a persistent Chronicle entry and a permanent +5% Production recovery bonus. Endless Survival then continues. This is a **narrative achievement**, not a custom DLL victory or mislabeled Science/Culture Victory.

## AI, balance and strategy

The Warden is AI-playable. AI automatically assigns experts, evaluates refugee Housing/supplies, selects rationing, resolves crises and queues defensive units when threatened. It constructs survival infrastructure when the native queue is otherwise idle. Defense-focused leader flavors and UNITAI roles support native decisions; ordinary tactical AI still controls movement. Survival resources/costs are identical for human and AI players.

Quick/Standard/Epic/Marathon use native `TrainPercent` for turns and lump provision/production costs; Production building costs use the engine's own scaling. Costs and intervals are intentionally configurable. More difficult games add up to two invaders and bounded disease pressure. Early Waves are intended to be survivable with a garrison, walls and a steady supply surplus. Granary Food still grows Population, so use rationing and prudent admissions to control pressure.

Start by defending nearby improvements, building the District, assigning Farmers and leaving a reserve before accepting large groups. Emergency rations save supplies but steadily break Morale. Preserve veteran Watch units rather than feeding replacements into repeated sieges. Invest in Housing and storage before pursuing Dawn.

## Delivery status

Implemented and connected: civilization/leader/UA/UU/UB, persistent economy, expert assignments, refugees/quarantine, Morale effects, starvation, bounded overcrowding, all fifteen crisis categories, infrastructure, scheduling/spawning/confirmed siege outcomes, bosses, veteran progression, Council, AI decisions and narrative endgame. Automated SQL, Lua simulation, UI wiring and package results are recorded in [Validation](docs/Validation.md).

Engine compromises: exceptional orphan gifts, stock art, stored-Food growth approximation, native enemy/defender tactics, CP-only barbarian ransom, conservative conversion outcomes and narrative victory. Native game behavior, visual layout, balance and performance on actual Huge/22-player saves remain untested. Future work should prioritize native smoke tests and multi-speed balance sessions, then original art and a DLL-supported dedicated hostile faction/custom victory.
