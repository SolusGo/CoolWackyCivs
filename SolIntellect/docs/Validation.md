# Sol validation

The focused validator uses a read-only BNW database backup copied into SQLite memory, then applies the installed official CP schema. It deliberately changes the University/Public School baseline and injects a future scalar column to prove activation-time inheritance. Every installed building companion relation is compared, while the intended specialist Science and Institute GP additions are tested separately. The actual game database and saves are never edited.

Automated checks cover the canonical 3/4/5/7/10/15-turn reward boundaries, floors/minimum, Quick/Standard/Epic/Marathon/custom requirement scaling, Production modifiers/overflow independence, every production-order switch, immediate switch-back, active-building gold/faith purchases, free grants, fake completion hooks, instant active-turn completions, zero/negative costs, independent cities/players, World/National Wonders, Insight 1/2/3/4/5/5, the cap's notification behavior, specialist Culture floors and all installed specialist Science rows, Institute floors and additive GP rates, AI rewards and human-only notifications, queued research, duplicate completion/turn events, save/load during construction and an armed native cycle, capture/recapture, destruction, ID reuse, missing-city cleanup and interrupted/skipped turns.

Packaging checks cover SQL order, the runtime entry point, VFS flags, manifest hashes, all 26 DDS dimensions/alpha channels, legacy headers and static scene resolution. DirectXTex checks decode every texture when the local validator is available. The full collection validator checks compatibility with the other thirteen civilizations and all package assets.

## Source contracts

The implementation is based on CP v151/current 5.4.x source snapshots. Optional local assertions under `.tools/cp-v151-audit` verify these engine contracts against primary upstream source:

- [CvPlayer.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/master/CvGameCoreDLL_Expansion2/CvPlayer.cpp): native city production precedes `PlayerDoTurn`; `PlayerDoneTurn` is gated by `EVENTS_PLAYER_TURN` and runs at turn deactivation. Sol enables that option.
- [CvCity.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/master/CvGameCoreDLL_Expansion2/CvCity.cpp): `produce(BuildingTypes)` increments `m_iThingsProduced` before construction and its event; `popOrder` removes the head afterward; purchase callbacks have distinct gold/faith flags. Free-start-era grants do not increase the completion counter. Queue pushes dirty the specific city production information.
- [CvLuaCity.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/master/CvGameCoreDLL_Expansion2/Lua/CvLuaCity.cpp): native queue-order, specialist-count, completion-counter and speed-adjusted production-requirement bindings.
- [CvCityCitizens.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/master/CvGameCoreDLL_Expansion2/CvCityCitizens.cpp): specialist assignment changes emit city/game data dirty events. Native local specialist yields and general city GP modifiers handle the civilian specialist categories.

The Lua harness models the finishing native turn before `PlayerDoTurn`, a still-present completed queue head, native completion-counter changes, and synchronous dirty/research events. It does not approximate this timing with a turn-start-first mock.

## Live-engine acceptance still required

Automated verification cannot prove the closed-source Civ V UI's event delivery or visual rendering. Run these checks with the intended CP/VP installation in a new game:

1. Select Sol and confirm Sol Prime, icons, Dawn artwork, setup map, Civilopedia and the static diplomacy scene. Enable an AI Sol and confirm its normal city development.
2. Finish buildings in exactly 3, 4, 5 and 10 native city production turns. Verify 0%, 12%, 14% and 24%, respectively, using the displayed actual Production requirement. Repeat on another game speed.
3. Switch University to Unit and back, including returning before ending the same turn. Try replacing the head, popping it and reordering a queue. Confirm every interrupted streak restarts; appending behind an unchanged head should preserve the streak.
4. Buy the currently produced building after several turns with gold, then with faith where available. Test free-policy/free-start-era/Lua-created grants. Verify no research or Insight.
5. Finish a one-turn World/National Wonder, then five more in the same city. Verify independent Insight gain and a cap of five; purchases/free Wonders must grant none.
6. Work 0/1/3/6/10 mixed specialists and inspect native science yields and +0/+0/+1/+2/+3 Culture. Test CP Civil Servants, reassignment, selling the Archive, and saved/reloaded assignments.
7. Inspect a Reasoning Institute with every Insight value 0–5. Confirm +0/+0/+1/+1/+2/+2 Science and the additional +10% GP rate; five Insight should total +20% added GP rate with the Institute.
8. Capture a five-Insight city, recapture it and raze it. Confirm permanent Insight loss and no recycled city inheriting the original counters.
9. Save after three construction turns, reload and complete on the fourth. Save with no chosen technology after a burst, reload, select one and confirm the full bank applies once.

Same-turn interruption tracking depends on the normal CP/UI dirty events. Third-party scripts which change and restore the native queue without exposing an intermediate event cannot be observed by Lua; this is an engine interface limitation. Native instant-production scripts running specifically inside the armed next-turn city cycle and synthesizing the same production state/counter also cannot be distinguished from the engine's production path. Normal purchases and free grants are covered by separate native evidence. No whole-screen UI file is replaced to capture queue clicks.

Fresh-context reload tests deliberately retain stale `MapModData` and verify that saved construction/Insight data replaces it. A context-local `_G` guard prevents duplicate listeners only within the same add-in context.

No live Civ V playthrough or balance tuning is claimed by the automated suite.
