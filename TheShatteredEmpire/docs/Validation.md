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
