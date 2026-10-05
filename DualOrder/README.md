# The Dual Order

**CIVILIZATION FIELD GUIDE** · [Cool Wacky Civs](../README.md) · Brave New World + Community Patch

> *Raise the altar. Arm the chapter. Keep both mandates in balance.*

<img src="../art-source/DualOrder/DualOrderDawn.png" alt="The Dual Order artwork" width="960">

| At a glance | Details |
| --- | --- |
| **Leader** | Grandmaster Severin |
| **Signature system** | Twin Mandates |
| **Playstyle** | Faith-backed warfare · military infrastructure · Golden Age mobilization |
| **Player access** | Human-only — `Playable = 1`, `AIPlayable = 0` |
| **Requirements** | Civilization V: Brave New World; Community Patch v151 / 5.4.2+ |
| **Supported mode** | New single-player campaign; collection multiplayer/hotseat disabled |


## UA, UU and UBs

**UA** = Unique Ability · **UU** = Unique Unit · **UB** = Unique Building · **UI** = Unique Improvement.

| Type | Name | Replaces / role |
| --- | --- | --- |
| **UA** | **Twin Mandates** | Civilization trait: paired infrastructure, Zeal and Balance Pressure |
| **UU** | **Divided Templar** | Longswordsman |
| **UB** | **Hall of Concordance** | Armory |

