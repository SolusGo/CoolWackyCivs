# Validation and native testing checklist

Run `python tools/validate_lastcity_mod.py` for focused checks, `python tools/validate_all.py` for collection regressions, `python tools/build_lastcity_mod.py` for standalone packaging and `python tools/build_mod.py` for the collection. `validate_all.py` also runs `validate_modbuddy_entrypoints.py`: when the Firaxis SDK is installed, it invokes only the native manifest task and compares all eighteen entry points against the Python package. Tests clone the gameplay database read-only into memory; they do not edit installed mods or game caches. Lua tests execute the implementation with `lupa.lua51` and stateful native-API mocks.

Automated validation covers database activation/inheritance/localization, Lua 5.1 compilation, manifest hashes/VFS/load order, game speed intervals, resource accounting, cooldowns, quarantine, exactly-once rewards, expert caps, starvation recovery, crisis choices/eligibility, enemy route/domain safety, failed spawn/retreat outcomes, real siege rewards, veteran upgrades/ID reuse, Dawn completion, AI turns, persistence and UI wiring. On 2026-10-10, `validate_lastcity_mod.py` passed all focused checks, and `validate_all.py` passed all sixteen civilization suites. Both standalone and collection ZIP/Civ5Mod builds passed archive integrity checks. The focused suite includes all 45 crisis decisions, four speed profiles with 160-turn AI runs, strict native argument checks, delayed casualty deduplication, foreign conversion cleanup, island/open-water spawning, veteran upgrades/ID reuse, alternate save-bank recovery and real Council dispatch.

No actual Civ V game has been launched as part of this implementation. Engine integration, tactical AI, graphics, native turn order and balance require the following checks.

The suite includes twenty regression cases in `tools/tests/lastcity_regressions.lua`, four proportional attrition profiles, mixed speed-field checks and original DDS validation. The focused run reports 45 PASS groups after the 2026-10-11 loading correction. The Settler regression removes capital initialization, confirms that training remains blocked and checks that the first city can still be founded. UI tests start in a fresh context with no gameplay runtime, load it through the Council and verify handler registration before exercising interface modes, overlapping popups, tab reuse, stale previews, infection projections, fallen-state hiding and reused-context reloads. Native cleanup, Settler restrictions and signatures were checked against Release-5.4.6 source matching the installed CP v151 manifest. See [RefinementReport.md](RefinementReport.md) for survival changes and [LoadingFix.md](LoadingFix.md) for the installed manifest failure.

## Native smoke tests

- [ ] Enable standalone with BNW and CP; select The Warden and confirm Last Light, UA, UU, UB and custom Dawn/leader/map/portrait/flag art.
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

“Implemented” means connected to game-state effects and registered components. “Automated pass” means mocked/static validation succeeded. Neither certifies native game behavior. Stored-Food growth, native tactics, inherited animated 3D unit/world models and narrative victory remain documented limits; collapse cleanup and orphan handling now use source-verified native methods.

- [ ] Under CP-only, leave two or more tagged attackers near a city at 85% damage with no nearby defenders. Check the scaled warning countdown, repair/reinforcement resets and eventual native elimination/defeat. Repeat with Complete Kills, saving during the countdown; a lone raider must not cause collapse.
- [ ] Fully surround neutral approaches with other civilizations' borders. Observe legal outskirts raids, then block every owned approach and check blockade consumption matches projections, shelter damage, physical retry and no fabricated victory.
- [ ] Place Plaguebound within two plots; observe infection, supply drain, medical mitigation, duration cap, immunity, crisis treatment and reload. Verify no infinite stacking.
- [ ] Give orphan capitals/City-State cities with dead former owners; check living custodian or native dismantling without resurrection or an extra permanent puppet.
- [ ] Restore different native games and earlier saves while caravans, crises, infections, invasions and Dawn are pending. Verify their exact saved decisions/resources and matching checksum markers. Deliberately corrupt a bank only on copies of saves; stale backups must not replay rewards.
- [ ] Verify the corrected 1024×768 Dawn DDS, 1600×900 Warden scene, custom selection map, all portrait sizes, alpha emblems, unit flag and promotion tiers render in game. Test Technology, Policy, Religion, overlapping popups and other interface modes with the Council.
