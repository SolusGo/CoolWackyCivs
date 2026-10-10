# Engine contracts and implementation limits

The simulation is owned by `UI/SanctuaryCouncil.xml`'s single InGameUIAddin. `SanctuaryCouncil.lua` includes `LastCityCore.lua` once and owns gameplay handlers for every Last City player, including AI. Module functions are shared with the Council through `MapModData.TheLastCity` within that context. `LuaEvents.LastCityChanged` refreshes UI; there is no frame timer, continuous polling or second state owner. Multiplayer/hotseat are disabled.

## Verified API contracts

The installed `(1) Community Patch (v 151).modinfo` identifies DLL **5.4.6**. The refinement audit uses [Release-5.4.6](https://github.com/LoneGazebo/Community-Patch-DLL/tree/Release-5.4.6/CvGameCoreDLL_Expansion2), commit `dcb33a654cd9e8efb038a0733b4025e19cbcd8ba`, rather than assuming current master matches v151. Local reference copies are in `.references/psj-cp-5.4.6`. Hook declarations are in `CustomMods.h`, actual invocations in `CvPlayer.cpp`, `CvCity.cpp` and `CvUnit.cpp`, and method bindings in `Lua/CvLuaPlayer.cpp`, `Lua/CvLuaCity.cpp` and `Lua/CvLuaUnit.cpp`. This verifies source contracts, not execution in a running game.

| Event/API | Parameters used | Contract/context |
|---|---|---|
| `PlayerDoTurn` | player | Native gameplay observer; one economic tick per saved game turn |
| `PlayerCityFounded` | player, x, y | Native observer; initialize persistent capital identity |
| `PlayerCanFoundCity` | player, x, y | CP `EVENTS_CITY_FOUNDING`, TESTALL boolean veto |
| `PlayerCanTrain` | player, unit | Standard TESTALL boolean veto, covers unit eligibility including purchase |
| `CityCanConstruct` | player, city ID, building | Standard TESTALL boolean veto; unique infrastructure eligibility |
| `CityConstructed` | player, city ID, building, gold, faith | CP `EVENTS_CITY` observer; Dawn completion |
| `UnitCreated` | player, unit ID, type, x, y | CP `EVENTS_UNIT_CREATED` observer; initialize defender effects |
| `UnitSetXY` | player, unit ID, x, y | Native observer; recalculate local Defense |
| `UnitUpgraded` | player, old ID, new ID, goody | CP `EVENTS_UNIT_UPGRADES` observer; transfer persistent identity records |
| `UnitConverted` | old owner, new owner, old ID, new ID, upgrade | CP `EVENTS_UNIT_CONVERTS` observer; reconcile local effects and remove sanctuary effects after foreign conversion |
| `UnitPrekill` | player, unit ID, type, x, y, delayed, killer | Native/CP `EVENTS_UNIT_PREKILL` observer; actual combat attribution and deduplication |
| `CityCaptureComplete` | old owner, capital flag, x, y, new owner, population, conquest, great-work count, capture count | Native observer; uses first five arguments, records acquisition, defers mutation |
| `AcquireCity` | city, conquest, gift, optional original | Native player method; transfer creates a replacement city object, so old references must be discarded |
| `InitUnit` | type, x, y, UnitAI, direction | Native creation; only validated candidate plots are used |
| `PushMission` | move-to, x, y, flags, append (integer), manual (integer) | Bounded once-per-turn orders for distant tagged invaders; native AI may replace them |
| `GetScriptData` / `SetScriptData` | string | Append namespaced tags, preserving other mod content |
| `GetGameTurnCreated` | none | Native unit generation identity; combined with script tag and owner/ID |
| `PushOrder` | order, data1, data2, save (integer), pop, append, rush/force (optional integer) | Native city queue; substantial Production investments |
| `FoodDifferenceTimes100`, `GetFood`, `ChangeFood` | hundredths of native net surplus/integer stockpile/delta | PlayerDoTurn follows native city growth; fractional remainder retained |
| `GetProduction`, `ChangeProduction` | current order stockpile/delta | Costs must already exist; never charge a negative stockpile or a process |
| `Modding.OpenSaveData` | GetValue/SetValue | Save-specific persistence, not global ModUserData |
| `KillCities` / `KillUnits` | none | Native snapshot iterators; collapse cleanup only at player-turn boundary |
| city `Kill` | none | Native PreKill/PostKill cleans trades, spies, religion and capital state; orphan-only fallback at turn boundary |
| player `GetScriptData` / `SetScriptData` | string | Save-resident checksum marker, preserves other mods' content |
| `GetMaxHitPoints` | none | Uses actual city HP rather than assuming 200 |
| `GetBuildingProductionNeeded` | building ID | Engine-scaled Production in Council previews |

SQL enables only the needed CP event options. Standard hooks do not need invented option names. No `CityCanAcquire` hook was found; `CityCanAcquirePlot` concerns tiles rather than city ownership, so it is deliberately not used as a city veto. No CanMoveInto handler is registered because it would impose expensive global pathfinding callbacks.

## Persistence and effects

Namespaced save keys (`LASTCITY_P...`) hold deterministic length-prefixed snapshots in 6000-character chunks. Alternate banks and the active-pointer-last write protocol are preserved. Schema 2 additionally saves a checksum marker in native player ScriptData. A matching backup can recover; an older bank that disagrees with native state is rejected, preventing repeated admission or siege rewards. Missing banks with an existing marker, unsupported schemas, newer-turn snapshots, and schema-2 banks without their marker fail closed. Normal schema-1 restoration migrates in place without changing pending events or starting resources. Identical snapshots skip writes.

`OpenSaveData` is documented as savegame storage, distinct from disk-backed `OpenUserData` ([API storage documentation](https://modiki.civfanatics.com/index.php/Persisting_data_%28Civ5%29), [author's persistence tutorial](https://www.picknmixmods.com/tutorials/home/home.html)). Its proprietary engine implementation is outside the CP DLL source. Separate databases/markers, earlier-slot restoration and missing/mismatched data are exercised by mocks; actual native multiple-save-slot persistence remains an explicit smoke-test requirement. No global ModUserData fallback is used.

Every snapshot includes stockpile/capacity, fractional Morale/Food, ration cooldown, shortage progression, capital identity, experts/assignments, caravan bag/status/pre-roll, history/group flags, crisis, infection/immunity, blockade/collapse/fall, wave identity/participants/deaths, defense legacy, temporary defenders and Dawn. `lastTurn` prevents a saved turn being processed twice. LoadScreenClose reopens native save storage, clears cached state/effects, refreshes speed/player slots and resets Council modal state before reconciliation. This also handles an engine-reused UI context; no turn is simulated and handlers are not registered again.

All hidden effect counts are set to the desired value. Morale thresholds are mutually exclusive. Expert yield effects have 0–5 building counts. Permanent City Defense has at most fifteen +2% copies. Veteran rank markers survive upgrades; active bonuses are refreshed only locally. Foreign ownership loses sanctuary-specific promotions through `LostOnGifting` and owner reconciliation.

## Compromises and risks needing native tests

1. **Enemy AI and defeat.** CP-only barbarian ransom is confirmed in `CvUnitCombat::ResolveMeleeCombat`. The new sustained-collapse rule requires multiple nearby tagged enemies, breached walls and no nearby defenders for three scaled turns. `Fall` persists the dramatic event; `FinishFall` uses verified native `KillCities`/`KillUnits` outside combat/acquisition. `CvGame::update` calls `testAlive`, then `CvPlayer::verifyAlive` eliminates empty players, including Complete Kills, and the engine handles game state. No `SetAlive`, fake screen or custom game-over API is called. Actual defeat UI/delivery and interactions with other mods still require native tests. Existing hostile-major AI can choose other targets; distant move missions are refreshed per turn, peace cancels the wave, and timed-out armies withdraw into blockade pressure.
2. **One-city gifts.** Extra cities return to living previous/original owners, then living AI custodians (City-States first). If no recipient exists, source-verified native city `Kill` dismantles only the extra city at a turn boundary. Native cleanup handles capital/holy-city bookkeeping and can affect original-capital/holy-city history. Neither original Last Light identity nor dead-player status is rewritten by Lua. No permanent extra puppet is deliberately retained.
3. **Growth.** Rations adjust stored Food by a fraction of positive native surplus. This is not an exact native Growth percentage and depends on city turn ordering/current Food. Fractional remainders are kept; negative debt is discarded when Food reaches zero. Starvation Population losses are separate bounded survival consequences, while native Food/Happiness growth remains functional.
4. **Production projects.** Infrastructure and Dawn are unique one-time buildings. This provides real native cost, speed scaling and build queues without fake projects or unverified completion events. Dawn eligibility is checked during construction and supplies/Morale again at completion. Stored production costs for crisis gate repairs operate on the current native order.
5. **Combat timing.** Local defense reconciles on movement/creation/upgrades or changed defense inputs. Boss aura updates on tagged movement and immediately loses its commander on confirmed death. Watch movement into the sanctuary records participation; surviving participants earn one capped rank per Major Siege. Transfer invalidates participation and clears earned ranks. Conversion revokes provisional kill credit before turn resolution. Unknown disappearances and ransom still grant no victory. Plague uses once-per-turn proximity of identified Plaguebound; `Battle*` hooks exist, but introducing global combat observers is unnecessary. `UnitPillageGold` is a VALUE callback used while calculating gold, so attaching infection side effects would risk repeated execution. No global combat or map polling is added.
6. **Spawning.** Flood fills at radius 8, then 16, exclude foreign territory and invalid terrain. Smaller real raids/coastal forces can spawn. Blocked/failed physical creation, peace and timeout produce a bounded blockade, with consumption included in projections, Morale loss and limited shelter damage. It grants no military rewards and retries physical spawning. Final achievement additionally requires at least 75% of the planned force actually spawned. Naval capture/tactical effectiveness remains native-map dependent. Stock ocean restrictions are removed only from hostile fleets and restored after capture where appropriate.
7. **Art.** Fourteen original generated sources supply the 1024×768 Dawn illustration, 1600×900 Warden diplomacy scene, selection map, custom civilization/leader/unit/building portraits, alpha icons, unit flag and promotion atlases. Animated Spearman and ordinary city/building world models remain inherited. Art registration runs after mechanical inheritance without changing gameplay stats. [Art.md](Art.md) records the prompt set, exact dimensions and reproducible conversion.
8. **UI/balance.** Seven event-driven tabs, confirmation previews and native modal visibility handling are implemented. Native visual sizing and less common modal contexts must be checked in Civ V. Huge maps/22 majors are covered by bounded algorithms and mocks; no native FPS/turn-time claim is made. Existing saves cannot gain a new selectable player civilization retroactively.
9. **Endgame.** Humanity Endures is a persistent narrative achievement with a Council aftermath and Endless Survival. No reliable custom victory contract was established, so no native victory type or achievement-service entry is fabricated.

No additional DLL, external unit models, unsupported city/player methods or custom game-over screen is required. Native smoke tests remain outstanding. See [RefinementReport.md](RefinementReport.md) for corrections, balance changes and validation evidence.
