# Implementation and CP contracts

The only `InGameUIAddin` loads `ImperialAdministration.xml`, whose paired script includes `ImperialCore`. The core owns gameplay and registers handlers for every matching human/AI player independently of opening the screen. Included modules have unique VFS basenames. The context guard prevents repeat includes; fresh contexts load the game save database. UI sends `LuaEvents.ImperialRequest`; the gameplay handler validates ownership, stable Governor/succession identity, Gold, Authority, prerequisites and cooldowns before acting.

## Verified native interfaces

The local `.tools/cp-v151-audit` contains CP native source used by the repository. The automated source audit checks registration and critical signatures. Active schema checks use a read-only backup of `Civ5DebugDatabase.db`, copy it into memory and apply installed CP schema updates. Original caches are never edited.

- `PlayerDoTurn(player)` drives the once-per-turn simulation.
- `PlayerCityFounded(player,x,y)` reconciles Governors and starting entitlements.
- `CityCaptureComplete(oldOwner,wasCapital,x,y,newOwner,population,conquest)` clears namespace dummy buildings and updates territorial records.
- `CityConstructed(player,cityID,buildingID,...)` checks demands and prestige.
- `CityTrained(player,cityID,unitID,...)` establishes the actual recruiting province.
- `UnitCreated(player,unitID,unitType)` registers land soldiers.
- `UnitConverted(oldOwner,newOwner,oldID,newID,isUpgrade)` moves lineage/Oath records before the old unit is killed; CP copies promotions and names, but does not copy ScriptData. No ScriptData rewriting is used here.
- `UnitPrekill(player,unitID,type,x,y,delay,killer)` processes final kills once. Delayed kill notifications are ignored.
- `CombatEnded(attackerPlayer,attackerUnit,inflictedDamage,finalDamage,maxHP,defenderPlayer,defenderUnit,inflictedDamage,finalDamage,maxHP,interceptorPlayer,interceptorUnit,damage,x,y)` uses final damage to recognize kills and capped defensive legitimacy.
- Native `Player:CanFound(x,y)` enforces CP settlement eligibility. `Player:Found(x,y)` executes the complete founding pipeline. `InitCity` is deliberately avoided because it bypasses normal founding behavior. Unavailable sites produce Settlers.
- `Player:CanBuild(plot,build,0,0)` uses CP's integer optional flags; build availability prevents impossible Farm/resource petitions.
- City/Unit/player methods, standard UI events and static building/promotion columns are checked against CP bindings and real schema.

SQL enables the required CITY, CITY_FOUNDING, PLAYER_TURN, UNIT_CREATED, UNIT_CONVERTS, UNIT_PREKILL, RED_COMBAT and RED_COMBAT_ENDED options. The RED parent switch is necessary for CombatEnded. Missing optional events are logged only in debug mode; turn reconciliation retains city/unit cleanup. Correct upgrade lineage requires CP's enabled conversion hook.

## Persistence and bounds

Version-1 saves use `SHATTERED_V1_P<player>_` keys. A deterministic length-prefixed serializer stores only numbers, strings, booleans and tables; it never evaluates saved code. Two chunked banks with checksums recover the preceding complete snapshot after corruption. Migration fills missing state fields and rejects newer schemas. Reentrancy flags are context-local in practice and cleared on load. Turn markers, entitlements, deadlines, completed eras and cooldowns prevent repeat grants, rerolls and reward duplication.

Bounds: 300 Chronicle entries, 12 personal Governor entries, 50 inactive Governors, 50 Emperors, 30 completed wars, 30 inactive factions and 256 capture-event identities per player. Active city and live-unit records grow with the actual empire. Rebel recruitment is at most eight per province, plus a separate two-defection allowance, six active defections empire-wide, six active factions and 24 tracked live units per player. No map-wide per-turn plot scans or frame timers are used; local ranges are deduplicated for wrapping. Political intervals, deadlines, costs and temporary effects use the actual game speed TrainPercent; percentage bonuses retain their stated size.

Dummy buildings apply boolean state, never increment counts. Switching reforms, dormant Restoration and city captures remove prior effects. The Palace's scalar and companion effects are inherited once; Gold is added once. Legion upgrades keep a permanent lineage promotion; a separate boolean native promotion supplies conditional friendly-territory strength. Counterinsurgency uses the native barbarian modifier.

## Safe equivalents and remaining limits

