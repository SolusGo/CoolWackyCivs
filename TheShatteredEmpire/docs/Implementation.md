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

Bounds: 300 Chronicle entries, 12 personal Governor entries, 50 inactive Governors, 50 Emperors, 30 completed wars and 30 inactive factions. Active city and live-unit records grow with the actual empire. Rebel recruitment is at most eight per province, six active factions and 24 tracked live units per player. No map-wide per-turn plot scans or frame timers are used; local ranges are deduplicated for wrapping. Political intervals, deadlines, costs and temporary effects use the actual game speed TrainPercent; percentage bonuses retain their stated size.

Dummy buildings apply boolean state, never increment counts. Switching reforms, dormant Restoration and city captures remove prior effects. The Palace's scalar and companion effects are inherited once; Gold is added once. Legion upgrades keep a permanent lineage promotion; a separate boolean native promotion supplies conditional friendly-territory strength. Counterinsurgency uses the native barbarian modifier.

## Safe equivalents and remaining limits

- Factions use tracked barbarian armies, Governor records and native city yield/happiness penalties, rather than new major/city-state slots or forced city ownership changes. Normal barbarians can attack third parties. Tracked cleanup never deletes unrelated barbarians. Independence is simulated by negotiated autonomy; unrest cannot permanently trap a city.
- Defection safely replaces eligible stock soldiers with a barbarian unit. Experience and persistent promotions transfer; movement is exhausted. Spawn failure leaves the imperial soldier intact. Unique units from other mods are excluded.
- Defiance/revolt uses explicit local yield and Happiness pressure; there is no perpetual forced resistance. Replacement alone adds one turn of native resistance. No infrastructure is destroyed.
- Reforms supplement Social Policies. Military coup pressure is expressed through militarist Ambition, Oaths, succession and claimant wars; there is no separate arbitrary coup timer.
- Succession changes the internal reigning Emperor and records their traits/relationships. The diplomatic model remains The Last Emperor. The current ruler remains until a successor is selected; the Council concludes the reign at resolution.
- AI can pay, replace, negotiate, choose heirs/reforms and request nearby garrisons. It does not override construction queues or issue strategic declarations of war. Normal AI builds infrastructure and tactically fights rebels. These behaviors require engine playtesting.
- Farms and improvements are feasible when requested; changing ownership or war can later prevent completion. The compensation choice remains available. Foreign war demands are omitted to avoid unsafe diplomacy side effects. Camp and strategic requests show their plot coordinates.
- No extra Workers, technologies or starting buildings are supplied; stock civilization/handicap grants remain. Initial normal warrior-class units use the Legion override. Advanced-start and unusual map scripts should be checked in-game.
- Assets are original generated paintings plus the collection's native geometric icon style; stock Warrior models are inherited. No animated 3D leader or bespoke unit mesh is supplied.
- Multiplayer, hotseat, runtime engine verification and numerical balance are unverified. Adding a civilization requires a new campaign; existing v19 civ save keys are unchanged.
