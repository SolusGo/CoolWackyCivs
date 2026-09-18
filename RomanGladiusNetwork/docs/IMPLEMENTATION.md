# RomanGladius Network implementation notes

The concept's open-ended server simulation is implemented as deterministic Civ V systems:

- Population yield thresholds are maintained with counted dummy buildings.
- Reputation bands and timed modifiers are mutually exclusive dummy-building states refreshed by Lua.
- Moderator and Administrator counts, event IDs, chat, logs, milestone flags, maximum population, launch timers, and Peak Hours timers use `Modding.OpenSaveData()`.
- City save keys include owner, ID, coordinates, and founding turn to prevent state leakage when an ID is reused.
- Server Owners inherit the current Community Patch Settler and Server Consoles inherit the current Monument through activation-time scalar and companion-table cloning.
- The required Community Patch city-founding and capital-change event switches are enabled explicitly. `PlayerCanFoundCity` enforces the launch Gold requirement; the founding handler charges the cost and applies the free Console/opening state to every Server, including the first.
- Server Owner population loss also accounts for the optional Community Patch rule that already removes one Population from completed Settlers, and purchases cannot bypass the two-Population cost.
- Staff counts are clamped after Population loss so a Server can never retain more staff roles than Players.
- The dashboard is single-player only, matching the collection's multiplayer setting and avoiding unsynchronized UI decisions.
- AI Servers promote staff toward the same target ratio and resolve pending incidents through the runtime without UI input.

The original concept is preserved in `OriginalDesign.md`; this file describes only implementation choices needed to make it playable and testable in Civ V.
