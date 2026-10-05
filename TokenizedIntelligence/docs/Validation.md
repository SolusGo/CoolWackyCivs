# Tokenized Intelligence validation

Implementation audit for collection version 17, 2026-10-05.

## Automated checks

`python tools/validate_token_mod.py` runs the actual SQL against a disposable
in-memory copy of the installed BNW gameplay database, expanded using installed
Community Patch DDL. The on-disk game cache is opened read-only. The retained
Community Patch v151 baseline DDL is also checked when available.

The checks cover exact Infantry, University and Research Lab scalar/companion
inheritance; unique class overrides; AI availability; dummy-building Happiness;
promotion strengths, Sight, Movement and land-domain targeting; seven Civilopedia
concepts; localization references; and all 28 atlas rows and image dimensions.

Lua 5.1 doubles execute the complete gameplay runtime at 67%, 100%, 150% and 300%
speed. They exercise generation and capacity overflow, specialist/infrastructure
income, nil and foreign targets, zero-token rejection, capacity/era gates, cache
discounts and switching, cumulative saturation/expiry (including the exact number
of reduced income ticks at every speed), all nineteen Prompts,
production and research completion guards, per-turn query limits despite tech
switching, movement repeat restrictions, Clear Context cooldown, saved active
effects, reloads retaining stale shared MapModData, context-local registration,
duplicate turn callbacks, model notification/slot progression,
Adaptive mode replacement, upgrade/death/reused IDs, captured Token-to-Token
cities, empire bonuses, trade origin counts, per-player isolation and AI spending.

Hardening regressions at all four speeds cover none→Light, equal-tier refresh,
Light→Heavy, Heavy→Critical, direct Light→Critical, and Heavy/Critical with one
income tick left followed by a new Light trigger. The stronger level and original
expiry survive both the action and reload. All three tiers receive exactly their
scaled number of reduced income ticks. Atomic/Information severity reduction is
unchanged. The existing `TOKEN_V1_P<id>_satLevel`/`satExpiry` pair needs no migration.

Clear Context previously zeroed saturation; it now retains the original tier and
expiry while restoring exactly 25% capacity, removing persistent effects/cache,
and preserving cumulative spending, Query/Route limits and the scaled cooldown.
All eight era capacities and +75/+500 building increments are verified at every
speed. A two-city case checks one Data Centre (+13.5 local modifier) and then two
(+26.5), including population, specialists and Cluster bonuses. Cache expiry at
its last valid tick and the following tick is checked across reloads and speeds.

Source-live conversion doubles cover all eight temporary promotions, same-owner
upgrades, Token-to-Token gifts and foreign/City-State recipients. Prekill tests
check immediate record/slot removal before delayed deletion. Capture/recapture,
razing/removal and ID reuse test both city and unit identities. Separate AI cases
check saving at low storage, Happiness, wounded wartime defense, wonder Production,
Research Query and at most one successful action per own turn.

Specialist UI doubles verify +15 per Scientist, +5 additional Cluster income,
assignment/removal and dirty events while city view hides the UI. Existing
`SerialEventGameDataDirty` and `SerialEventCityInfoDirty` listeners suffice;
no specialist listener or timer was added. Six named major-screen popup transitions
are exercised through the existing callbacks; actual screen event wiring/rendering
still requires the live checks below.

Additional checks exercise three simultaneous effects at Information, live
promotion cancellation, route limits after reload, 500 turns of capacity-safe
income, and military AI response. UI doubles execute real console callbacks to
verify owned targeting, disabled costs, execution revalidation, full-slot targeted
refresh, city/diplomacy/nested popup hiding, Escape, active-player changes, unrelated
civilization hiding and network-mode hiding. There are no periodic UI updates or
whole-map scans.

`python tools/validate_all.py` runs all twelve civilization suites, checking the
single project's 420 files, 48 ordered SQL actions, manifest hashes/VFS flags,
Lua 5.1 syntax for 21 files, XML controls, combined SQL activation, inherited
effects, source references and the existing civilizations' regression tests.
DirectXTex validates headers and decoded pixels for all 331 collection DDS files.

`python tools/build_mod.py` produces one unpacked v17 directory, ZIP and native
LZMA `.civ5mod`, then checks native archive file names and integrity. It refreshes
the tracked manifest. Build output is local and ignored by Git.

## Results — 2026-10-05

- `python tools/validate_token_mod.py`: passed installed/current and retained CP
  v151 SQL checks, all four speeds, Lua 5.1 lifecycle, source contracts and UI doubles.
- `python tools/validate_all.py`: all twelve civilization suites passed, including
  combined activation, 420 project files, 48 SQL actions and all 331 DDS decodes.
- `python tools/build_mod.py`: built v17 directory, ZIP and native LZMA `.civ5mod`;
  archive names and integrity passed.
- Restoring either original saturation implementation in an isolated Lua double
  made the new regressions fail, confirming they detect both reported bugs.
- `git diff --check`: passed. Original Token artwork and balance were preserved.

## Community Patch contracts

