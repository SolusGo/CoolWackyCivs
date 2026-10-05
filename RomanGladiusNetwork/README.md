# The RomanGladius Network

**CIVILIZATION FIELD GUIDE** · [Cool Wacky Civs](../README.md) · Brave New World + Community Patch

> *One more Player. One healthier Server. One Network worth returning to.*

<img src="../art-source/RomanGladiusNetwork/RomanGladiusLeader.png" alt="The RomanGladius Network artwork" width="960">

| At a glance | Details |
| --- | --- |
| **Leader** | Lachlan “RomanGladius” |
| **Signature system** | The Server Network |
| **Playstyle** | Tall population · Reputation management · staff and incidents |
| **Player access** | Human-only — `Playable = 1`, `AIPlayable = 0` |
| **Requirements** | Civilization V: Brave New World; Community Patch v151 / 5.4.2+ |
| **Supported mode** | New single-player campaign; collection multiplayer/hotseat disabled |

## UA, UU and UBs

**UA** = Unique Ability · **UU** = Unique Unit · **UB** = Unique Building · **UI** = Unique Improvement.

| Type | Name | Replaces / role | What it does |
| --- | --- | --- | --- |
| **UA** | **The Server Network** | Civilization trait | Population yields, Reputation and Server management. |
| **UU** | **Server Owner** | Settler | Costs 60% more Production and consumes 2 Population on creation, including purchases. Founding installs a free Console, starts the Server at 60 Reputation and grants ten turns of +50% Food. Later launches charge escalating Gold fees. |
| **UB** | **Server Console** | Monument | Provides +2 Culture/+1 Gold and enables Server Management: Reputation, staffing, incidents, roster and chat. Every newly founded Server receives one free. |