- Factions use tracked barbarian armies, Governor records and native city yield/happiness penalties, rather than new major/city-state slots or forced city ownership changes. Normal barbarians can attack third parties. Tracked cleanup never deletes unrelated barbarians. Independence is simulated by negotiated autonomy; unrest cannot permanently trap a city.
- Defection safely replaces eligible stock soldiers with a barbarian unit. Experience and persistent promotions transfer; movement is exhausted. Spawn failure leaves the imperial soldier intact. Unique units from other mods are excluded.
- Defiance/revolt uses explicit local yield and Happiness pressure; there is no perpetual forced resistance. Replacement alone adds one turn of native resistance. No infrastructure is destroyed.
- Reforms supplement Social Policies. Military coup pressure is expressed through militarist Ambition, Oaths, succession and claimant wars; there is no separate arbitrary coup timer.
- Succession changes the internal reigning Emperor and records their traits/relationships. The diplomatic model remains The Last Emperor. The current ruler remains until a successor is selected; the Council concludes the reign at resolution.
- AI can pay, replace, negotiate, choose heirs/reforms and request nearby garrisons. It does not override construction queues or issue strategic declarations of war. Normal AI builds infrastructure and tactically fights rebels. These behaviors require engine playtesting.
- Farms and improvements are checked against technology/build legality when requested. Lost ownership, resources or invalid targets cancel impossible petitions without penalties. Financial requests remain the fallback. Foreign war demands are omitted to avoid unsafe diplomacy side effects. Camp and strategic requests show their plot coordinates.
- No extra Workers, technologies or starting buildings are supplied; stock civilization/handicap grants remain. Initial normal warrior-class units use the Legion override. Advanced-start and unusual map scripts should be checked in-game.
- Assets are original generated paintings plus the collection's native geometric icon style; stock Warrior models are inherited. No animated 3D leader or bespoke unit mesh is supplied.
- Multiplayer, hotseat, runtime engine verification and numerical balance are unverified. Adding a civilization requires a new campaign; existing v19 civ save keys are unchanged.

## Hardening report — 2026-10-10

Peacetime `CHARTER` pays the half-scale provincial Gold price and 5 Authority; wartime `CHARTER` pays the double-scale price and 10 Authority, even for a previously autonomous province. Both require a Palace. The peacetime branch accepts loyal/discontented provinces, adds 15 Loyalty and 12 Ambition, and cannot be repeated. The wartime branch resolves only the matching active Governor faction, guarantees at least 70 Loyalty, adds 20 Ambition and stores hereditary privileges. Those privileges add 0.5 Ambition each political interval and survive administrative replacement. The +2 petition reward remains; completed-war rewards now follow the outcome rules below. Reconciliation still costs 15 Authority. AI selects the first affordable settlement through the same action validator.

Faction recruitment budgets are unchanged. `defectionLimit` persists independently of the budget and defaults to two. Each successful defection reserves its allowance before native death callbacks, creates a safe replacement first, transfers experience/permanent non-imperial promotions and then kills the original. Imperial Legion free promotions are explicitly stripped from the rebel. Two-per-faction, six-across-active-factions and 24-live-rebel limits still apply. Legacy factions that already spent more than two slots retain their historical count and receive no reopened slots.

Petitions now exclude chartered Governors and verify current technology, build legality, territory, strategic resource/improvement matching and target validity. Pillaged Farms count only when repair is feasible. Impossible requests are cancelled without Loyalty/Ambition penalties, while valid expiry retains the existing penalty. Completion clears the petition before rewards; deadlines remain saved. Construction checks only that city's request, and turn generation records the last request turn to enforce the notification limit. Replacing a Governor clears the old request.

The initial hardening required revealed starting plots; the founding correction below supersedes that visibility restriction. A bounded local flood visits passable land only within eight tiles, including canonical wrapping coordinates; sea/mountain barriers cannot be crossed. Normal spacing, rival starts, ownership and occupancy remain checked. Each entitlement records an intention before `Found`/`InitUnit`; callbacks complete it, and load recovery recognizes the previously created city or Settler. Existing Settler IDs are excluded when recovering an interrupted grant. A completed entitlement remains spent if its city/unit later disappears. Freshly introduced state in an established game cannot grant free cities, including a newly founded late-game capital. Saves already recording a legitimate starting operation can resume it.

`I.Commit` queues work in the existing Lua owner. A synchronous transaction depth coalesces nested city/unit callbacks, AI actions and parent turn commits into one final snapshot per affected player. Outermost completion flushes immediately; there are no timers or delayed player-action saves. City caches compare effect signatures only for dirty cities, or across the empire when reform/council/restoration conditions change. Unit creation/conversion marks individual promotions dirty; Authority crossing 60 or Dictatorship changes refresh the army, folded into the turn's existing unit pass when possible. Caches are transient and rebuilt on reload. Combat records still save because battles/Oaths/Chronicle are meaningful state changes. A closed Administration screen refreshes its status only when displayed Authority changes.

Additional code-supported fixes:

