# The Last City — Humanity's Final Refuge

**Leader:** The Warden · **Capital:** Last Light · **UA:** The Final Sanctuary

“When the world fell, one city refused to die.”

Last Light saves the survivors of a fallen world, feeds an expanding population and defends its walls against recurring invasions. The Sanctuary Council button above the map opens the survival dashboard. This is a playable source implementation with automated validation; native game smoke tests remain necessary. See [validation](docs/Validation.md) and [engine limitations](docs/Implementation.md).

Human-only civilization: `Playable = 1`, `AIPlayable = 0`. Humans can choose The Last City; ordinary AI selection is disabled.

## Installation

Requires Civilization V: Brave New World and `(1) Community Patch` mod version 151 or newer. The local validation schema is the installed CP v151 schema, with upstream 5.4.2/5.4.6 source references. Full Vox Populi is optional. Single-player only; multiplayer/hotseat are disabled.

Choose **one** installation:

- Collection: build `python tools/build_mod.py`, then install `dist/Cool Wacky Civs (v 21).civ5mod`, or extract the ZIP into your Civ V `MODS` directory.
- Standalone: build `python tools/build_lastcity_mod.py`, then install `dist/The Last City (v 1).civ5mod`, or extract its ZIP into `MODS`.
- Pure files: copy this directory, including `The Last City (v 1).modinfo`, into `MODS`. No ModBuddy is required.

Enable BNW, CP and the selected mod through the Mods menu. Start a new modded game and select The Warden. The standalone manifest blocks collection versions containing this civilization to prevent duplicate registration. Development dependencies are in `requirements-dev.txt`; the bundled repository `.tools/python` directory is supported by the builders/validators.

## Unique components

**The Final Sanctuary:** begin with the normal Settler. Founding Last Light permanently closes further city founding and Settler training/purchasing. Granted/captured Settlers cannot found another city and are removed on the following owner turn. Combat units receive a no-capture promotion. Extra cities are returned to a living previous/original owner at a turn boundary; orphan cities go to a living AI custodian, preferring City-States. With no custodian, verified native city cleanup dismantles the extra city. No player is resurrected and no exceptional permanent puppet is retained.

Combat units within three plots of Last Light have **+15% Defense**, refreshed on movement and changed defense inputs. Every fifth physical wave is a **Major Siege**; defeating it provides **+2% permanent City Defense**, capped at **+30%**. Units attacking distant cities gain no local defense bonus.

**Last Watch (Spearman):** retains the Spearman's database stats, animated 3D model, upgrades and all companion effects; its portrait and flag use original generated art. Its local +15% Defense is the same UA bonus, applied once. A Watch unit present within three plots during a Major Siege and still alive at its conclusion earns a persistent veteran rank: **+3% local Defense**, up to **five ranks (+15%)**. Units built after a siege do not inherit prior victories. The Watch identity and earned ranks survive normal upgrades.

**Sanctuary District (Granary):** inherits all Granary columns and companion tables, including resource Food yields. Adds **+6 Housing**, **+2 Provisions/turn**, enables quarantine and unlocks Sanctuary infrastructure.

## Provisions and rationing

Provisions are separate from Food and Gold. Start with **45**, capacity **200**, Morale **65**, Housing **12**. Global economics and scheduling are configured in `Lua/LastCityConfig.lua`; individual event costs/outcomes accompany the refugee/crisis tables. Native yield and promotion percentages are defined in `SQL/02_LC_Effects.sql`.

Income is **4/turn**, plus **2** from the District, **1** per completed, owned, unpillaged Farm/Fishing Boats in the native city plot radius, **2** per assigned Farmer, and **4** from Reclaimed Waterworks. Remote owned improvements outside the city radius do not produce Provisions. There is no world scan.

Consumption is `ceil(ceil(Population * 0.6 + owned military units * 0.4) * ration multiplier)`, plus active infection and blockade costs. Armed units include ranged-only aircraft/missiles, free-maintenance and temporary troops; civilians are excluded. The Council and ration previews include these costs. Lump supply costs and durations use native `GrowthPercent` (falling back to `TrainPercent`); crisis Production costs use `ConstructPercent`. Infrastructure Production is scaled by the engine once.

| Rations | Consumption | Morale/turn | Positive Food surplus adjustment |
|---|---:|---:|---:|
| Generous | 150% | +0.3 | +15% |
| Standard | 100% | 0 | 0 |
| Strict | 75% | −0.4 | −15% |
| Emergency | 50% | −0.9 | −35% |

