# Engine contracts and implementation limits

The simulation is owned by `UI/SanctuaryCouncil.xml`'s single InGameUIAddin. `SanctuaryCouncil.lua` includes `LastCityCore.lua` once and owns gameplay handlers for every Last City player, including AI. Module functions are shared with the Council through `MapModData.TheLastCity` within that context. `LuaEvents.LastCityChanged` refreshes UI; there is no frame timer, continuous polling or second state owner. Multiplayer/hotseat are disabled.

## Verified API contracts

Verified against the local upstream CP source references (`.references/CustomMods.h`, `CvPlayer.cpp`, `CvUnit.cpp`, `CvLuaCity.cpp`, `CvLuaUnit.cpp`, `ViltrumCvLuaPlayer.cpp`, `ViltrumCvUnitCombat.cpp`) and installed BNW/CP database schema. Source provenance is [Community Patch DLL](https://github.com/LoneGazebo/Community-Patch-DLL). The hook definitions and invocation contracts are in [CustomMods.h](https://github.com/LoneGazebo/Community-Patch-DLL/blob/master/CvGameCoreDLL_Expansion2/CustomMods.h); city-capture and ransom behavior are in [CvUnitCombat.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/master/CvGameCoreDLL_Expansion2/CvUnitCombat.cpp).

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
| `CityCaptureComplete` | old owner, capital flag, x, y, new owner, population, conquest | Native observer; record acquisition, defer mutation |
| `AcquireCity` | city, conquest, gift, optional original | Native player method; transfer creates a replacement city object, so old references must be discarded |
| `InitUnit` | type, x, y, UnitAI, direction | Native creation; only validated candidate plots are used |
| `PushMission` | move-to, x, y, flags, append (integer), manual (integer) | One initial ordinary movement order toward nearby sanctuary approaches; native AI may replace it |
| `GetScriptData` / `SetScriptData` | string | Append namespaced tags, preserving other mod content |
| `GetGameTurnCreated` | none | Native unit generation identity; combined with script tag and owner/ID |
| `PushOrder` | order, data1, data2, save (integer), pop, append, rush/force (optional integer) | Native city queue; substantial Production investments |
| `FoodDifference`, `GetFood`, `ChangeFood` | native net surplus/stockpile/delta | Stored-Food alternative to ration Growth modifiers |
| `GetProduction`, `ChangeProduction` | current order stockpile/delta | Costs must already exist; never charge a negative stockpile or a process |
| `Modding.OpenSaveData` | GetValue/SetValue | Save-specific persistence, not global ModUserData |

SQL enables only the needed CP event options. Standard hooks do not need invented option names. No `CityCanAcquire` hook was found; `CityCanAcquirePlot` concerns tiles rather than city ownership, so it is deliberately not used as a city veto. No CanMoveInto handler is registered because it would impose expensive global pathfinding callbacks.

## Persistence and effects

Namespaced save keys (`LASTCITY_P...`) hold deterministic length-prefixed snapshots in 6000-character chunks. Checksummed alternate banks preserve the previous snapshot if an interrupted write damages the active bank. The active-bank pointer is written last. No `loadstring`, executable serialization or per-frame saving. A newer unsupported schema, or corruption of both existing banks, disables that player's survival simulation instead of minting starting resources or repeating Population rewards.

Every snapshot includes stockpile/capacity, fractional Morale/Food, ration cooldown, shortage progression, capital coordinates/founding turn, expert reserves/assignments, caravan status and pre-roll, history/accepted-group flags, crisis state, wave identity/units/participants/deaths, defense legacy, temporary defenders, damage and Dawn status. `lastTurn` prevents a saved turn from being processed twice. Loading reconciles dummy buildings/promotions without simulating another turn.

All hidden effect counts are set to the desired value. Morale thresholds are mutually exclusive. Expert yield effects have 0–5 building counts. Permanent City Defense has at most fifteen +2% copies. Veteran rank markers survive upgrades; active bonuses are refreshed only locally. Foreign ownership loses sanctuary-specific promotions through `LostOnGifting` and owner reconciliation.

## Compromises and risks needing native tests

1. **Enemy AI and defeat.** Barbarians are available without consuming one of the 22 major slots. CP-only barbarians ransom cities instead of capturing them; full VP changes that. A living hostile AI major is used when available, but the mod does not force a war or reserve a custom faction. City loss and civilization elimination always follow native rules. Native armies can pursue other targets. The mod makes no claim to custom tactical AI.
2. **One-city gifts.** Normal founding, settling and military capture are prevented. Foreign gifts are returned outside the acquisition callback. If a third-party script grants a city whose previous/original owners are both dead, the safe fallback is an exceptional puppet and notification. Lua does not delete a capital or resurrect a player through an unverified API. Such a gift violates the permanent-one-city rule until a valid recipient exists.
3. **Growth.** Rations adjust stored Food by a fraction of positive native surplus. This is not an exact native Growth percentage and depends on city turn ordering/current Food. Fractional remainders are kept; negative debt is discarded when Food reaches zero. Starvation Population losses are separate bounded survival consequences, while native Food/Happiness growth remains functional.
4. **Production projects.** Infrastructure and Dawn are unique one-time buildings. This provides real native cost, speed scaling and build queues without fake projects or unverified completion events. Dawn eligibility is checked during construction and supplies/Morale again at completion. Stored production costs for crisis gate repairs operate on the current native order.
5. **Combat timing.** Local defender effects refresh on UnitSetXY, creation/upgrades and sanctuary turns. A battlefield aura refreshes once per sanctuary turn; it is not an attack-time DLL aura. Watch participants qualify if recorded within three plots at a Major Siege turn, including arrival during the siege; survivors get one rank on victory. Movement between ticks can affect presence detection. Combat attribution is conservative: unknown disappearances, ransom and untracked conversion resolve without rewards.
6. **Spawning.** Bounded local flood fills exclude foreign territory. They can postpone attacks indefinitely in cramped/dense 22-player worlds. Naval attackers can be unable to capture certain coastal cities and may prioritize other targets. The post-spawn timeout withdraws only identity-verified invaders, without rewards. Ships fall back to Triremes if the sanctuary has no suitable naval tech. Stock ocean-impassable promotions are removed only from hostile fleets so their open-water routes are traversable, and restored after capture where normally required.
7. **Art.** Verified stock America/Washington, Spearman, Granary and promotion atlases are inherited, including alpha icons, map/Dawn art, leader scene, unit flags and Civilopedia images. The requested original dark-fantasy imagery is not supplied; there are no unresolved custom DDS dependencies. Stock Washington imagery will appear for the Warden.
8. **UI/balance.** Seven event-driven tabs, confirmation previews and native modal visibility handling are implemented. Native visual sizing and less common modal contexts must be checked in Civ V. Huge maps/22 majors are covered by bounded algorithms and mocks; no native FPS/turn-time claim is made. Existing saves cannot gain a new selectable player civilization retroactively.
9. **Endgame.** Humanity Endures is a persistent narrative achievement with a Council aftermath and Endless Survival. No reliable custom victory contract was established, so no native victory type or achievement-service entry is fabricated.

No new DLL, external unit models, unsupported city deletion, custom game-over logic or external art download is required.