- Native conversion loses conditional promotions before `UnitConverted`; upgraded Legions now regain the correct active bonus immediately. Ownership changes refresh the recipient Empire or remove imperial promotions from a foreign owner.
- A rebel created as an Imperial Legion inherited its unit-type free Discipline promotion; it now loses imperial markers while keeping appropriate veteran promotions.
- Governor replacement reset provincial autonomy; autonomy and hereditary privileges now survive replacement in the same active city.
- Retired Governors were reactivated after recapture, retaining stale petitions/allegiances. Recapture now appoints a fresh Governor; faction identity checks reject the retired one.
- Combat could grant Prestige through an obsolete home-Governor ID; it now checks the recorded identity and unit birth.
- Repeated city-loss callbacks charged Authority/reign loss twice; bounded saved capture identities prevent replay, including after reload.
- Optional civil-war joiners contributed troops but omitted defections from the Chronicle totals; both totals now include them.
- Dead rebel records occupied the global live-army cap until the next turn; counting now validates identities and removes stale records immediately.
- City loss could leave Restoration active until the next turn despite Authority falling below 60; capture handlers now recalculate it immediately.
- CP rejects starting another copy of queued Walls when `CanConstruct` uses `bContinue=0`; ongoing Walls petitions use the verified integer continuation flag so valid construction is not cancelled.
- Creation scanned the whole army and construction checked all provinces; both now target the affected object. AI collects idle garrison candidates once per decision pass.

Save keys, schema version 1, mod IDs and package versions remain unchanged. Migration fills `startEligible` and missing faction allowances, clears transient reentrancy flags, and leaves existing Authority, Governors, factions, heirs, chronology and completed entitlements intact. New settlement/capture/pending-grant fields use the existing serializer; no ScriptData, custom DLL or ModBuddy dependency is introduced. Older code will ignore new political fields, so rolling back the code also rolls back their effects.

Exact modified/added files for this update:

```text
TheShatteredEmpire/Lua/ImperialAI.lua
TheShatteredEmpire/Lua/ImperialCore.lua
TheShatteredEmpire/Lua/ImperialEvents.lua
TheShatteredEmpire/Lua/ImperialGovernors.lua
TheShatteredEmpire/Lua/ImperialLegions.lua
TheShatteredEmpire/Lua/ImperialLoyalty.lua
TheShatteredEmpire/Lua/ImperialPersistence.lua
TheShatteredEmpire/Lua/ImperialRebellions.lua
TheShatteredEmpire/Lua/ImperialReforms.lua
TheShatteredEmpire/Lua/ImperialStartingCities.lua
TheShatteredEmpire/UI/ImperialAdministration.lua
TheShatteredEmpire/SQL/10_Imperial_Text.sql
TheShatteredEmpire/The Shattered Empire (v 1).modinfo
Cool Wacky Civs (v 20).modinfo
TheShatteredEmpire/README.md
TheShatteredEmpire/CHANGELOG.md
TheShatteredEmpire/docs/Implementation.md
TheShatteredEmpire/docs/Validation.md
PATCHNOTES.md
tools/validate_shattered_mod.py
tools/benchmark_shattered.py
tools/tests/shattered_mock.lua
tools/tests/shattered_hardening_assertions.lua
tools/tests/shattered_defection_assertions.lua
tools/tests/shattered_stress_assertions.lua
```

## Final founding and civil-war correction — 2026-10-10

The founding defect combined limited normal sight with a requirement to choose an already revealed site. The old mock exposed the entire map and then overrode native fog checks in map tests, masking the ordinary start failure. The reward defect counted autonomy, concessions and reconciliation as `victories`, granting the military completion reward for peaceful wars.

### Founding investigation and implementation

The pinned [CP Release-5.4.2 player source](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvPlayer.cpp) rejects unrevealed plots in `canFoundCityExt`; `foundCity` calls that validator. The [player Lua binding](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/Lua/CvLuaPlayer.cpp) exposes no force parameter. Removing our fog predicate alone therefore cannot fix founding. `PlayerCityFounded` runs after native creation, so the existing pending intent must precede `Found`.

The retained CP v151 `CoreWorldChanges.sql` sets `MinDistanceCities` to 3 for every world; `MIN_CITY_RANGE=3` is the fallback. The [native site evaluator](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvSiteEvaluationClasses.cpp) rejects distance **≤3**, requiring city centers at least four plots apart. It also handles terrain, features, ownership, neighboring foreign territory, happiness through the player validator, and other native restrictions. These checks remain authoritative.

Stock Warrior/Settler `BaseSightRange` is 2 in the read-only BNW database. [Native unit visibility](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvUnit.cpp) adds promotion/handicap/AI modifiers; terrain affects actual sight. Owned plots supply one-tile border sight, so a normal capital's initial ring commonly exposes only about two tiles from its center. That can reveal no legally spaced province.

