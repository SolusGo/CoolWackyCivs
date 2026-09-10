# Patch Notes

## Capano Circuit version 1 — Initial implementation — 2026-09-11

- Added Enrico Capano and The Capano Circuit as a standalone, AI-playable Community Patch civilization.
- Implemented target-specific Beta across four failed attacks, maximum-Beta SEND rewards, five-step technique progression, and the once-per-player Ammagamma challenge.
- Added the 3-Movement Route Setter with Worker inheritance, Hill movement/work bonuses, and exclusive Boulder Sector construction.
- Added the non-adjacent Boulder Sector, its Science/Culture/Production Circuit progression, asymmetric movement, hostile Awkward Sequence, once-per-era training, Yellow status, and BlocHaus cosmetic messages.
- Added the Competition Coaching Centre with Armory inheritance, +2 Science, +2 Culture, and two-tile Competition Movement for normally trained land units.
- Added save-backed identity/progression and Community Patch battle, construction, movement, upgrade/conversion, war, and diplomacy integrations.
- Added generated Enrico-inspired leader art plus extracted civilization, unit, building, improvement, promotion, map, and flag textures from the supplied concept art.
- Added full English localization, fictional leader dialogue, Civilopedia text, city and spy names, ModBuddy packaging, build tooling, and schema/behavior validation.

## Luna Network version 1 — Correct standalone implementation — 2026-09-06

- Added GPT-5.6 Luna and The Luna Network as a separate Community Patch civilization mod.
- Implemented Low Latency for normally produced military units and non-Wonder buildings using game-speed-adjusted Production requirements.
- Added save-backed pending Production, Process/empty-queue handling, and capture/destruction cleanup.
- Added two-turn Rapid Response for trained land and naval combat units, including save/load and upgrade continuity.
- Added the Packet Settler with dynamically inherited Settler behavior, 10% lower Production cost, and +1 Movement.
- Added the Cache Node with dynamically inherited Community Patch Library effects, 15% lower Production cost, and +1 Production.
- Added dedicated Luna leader and civilization artwork, localization, city names, spy names, diplomacy, and metadata.
- Set Luna to `Playable = 1` and `AIPlayable = 0` so it remains human-selectable but cannot be chosen by AI.
- Added Luna-specific build and validation tooling.
- Split civilization documentation into separate Rou'ls and Luna READMEs and made the repository README collection-wide.

## Rou'ls Ascendancy version 1 — Player-only civilization selection — 2026-09-06

- Set The Rou'ls Ascendancy to remain human-playable while preventing AI selection.
