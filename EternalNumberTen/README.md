# The Eternal Number Ten

**CIVILIZATION FIELD GUIDE** · [Cool Wacky Civs](../README.md) · Brave New World + Community Patch

> *From a first touch in Rosario to a career the world remembers.*

<img src="../art-source/EternalNumberTen/EternalDawn.png" alt="The Eternal Number Ten artwork" width="960">

| At a glance | Details |
| --- | --- |
| **Leader** | Lionel Messi |
| **Signature system** | From Rosario to Immortality |
| **Playstyle** | Permanent Legacy · Great People · coordinated formations · Golden Ages |
| **Player access** | Human-only — `Playable = 1`, `AIPlayable = 0` |
| **Requirements** | Civilization V: Brave New World; Community Patch v151 / 5.4.2+ |
| **Supported mode** | New single-player campaign; collection multiplayer/hotseat disabled |

## UA, UU and UBs

**UA** = Unique Ability · **UU** = Unique Unit · **UB** = Unique Building · **UI** = Unique Improvement.

| Type | Name | Replaces / role | What it does |
| --- | --- | --- | --- |
| **UA** | **From Rosario to Immortality** | Civilization trait | Legacy and Career Chapters. |
| **UU** | **The Number Ten** | Great General | Retains Citadel construction; has 2 Movement and ignores terrain costs/Zone of Control. Adjacent combat units receive turn-long Vision: +1 Movement, ignored Zone of Control and +6% flanking. Can build a Football Academy; assisted killers with Vision heal 5 HP. |
| **UB** | **La Masia** | Garden | At Theology, costs 135 Production without a Fresh Water requirement. Provides +15% Great Person generation, +1 Culture and floor(Specialists / 2) Food. A local Great Person birth adds 1 Legacy, one WLTKD turn and a refreshable six-turn +5% Production bonus. |
| **UI** | **Football Academy** | Alternative improvement built by The Number Ten; Citadel remains available | Culture-bombs one tile and provides +1 Culture/+1 Science, plus +1 Tourism after Flight. A stationed unit gains +10% Defense. Adds +1 Gold to its assigned working city if that city has a specialist-slot building. |

The UI is a tile improvement; it is separate from the UB.

