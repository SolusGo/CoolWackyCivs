# Version 15 audit — 5 October 2026

This record distinguishes **automated Lua/SQL tests**, **source-audited CP contracts**, and **unrun Civ V/IGE acceptance**. No native game execution or actual saved-game migration is claimed. The previous implementation record is retained below with corrected source statements.

## Findings and fixes

| Request | Finding and resulting behavior |
|---|---|
| 1. Genome | **Bug:** choice alone granted Genome throughout either primary crisis. Training now requires recovered=1, neither crisis timer active, and no original-survivor marker. Native city training precedes PlayerDoTurn, so training at the expiry boundary enters recovery once before testing eligibility. Existing units are never retroactively marked; upgrades preserve existing promotions. |
| 2. Capital heal | **Bug:** IsOriginalCapital excluded relocated capitals. BattleJoined now snapshots IsCapital while the city still belongs to the defender. Only the identified attacking Pureblood in a matching melee capture heals fully. Planetbreaker independently grants its 35 HP. Duplicate capture callbacks cannot repeat either heal. |
| 3. Quarantine training/purchases | Already intentional and correctly uses CityCanTrain. Source confirms Gold/Faith purchase validation calls canTrain with bWillPurchase=true, and the same veto executes. Explicit Settler, Caravan, Cargo Ship, Worker, ordinary military and Warrior tests were added; README, event help and popup wording now agree. |
| 4. Growth | **Tooltip/edge-case defect:** -10000 is clamped safely by CP, but displays an excessive player modifier and does not prevent growth from already-above-threshold food after massive population loss. A lone -100 is insufficient because bonuses are additive. Replaced with -100 plus minimal additional binary native policy compensation based on actual positive surplus, refreshed on phase/city-info events with recursion protection. Negative food remains native; below-threshold stored food is retained and above-threshold food is trimmed just below threshold. |
| 5. Resistance | Formula already intentionally rounds upward. Kept ceil(r*.20), and help/README now say rounded-up 20%, minimum one turn when resistance exists. Six boundary cases cover 1/2/3/5/9/10. |
| 6. Peace scans | **Performance bug and ordering risk:** every player's turn and every ordinary refresh scanned globally; DeclareWar was sampled before native setAtWar. Scanner now runs at load, Crusade start, post-state WarStateChanged(aTeam,bTeam,bWar), and once per Viltrum turn while a lock is outstanding. It stops after cleanup. Native scenario flags and mod ownership are retained; both directions and non-Viltrum teammates are vetoed. |
| 7. Garrison movement | **Performance bug:** full-empire scans per tile. UnitSetXY now refreshes only cached previous-city coordinates and the unit's current city. Full refresh seeds caches on load and repairs phase/capture state. Native kill moves units to invalid coordinates and emits UnitSetXY, allowing departure/death repair. |
| 8. Status UI | **Visibility bug:** launcher/optional status panel could overlay major views. City-screen enter/exit, leader message/leave, and popup shown/processed events gate them. Nested popup types remain blocked until all finish; mandatory pending choices still queue/show. No SetUpdate or frame polling. XML structure was reviewed and needed no change. |
| 9. Battle safety | **Bug:** withdrawal/RED veto can omit Finished; defensive support can nest after melee info generation, and queued support can defer the outer battle. Retained bounded participant contexts, cleared temporary effects before a new calculation, and enabled CombatResult to select the actual resolving identity/plot. Bystanders/interceptors cannot replace main participants. Finish/load/new-start cleanup prevents target bonuses entering later damage calculations. |
| 10. Paradrop | Existing handler is correct. Native argument order is player, unit, fromX, fromY, toX, toY. Native drop leaves one movement point and increments attacks-made; SetMadeAttack(false) resets that counter, including Blitz. No extra movement or separate attack-state adjustment is needed. DropRange remains 7. Tactical AI enumerates canParadropAt and can issue native paradrop missions. Actual AI use and drop/attack execution remain IGE work. |
| 11. Auxiliary | Implementation already correct: a Viltrum-only class override resolves the Auxiliary, while Infantry class resolves the Warrior. All ordinary scalar fields except intentional identity/art fields, roles, resources and outgoing upgrades match Infantry. No Viltrum Bloodline/Flight/free promotions are inherited. Runtime tests include Auxiliary training. AI composition still requires playtesting. |
| 12. Inheritance | **Latent compatibility bug:** cloning every table with UnitType/BuildingType would duplicate foreign class overrides, free Infantry grants and promotion definitions if those otherwise-empty CP rows were populated. Restricted to real companion tables and unit gameplay scripts. Preserved CP companions/prerequisites, reset surrogate IDs, omitted Warrior resource requirements/expenditure and explicitly nullified scalar ResourceType. Sentinel-reference tests ensure nonempty external references stay untouched. |
| 13. Population protection | Existing final min(oldPopulation,result) is correct and prevents Population-1 growth. No math/balance change. Clarified the misleading failure-message wording and tested all 48 population/Complex/capital/branch combinations. |
| 14. Hook contracts | Callback prefixes were correct; ignored trailing parameters are intentional. Crucial additional source findings are pre-state DeclareWar/MakePeace, pre-convert UnitUpgraded, current capital before ownership transfer, and identity-carrying CombatResult. See the contract table below. |
| 15. Existing safety | Original synchronized Game.Rand, casualty floors, persistent markers, ID-reuse safety, capture/Complex history, quarantine history consumption, durations/caps, phase/choice deduplication, Golden Age cancellation, listener guard and multiplayer-disabled metadata remain tested. No balance values or mechanics were removed. |

