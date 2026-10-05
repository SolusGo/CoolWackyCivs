# The Filthy Realm

**CIVILIZATION FIELD GUIDE** · [Cool Wacky Civs](../README.md) · Brave New World + Community Patch

> *Spread the Filth. Bank the points. Choose the moment everything goes wrong.*

<img src="../art-source/FilthyRealm/FilthyDawn.png" alt="The Filthy Realm artwork" width="960">

| At a glance | Details |
| --- | --- |
| **Leader** | Filthy Frank |
| **Signature system** | Welcome to the Rice Fields — Filth and Filthy Points |
| **Playstyle** | Foreign-city disruption · cultural pressure · active battlefield control |
| **Player access** | Human-only — `Playable = 1`, `AIPlayable = 0` |
| **Requirements** | Civilization V: Brave New World; Community Patch v151 / 5.4.2+ |
| **Supported mode** | New single-player campaign; collection multiplayer/hotseat disabled |

## UA, UU and UBs

**UA** = Unique Ability · **UU** = Unique Unit · **UB** = Unique Building · **UI** = Unique Improvement.

| Type | Name | Replaces / role | What it does |
| --- | --- | --- | --- |
| **UA** | **Welcome to the Rice Fields** | Civilization trait | Filth and Filthy Points. |
| **UU** | **Peace Lord** | Great War Infantry | 52 Combat Strength. Kills grant 5 extra Filthy Points and a one-turn -10% strength debuff to adjacent enemies. Once per unit, Filthy Intervention can force an adjacent enemy below 30 HP to a legal retreat tile and award 10 FP. |
| **UB** | **Filthy Kitchen** | Broadcast Tower | Retains Broadcast Tower effects and adds +2 Tourism. A new Great Work in its city grants 25 Food and the normal 10 FP. Every five turns, its Great Works generate FP, capped at 3 per city. |
| **Additional summoned unit** | **Salamander Man** | Temporary support unit summoned through the UA; no replacement | For 25 FP, summons a five-turn non-combat unit with 5 Movement. Adjacent enemies suffer -10% strength/-1 Movement; adjacent friendly military units gain +1 Movement. |

Salamander Man is an ability summon; Peace Lord is the normal unit replacement.

