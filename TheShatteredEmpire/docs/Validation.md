# Validation

Automated checks are distinct from actual Civ V playtesting. No Civ V game has been launched by this task.

## Automated checks

`python tools/validate_shattered_mod.py` validates the real BNW/CP database in memory, full Warrior/Monument companion inheritance, exactly one added Gold yield, civilization/AI registration, localized descriptions, readable DDS atlases, Lua 5.1 syntax and package checksums/registrations.

Lua 5.1 scenarios use the actual database definitions at speed multipliers 67, 100, 150 and 300. Coverage includes capital/province creation and Settler fallback, reload idempotence, Governor persistence, Loyalty calculation, costly/stale decisions, feasible demands and expiry, unit upgrades/death/recycled IDs, capture reward limits, capital loss, corrupted-bank recovery, two-check rebellion thresholds, protected garrisons/civilians, limited defections and recruitment, unrelated barbarian preservation, geographic civil wars, definite resolution, exhaustion, final-damage defensive rewards, reforms/cooldowns/nonstacking, persistent succession and reversible restoration.

The seven UI tabs, callbacks, succession choices, City/Diplomacy/popup hiding, AI visibility and Escape are exercised with strict UI mocks. A 500-turn fixture with 22 player slots runs human/AI politics and ten fresh-context reloads. This is simulation coverage, not a Huge-map engine performance claim.

The collection's `python tools/validate_all.py` also runs every existing civilization suite. `python tools/build_mod.py` and `python tools/build_shattered_mod.py` check native archive integrity. Actual result details are recorded below after execution.

## Results — 2026-10-10

- All fifteen collection validation suites passed. The combined manifest contains 538 gameplay/art files and 60 database actions; all 401 DDS files passed decode and DirectXTex checks, and all 52 shipped Lua scripts passed Lua 5.1 syntax checks.
- Shattered Empire passed all four speed scenarios, seven-tab UI checks, the 500-turn/22-player fixture with ten reloads, and an additional large-empire fixture with 80+ provinces and 500+ units.
- Actual native CP contracts and SQL against installed CP and the retained v151 baseline were checked. Native `.civ5mod` archives and ZIPs were built for both standalone and collection packages and their integrity verified.
- Original leader/Legion/Palace crops, emblem and final art review sheet were visually inspected. Runtime UI mocks verify behavior and control wiring; engine rendering remains unverified.
- Final follow-up checks cover nonstacking Dictatorship Oaths, uniquely named faction troops, precise resource petitions, integer optional CP API flags, finite exhausted conflicts and accurate war counters. These changes are checked with the affected suites after refreshing both manifests.

## Hardening validation — 2026-10-10

The focused suite adds charter/settlement affordability and repeat/stale identity checks, lasting privileges after replacement/reload, partial civil-war settlement, shared AI prices, redundant/infeasible petitions, saved deadlines and single completion rewards. Four-speed defection tests cover zero recruitment, several Legions, upgraded veteran lineage, effective Dictatorship Oaths, XP/permanent promotion transfer, garrison/civilian/unique/cargo/embarked protection, faction/empire/live-army caps, dead rebel cleanup, failed spawns, active-faction reloads and repeated calls.

The initial hardening used twelve local map fixtures with a visibility override. That mock limitation is corrected by the final founding validation below. Saves taken inside city and Settler creation callbacks recover pending grants without multiplication; failed Settler creation resumes safely, and established saves at turns 1 and 20 receive no new starting bonus. These are synthetic map scenarios, not generated Civ V maps.

The stress suite runs 100+ provinces and 650+ units through consecutive combat, mass creation, local charters, Authority promotion thresholds, active wars, expiring requests, repeated decisions, 100 turns, five reloads, restoration and AI decisions. It asserts that ordinary combat/creation performs zero full army passes and zero dummy-building checks, a local charter updates at most one city's effects, and nested AI actions/defections save once. UI checks verify the displayed Gold/Authority costs, both consequence tooltips and closed-screen refresh filtering. Existing 500-turn/22-player and all-collection regression coverage remains.