Rations have a five Standard-turn cooldown and require preview/confirmation. The table gives Standard-speed Morale rates; gradual Morale changes and starvation mortality probabilities are divided by speed so Marathon does not triple cumulative attrition between events. Fractional Morale and Food persist. Growth uses `FoodDifferenceTimes100`/`ChangeFood` after the native city turn, adjusting stored Food. Negative adjustments cannot remove more than the retained growth stockpile; growth that already happened cannot be reversed. A generous bonus is evaluated by native growth on the following city turn.

At zero Provisions, shortages build progressively: growing Morale losses, another −60% positive Food surplus adjustment, and a bounded probability of Population loss after four scaled turns. Population loss stops at one. Physicians and the hospital reduce mortality. Adequate supplies reduce shortage progression by two per turn; lingering shortages temporarily retain a smaller growth penalty. Stockpiles are clamped to capacity and cannot go negative.

## Refugees and the Council

Twelve narrated caravan templates select survivor descriptions, Population contributions (1–3), expertise, supply costs and pre-rolled consequences. A saved shuffled bag visits every narrative before repeating. Arrivals begin after founding, about every 8–14 Standard turns, with one pending caravan at a time. Quarantine and Physicians reduce harmful complications without suppressing beneficial discoveries.

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

Forces evolve from Scavengers through Marauders, Siege Cults, the Plaguebound, Iron Reavers, Remnants and Harbingers. Choices respect researched prerequisites, falling back to earlier roles. Hostile ships lose stock ocean restrictions, restored after capture where appropriate. Tiny islands use naval forces. Empty neutral spawn plots are searched at radius 8 then 16 with a passable route to the sanctuary or connected coast. If neutral routes are unavailable, a smaller raid can use empty Last City outskirts at distance three or more; the hostile owner is already at war. Other civilizations' territory, cities, occupied plots, mountains, ice and impassable terrain are excluded. If all safe approaches fail, a bounded blockade threatens supplies/shelter and retries physical spawning.

An existing hostile AI major may own the force, allowing normal native capture. Otherwise invaders are barbarians. CP-only barbarians ransom cities; the sustained-collapse rule below supplies a lethal survival condition using verified native cleanup and engine elimination. No extra major slot or forced diplomacy is required. Distant invaders receive a bounded approach order each sanctuary turn; native AI can still redirect them. Peace or timeout withdraws tagged troops into blockade pressure, without a military victory.

Every fifth wave has the named **Harrower**: +25% strength, +35% City Attack, and a +10% strength aura for tagged troops within two plots, reconciled on sanctuary turns. The Final Night adds elite strength. Wave tags combine owner, unit ID, creation turn and script-data identity; supported upgrades preserve records. Reused IDs cannot become invaders accidentally.

Only confirmed combat destruction of every spawned unit awards victory. Ransom removals, capture/conversion without confirmed kill attribution, missing tags, ownership changes, failed spawns and timeouts grant no victory. After 18 scaled turns, unresolved forces withdraw and the next encounter is scheduled. Withdrawn troops are removed only when their saved identity matches. This bounds stuck waves without affecting unrelated armies. A failed Final Night is retried.

## Dawn Initiative and Endless Survival

Unlock with Atomic Era, Atomic Theory, **12 confirmed invasion victories**, **55 Morale**, **150 Provisions**, the District and **900 base Production**. Completion consumes 150 Provisions and schedules the Final Night. If resources drop during construction, the completed Initiative waits for adequate supplies and Morale. Existing waves finish before the final warning.

Defeat the Final Night to receive the **HUMANITY ENDURES** Council aftermath, a persistent Chronicle entry and a permanent +5% Production recovery bonus. Endless Survival then continues. This is a **narrative achievement**, not a custom DLL victory or mislabeled Science/Culture Victory.

## AI, balance and strategy

The Warden is human-only (`Playable = 1`, `AIPlayable = 0`). Retained AI fallback logic automatically assigns experts, evaluates refugee Housing/supplies, selects rationing, resolves crises and queues defensive units when threatened. It constructs survival infrastructure when the native queue is otherwise idle. Defense-focused leader flavors and UNITAI roles support native decisions; ordinary tactical AI still controls movement. Survival resources/costs are identical for human and AI players.