**Explore:** [UA / UU / UBs](#ua-uu-and-ubs) · [Signature kit](#signature-kit) · [Mechanics](#mechanics-and-reference) · [Campaign guide](#campaign-guide) · [Worked example](#worked-example) · [Field notes](#field-notes) · [Install](#installation-and-validation) · [Developer reference](#developer-reference)

---

## Civilization identity

Frank builds influence through persistent, disruptive contact. Trade and cultural reach establish contamination, military pressure keeps it relevant, and Filthy Points turn that pressure into active interference. The civilization links a Culture game to a war game: the same foreign cities can become audiences, sources of stolen yields and vulnerable fronts.

## Signature kit

**The core loop:** Maintain foreign contact → raise Filth → earn Filthy Points → spend on disruption or stolen yields.

| Element | Replaces / threshold | What it contributes |
| --- | --- | --- |
| Filth | Five foreign-city levels | Persistent contact sustains penalties; high levels aid nearby Filthy military units. |
| Filthy Points | Shared ability currency | Spend through ENTER THE FILTHY REALM; target and ability cooldowns still apply. |
| Peace Lord | Great War Infantry replacement | 52 strength, extra kill points, nearby enemy debuffs and one Filthy Intervention. |
| Filthy Kitchen | Broadcast Tower replacement | Inherited effects, +2 Tourism, Great Work Food and recurring point generation. |
| Salamander Man | Temporary aura unit | Five-turn, 5-Movement non-combat support summoned for 25 FP. |

Campaign advice explains how to use the implemented mechanics. Numeric worked examples use Standard speed unless stated otherwise. Inherited base-unit and base-building statistics follow the active ruleset.

## Mechanics and reference

### Contamination ladder

| Level | Culture | Gold | Production | Additional pressure |
| --- | ---: | ---: | ---: | --- |
| I | -2% | — | — | Entry-level contamination |
| II | -3% | -3% | — | Economic disruption begins |
| III | -5% | -5% | -5% | Construction is affected |
| IV | -7% | -7% | -7% | Nearby Filthy military units receive +10% strength |
| V | -10% | -10% | -10% | -1 local Happiness; nearby Filthy military units receive +15% strength |

Only the current level applies. Distortion replaces it temporarily with the amplified version: yield penalties become -3%, -5%, -8%, -11% or -15% respectively, reflecting integer rounding. It does not add a second normal penalty building.

### Ability desk

| Ability | Cost | Window / restriction | Tactical role |
| --- | ---: | --- | --- |
| Salamander Man | 25 FP | Five-turn summoned unit | Adjacent enemies: -10% strength/-1 Movement; adjacent friendly military units: +1 Movement |
| Realm Distortion | 40 FP | Five-turn effect; ten-turn cooldown | Amplify one contaminated city, support nearby Zone-of-Control bypass and suppress up to 10 starting XP there |
| Ravioli Ravioli | 60 FP | Fifteen-turn target-city cooldown | Choose Gold, Science, Culture, Food or Production theft, scaled by era |
| It's Time to Stop | 80 FP | Twenty-turn cooldown | Exhaust and prevent attacks by enemy military units within four tiles of Filthy military units for the remainder of the game turn |

Read the panel's target list before activating. Points alone do not make an invalid city or unit eligible.

### Filth and Filthy Points

- Trade Routes spread one Filth every 6 turns, or every 4 turns when their origin has a Filthy Kitchen.
- Familiar-or-better cultural influence spreads Filth to a foreign capital every 10 turns.
- Pillaging and enemy kills near their cities spread Filth immediately.
- Every 10 turns, a contaminated city loses one level unless it has a Filthy trade connection, meaningful tourism pressure, or nearby Filthy military presence.
- New Filth levels, kills, pillaging, routes, Great Works, city captures, denunciations, and declarations of war generate persistent Filthy Points.

The top-screen `ENTER THE FILTHY REALM` button opens a panel with the current point total, cooldowns, valid targets, and all active abilities:

- Salamander Man (25 FP): creates a non-combat 5-Movement aura unit beside the capital for five turns.
- Realm Distortion (40 FP, 10-turn cooldown): increases one contaminated city's penalties by 50% for five turns, lets nearby Filthy units ignore Zone of Control, and removes up to 10 starting XP from units trained there.
- Ravioli Ravioli, What's in the Pocketoli (60 FP): steals a player-selected Gold, Science, Culture, Food, or Production amount scaled by era. A city has a 15-turn target cooldown.
- It's Time to Stop (80 FP, 20-turn cooldown): exhausts enemy military units within four tiles of Filthy military units and prevents their attacks for the rest of that game turn.

The retained AI fallback prioritizes Stop during war, then Ravioli, Realm Distortion, and Salamander Man.

### Unique objects

The Peace Lord replaces Great War Infantry at 52 Combat Strength. Its kills grant 5 extra FP and impose a one-turn -10% Combat Strength debuff on adjacent enemies. Each Peace Lord can use Filthy Intervention once through the Realm panel: an adjacent enemy below 30 HP retreats to a valid tile farther away, and Frank gains 10 FP.

The Filthy Kitchen replaces the Broadcast Tower, retains inherited Brave New World/Community Patch effects, and adds 2 Tourism. New Great Works in its city add 25 Food as well as the normal 10 FP. Every five turns it also contributes one FP per Great Work, capped at three per city.

---

## Campaign guide

### Opening — create contact

Use exploration, diplomacy and international routes to build useful foreign connections. Keep an ordinary economy and army behind the pressure system. A contaminated city requires continued support; abandoning every route, tourism source and nearby troop lets Filth decay.

### Middle game — choose a pressure front

Concentrate routes, cultural reach and military operations where sustained contamination will matter. Do not spend every point as soon as an ability unlocks. Saving for a theft or a decisive Stop can be more useful than repeatedly summoning a short-lived support unit.

### Late game — combine culture and disruption

Fill Kitchens with Great Works to support Tourism, Food and points. Fight near heavily contaminated enemy cities with Peace Lords. Use Distortion or Stop when your army can capitalize on the effect immediately; exhausting enemies without a follow-up wastes the opportunity.

## Worked example

You hold **100 FP**. Realm Distortion costs **40**, leaving **60** for Ravioli. That sequence spends the entire pool and leaves you short of the **80-FP** Stop ability. If the next enemy turn is the major threat, saving for Stop may be the better tactical choice. Ravioli also respects a separate **15-turn cooldown on its target city**.

## Field notes

### Why is an abandoned city losing Filth?

Every ten turns it can lose one level without an active Filthy trade connection, meaningful tourism pressure or nearby Filthy military presence.

### Do overlapping contaminated cities multiply the combat bonus?

No. Units receive the strongest applicable high-Filth bonus, rather than a stack from every city.

### Can the Peace Lord force any enemy to retreat?

Filthy Intervention requires an adjacent enemy below 30 HP, a legal farther retreat tile and an unused intervention for that Peace Lord.

---

## Installation and validation

This civilization ships with **all twelve civilizations in one Cool Wacky Civs package**. Install and enable the collection once; there is no separate per-civilization mod to enable.

1. Install Civilization V with **Brave New World** and the required **Community Patch**.
2. Put the collection's unpacked mod folder in the game's `MODS` directory, or import its `.civ5mod` package.
3. Enable Community Patch and **one version** of Cool Wacky Civs through the Mods menu.
4. Start a **new single-player game** and choose **The Filthy Realm** for the human player. All collection civilizations are excluded from normal AI selection.

To validate or rebuild from source, run these commands from the **collection root**, one directory above this README:

```powershell
python tools/validate_filthy_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

The first command focuses on this civilization; the second checks the complete collection. The builder writes an unpacked folder, ZIP and native LZMA `.civ5mod` under `dist/`, using the current version in [the project](../CoolWackyCivs.civ5proj). If development dependencies are missing, follow the [collection setup instructions](../README.md#build-and-validation).

**Testing boundary:** automated checks cover the database, packaging and applicable Lua behavior. A running Civ V match is still needed to confirm executable timing, combat previews, UI transitions and save/load behavior.

## Developer reference

<details>
<summary><strong>Expand implementation, artwork and detailed validation notes</strong></summary>

Ordinary setup is human-only. Any AI routines described here are retained fallback implementation, rather than permission for Civ V to select this civilization as an AI opponent.

### Implementation

- `SQL/00_Filthy_Core.sql` creates the civilization, leader, unique objects, art atlases, and temporary promotions.
- `SQL/01_Filthy_Inheritance.sql` clones every BNW/Community Patch companion-table row for Great War Infantry and the Broadcast Tower.
- `SQL/02_Filthy_UniqueEffects.sql` defines the ten mutually exclusive normal/distorted Filth buildings, AI flavor, city list, and supporting effects.
- `Lua/FilthyRuntime.lua` owns save data and gameplay state. Filth is persisted by physical city identity so conquest cannot erase `NeverCapture` dummy buildings; Filthy captures still cleanse it. Unit script markers preserve temporary effects without overwriting other mods' script data, with upgrade-lost debuffs intentionally excluded from upgrade transfer.
- `UI/FilthyPanel.xml` is the only entry point; it includes the runtime before presenting controls.
- `docs/OriginalDesign.md` preserves the supplied design brief, while `docs/ART_GENERATION.md` records the art pipeline.

The World Congress reward uses the Community Patch `ResolutionResult` event and applies when a passed enactment has the `EmbargoPlayer` effect and targets Filthy Frank. Denunciation rewards are detected as state transitions, which prevents repeated points from one unchanged diplomatic state.

</details>