Reproduce the benchmark with `python tools/benchmark_shattered.py --ref 246806f` and `python tools/benchmark_shattered.py`. The identical workload builds 100+ provinces/600+ units, creates 50 soldiers, fires 200 combats, then runs one political turn with two defections:

| Mock work | Before (`246806f`) | After |
|---|---:|---:|
| Dummy-building checks | 341,445 | 13 |
| Player unit iterator visits | 33,281 | 651 |
| Snapshots during the nested rebellion turn | 3 | 1 |
| Total snapshots | 255 | 253 |
| Save storage writes | 5,614 | 5,570 |
| Wall time, one sequential sample | 6.488 s | 6.089 s |

Timing includes Lua mock serialization and varies with host load. Independent events still save changed battle/unit state immediately; the improvement removes repeated effect work and nested snapshots. This does not establish native game turn/frame performance.

Both `python tools/validate_shattered_mod.py` and `python tools/validate_all.py` passed; all fifteen collection suites passed. `python tools/build_mod.py` and `python tools/build_shattered_mod.py` built the collection and standalone ZIP/native packages and verified native archive integrity. Both manifests retain their mod IDs/versions and synchronize the changed Lua/SQL/UI hashes. No actual Civ V game was launched; native rendering, generated-map geography, long AI tactics and numerical balance remain outstanding.

Focused manual CP v151 checks:

1. Start spacious/island/cramped/wrapped games with normal fog; verify connected legal founding, population 2/1, exactly two grants and reload safety before/after each founding.
2. Test both autonomy decisions with insufficient and sufficient resources, repeat/stale clicks and a previously autonomous rebel. Check UI prices, permanent Ambition pressure and a three-faction war continuing after one settlement.
3. Upgrade a veteran Legion, exhaust recruitment, then lower its effective Oath. Verify safe defection, XP, protected units, two/six/24 caps and reload behavior.
4. Lose a petition resource/city, repair Farms, replace a Governor and reload near deadlines. Verify withdrawal without unfair penalty and no duplicate reward.
5. Use a large AI empire through combat, repeated wars, restoration and saving; inspect Lua.log, city modifiers and conditional promotions, and measure actual turn times.

## Final founding and civil-war validation — 2026-10-10

The default Lua fixture now starts with team-specific sight only within two tiles of each capital, rather than revealing every plot. Native `CanFound` rejects unexplored sites, and successful `Found` reveals the new city's normal local sight before firing the creation event. Terrain-only reveal flags and visibility counts are checked against the pinned CP bindings; source assertions cover the native fog gate, wonder side effects and spacing. The synthetic distance model remains a simplified wrapped grid, so it cannot establish generated hex-map or line-of-sight behavior.

Thirteen local profiles cover spacious Pangaea, Continents, Small Continents, Archipelago, Tiny Islands, mountain barriers, coastal starts, foreign ownership, occupied plots, nearby rival starts, no legal sites, an X-wrapped boundary and a cramped torus. Spacious connected land must produce three cities, zero fallback Settlers, one capital and populations 2/1/1. Restricted land must deliver the remaining entitlements as Settlers. Every profile checks exactly two distinct grants, normal native sight only, and repeated reload identity.

Additional cases cover per-plot native vetoes, a silent failed `Found`, natural and pseudo-natural wonder exclusion, unchanged hidden-resource ranking, restoration of rejected tiles to fog, a save after temporary revelation but before founding, callback errors, saves during city/Settler creation, failed Settler initialization and established-save exclusion. The pseudo-wonder test clones a real feature row because the retained BNW cache plus CP DDL may contain no pseudo-wonder content.

At speed multipliers 67/100/150/300, outcome scenarios check military-only (+10), negotiated-only (+0), clean mixed (+3/+6 for one/two military factions of three), partial and total exhaustion (+0), territorial failure (+0), unchanged per-faction 5/7 suppression, Authority clamping, peaceful Empire Reborn progression, active-war reload, one-time legacy reconstruction, pruned ambiguous resolutions, preserved completed legacy records, Governor/Oath persistence, stale identities, native cleanup reentrancy, repeated calls and AI-paid negotiation. UI checks inspect every stored outcome and legacy label through the real Overview callbacks.