**Explore:** [UA / UU / UBs](#ua-uu-and-ubs) · [Signature kit](#signature-kit) · [Mechanics](#mechanics-and-reference) · [Campaign guide](#campaign-guide) · [Worked example](#worked-example) · [Field notes](#field-notes) · [Install](#installation-and-validation) · [Developer reference](#developer-reference)

---

## Civilization identity

Every city is a Server and every citizen a Player in Lachlan's community-management empire. The dashboard gives each place its own staff, Reputation, chat and incidents. Beneath the humor is a population economy: healthy communities grow into better yields, while neglected incidents can damage the people and output that made them successful.

## Signature kit

**The core loop:** Grow Players → earn threshold yields → appoint proportionate staff → protect Reputation → grow again.

| Element | Replaces / threshold | What it contributes |
| --- | --- | --- |
| Server Network | Population-driven yields | Per city: +1 Gold per two Population, +1 Science per four, +1 Culture per five. |
| Reputation | 0–100 per Server | Six bands alter local Food, Gold and Culture; incidents and staff influence stability. |
| Server Owner | Settler replacement | +60% Production cost, two-Population creation cost and escalating launch Gold. |
| Server Console | Monument replacement | +2 Culture/+1 Gold, Server Management and free installation on founding. |
| Network Dashboard | Interactive management panel | Inspect staff, roster, logs, chat, active modifiers and unresolved incidents. |

Campaign advice explains how to use the implemented mechanics. Numeric worked examples use Standard speed unless stated otherwise. Inherited base-unit and base-building statistics follow the active ruleset.

## Mechanics and reference

### Reputation ladder

| Band | Reputation | Food | Gold | Culture |
| --- | ---: | ---: | ---: | ---: |
| Legendary | 90–100 | +20% | +15% | +10% |
| Thriving | 70–89 | +10% | +10% | — |
| Stable | 50–69 | — | — | — |
| Troubled | 30–49 | -10% | — | — |
| Toxic | 10–29 | -20% | -10% | — |
| Dead Server | 0–9 | -50% | — | — |

The current band supplies its own modifiers. Grand Opening, Owner Online and Peak Hours are separate effects. Below 30 Reputation, periodic departure checks can remove a Player, creating a feedback loop between weak growth and lost threshold yields.

### Staff desk

| Role | Population gate | Appointment cost | Ongoing role |
| --- | ---: | --- | --- |
| Moderator | 4 | 75 Gold + 25 per existing Moderator in that Server | +1 Culture, coverage and incident handling |
| Administrator | 8 | Promote an existing Moderator for 150 Gold | Senior support; 2 Gold upkeep per turn; one maximum |

Each Moderator supplies one coverage point and an Administrator supplies two. From four Population onward, required coverage is `max(1, floor((Population + 4) / 5))`; too many Moderators can separately trigger overmoderation.

With adequate coverage, Reputation below equilibrium recovers by one per turn, or two with an Administrator. Undermoderation instead loses two per turn; overmoderation loses one. Base equilibrium is 50, with +10 for the capital and +10 after the 100-Player milestone.

### Network milestones

| Total Players | One-time / lasting result |
| ---: | --- |
| 10 | 100 Gold |
| 25 | A free Moderator in the capital |
| 50 | +1 Happiness per Server |
| 100 | Permanent +10% Gold/Culture and +10 Reputation equilibrium |

The dashboard's roster and chat give the cities character. Population, staff, Reputation and incident outcomes are the gameplay systems behind that presentation.

### Unique Ability — The Server Network

- Every 2 Players in a Server provide +1 Gold, every 4 provide +1 Science, and every 5 provide +1 Culture.
- Each Server has persistent 0–100 Reputation, Moderators, up to one Administrator, a generated Player roster, Server Chat, logs, activity, and events.
- Reputation bands apply the design's Food, Gold, and Culture modifiers: Legendary (90–100), Thriving (70–89), Stable (50–69), Troubled (30–49), Toxic (10–29), and Dead Server (0–9).
- The Capital has Owner Online: +10% Production, +10% Gold, and +10 Reputation equilibrium.
- Total Population milestones award 100 Gold at 10, a free Capital Moderator at 25, +1 Happiness per Server at 50, and permanent +10% Gold/Culture plus +10 Reputation equilibrium at 100.

The in-game Network Dashboard lists every Server and exposes its staff, roster, chat, log, Reputation band, timed bonuses, and unresolved incident. Human players choose how to resolve incidents. Retained AI fallback logic can staff and resolve Servers automatically, but ordinary setup cannot assign this civilization to AI.

### Unique Unit — Server Owner

Replaces the Settler. It costs 60% more Production and always consumes 2 Population when created, including when purchased. Launching the second Server costs 100 Gold, the third costs 200, and so on. Every newly founded Server, including the first, receives a free Server Console, starts at 60 Reputation, and has Grand Opening (+50% Food) for 10 turns. Scenario, Advanced Start, and other preplaced Roman cities receive the same setup exactly once without a retroactive launch fee.

### Unique Building — Server Console

Replaces the Monument and provides +2 Culture and +1 Gold. It unlocks Server Management, Reputation, Chat, staff actions, and events for that City. Server Owners install one for free when founding a new Server.

### Staff and events

Moderators become available at 4 Population, cost Gold, contribute +1 Culture, stabilize Reputation, and help resolve incidents. Administrators become available at 8 Population, are promoted from Moderators, cost 150 Gold, and have 2 Gold maintenance per turn. Understaffing and overmoderation both harm a Server.

The runtime includes Suspected Cheater, Griefer Attack, Moderator Abuse, Staff Civil War, Server Crash, Duplication Exploit, Community Build, and Generous Donator choices, plus automatic Viral Server, Veteran Returns, and Player Record events. Outcomes alter Population, Reputation, Gold, Science, Culture, Production, staff, and timed Peak Hours.

---

## Campaign guide

### Opening — make the first Server work

Grow the capital and use its free Console and Grand Opening window. Avoid launching a new Server before the parent city can afford the two-Population cost and the treasury can pay the founding fee. Large, stable cities multiply the trait's yield thresholds.

### Middle game — staff for the population

At four Players, consider a Moderator; at eight, an Administrator becomes possible. Keep coverage proportional instead of hiring indiscriminately. Save a treasury buffer for incident responses. Read each city's Reputation and log before deciding which problem deserves Gold first.

### Late game — keep the Network healthy

Pursue total-Population milestones while protecting each local community. High Reputation supports growth and economic output; neglected Servers can lose Players and fall below yield thresholds. Use the dashboard regularly after expansion, conquest or large population changes.

## Worked example

A **12-Player Server** supplies **+6 Gold**, **+3 Science** and **+2 Culture** from population thresholds before its Console, staff or percentage modifiers. A separate **3-Player Server** contributes **+1 Gold, +0 Science and +0 Culture**. These floors are calculated per city; leftover population fractions do not pool across the Network.

## Field notes

### Can buying a Server Owner avoid population loss?

No. Creating one consumes two Population, including purchases; its launch fee is a separate founding requirement.

### Does an Administrator appear in addition to the promoted Moderator?

Promotion converts a Moderator into an Administrator. A Server can have at most one Administrator, with two Gold upkeep per turn.

### Should every Server have as many Moderators as possible?

No. Overmoderation harms Reputation just as understaffing does. Check the dashboard's current coverage state.

---

## Installation and validation

This civilization ships with **all twelve civilizations in one Cool Wacky Civs package**. Install and enable the collection once; there is no separate per-civilization mod to enable.

1. Install Civilization V with **Brave New World** and the required **Community Patch**.
2. Put the collection's unpacked mod folder in the game's `MODS` directory, or import its `.civ5mod` package.
3. Enable Community Patch and **one version** of Cool Wacky Civs through the Mods menu.
4. Start a **new single-player game** and choose **The RomanGladius Network** for the human player. All collection civilizations are excluded from normal AI selection.

To validate or rebuild from source, run these commands from the **collection root**, one directory above this README:

```powershell
python tools/validate_roman_gladius_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

The first command focuses on this civilization; the second checks the complete collection. The builder writes an unpacked folder, ZIP and native LZMA `.civ5mod` under `dist/`, using the current version in [the project](../CoolWackyCivs.civ5proj). If development dependencies are missing, follow the [collection setup instructions](../README.md#build-and-validation).

**Testing boundary:** automated checks cover the database, packaging and applicable Lua behavior. A running Civ V match is still needed to confirm executable timing, combat previews, UI transitions and save/load behavior.

## Developer reference

<details>
<summary><strong>Expand implementation, artwork and detailed validation notes</strong></summary>

Ordinary setup is human-only. Any AI routines described here are retained fallback implementation, rather than permission for Civ V to select this civilization as an AI opponent.

### Compatibility

Requires Brave New World and Community Patch 151 / release 5.4.2 or newer. The civilization is human-only (`Playable = 1`, `AIPlayable = 0`). State is stored per City identity so captures or refounded City IDs cannot inherit another Server's records.

</details>