**Additional capture defect found:** CP sets bConquest=true for cities ceded in peace treaties, while CityCaptureComplete omits bGift. Requiring a matching melee capture context for conquest rewards prevents peace cessions from awarding Population/Momentum or consuming future real-conquest history. Existing tests representing actual capture were changed to generate native battle context; they were not weakened.

## Source contracts checked

Primary release snapshot: [Community Patch Release-5.4.2](https://github.com/LoneGazebo/Community-Patch-DLL/tree/Release-5.4.2/CvGameCoreDLL_Expansion2), matching the collection's CP v151 baseline. Installed 5.4.6 CP schema was also exercised. Source files were fetched into ignored `.tools/cp-v151-audit`; source assertions run if that snapshot is present, otherwise explicitly report SKIP. They require no network during validation.

| Event | Native arguments / dispatch evidence |
|---|---|
| PlayerDoTurn | playerID; CvPlayer::doTurn, after city turns. |
| UnitCreated | playerID, unitID, unitType, x, y; CvUnit init. |
| CityTrained | playerID, cityID, unitID, gold, faith; production and both purchases in CvCity. |
| CityConstructed | playerID, cityID, buildingID, gold, faith; CvCity construction/purchases. |
| CityCaptureComplete | oldPlayer, wasCapital, x, y, newPlayer, population, conquest, greatWorksPresent, capturedGreatWorks; CvPlayer::acquireCity. The conquest bool includes peace cessions. |
| BattleStarted | kind, targetX, targetY; Generate*CombatInfo / paradrop interception. |
| BattleJoined | playerID, unit-or-cityID, role, isCity; CvCombatInfo setters / explicit city/garrison dispatch. Roles 0 attacker, 1 defender; 2 interceptor and 3 bystander are ignored. |
| BattleFinished | no arguments; Resolve* routines. Withdrawal and RED abort can omit it; queued support can postpone an outer battle. |
| CombatResult (new) | attackerPlayer, attackerUnit, damage, finalDamage, maxHP; defenderPlayer, defenderUnit, damage, finalDamage, maxHP; interceptorPlayer, interceptorUnit, damage; x, y. City unit IDs are -1; city attackers also report attackerPlayer=-1 in this release, so city-attack matching uses the target plot/defender and the city role. Dispatch is just before actual Resolve*. |
| UnitSetXY | playerID, unitID, x, y; after native previous/new garrison repair. Kill also uses setXY(invalid,invalid). |
| CityCanTrain | playerID, cityID, unitType; TestAll in CvCity::canTrain, also reached through Gold/Faith purchase checks. |
| PlayerCanMakePeace | originatingPlayerID, againstTeamID; CvDealClasses peace item TestAll. Both native team permanent flags are also checked. |
| DeclareWar | originatingPlayerID, againstTeamID, aggressor with CP option enabled; before setAtWar. Legacy fallback uses team IDs. Removed from runtime in favor of post-state event. |
| MakePeace | originatingPlayerID, againstTeamID, pacifier with CP option enabled; before setAtWar(false), originating player can differ in chained/vassal operations. Removed from runtime. |
| WarStateChanged (new UI event) | firstTeamID, secondTeamID, warBool; native GameplayWarStateChanged after war-state/caches update. |
| ParadropAt | playerID, unitID, fromX, fromY, toX, toY; after movement=one and setMadeAttack(true). |
| UnitUpgraded | playerID, oldUnitID, newUnitID, goodyHut; before convert kills old unit. Persistent native promotions transfer after this callback, so callback does not invent survivor/Genome identity. |
| TeamTechResearched | teamID, techID, changeCount; CvTeam tech setter. |

Source references: [CvCity growth/purchases](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvCity.cpp), [CvUnit drop/upgrade/movement](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvUnit.cpp), [combat and support](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvUnitCombat.cpp), [participant dispatch](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvGameCoreStructs.cpp), [CvPlayer capture/turn](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvPlayer.cpp), [CvTeam war/tech](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvTeam.cpp), [peace-deal veto](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvDealClasses.cpp), [native AI deployment](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvTacticalAI.cpp). CP v151's locally installed CityView, LeaderHeadRoot, TechTree and CultureOverview scripts confirm the selected UI shown/processed and enter/leave events.

## Validation results

- `python tools/validate_viltrum_mod.py`: PASS, including the source snapshot assertions, both current installed CP and v151 backup DDL activation, Lua 5.1 syntax and all runtime/UI regressions.
- `python tools/validate_all.py`: PASS for all eleven civilization suites. Collection checks confirm 381 manifest files, 44 ordered SQL actions, project/manifest matching, XML control wiring and Lua 5.1 syntax for all 19 scripts.
- DirectXTex decoded all 300 DDS textures in the collection; no art changed in this audit.
- `git diff --check`: PASS.
- `python tools/build_mod.py`: PASS. Built the v15 folder, ZIP and Firaxis-compatible LZMA `.civ5mod`; native archive membership/integrity passed. ZIP CRC integrity also passed.
- Installed v15 into `Documents/My Games/Sid Meier's Civilization 5/MODS/Cool Wacky Civs (v 15)`. The installed manifest matches the build byte-for-byte and all 381 content MD5 hashes match. The existing v14 directory was retained; enable only v15 for a new audit-version game. Installation verification does not claim in-game activation.

## Automated regressions

- Both Genome branches: training and Gold/Faith completions during crises, reload, exact expiry-before-turn callback, original-survivor exclusion and upgrade persistence.
- Original/current/relocated/non-capital capture, ordinary Warrior, unrelated unit, bystander, duplicate callback, trade/liberation and peace cession; later genuine conquest remains eligible.
- Settler/Caravan/Cargo Ship veto, Worker/Infantry/Warrior/Auxiliary allowance, foreign-player allowance and expiry cleanup. Purchases are source-audited; native purchase UI has not been executed.
- Source-derived positive-food model with additive bonuses (including a mid-crisis increase), zero surplus, stored food, threshold cap, starvation, reload and compensation cleanup. This is a double of native math, not an engine run.
- Forty-eight population-protection combinations: 1/2/3/5/10/20, both Complex states, capitals/non-capitals, both branches. Fourteen existing army-size casualty-floor cases remain.
- Movement write counts prove unrelated cities are untouched; load-cache/death departure and entry repair are checked. Peace-read counts prove unrelated turns, ordinary refreshes and post-expiry turns do not scan; post-state events, distinct player/team IDs and scenario flags are tested.
- Missing/duplicate finish, low-health thresholds, interceptor/bystander exclusion, reload cleanup, immediate and queued support, out-of-order identity selection and city capture after unrelated combat generation.
- Source-derived attacks-made reset with one movement point and Blitz; ordinary units are untouched.
- Nested UI popup types, city/diplomacy entry/exit, normal-world restoration, mandatory decision over an overview, affordability, elimination and listener guard.
- SQL activation with populated external-reference sentinels, complete Auxiliary scalar/AI/resource/upgrade inheritance, Complex CP prerequisites/experience and Warrior resource exclusions.

## Remaining real game acceptance — not run

1. Exercise both crisis choices; train and buy Warriors during crisis and at its exact expiry, then save/reload and upgrade true survivors, pre-crisis troops and Genome rebuilds. Test v14 save migration separately from a new v15 game.
2. Capture an original and relocated enemy capital with the actual Pureblood; verify full heal, independent 35 HP, non-capital/ordinary-unit negatives, peace cessions, liberation and recapture-history guards.
3. Buy Settler/Caravan/Cargo Ship with eligible currencies during quarantine (blocked); Worker and conventional military remain available. Check active route recall.
4. Inspect native growth/food tooltips with WLTKD, religion, Purge and VP Happiness bonuses; confirm zero positive growth, retained stored food and natural starvation. Confirm phase expiry timing against native city-turn order. CP/custom MinimumFood effects bypass growth multipliers and need separate compatibility acceptance; the expected baseline has no such Viltrum city effect. Compensation is bounded at 16383 additional percentage points, far above ordinary ruleset bonuses; scenarios exceeding that require separate support.
5. Enter/leave City View, diplomacy/trade, Culture, Tech Tree, Economic/Military and other full-screen overviews; check nested screens and pending mandatory decisions. Modded screens that do not emit standard events require their own bridge.
6. Verify real garrison entry/exit, death, upgrades and ownership transfer; measure large-empire movement performance.
7. Test melee/ranged/city combat, enabled defensive support, withdrawal, RED veto, air interception/sweep, quick combat and animation queues. CP provides no universal combat ID; identity selection and bounded contexts are tested, but arbitrary other-mod combat reentrancy requires integration testing.
8. Deploy exactly seven tiles, verify one remaining move and attack/city capture afterward, repeat with Blitz and AA interception, and observe native AI deployment/army composition.
9. Test two-way peace deals, forced/vassal peace, lock expiry and scenario flag preservation through real serialization. Another script changing the same permanent flag during a lock remains indistinguishable from the mod's own mutation.

## Save and behavior changes

The v1 save-key namespace, choices, absolute timers, history and marker promotions are unchanged. Existing mistakenly granted Genome is retained because v14 recorded no training date; the fix applies to future training. The new binary dummy policies require updated definitions. No real saved-game upgrade is claimed; preserve backups and start a new game as the collection already recommends.

Intentional corrections: Genome begins after the primary crisis, relocated capitals qualify, peace cessions give no conquest reward, duplicate callback healing is blocked, below-threshold food stays intact and overflow food is capped, optional UI is view-gated, and external references are no longer duplicated. Resistance rounding, deployment range, combat/capture heal numbers, survivor floors, production/population percentages and all durations remain unchanged. Multiplayer/hotseat remain disabled.

## Exact audit file inventory

- `ViltrumEmpire/Lua/ViltrumRuntime.lua`
- `ViltrumEmpire/UI/ViltrumPanel.lua`
- `ViltrumEmpire/SQL/00_Viltrum_Core.sql`
- `ViltrumEmpire/SQL/01_Viltrum_Inheritance.sql`
- `ViltrumEmpire/SQL/02_Viltrum_Effects.sql`
- `ViltrumEmpire/SQL/10_Viltrum_Text.sql`
- `ViltrumEmpire/README.md`
- `ViltrumEmpire/docs/Validation.md`
- `ViltrumEmpire/docs/Files.md`
- `tools/create_viltrum.py`
- `tools/validate_viltrum_mod.py`
- `tools/tests/viltrum_mock.lua`
- `tools/tests/viltrum_assertions.lua`
- `PATCHNOTES.md`
- `CoolWackyCivs.civ5proj`
- `Cool Wacky Civs (v 15).modinfo` replacing `Cool Wacky Civs (v 14).modinfo`

`ViltrumPanel.xml` was inspected but unchanged. Art and the other ten civilizations' gameplay are unchanged. Ignored source snapshots and generated archives are not committed.

---

# Initial implementation validation — 5 October 2026

## Passed automatically

- All eleven existing/new civilization suites through `tools/validate_all.py`: full manifest/project matching, ordered activation, no VFS filename collisions, Lua 5.1 syntax, XML controls and installed CP SQL activation.
- DirectXTex decoded all 300 collection DDS textures, including all 31 Viltrum DDS files. Viltrum's 28 atlas rows have the declared dimensions and transparent corners. Atlas/leader source images were inspected visually; actual in-game UI was not.
- Viltrum database assertions: 1300/82/3 Warrior, Replaceable Parts, no resources; ordinary Auxiliary Infantry inherits current Infantry stats, cost/tech/upgrade and model; Complex inherits Academy and adds the requested values; persistent survivor markers, native flight columns, growth/crisis dummy policies, localized entries and unique IDs.
- Lua engine doubles exercise military/civilian/barbarian kills, temporary target thresholds and cleanup, personal capture healing, first conquest and recapture, Momentum activation/extension/cap, movement garrisons, Complex sale/rebuild, Conditioning, training XP and postdrop attack reset.
- Great Purge strong and preservation choices, permanent XP, same-turn General progress deduplication, AI stress decision and Culture formula.
- Scourge research and first-Warrior trigger, no-Warrior deadline, warnings, quarantine/Crusade effects, population floors/Complex protection, quarantine capture suppression and consumed history.
- Both casualty choices at 0, 1, 2, 3, 5, 10 and 30 Bloodline units: fourteen scenarios verify rounded losses, all survivor floors, conventional/civilian safety and synchronized RNG use.
- Genuine survivor markers/HP, new-unit Genome exclusion from survivor powers, native voluntary peace locks/expiry/pre-existing scenario flags, Last Pureblood conditional strength and current-capital full healing, crisis shortening, both recoveries, Golden Age cancellation, both extinction choices, General/XP/rebel spawns and Gold costs.
- Reload during Momentum, warnings, crises and post-event state; duplicate-listener guard; upgrade promotion continuity; unit-ID reuse; zero-city, elimination and revival safety. Quick/Standard/Epic/Marathon fallback timing survives reload.
- Final archive integrity and installed-file hashes are checked when packaging/deploying.

These tests execute the production Lua against explicit engine doubles. They do **not** prove native movement/AI/UI integration, actual combat damage or actual saved-game serialization.

## Fixes made during implementation

- Used named Colors columns after activation found the cache's additional ID column.
- Added Concepts.Advisor after the CP database rejected missing required metadata.
- Marked temporary policies IsDummy to avoid normal policy progression side effects.
- Restricted kill healing to melee/ranged battle participants so air interception cannot heal an uninvolved land defender.
- Initial implementation confirmed BattleJoined precedes strength/damage calculation. The v15 audit below additionally covers missing finishes, nested support and identity-keyed resolution.
- Replaced an initially conservative no-recall fallback after auditing the actual CP RecallTrader(true) binding.
- Initial implementation used native temporary war/peace flags. The v15 audit corrected the earlier documentation claim about missing peace dispatch: Release-5.4.2 dispatches PlayerCanMakePeace in CvDealClasses and DeclareWar/MakePeace in CvTeam, before native war-state changes. Flags retain ownership and scenario preservation.
- Granted native Blitz directly to actual Crusade survivors instead of duplicating its active-ruleset effects in another promotion.
- Counted the Purge choice turn as the first General-progress tick, preventing a 19-of-20-turn off-by-one; a full twenty-turn fixture verifies the total.
- Added the civilization/leader Civilopedia section keys and combat concept headers; a pending popup now dequeues immediately after player elimination.
- Updated both collection packaging validators to recognize the new UI XML as a non-VFS add-in, retaining SQL/UI import requirements.

## Engine/IGE checklist — not run

The specification's 50 tests are the playtest acceptance checklist. None has been marked as an actual in-game pass in this delivery. In particular:

1. Start a new game as Viltrum; inspect setup portrait, leader scene, Dawn of Man, map, pedia, flags, popup layout and tooltips.
2. Use IGE for combat kills, <50 HP Execution, below-half-health Planetbreaker, 35 HP city capture and Last Pureblood capital full heal. Check combat preview and actual damage.
3. Traverse rough terrain, mountains and coasts; deploy exactly seven tiles from eligible territory, attack afterwards and test March. Inspect visual model compatibility.
4. Capture/lose/recapture/raze/refound/liberate cities; sell/rebuild Complexes; check exact Production, resistance, garrison strength and Happiness in the native UI.
5. Play both Purge choices, both Scourge choices and both extinction choices. Inspect actual growth, production, healing approximations, Settler/purchase gates, route recall, spies and peace negotiations.
6. Save and reload at every phase and pending choice. Verify survivor promotions survive real upgrades, IDs and serialization; verify no rewards repeat or crisis timers reset.
7. Play against AI Thragg with other civs; observe army composition, decisions, survivor preservation, Gold and long-term balance. Exercise capital loss, elimination/revival and externally forced peace.
8. Inspect Lua.log and Database.log with DEBUG enabled for Viltrum. Gameplay has no frame polling. Multiplayer remains unsupported.

## CP source audit

Installed Community Patch database changes and local 5.4.2/5.4.6 source references were inspected. Additional primary source checks used release 5.4.2:

- [CvCombatInfo participant dispatch](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvGameCoreStructs.cpp)
- [Combat calculation and resolution](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvUnitCombat.cpp)
- [Player Lua bindings](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/Lua/CvLuaPlayer.cpp)
- [Team flags and voluntary peace rules](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvTeam.cpp)