**Explore:** [UA / UU / UBs](#ua-uu-and-ubs) · [Signature kit](#signature-kit) · [Mechanics](#mechanics-and-reference) · [Campaign guide](#campaign-guide) · [Worked example](#worked-example) · [Field notes](#field-notes) · [Install](#installation-and-validation) · [Developer reference](#developer-reference)

---

## Civilization identity

The Eternal Number Ten turns a career into a campaign. Great People, Wonders, alliances and team play write a persistent Legacy, carrying the civilization from a modest opening through six permanent chapters. Formation bonuses and academies make the football theme part of economic development and battlefield coordination as well as the story.

## Signature kit

**The core loop:** Create defining moments → earn Legacy → cross threshold and Era gates → keep the chapter bonuses forever.

| Element | Replaces / threshold | What it contributes |
| --- | --- | --- |
| Legacy | Permanent career progress | Great People, Wonders, first-per-era alliance/Golden Age moments and qualifying Assists. |
| Six Career Chapters | 25 / 55 / 90 / 130 / 180 / 240 Legacy | Permanent unlocks, with Era gates after Chapter I. |
| The Number Ten | Great General replacement | Mobile support, Vision aura, Citadel or Football Academy construction. |
| La Masia | Garden replacement at Theology | Specialist Food, Great Person support and additional Legacy on a local Great Person birth. |
| Football Academy | Alternative General improvement | Culture/Science, Flight Tourism and conditional working-city Gold. |

Campaign advice explains how to use the implemented mechanics. Numeric worked examples use Standard speed unless stated otherwise. Inherited base-unit and base-building statistics follow the active ruleset.

## Mechanics and reference

### Unique ability — From Rosario to Immortality

Legacy is stored per player through `Modding.OpenSaveData`. Great People grant 2, World Wonders grant 4, and the first City-State alliance and Golden Age in each Era grant 3. A qualifying Assist grants 1 Legacy, 15% of the defeated unit's base strength as Culture, and the same amount of Golden Age Points, with a 2–12 yield clamp and a two-reward player-turn cap.

At the beginning of a turn, an eligible land combat unit beside at least two friendly combat units receives One-Two Football for that turn: +1 Movement, +5% Combat Strength, and +10% Flanking Bonus. Chapter III raises the strength bonus to +8% total.

### Career Chapters

| Chapter | Requirement | Permanent result |
| --- | --- | --- |
| A Ball and a Dream | 25 Legacy | Capital +1 Food/+1 Production; new cities +10 Food; Capital-trained Scouts and civilians +1 Sight |
| The Napkin Contract | 55 Legacy, Classical | +6% Great Person generation; free Capital La Masia after Theology; Capital Specialists +1 Science |
| The Golden Years | 90 Legacy, Renaissance | +10% Golden Age duration; Assist yields +15%; stronger One-Two Football; Wonders +1 Culture |
| Heavy Is the Shirt | 130 Legacy, Industrial | unlocks four-turn Resilience after specified setbacks, with a 22-turn civilization cooldown |
| The Long-Awaited Crown | 180 Legacy, Modern | allied City-State Culture/Happiness, +10% quest Influence, +17% Great General aura, quest Legacy |
| The Third Star | 240 Legacy, Atomic | one-time Golden Age/WLTKD/policy/healing/XP and permanent Golden Age Science/Tourism plus Great Work Culture |

Legacy can accumulate before an Era gate. The runtime checks every unmet chapter after Legacy or Era changes and never grants a chapter twice.

Every 55 Legacy earned after Chapter VI actually unlocks grants a two-turn Golden Age and `15 × current Era number` Culture. Legacy banked before the Atomic Era gate does not count toward these repeats. The first six repeat rewards also grant +1% permanent Tourism each; later repeats retain the Golden Age and Culture without exceeding +6% Tourism.

### Uniques

- **The Number Ten** replaces the Great General. It has 2 Movement, ignores terrain movement costs and enemy Zones of Control, retains Citadel construction, and can build a Football Academy. Adjacent combat units receive Vision Beyond the Defence for the turn: +1 Movement, ignored enemy Zones of Control, and +6% Flanking Bonus. An assisted killer with Vision heals 5 HP.
- **La Masia** replaces the Garden at Theology. It costs 135 Production, requires no Fresh Water, supplies +15% Great Person generation and +1 Culture, and adds exactly `floor(Specialists / 2)` Food. A Great Person born there grants one WLTKD turn, one additional Legacy, and a refreshable six-turn +5% Production bonus.
- **Football Academy** is an alternative Great General improvement. It culture-bombs one tile, supplies +1 Culture and +1 Science, adds +1 Tourism after Flight, gives a stationed unit +10% Defense, and deals no adjacent damage. Each Academy assigned to a working city contributes exactly +1 Gold to that city when it contains at least one specialist-slot building.

### Legacy panel

The gameplay runtime and optional Legacy panel are registered as separate in-game add-ins. The panel shows current Legacy, the next threshold and Era gate, all six chapters, chapter story/effects, the Third Star, and Epilogue history. It waits safely for `MapModData.MessiLegacy` if its UI context loads first; closing or failing to load the panel does not disable gameplay.

---

## Campaign guide

### Opening — earn the first moments

The civilization starts without an immediate numerical trait bonus. Build an ordinary foundation, meet City-States and pursue sustainable Great Person generation. Chapter I arrives at 25 Legacy; pursuing every World Wonder at the expense of your economy can delay the whole career.

### Middle game — build the academy and the formation

Use La Masia and specialists to grow Great People and Legacy. Keep land combat units in useful supporting formations at turn start for One-Two Football. Position the Number Ten safely so Vision reaches troops that can convert the mobility into a real Assist.

### Late game — close the career

Track both Legacy and the next Era gate in the panel. A banked threshold waits for its Era. After the Third Star actually unlocks, begin building new 55-Legacy Epilogue cycles; the earlier bank does not generate retroactive repeats.

## Worked example

You reach **90 Legacy in Medieval**. Chapters I and II can be earned if their requirements are met, but Chapter III waits for **Renaissance**. The Legacy is not lost. Once that Era gate opens, the runtime can award the chapter without requiring you to earn the same 90 again.

## Field notes

### Is Legacy spent when a chapter unlocks?

No. It is career progress; the threshold and Era gate determine whether a chapter can unlock.

### Can I repeatedly break and regain one alliance for Legacy?

The core alliance reward is the first qualifying alliance in each Era. Repeated transitions do not reset that per-Era reward.

### Does closing the panel stop the career?

No. The runtime and optional panel load independently. Legacy, chapters and timers continue through gameplay hooks.

---

## Installation and validation

This civilization ships with **all twelve civilizations in one Cool Wacky Civs package**. Install and enable the collection once; there is no separate per-civilization mod to enable.

1. Install Civilization V with **Brave New World** and the required **Community Patch**.
2. Put the collection's unpacked mod folder in the game's `MODS` directory, or import its `.civ5mod` package.
3. Enable Community Patch and **one version** of Cool Wacky Civs through the Mods menu.
4. Start a **new single-player game** and choose **The Eternal Number Ten** for the human player. All collection civilizations are excluded from normal AI selection.

To validate or rebuild from source, run these commands from the **collection root**, one directory above this README:

```powershell
python tools/validate_messi_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

The first command focuses on this civilization; the second checks the complete collection. The builder writes an unpacked folder, ZIP and native LZMA `.civ5mod` under `dist/`, using the current version in [the project](../CoolWackyCivs.civ5proj). If development dependencies are missing, follow the [collection setup instructions](../README.md#build-and-validation).

**Testing boundary:** automated checks cover the database, packaging and applicable Lua behavior. A running Civ V match is still needed to confirm executable timing, combat previews, UI transitions and save/load behavior.

## Developer reference

<details>
<summary><strong>Expand implementation, artwork and detailed validation notes</strong></summary>

Ordinary setup is human-only. Any AI routines described here are retained fallback implementation, rather than permission for Civ V to select this civilization as an AI opponent.

### Community Patch dependencies

- `UnitPrekill` plus battle membership hooks provide reliable victim position and killer attribution for Assists and military-death Resilience.
- `PlayerGoldenAge(iPlayer, bStart, iTurns)` detects Golden Age starts and ends.
- `MinorAlliesChanged(iMinor, iMajor, bIsAlly, iOldFriendship, iNewFriendship)`, enabled by `EVENTS_MINORS`, detects alliance gains and losses immediately; idempotent turn snapshots provide a save/load fallback.
- `UnitConverted(iOldPlayer, iNewPlayer, iOldUnit, iNewUnit, bIsUpgrade)`, enabled by `EVENTS_UNIT_CONVERTS`, refreshes the converted unit and safely coexists with the upgrade hook.
- `CityConstructed`, `UnitCreated`, `PlayerCityFounded`, `TeamTechResearched`, and unit upgrade hooks keep rewards and states event-driven.
- Hidden CP policies implement exact Great Person rate, Golden Age duration, quest Influence, Great General aura, Golden Age yield, Great Work yield, and permanent Tourism effects.

The Community Patch does not expose a dedicated quest-completed Lua hook. Chapter V therefore compares each City-State's displayed quest count and Influence at the Messi turn boundary. A decreased quest count accompanied by increased Influence counts as completion; its per-Era Legacy cap is persisted. The +10% Influence reward itself is an exact CP policy effect.

The promotion API cannot remove ignored Zone of Control after only the first movement action, so Vision grants it for the whole receiving turn. This is the closest stable event-driven equivalent and does not change the specified Movement or Flanking values.

### Debugging

Set `DEBUG = true` near the top of `Lua/MessiRuntime.lua`, enable Civ V logging, and inspect `Lua.log` for chapter, La Masia, and Resilience messages. Persistent keys are namespaced as `Messi|<playerID>|...`; no state uses a global player assumption.

Run the deterministic and package validators from the repository root:

```powershell
python tools/validate_messi_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

### In-game smoke checklist

1. Start as The Eternal Number Ten and confirm Rosario is the Capital and the Legacy launcher appears.
2. Use FireTuner or normal play to cross every threshold before and after its Era gate; confirm each chapter unlocks once.
3. Form and break a three-unit triangle across turns; verify temporary promotions clear and Vision stacks with One-Two Football.
4. Kill beside another friendly unit; verify two rewards per turn, Culture/GAP rounding, Legacy, and Vision healing.
5. Trigger every Resilience source; verify four active turns, no magnitude stacking, and the 22-turn cooldown.
6. Research Theology before and after Chapter II; confirm exactly one free Capital La Masia.
7. Change specialist counts and produce Great People in La Masia; verify floor division and Production-duration refresh.
8. Gain, lose, and regain City-State alliances within one Era; confirm the first-alliance reward cannot be farmed.
9. Complete at least three quests in one Era; confirm only two grant Legacy and quest Influence is 10% higher.
10. Unlock Chapter VI, then trigger at least seven Epilogue rewards; confirm Tourism stops at +6% while Culture and Golden Ages continue.
11. Save and reload during Resilience and La Masia Production; confirm remaining durations and chapter state survive.

### Art

The leader, Dawn of Man, and Football Academy source PNGs were produced with the built-in image generator and compiled into Civ V DDS families by `tools/make_messi_assets.py`. The generator's public-figure safeguard rejected a direct Messi portrait, so the final leader scene intentionally uses an original, non-identifiable symbolic Number Ten figure. No team crests, sponsor marks, federation marks, or tournament branding are used.

</details>
