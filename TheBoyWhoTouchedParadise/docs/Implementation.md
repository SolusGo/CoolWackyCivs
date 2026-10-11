# Implementation and CP audit

`Lua/ParadiseRuntime.lua` is the independent gameplay InGameUIAddin. The panel XML is a second add-in and never includes the runtime. `Lua/ParadisePersistence.lua` implements deterministic, length-prefixed, typed serialization. Save keys are `PARADISE_v1|playerID`; parsing never executes stored Lua and refuses to reset an unreadable existing journey. UI snapshots are copies. Humans are resolved by civilization type and active player, never by assuming player zero.

The generated SQL preserves every Amphitheater scalar except the names, portrait and additional GP modifier; it clones every installed `Building_*` companion table with a BuildingType column. These statements also copy rows supplied before collection activation. `create_paradise_database.py` inspects a disposable in-memory clone of the read-only CP cache/schema. The installed game database is never edited by development tools.

The baseline +5% GP modifier is the Trait. The capital Culture, single hosting city, pressure tiers, hope, memorial and fulfillment use native hidden buildings. Native `YIELD_GOLDEN_AGE_POINTS` is supported by CP's `Database Changes/WorldMap/Yields/CoreNewYields.xml`; `CvPlayer::GetGoldenAgePointsPerTurn()` sums city rates. Presence therefore uses an actual +2 GAP yield rather than a manual approximation. Native modifiers remain visible in normal yield calculations. Refresh compares current building counts before setting them.

The Last Dance has `MaxPlayerInstances=1`, 450 base Production and Radio prerequisite. `CityCanConstruct(playerID, cityID, buildingID)` checks the persistent additional criteria for every civilization. Lifetime totals and completed objectives never regress. Its production completion is handled idempotently; a captured Wonder never triggers fulfillment for its recipient. The fulfillment and memorial effects follow the current capital. Capital/city transfer handlers remove old effects before rebuilding the affected empire's legitimate ones.

## Audited signatures and native timing

The [v25 stability audit](Audit.md) rechecked these signatures and ordering against the matching Release-5.4.6 source and installed CP v151 UI. Paradise now explicitly enables `EVENTS_MINORS_INTERACTION` for PlayerCanGiftUnit as well as the event groups below; it never depends on another civilization enabling a hook. Vanilla hooks need no invented options.

| Hook | Signature / proof |
| --- | --- |
| CityConstructed | `(player, city, building, gold, faith)`, `EVENTS_CITY`. `CvCity::produce()` increments ThingsProduced and keeps the completed queue head through the callback. Free-start grants do not increment it; purchases have separate flags. |
| UnitCreated | `(player, unit, type, x, y)`, `EVENTS_UNIT_CREATED`. Called at the end of unit init, before native generated GP counters are incremented by the spawning caller. |
| UnitPrekill | `(player, unit, type, x, y, delay, killer)`, `EVENTS_UNIT_PREKILL`. Capture, delayed/final kill and deletion share one stable per-unit loss record. |
| UnitCaptured | `(byPlayer, byUnit, capturedPlayer, capturedUnit, willBeKilled, reason)`, `EVENTS_UNIT_CAPTURE`. Classify the hero loss while its source identity is available. |
| UnitConverted | `(oldPlayer, newPlayer, oldUnit, newUnit, isUpgrade)`, `EVENTS_UNIT_CONVERTS`. Exclude conversion births; keep captured heroes out of foreign effects. Cleanup requests delayed death because native init/convert can still hold a unit pointer. |
| PlayerGoldenAge | `(player, started, turns)`, `EVENTS_GOLDEN_AGE`. CP can emit the positive-duration hook for an extension; the persisted start/end state excludes extensions. |
| MinorAlliesChanged | `(minor, major, isAlly, oldFriendship, newFriendship)`, `EVENTS_MINORS`. Track first-ever alliance identity and how long an alliance lasted. |
| CapitalChanged | `(player, newCapital, oldCapital)`, `EVENTS_CITY_CAPITAL`. Reconcile both capital buildings once. |
| PlayerCanGiftUnit | `(player, minor, unit)`, `EVENTS_MINORS_INTERACTION`. Deny only the unique hero; leave ordinary gifting alone. |
| CityCaptureComplete | `(oldPlayer, isCapital, x, y, newPlayer, population, conquest)`. Clear transferred city effects, invalidate local timers, preserve stable city-loss claims. |
| UnitSetXY / GreatWorkCreated | Transfer presence immediately and update cultural objective progress on actual changes. |

