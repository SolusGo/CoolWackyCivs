# Patch Notes

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