Reviewed official [Release-5.4.2 source](https://github.com/LoneGazebo/Community-Patch-DLL/tree/Release-5.4.2):

- Team research belongs to `team:GetTeamTechs()`, whose Lua object exposes
  `GetResearchCost`, `GetResearchProgress`, and `ChangeResearchProgress(tech, amount, playerID)`.
- `SetPopulation` supplies **x, y, old population, new population**, not player ID.
  The handler resolves the city's current owner from its plot.
- `CityConstructed` supplies player ID first, so the refresh handler deliberately
  ignores extra arguments.
- `CityCaptureComplete` supplies old owner, capital flag, x, y, new owner first.
  The handler accepts those fields and strips captured temporary buildings.
- `UnitConverted` supplies old owner, new owner, old ID, new ID, upgrade flag
  **after** native promotion copying but **before** source deletion. Cleanup now
  explicitly removes the old unit's targeted record before reconciling both owners;
  a still-live source object cannot keep its Prompt slot occupied.
- Direct `CvUnit::gift` calls `convert(this, false, true)`, so it uses that hook.
  Distant City-State gifts instead snapshot the source, then kill it without
  `UnitConverted`. All eight temporary promotions now have `LostOnGifting=1`,
  which CP's incoming gift delivery checks after creating the recipient unit.
- `UnitPrekill(player, unitID, type, x, y, delay, killer)` is available both through
  CP's option and its fallback Lua hook. The new listener only removes source
  records/promotions and emits the state change; it does not reconcile or scan
  before native deletion. Dead/delayed-death units cannot receive targeted effects.
- Both `DoAddSpecialistToBuilding` and `DoRemoveSpecialistFromBuilding` mark
  `GameData_DIRTY_BIT` and `CityInfo_DIRTY_BIT`, covering the existing UI listeners.
- `UnitCreated` supplies player ID first. Empire unit bonuses are reconciled there
  and after conversion; no expensive unit-movement hook is needed.
- `ChangeMoves` uses internal move units, so Route Optimization adds twice
  `MOVE_DENOMINATOR`. Mobility uses the native promotion field instead.

Source contract assertions run when the repo-local ignored API snapshots exist.
This audit avoids fabricated CP methods and optional unstable visibility hooks.

## Required engine smoke tests — not yet performed

Automated tests do **not** constitute a launched Civ V game, save-file roundtrip,
rendered Civ V UI or multiplayer test. The following remain manual acceptance:

1. Enable only v17 plus BNW/CP and start Tokenized Intelligence on Standard.
   Check selection/leader/Dawn/map art, unique entries, flags, animations and logs.
2. Verify the Token display, source tooltip, Console, targets and disabled reasons.
   Confirm it remains absent for another civilization.
3. Trigger Light, Heavy and Critical; check penalties and duration income ticks.
4. With Critical at one turn remaining, make a spend that normally triggers Light.
   Confirm its expiry does not move; repeat with Heavy.
5. Use Clear Context during saturation. Confirm the quarter-window refill,
   persistent effect/cache removal, retained saturation and unchanged Query/Route
   restrictions and cumulative spending. Check its 15-turn scaled cooldown.
6. Save/reload during saturation, including just after the weaker spend; verify
   the same level, expiry and remaining reduced income ticks.
7. Save/reload with city, unit and empire Prompts active; verify identity, slots,
   replacement/refresh, cache and normal expiration. Check v16 Token save records.
8. Assign/remove Scientists and confirm immediate displayed income/tooltip changes,
   including the Cluster +5. Check updates after leaving city view.
9. Build a Data Centre in City A only; verify +10% on A's complete contribution.
   Add one in City B; verify both modifiers apply locally exactly once. Check
   capacity additions and a short Quick/Epic/Marathon game.
10. Apply each Agent/Tactical/Simulation mode and empire combat effects; upgrade,
    convert, capture, gift to a player/City-State (direct and distant), and kill.
    Confirm recipient cleanup and immediate source slot/saved-record release.
    Capture/recapture/raze a Growth-targeted city and check eventual ID reuse.
11. Enter/exit city view, leader diplomacy, Culture Overview, Civilopedia, Tech
    Tree, Espionage, Trade and Victory screens, including nested popups. Check
    no persistent Console overlay at 1024×768 and larger resolutions.
12. Let an AI Token Network play several dozen turns at peace/war and while unhappy.
    Verify sensible spending, low-bank saving and at most one action per own turn.

Additional CP edge to inspect live: destroying a City-State with a distant gift
in transit returns the snapshot to its donor using `bReturn=true`, which bypasses
native `LostOnGifting`. CP applies that snapshot after `UnitCreated`. The existing
next-own-turn/load/explicit-action reconciliation removes stale targeted promotions,
but immediate post-return cleanup is not guaranteed by `UnitConverted` or the new
gift-loss flag. This rare return path remains a documented limitation; no movement
polling or fabricated post-gift hook was added.

Network/hotseat remain intentionally disabled by the existing collection manifest.
Player-isolated save records do not establish synchronized multiplayer transactions.