Owner-turn clocks and the last applied game turn survive reload. A duplicate PlayerDoTurn does not advance pressure, recovery practice or timers. Gameplay handlers guard the civilization before city/unit scans; other civilizations do not trigger Paradise map scans. No handler scans the whole map.

## Generated GP proof and limitations

At UnitCreated, a pending identity includes owner, unit ID, creation turn, unit type, turn, owner clock and active challenge serial. The next safe callback or turn settles it against native post-creation evidence. Civilian specialist classes use `City:GetSpecialistUpgradeThreshold(unitClassID)`, which reflects class creation counts and respects CP's enabled `GLOBAL_TRULY_FREE_GP`. This handles Writers, Artists, Musicians and the shared Scientist/Merchant/Engineer pool without requiring unavailable Lua counter getters. Generals use `GetGreatGeneralsCreated(true)`; Prophets use the next faith cost. `CityTrained` excludes produced/purchased candidates; conversion callbacks exclude transfers. Direct InitUnit alone does not raise these thresholds and provides no reward.

The specialist threshold is owner-wide even though the getter lives on a city; the capital is valid for non-capital births. v25 checks a unit's Created claim before settling pending evidence, so an early duplicate callback cannot discard a genuine birth before its native counter increment. The existing serialized pending records and payout values are retained without migration. Prophet belief/trait cost changes and arbitrary native non-free script grants remain attribution limitations detailed in the audit.

CP exposes an Admiral threshold modifier but no Admiral count. `setNavalCombatExperienceTimes100()` creates a naturally earned Admiral before spending the accumulated meter. The candidate must therefore have naval experience at least `GreatAdmiralThreshold()` during UnitCreated, followed by the complete own-plus-team threshold increment. Free/scripted Admirals with no earned-meter proof do not qualify. This is conservative; third-party mods that change birth thresholds or manually manufacture a non-free native GP during an earned-meter crossing can affect attribution. Do not claim arbitrary third-party compatibility. Native combat-earned Admirals should still be checked in-game. The attainable specialist-based final objective does not require an Admiral.

The standard source rewards do not scale Dreams: achievement counts and lifetime requirements stay consistent across speeds. Duration scaling uses the installed GameSpeeds row. Pressure percentage penalties do not scale. Burst yields snapshot native city rates, and the research target is checked before spending; magic reserves the era and cost before native callbacks re-enter. Influence recipients are deterministic and checked for met/alive/peaceful status. `IsMinorPermanentWar` receives the **major's team ID**, not its player ID.

## Explicit design choices

- Hope uses CP `BuildingDefenseModifier=15`, which increases building defense rather than total city strength; UI/help report the supported effect.
- The Final Peak adds its Golden Age duration to any existing age. Its scripted age is not an earning/recovery source.
- Current cities celebrate through three scaled WLTKD turns, a visible native celebration with a modest growth benefit.
- Recovery practice needs eight owner turns of El Diez in any owned Potrero city during the active deadline, with no forced failures. After a failed deadline, the same attainable objective is available again after eight turns.
- Cultural development is two genuinely constructed Potrero cities plus a peak of two currently owned Great Works. Purchases/captured grounds remain useful, but do not fabricate a construction achievement.
- Memories are capped by unique milestone/category/era keys. Neither spendable Legacy nor career chapters are reproduced. The six requested Legacy Objectives are alternative final eligibility accomplishments, without another resource/progression system.
- The artwork portrays a fictional Argentine Number Ten figure because direct portrait generation was restricted. The Great Merchant supplies the compatible visible map model, with no Great Person actions inherited.

The exact original request is retained in `docs/OriginalDesign.md`. Implementation should be reviewed together with the focused automated tests and live smoke checklist.
