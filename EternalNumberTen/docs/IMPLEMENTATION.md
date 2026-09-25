# Implementation notes

`Lua/MessiRuntime.lua` owns all mutable gameplay. Every Legacy source calls the exported `MapModData.MessiLegacy.ChangeMessiLegacy(playerID, amount, sourceKey)` function. Chapter state, Era-first rewards, Assist counters, Resilience times, delayed La Masia state, per-city Production expiry, quest snapshots, Epilogue count, and permanent Tourism are stored with player-scoped save keys.

The SQL layer uses hidden policies for effects the Community Patch can apply natively and dummy buildings only for variable city-local counts or timed modifiers. This prevents save/load drift and avoids recomputing permanent bonuses by hand.

Formation scans run only for the affected civilization at `PlayerDoTurn`. City refreshes run on the same turn boundary and relevant construction, founding, capture, alliance, technology, and chapter events. There are no per-frame map scans. The UI has a throttled refresh callback but reads only the active player's exported state.

`Lua/MessiRuntime.lua` and `UI/MessiLegacyPanel.xml` are separate `InGameUIAddin` entries. The panel never includes the runtime and tolerates `MapModData.MessiLegacy` being unavailable during its initial refresh, so gameplay initialization does not depend on the optional interface.

City-State status changes use the Community Patch `MinorAlliesChanged(iMinor, iMajor, bIsAlly, iOldFriendship, iNewFriendship)` event with `EVENTS_MINORS`. The callback updates the persisted alliance snapshot immediately, making the turn fallback idempotent. Unit ownership conversion uses the documented five-argument `UnitConverted` event with `EVENTS_UNIT_CONVERTS`; its promotion refresh is idempotent with `UnitUpgraded`.

The runtime enables exactly the CP event groups it consumes: `EVENTS_BATTLES` (`BattleStarted`, `BattleJoined`, `BattleFinished`), `EVENTS_CITY` (`CityTrained`, `CityConstructed`), `EVENTS_GOLDEN_AGE` (`PlayerGoldenAge`), `EVENTS_MINORS` (`MinorAlliesChanged`), `EVENTS_UNIT_CONVERTS` (`UnitConverted`), `EVENTS_UNIT_CREATED` (`UnitCreated`), `EVENTS_UNIT_PREKILL` (`UnitPrekill`), and `EVENTS_UNIT_UPGRADES` (`UnitUpgraded`). `PlayerDoTurn`, `PlayerCityFounded`, `CityCaptureComplete`, and `TeamTechResearched` are available without an additional CP option. Unrelated event groups are not enabled by this civilization.

Assist attribution uses `BattleStarted`, `BattleJoined`, and `UnitPrekill`: the victim remains available at `UnitPrekill`, and the battle roster identifies the killer so the adjacent support unit can be required to be a different unit. The reward counter is player-turn scoped and persisted for unusual save timing.

World Wonders are classified by `BuildingClasses.MaxGlobalInstances`; Great People are classified by `SPECIALUNIT_PEOPLE` with a Great Person class fallback. Replacement buildings and free buildings are detected through live city building queries.

Football Academy Gold counts qualifying Academy plots, not their adjacent tiles. Each Academy whose working city contains at least one building with specialist slots contributes one Gold dummy-building stack to that city, so one Academy cannot create several Gold by surrounding-plot count.

Chapter V quest completion uses a documented fallback because current Community Patch source exposes quest queries and reward modifiers but no quest-completed Lua event. A disappearing displayed quest plus increased Influence is treated as completion. This is intentionally conservative: expiry, revocation, and war cancellation do not normally increase Influence.

The package remains marked single-player only. Runtime state is player-scoped and deterministic where practical, but the collection's existing interactive UI systems have not been multiplayer synchronization tested.