Quick/Standard/Epic/Marathon use native growth speed for intervals/lump supplies and construction speed for crisis Production costs; buildings use the engine's own scaling. Gradual Morale/mortality rates normalize by speed. Costs and intervals are configurable. Difficulty adds at most two invaders and bounded disease pressure. Early waves are intended to be survivable with a garrison, walls and a supply reserve. Granary Food still grows Population, so use rationing and prudent admissions to control pressure.

Start by defending nearby improvements, building the District, assigning Farmers and leaving a reserve before accepting large groups. Emergency rations save supplies but steadily break Morale. Preserve veteran Watch units rather than feeding replacements into repeated sieges. Invest in Housing and storage before pursuing Dawn.

## Delivery status

Implemented and connected: civilization/leader/UA/UU/UB, persistent economy, expert assignments, refugees/quarantine, Morale effects, starvation, bounded overcrowding, all fifteen crisis categories, infrastructure, scheduling/spawning/confirmed siege outcomes, bosses, veteran progression, Council, AI decisions and narrative endgame. Automated SQL, Lua simulation, UI wiring and package results are recorded in [Validation](docs/Validation.md).

Gameplay refinements and the complete audit are described in [the implementation report](docs/RefinementReport.md). The Dawn illustration (1024×768), Warden scene (1600×900), selection map, civilization emblem, leader/unit/building portraits, flags and promotion icons use original generated art. Fourteen retained PNG sources compile into 43 DDS textures; animated 3D unit/world models remain inherited. The full prompt set, asset dimensions and reproducible conversion are recorded in [Art provenance](docs/Art.md).

Native game behavior, defeat-screen delivery, visual layout, tactical targeting and performance on actual Huge/22-player saves remain untested. The stored-Food approximation and Humanity Endures narrative achievement remain deliberate engine limits. No additional DLL is required.

## Breached walls, blocked approaches and plague

CP-only barbarians ransom cities. The survival rule now checks **at least two tagged invaders within two plots**, **one adjacent**, **no owned combat defender within two plots**, and **at least 85% city damage** for **three scaled consecutive sanctuary turns**. A returning defender or repaired wall resets the countdown; one raider cannot trigger it. The Council warns of collapse. At collapse, **THE LAST LIGHT HAS FALLEN** is recorded before verified native `KillCities`/`KillUnits` cleanup at a player-turn boundary. CP's normal alive/game-state checks handle elimination; the mod never calls `SetAlive` or fabricates a defeat screen. Native capture also records the fall, with cleanup deferred outside acquisition.

Spawn searches first use radius 8 and expand to radius 16 if insufficient. Both use bounded route flood fills, correct domains, and exclude foreign territory, cities, occupied plots, impassable terrain and ice. When no safe physical attack can spawn, or an attack stalls/expires or its major owner makes peace, a six-scaled-turn blockade threatens supply routes. Consumption increases by `max(1, 6 + floor(era/2) + finalBonus - localDefense)`; up to three stationed defenders and two assigned Veterans reduce it. The blockade costs Morale, may damage Housing, grants **no wave victory, veteran rank or achievement**, and retries physical spawning four scaled turns after ending. Wave progression is preserved.

Plaguebound within two plots during a physical siege can infect the city once per turn. Infection has severity 1–4, capped duration eight scaled turns, additional consumption, gradual Morale loss and limited severe untreated mortality. Physicians/Hospital reduce probability, severity and duration, mitigate supply drain and accelerate recovery. Infection cannot stack or continually refresh; a four-scaled-turn immunity period follows recovery. Paying for outbreak treatment clears it. State, notifications and Council details survive reload.

Confirmed Harrower deaths remove the aura immediately and grant **+6 Morale once**, even if remaining troops later retreat. Final Night success requires confirmed kills and at least 75% of the planned force to have spawned; an undersized final encounter retries without awarding Humanity Endures.

Save schema 2 keeps checksummed alternating banks and adds a matching marker to native player ScriptData. Missing/mismatched banks disable the simulation rather than restoring an older decision against newer Population or generating resources again. Schema 1 saves migrate when restored normally. A matching backup may recover; a stale backup is intentionally rejected. Other ScriptData content is preserved. Identical snapshots skip writes, UI tabs are reused, casualty deduplication is pruned, and cosmetic Council changes no longer refresh the whole army.
