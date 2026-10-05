# The Luna Network

**CIVILIZATION FIELD GUIDE** · [Cool Wacky Civs](../README.md) · Brave New World + Community Patch

> *Build the next city. Finish the next order. Arrive before the moment passes.*

<img src="../art-source/LunaLeader.png" alt="The Luna Network artwork" width="960">

| At a glance | Details |
| --- | --- |
| **Leader** | GPT-5.6 Luna |
| **Signature system** | Low Latency |
| **Playstyle** | Wide development · construction tempo · rapid deployment |
| **Player access** | Human-only — `Playable = 1`, `AIPlayable = 0` |
| **Requirements** | Civilization V: Brave New World; Community Patch v151 / 5.4.2+ |
| **Supported mode** | New single-player campaign; collection multiplayer/hotseat disabled |

**Explore:** [Signature kit](#signature-kit) · [Mechanics](#mechanics-and-reference) · [Campaign guide](#campaign-guide) · [Worked example](#worked-example) · [Field notes](#field-notes) · [Install](#installation-and-validation) · [Developer reference](#developer-reference)

---

## Civilization identity

Luna turns ordinary construction into momentum. Cheap settlement, discounted research infrastructure and short-lived deployment speed encourage an expanding network of cities that keep finishing useful work. The appeal is in the rhythm: many small completions become an early territorial and logistical advantage, provided the empire can support the growth.

## Signature kit

**The core loop:** Complete normal construction → refund Production → keep the next order moving → expand the network.

| Element | Replaces / threshold | What it contributes |
| --- | --- | --- |
| Low Latency | 10% completion refund | Normally produced combat units and non-Wonder buildings feed the next construction. |
| Rapid Response | Temporary +1 Movement | Eligible trained land and naval combat units move faster during their creation turn and the following Luna turn. |
| Packet Settler | Settler replacement | 90% of the active Settler cost, rounded down; one more Movement than the active Settler. |
| Cache Node | Library replacement | 85% of the active Library cost, rounded down; inherited Library effects and +1 Production. |

Campaign advice explains how to use the implemented mechanics. Numeric worked examples use Standard speed unless stated otherwise. Inherited base-unit and base-building statistics follow the active ruleset.

## Mechanics and reference

### A completion checklist

Before expecting a refund, confirm that the item was **normally produced**, is an eligible military unit or non-Wonder building, and actually completed. Gold/Faith purchases, gifts, free spawns, captures, Projects and Processes do not generate the trait refund. An empty queue can store it; ownership changes invalidate that city's stored Production.

The refund and Rapid Response are separate checks. A combat aircraft can pass the refund check while failing the movement check. A Packet Settler is civilian and does not qualify as a military completion.

### Unique ability — Low Latency

Completing a normally produced military unit or non-Wonder building returns 10% of its current game-speed Production requirement, rounded down with a minimum of 1 Production, toward the city's next construction.

- Gold and Faith purchases do not trigger it.
- Free, gifted, spawned, and captured items do not trigger it.
- World, National, and Team Wonders do not generate refunds.
- Projects and Processes do not generate refunds.
- If the queue is empty or running a Process, the refund remains saved until the city starts a unit, building, or project.
- Stored Production is deleted if the city is captured, destroyed, or replaced.

Normally trained land and naval combat units also receive Rapid Response: +1 Movement on their creation turn and the following Luna turn. The promotion expires at the beginning of the next Luna turn, persists correctly through saves, and follows an upgrade only for its remaining duration. Air units receive the Production refund but not Rapid Response.

### Unique unit — Packet Settler

The Packet Settler replaces the Settler. At database activation its cost is calculated as 90% of the installed Community Patch Settler cost, rounded down, and its Movement is the current Settler Movement plus one. It inherits all Settler companion-table behavior and does not trigger Low Latency.

### Unique building — Cache Node

The Cache Node replaces the Library. At database activation its cost is calculated as 85% of the installed Community Patch Library cost, rounded down. It inherits all Library scalar and companion-table effects, then adds +1 Production.

### Strategy

Keep real construction queues active across many cities. Packet Settlers can secure contested rivers, resources, and choke points before rivals arrive. Cache Nodes are strong early infrastructure in newly founded cities, and military units trained immediately before a campaign can reach staging areas unusually quickly.

Luna has no Happiness protection, direct combat-strength bonus, growth bonus, or permanent Science multiplier. Convert early tempo into territory, alliances, resources, or conquest before specialized late-game civilizations catch up.

---

## Campaign guide

### Opening — claim the network

Scout sites before committing Packet Settlers. Their lower cost and extra movement help claim resources and contested locations, but each new city still needs normal Happiness, defense and infrastructure. A Cache Node gives an expanding city both its inherited research role and a little construction support.

### Middle game — chain completions

Keep productive cities on useful queues. A completion refund is most valuable when it immediately helps the next required building or unit. Stage trained troops close enough to exploit Rapid Response; its temporary movement is much less useful after a long idle wait.

### Late game — spend the head start

Turn early expansion into strong production centers, research infrastructure and secure resources. The trait keeps supporting construction, but it supplies no permanent combat-strength or Science multiplier. Protect the territory and development your tempo secured.

## Worked example

A qualifying item with a current speed-adjusted requirement of **73 Production** returns **floor(73 × 10%) = 7 Production**. A qualifying 9-Production item still returns the minimum **1**. Purchasing either item gives **0** refund. If the queue cannot accept the refund, it waits for a valid construction rather than disappearing immediately.

## Field notes

### Can a Wonder receive the previous refund?

Stored refunds can support a valid next construction. Completing a Wonder itself does not generate a new refund.

### Do air units receive Rapid Response?

They can generate the military Production refund, but do not receive the temporary movement promotion.

### Why are the Settler and Library costs different in my game?

Their costs are calculated from the active BNW/Community Patch rows at activation. The percentages are fixed; the inherited base costs can differ.

---

## Installation and validation

This civilization ships with **all twelve civilizations in one Cool Wacky Civs package**. Install and enable the collection once; there is no separate per-civilization mod to enable.

1. Install Civilization V with **Brave New World** and the required **Community Patch**.
2. Put the collection's unpacked mod folder in the game's `MODS` directory, or import its `.civ5mod` package.
3. Enable Community Patch and **one version** of Cool Wacky Civs through the Mods menu.
4. Start a **new single-player game** and choose **The Luna Network** for the human player. All collection civilizations are excluded from normal AI selection.

To validate or rebuild from source, run these commands from the **collection root**, one directory above this README:

```powershell
python tools/validate_luna_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

The first command focuses on this civilization; the second checks the complete collection. The builder writes an unpacked folder, ZIP and native LZMA `.civ5mod` under `dist/`, using the current version in [the project](../CoolWackyCivs.civ5proj). If development dependencies are missing, follow the [collection setup instructions](../README.md#build-and-validation).

**Testing boundary:** automated checks cover the database, packaging and applicable Lua behavior. A running Civ V match is still needed to confirm executable timing, combat previews, UI transitions and save/load behavior.

## Developer reference

<details>
<summary><strong>Expand implementation, artwork and detailed validation notes</strong></summary>

Ordinary setup is human-only. Any AI routines described here are retained fallback implementation, rather than permission for Civ V to select this civilization as an AI opponent.

### Build and validation

From the repository root:

```powershell
python tools/make_luna_assets.py
python tools/validate_luna_mod.py
python tools/build_mod.py
```

The validator checks Luna's portion of the combined project, VFS and entry-point wiring, DDS headers, Lua 5.1 syntax and behavior mocks, and SQL against a disposable copy of the installed BNW + Community Patch database. The builder produces the single Cool Wacky Civs package containing all twelve civilizations.

The supplied design is preserved in [docs/OriginalDesign.md](docs/OriginalDesign.md). Automated checks cannot reproduce Civ V's executable timing, so a final in-game smoke test remains required for production completion, queue changes, save/reload, capture, and upgrade animations.

</details>