The earlier petition, costly autonomy, veteran defection, reform, succession, capture, dirty-effect/save-coalescing and UI scenarios remain. Existing 500-turn/22-player, 80+ province/500+ unit and 100+ province/650+ unit stress fixtures remain in the focused suite.

Final execution results:

- `python tools/validate_shattered_mod.py` passed all four speeds, thirteen limited-sight profiles, interrupted/rejected founding, war outcome/migration/AI/UI cases and every earlier endurance regression.
- `python tools/validate_all.py` passed all fifteen civilization suites. Collection checks verified 538 gameplay/art files, 60 SQL actions, all 401 DDS files and 52 shipped Lua scripts.
- `python tools/build_mod.py` and `python tools/build_shattered_mod.py` built both ZIP and native `.civ5mod` packages and passed native archive integrity checks. Both manifests retain their original IDs/versions and match the changed gameplay hashes. Documentation was included in refreshed final packages.
- `git diff --check` passed. No Civ V game was launched; the engine-specific checks below remain outstanding.

Remaining engine checks: generated standard maps and actual hex wrapping; native terrain sight and temporary fog rendering; tactical/exploration cache updates; discovery hooks enabled by other mods; saves made through Civ V inside callbacks; final UI text/layout; AI tactics and numeric balance. The collection enables natural-wonder discovery for PaulsoaresJr, so verify that only genuine city sight discovers adjacent wonders and that rejected candidate probes never do. CP v151's tile-revealed hook is disabled by default and this collection does not enable it; third-party hooks may introduce non-reversible observer effects. No Civ V game was launched.

## Required in-game checklist

1. Enable CP v151 and one package. Confirm the civilization, leader portrait, city list, Legion and Palace appear in setup/Civilopedia; inspect Database.log and Lua.log for errors.
2. Start normal, cramped, islands and wrapping maps. Found Aeternum; verify population 2, two legally spaced provinces or exactly two fallback Settlers, stock handicap grants and no extra workers/techs. Save/reload before and after founding.
3. Inspect Governor names and calculated Loyalty reasons. Build a Palace, garrison/connect a province, complete and refuse petitions, pay compensation and replace a Governor. Check exact Gold/Authority costs and cooldowns.
4. Use IGE to set Authority/Loyalty low via `MapModData.TheShatteredEmpire.State(player)`. Wait two political checks. Verify era-appropriate safe rebel plots, finite armies, named factions, bounded defections and unchanged infrastructure. Destroy the tracked armies, or test each negotiated resolution.
5. Create three nearby severe provinces and a high-Ambition claimant at Authority below 30. Verify one named war, regional participation, history counters and cooldown. Capture/destroy a rebel city and test inaccessible conflict exhaustion.
6. Train soldiers in different provinces; upgrade a veteran Legion and check persistent Oath/lineage and Discipline on both attack and defense above/below Authority 60. Test unit death, capture/gifting, cargo/embarkation and unrelated unique units.
7. Adopt each reform after Ancient; switch after cooldown. Verify native city modifiers, conditional promotions and no duplicate effects. Advance eras and choose each successor. Save during a pending Council and verify unchanged candidates/deadlines.
8. Recover from collapse and maintain restoration requirements for twenty scaled turns. Confirm +10% Production/Culture, dormancy after renewed unrest and safe reactivation.
9. Verify Administration hides in City View, Culture/other popups and Diplomacy; test long scroll lists, all tabs, invalidated selections and resolution messages at common display resolutions.
10. Run AI-led Empire autoplay on Quick and Marathon and a Huge map with about 22 civilizations through late eras. Observe garrisons, city queues, rebel combat, costs, repeated crises, save size, turn time and restoration. Record balance changes before claiming gameplay verification.