The local eight-tile flood and deterministic ranking now consider connected unseen land. Water, mountains, impassable terrain, city/unit occupancy, rival territory, rival starts within six plots and existing major-city spacing are prefiltered. Natural/pseudo-natural wonders and no-city features are excluded. Resource scoring uses only revealed tiles. Each selected candidate records `pendingCity` with `revealWasHidden` before native callbacks; the native validator still decides whether to found. Rejected candidates try the next local choice; only exhausted legal choices fall back to a Settler. Search bounds, 2/1/1 populations, the sole capital, Legion override and two-entitlement identity rules remain unchanged.

The [plot Lua binding](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/Lua/CvLuaPlot.cpp) verifies `SetRevealed(team,value,1,-1)`, `GetVisibilityCount(team)` and `GetFeatureType()`. The terrain-only flag is an integer. Only the candidate tile is exposed, with no scouting unit. Failed probes clear that terrain bit unless native sight or a city now exists; successful founding retains normal city sight. Pending recovery also cleans an interrupted temporary reveal. Callback errors release the starting lock and restore failed-probe fog before propagating.

[Native plot revelation](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.2/CvGameCoreDLL_Expansion2/CvPlot.cpp) adjusts the team's area reveal count in both directions. Terrain-only mode avoids owner/improvement/route discovery; passing no unit avoids scouting XP/yields. However, wonder discovery occurs outside that guard, so wonders must never be probed. The DLL also updates tactical/exploration bookkeeping and an ever-revealed-major marker; Lua cannot roll every side effect back. CP v151 defaults `EVENTS_TILE_REVEALED` off, and this collection does not enable it. Other mods enabling that hook could observe temporary probes and need an engine compatibility check. Native city sight can legitimately discover nearby wonders, including through the collection's existing discovery hook.

These source checks use the repository's pinned CP release, plus the retained v151 schema/configuration. They do not establish that every v151-distributed DLL or map-script variant behaves identically. Pangaea, Continents and island scripts retain native terrain/spacing validation without script-specific overrides; synthetic local fixtures cover their geographic patterns. Generated maps, native line of sight, AI caches and UI rendering still require a real CP game.

### Civil-war outcomes, balance and saves

New active wars store suppressed, negotiated, exhausted, lost and undocumented counters. Only `SUPPRESSED` is military; `AUTONOMY`, `CONCESSION` and `RECONCILED` are negotiated. Factions become inactive before native troop cleanup, preventing reentrant reward duplication. A missing, retired, replaced or lost Governor/city cannot earn suppression credit. Per-faction Chronicle prose and final war records distinguish force, compromise, exhaustion and territorial loss; Overview shows the stored breakdown and actual completion Authority gained.

| Final outcome | Completion Authority |
|---|---:|
| Every faction militarily suppressed | +10 |
| Every faction negotiated | 0 |
| Clean mixture of military and negotiated results | `floor(10 × suppressed / total)` |
| Any exhausted, lost or undocumented resolution | 0 |

Suppression still gives +5 per faction, or +7 under Monarchy. One suppression among three clean participants adds +3 at completion; two add +6. Individual settlement prices, autonomy, hereditary Ambition, reconciliation, faction exhaustion consequences and cooldowns retain their prior values. Authority remains clamped to 0–100; history/UI report the amount actually gained after clamping. Peaceful reunification and surviving provinces retain the existing collapse-resolution and stability-based Restoration progression.

Version-1 keys, dual-bank encoding, mod IDs and package versions remain unchanged. Older active wars reconstruct outcomes once from retained matching faction records. Resolved records already pruned are marked undocumented, never inferred military from the ambiguous legacy `victories` counter. Subsequent faction resolution increments exactly once; `victories` now mirrors military suppression. Completed historical war records and their already-paid rewards are untouched and labelled legacy in the UI. Governors, Oaths, dynasty, pending grants and Restoration records persist without resetting or regranting rewards. Editable localization now matches the previous hardening SQL and includes the new outcome text.

Exact modified/added files for this correction:

```text
Cool Wacky Civs (v 20).modinfo
README.md
PATCHNOTES.md
TheShatteredEmpire/CHANGELOG.md
TheShatteredEmpire/README.md
TheShatteredEmpire/docs/Implementation.md
TheShatteredEmpire/docs/Validation.md
TheShatteredEmpire/Lua/ImperialPersistence.lua
TheShatteredEmpire/Lua/ImperialRebellions.lua
TheShatteredEmpire/Lua/ImperialStartingCities.lua
TheShatteredEmpire/SQL/10_Imperial_Text.sql
TheShatteredEmpire/The Shattered Empire (v 1).modinfo
TheShatteredEmpire/UI/ImperialAdministration.lua
tools/shattered_localization.py
tools/validate_shattered_mod.py
tools/tests/shattered_hardening_assertions.lua
tools/tests/shattered_mock.lua
tools/tests/shattered_war_outcomes_assertions.lua
```
