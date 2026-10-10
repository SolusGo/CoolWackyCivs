# Validation and native testing checklist

Run `python tools/validate_lastcity_mod.py` for focused checks, `python tools/validate_all.py` for collection regressions, `python tools/build_lastcity_mod.py` for standalone packaging and `python tools/build_mod.py` for the collection. Tests clone the gameplay database read-only into memory; they do not edit installed mods or game caches. Lua tests execute the implementation with `lupa.lua51` and stateful native-API mocks.

Automated validation covers database activation/inheritance/localization, Lua 5.1 compilation, manifest hashes/VFS/load order, game speed intervals, resource accounting, cooldowns, quarantine, exactly-once rewards, expert caps, starvation recovery, crisis choices/eligibility, enemy route/domain safety, failed spawn/retreat outcomes, real siege rewards, veteran upgrades/ID reuse, Dawn completion, AI turns, persistence and UI wiring. On 2026-10-10, `validate_lastcity_mod.py` passed all focused checks, and `validate_all.py` passed all sixteen civilization suites. Both standalone and collection ZIP/Civ5Mod builds passed archive integrity checks. The focused suite includes all 45 crisis decisions, four speed profiles with 160-turn AI runs, strict native argument checks, delayed casualty deduplication, foreign conversion cleanup, island/open-water spawning, veteran upgrades/ID reuse, alternate save-bank recovery and real Council dispatch.

No actual Civ V game has been launched as part of this implementation. Engine integration, tactical AI, graphics, native turn order and balance require the following checks.

## Native smoke tests

- [ ] Enable standalone with BNW and CP; select The Warden and confirm Last Light, UA, UU, UB and stock fallback art.
- [ ] Enable collection v21 alone and confirm all sixteen civilizations; do not enable both packages.
- [ ] Found with the starting Settler; attempt training/purchasing/receiving/capturing another Settler and confirm no additional founding.
- [ ] Try capturing a foreign capital; sanctuary combat units cannot enter it. Gift a normal foreign city and confirm it is returned on the next turn without a crash, lost capital or lingering acquisition popup.
- [ ] Confirm unrelated civilizations can settle, train Settlers and capture cities normally.
- [ ] Build a District; verify the normal Granary/resource Food, +2 Provisions and +6 Housing.
- [ ] Compare income with Farms, Fishing Boats, pillage/repair, Waterworks and assigned Farmers. Count maintained combat units and excluded civilians.
- [ ] Preview/confirm all four rations, check cooldown, native Food surplus adjustment, fractional Morale and reload persistence.
- [ ] Accept, refuse and quarantine caravans. Save before/after each choice and during quarantine; check no duplicated Population or expertise. Let a caravan leave.
- [ ] Assign/unassign all six expertise types; exceed assignment/reserve caps and lose an expert. Verify actual Production/Science/Culture modifiers and local defender promotions.
- [ ] Test all five Morale thresholds, near/far combat defense, movement across the three-plot boundary, transfers and upgrades.
- [ ] Induce crowding, zero supplies, sustained shortages and recovery; verify gradual progression and bounded losses rather than an arbitrary defeat.
- [ ] Resolve each of the fifteen crises through all choices, with/without eligible expertise or stored Production. Test temporary militia expiration and persistent Housing damage/repair.
- [ ] Observe warning, assault and aftermath on inland/coastal/tiny-island/ice/mountain/packed maps. Check land routes, ship domains, role progression, prerequisite-tech fallbacks and bounded blocked-spawn retries.
- [ ] Defeat five waves; confirm a boss and +2% City Defense. Test fifteen Major Sieges for the +30% cap. Surviving participating Watch units gain ranks; newly trained units do not.
- [ ] Upgrade, capture and delete wave units; reuse IDs; ransom a city in CP-only; verify no false victory. Confirm boss aura expires after death, timeout withdrawal and native hostile-major city capture/elimination.
- [ ] Construct all infrastructure investments at their real native costs. Drop supplies during Dawn construction; restore them; survive the Final Night; confirm Humanity Endures, persistent aftermath and continuing ordinary victory conditions.
- [ ] Open/close all Council tabs, preview stale events, press Escape, enter city/diplomacy/production/other modal views, change the active player and reload. No panel should overlap major views or duplicate handlers.
- [ ] Play against an AI Warden: admissions, assignments, rationing, crises and production resolve without human popups or stalled turns. Check native tactical defenders stay useful.
- [ ] Repeat on Quick, Standard, Epic and Marathon, all map sizes, Huge with 22 majors and numerous city-states. Record actual turn times, visual layout, enemy targeting and long-run economic balance.

## Status terminology

“Implemented” means connected to game-state effects and registered components. “Automated pass” means mocked/static validation succeeded. Neither certifies native game behavior. Stock art, one orphan-gift exception, stored-Food growth, native tactics, CP-only barbarian ransom and narrative victory remain documented implementation compromises.
