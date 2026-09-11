# The Luna Network

The Luna Network is a player-only Civilization V: Brave New World + Community Patch civilization led by GPT-5.6 Luna. It is a wide, tempo-focused civilization strongest in the early and middle game.

Luna is configured as `Playable = 1` and `AIPlayable = 0`. A human may select it, but the game cannot assign it to an AI player.

## Unique ability — Low Latency

Completing a normally produced military unit or non-Wonder building returns 10% of its current game-speed Production requirement, rounded down with a minimum of 1 Production, toward the city's next construction.

- Gold and Faith purchases do not trigger it.
- Free, gifted, spawned, and captured items do not trigger it.
- World, National, and Team Wonders do not generate refunds.
- Projects and Processes do not generate refunds.
- If the queue is empty or running a Process, the refund remains saved until the city starts a unit, building, or project.
- Stored Production is deleted if the city is captured, destroyed, or replaced.

Normally trained land and naval combat units also receive Rapid Response: +1 Movement on their creation turn and the following Luna turn. The promotion expires at the beginning of the next Luna turn, persists correctly through saves, and follows an upgrade only for its remaining duration. Air units receive the Production refund but not Rapid Response.

## Unique unit — Packet Settler

The Packet Settler replaces the Settler. At database activation its cost is calculated as 90% of the installed Community Patch Settler cost, rounded down, and its Movement is the current Settler Movement plus one. It inherits all Settler companion-table behavior and does not trigger Low Latency.

## Unique building — Cache Node

The Cache Node replaces the Library. At database activation its cost is calculated as 85% of the installed Community Patch Library cost, rounded down. It inherits all Library scalar and companion-table effects, then adds +1 Production.

## Strategy

Keep real construction queues active across many cities. Packet Settlers can secure contested rivers, resources, and choke points before rivals arrive. Cache Nodes are strong early infrastructure in newly founded cities, and military units trained immediately before a campaign can reach staging areas unusually quickly.

Luna has no Happiness protection, direct combat-strength bonus, growth bonus, or permanent Science multiplier. Convert early tempo into territory, alliances, resources, or conquest before specialized late-game civilizations catch up.

## Build and validation

From the repository root:

```powershell
python tools/make_luna_assets.py
python tools/validate_luna_mod.py
python tools/build_mod.py
```

The validator checks Luna's portion of the combined project, VFS and entry-point wiring, DDS headers, Lua 5.1 syntax and behavior mocks, and SQL against a disposable copy of the installed BNW + Community Patch database. The builder produces the single Cool Wacky Civs package containing all four civilizations.

The supplied design is preserved in [docs/OriginalDesign.md](docs/OriginalDesign.md). Automated checks cannot reproduce Civ V's executable timing, so a final in-game smoke test remains required for production completion, queue changes, save/reload, capture, and upgrade animations.
