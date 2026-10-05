# Tokenized Intelligence validation

Implementation audit for collection version 16, 2026-10-05.

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

`python tools/build_mod.py` produces one unpacked v16 directory, ZIP and native
LZMA `.civ5mod`, then checks native archive file names and integrity. It refreshes
the tracked manifest. Build output is local and ignored by Git.

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
  **after** native promotion copying. Cleanup uses the post-conversion callback.
- `UnitCreated` supplies player ID first. Empire unit bonuses are reconciled there
  and after conversion; no expensive unit-movement hook is needed.
- `ChangeMoves` uses internal move units, so Route Optimization adds twice
  `MOVE_DENOMINATOR`. Mobility uses the native promotion field instead.

Source contract assertions run when the repo-local ignored API snapshots exist.
This audit avoids fabricated CP methods and optional unstable visibility hooks.

## Required engine smoke tests — not yet performed

Automated tests do **not** constitute a launched Civ V game, save-file roundtrip,
rendered Civ V UI or multiplayer test. The following remain manual acceptance:

1. Enable only v16 plus BNW/CP and start Standard as the Token Network; check
   selection art, unique entries, Civilopedia, flags, native unit animations and
   Lua.log/database.log. Start another civilization and confirm the meter is absent.
2. Generate to capacity, test each affordable Prompt and disabled reasons, inspect
   the tooltip, saturation timers, cache discounts and Clear Context cooldown.
3. Save with targeted and empire effects active; reload, verify exact Token/cache/
   saturation/cooldown state, then advance through expiry and a model transition.
4. Construct both replacements; employ each specialist type; compare city income,
   local Data Centre modifiers and displayed capacity. Capture/lose/raze cities.
5. Apply all Agent modes; upgrade, kill, gift and capture units with effects active.
   Confirm no promotion survives without valid owned state and no slot stays occupied.
6. Check growth and Happiness in occupied/resisting cities, routes appearing and
   disappearing, current production near completion and research tech switching.
7. Enter/exit city, diplomacy, Civilopedia, culture, tech tree, espionage, trade and
   victory screens; check no console overlap at 1024×768 and larger resolutions.
8. Repeat a short game on Quick/Epic/Marathon; let an AI Token Network play for many
   turns at peace and war. Enable debug logs to verify its one-action turn decisions.

Network/hotseat remain intentionally disabled by the existing collection manifest.
Player-isolated save records do not establish synchronized multiplayer transactions.