**Explore:** [UA / UU / UBs](#ua-uu-and-ubs) · [Signature kit](#signature-kit) · [Mechanics](#mechanics-and-reference) · [Campaign guide](#campaign-guide) · [Worked example](#worked-example) · [Field notes](#field-notes) · [Install](#installation-and-validation) · [Developer reference](#developer-reference)

---

## Civilization identity

Severin governs a realm where altar and arsenal share responsibility. Religious infrastructure supplies conviction, military infrastructure prepares its defense, and both together shape the troops a city trains. The result is a civilization whose wartime strength depends on maintaining a functioning religious and productive home front.

## Signature kit

**The core loop:** Pair religious and military buildings → train Zeal-bearing troops → maintain positive Faith → mobilize during Golden Ages.

| Element | Replaces / threshold | What it contributes |
| --- | --- | --- |
| Twin Mandates | Barracks / Armory / Temple classes | Each qualifying building supplies +1 Production and +1 Faith, including unique replacements. |
| Zeal | Normally trained military units | +10% strength inside/adjacent to friendly territory and 10 HP healing after a kill; survives upgrades. |
| Balance Pressure | Positive Faith per turn | +2% combat and +1% empire Production per active opposing civilization, capped at five. |
| Divided Templar | Longswordsman replacement | 23 strength, +10% cost, Cover I and conditional Schism Strike bonuses. |
| Hall of Concordance | Armory replacement | Inherited Armory, extra Faith/Production/XP, founded-religion Happiness and Great General progress. |

Campaign advice explains how to use the implemented mechanics. Numeric worked examples use Standard speed unless stated otherwise. Inherited base-unit and base-building statistics follow the active ruleset.

## Mechanics and reference

### Prepare a chapter city

1. Establish military-training infrastructure and religious infrastructure in the **same city**.
2. Normally produce the military unit there to receive Zeal.
3. Keep Faith per turn positive when using Balance Pressure.
4. Use a Golden Age as a training window: the extra XP applies to normally trained units completing during it.
5. Build a Hall to deepen the city's training, Faith and Production role.

The Hall's listed +3 Faith and +2 Production are its own additions to the inherited Armory. Its Armory class also qualifies for the separate Twin Mandates +1 Faith/+1 Production effect.

### Templar conditions at a glance

| Condition | Bonus | Practical check |
| --- | --- | --- |
| Zeal unit inside or adjacent to friendly territory | +10% strength | Position before fighting |
| Templar attacks a unit below 50% HP | +20% attack | Exactly half health does not satisfy “below” |
| Adjacent friendly Prophet, Missionary or Inquisitor | +10% strength | A Great General does not replace religious support |
| Zeal unit kills an enemy | Heal 10 HP | A kill reward, not passive healing |

These are different conditions. Read combat previews and keep vulnerable religious units out of enemy reach.

### Unique ability — Twin Mandates

- Barracks, Armories, Temples, and their unique replacements provide +1 Production and +1 Faith.
- Normally trained military units gain Zeal when their city contains both military-training and religious infrastructure.
- Zeal grants +10% Combat Strength inside or adjacent to friendly territory and heals 10 HP after a kill. It persists through upgrades.
- While Faith per turn is positive, each civilization currently at war with the Dual Order grants +2% Combat Strength and +1% Production in all Cities, capped at five wars.
- During Golden Ages, Cities receive +25% Production toward military units and normally trained military units receive +5 XP.

The compact in-game Balance Pressure indicator reports the current faith gate, counted wars, combat bonus, and empire Production bonus.

### Unique unit — Divided Templar

The Divided Templar replaces the Longswordsman. It has 23 Combat Strength, costs 10% more Production, and begins with Cover I and Schism Strike. Schism Strike grants +20% attack strength against units below 50% HP and +10% Combat Strength while adjacent to a friendly Great Prophet, Missionary, or Inquisitor.

### Unique building — Hall of Concordance

The Hall of Concordance replaces the Armory and inherits all Community Patch Armory effects. It adds +3 Faith, +2 Production, and five more XP to trained units. A Hall provides +1 Happiness when its City follows the Dual Order's founded religion, and each Hall contributes +1 Great General Point per turn.

---

## Campaign guide

### Opening — build both institutions

Grow your cities while establishing religious income and a military-training center. Mandate yields make selected infrastructure more useful, but Zeal requires both roles in the city that trains the unit. A training city with no religious building has only completed half the setup.

### Middle game — fight around the chapter

Use ranged damage to bring enemy units below half health, then let Templars finish them. Keep religious support protected while exploiting adjacency. Zeal is strongest near friendly territory, so controlled border campaigns suit it better than unsupported advances.

### Golden Ages — turn conviction into troops

Queue military production during Golden Ages to use the +25% training modifier and +5 completion XP. Halls improve that training base. Check the Balance Pressure indicator when Faith income changes; a large stored Faith pool does not replace positive Faith generation.

## Worked example

With **positive Faith income** and **three opposing civilizations at war**, Balance Pressure grants **+6% Combat Strength** and **+3% Production**. At five it reaches **+10% / +5%**; further wars add nothing. If income becomes zero, the gate closes even if thousands of Faith remain stored.

## Field notes

### Do purchases receive Zeal and Golden Age training XP?

Those rewards are for normally trained military units. Buying a unit does not satisfy the normal-production condition.

### Must I found a religion to use the entire trait?

The trait's infrastructure and positive-Faith war gate do not require a founded religion. A Hall's conditional Happiness specifically does require the city to follow your founded religion.

### Will declaring more wars always help?

The bonus caps at five opposing civilizations. Added fronts can cost far more than a small combat/Production modifier supplies.

---

## Installation and validation

This civilization ships with **all twelve civilizations in one Cool Wacky Civs package**. Install and enable the collection once; there is no separate per-civilization mod to enable.

1. Install Civilization V with **Brave New World** and the required **Community Patch**.
2. Put the collection's unpacked mod folder in the game's `MODS` directory, or import its `.civ5mod` package.
3. Enable Community Patch and **one version** of Cool Wacky Civs through the Mods menu.
4. Start a **new single-player game** and choose **The Dual Order** for the human player. All collection civilizations are excluded from normal AI selection.

To validate or rebuild from source, run these commands from the **collection root**, one directory above this README:

```powershell
python tools/validate_dual_order_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

The first command focuses on this civilization; the second checks the complete collection. The builder writes an unpacked folder, ZIP and native LZMA `.civ5mod` under `dist/`, using the current version in [the project](../CoolWackyCivs.civ5proj). If development dependencies are missing, follow the [collection setup instructions](../README.md#build-and-validation).

**Testing boundary:** automated checks cover the database, packaging and applicable Lua behavior. A running Civ V match is still needed to confirm executable timing, combat previews, UI transitions and save/load behavior.

## Developer reference

<details>
<summary><strong>Expand implementation, artwork and detailed validation notes</strong></summary>

Ordinary setup is human-only. Any AI routines described here are retained fallback implementation, rather than permission for Civ V to select this civilization as an AI opponent.

### Implementation notes

The unique unit and building are cloned at database activation, including their BNW and Community Patch companion-table rows. Lua controls position-sensitive promotions, below-half-health attack setup, faith-gated war tiers, dummy buildings, founded-religion Happiness, kill healing, Great General points, and the UI indicator. The project includes a deterministic Lua 5.1 mock and SQL validation against the installed Community Patch schema.

The concept sheet remains the canonical heraldry source. Its emblem is extracted without redesign for the civilization and alpha atlases; separate generated source art is retained for Grandmaster Severin, the Divided Templar, the Hall of Concordance, the Dawn of Man, and the civilization map.

</details>
