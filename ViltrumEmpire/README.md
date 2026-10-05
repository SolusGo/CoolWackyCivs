# The Viltrum Empire

**CIVILIZATION FIELD GUIDE** · [Cool Wacky Civs](../README.md) · Brave New World + Community Patch

> *Conquer before the Scourge. Choose what survives it.*

<img src="../art-source/ViltrumEmpire/Thragg.png" alt="The Viltrum Empire artwork" width="960">

| At a glance | Details |
| --- | --- |
| **Leader** | Grand Regent Thragg |
| **Signature system** | Blood of Conquest |
| **Playstyle** | Aggressive conquest · elite Bloodline troops · guaranteed crisis · survival choices |
| **Player access** | Human-only — `Playable = 1`, `AIPlayable = 0` |
| **Requirements** | Civilization V: Brave New World; Community Patch v151 / 5.4.2+ |
| **Supported mode** | New single-player campaign; collection multiplayer/hotseat disabled |

## UA, UU and UBs

**UA** = Unique Ability · **UU** = Unique Unit · **UB** = Unique Building · **UI** = Unique Improvement.

| Type | Name | Replaces / role | What it does |
| --- | --- | --- | --- |
| **UA** | **Blood of Conquest** | Civilization trait | Conquest rewards, Momentum and the Scourge crisis. |
| **UU** | **Viltrumite Warrior** | Infantry | 82 strength, 3 Movement, 1300 Production at Replaceable Parts. Ignores terrain costs, crosses mountains/coasts and deploys seven tiles. Gains conditional +15% attack against units below 50 HP and +20% city attack below half HP; personal city captures heal 35 HP. |
| **Additional unit** | **Auxiliary Infantry** | Separate conventional Infantry option; retains the active Infantry baseline | Retains conventional Infantry statistics, resources, upgrades and model. Provides an ordinary army option excluded from the Scourge's Bloodline casualty selection. |
| **UB** | **Viltrumite Breeding Complex** | Military Academy | Retains Military Academy effects; adds +15 training XP, +2 Production, +1 Food and +5% military Production. First construction adds 1 Population once per original city; protects one citizen during the Scourge and gives trained land troops Imperial Conditioning. |

The Warrior occupies the Infantry replacement slot. Auxiliary Infantry is a separate conventional option with its own unit class.

**Explore:** [UA / UU / UBs](#ua-uu-and-ubs) · [Signature kit](#signature-kit) · [Mechanics](#mechanics-and-reference) · [Campaign guide](#campaign-guide) · [Worked example](#worked-example) · [Field notes](#field-notes) · [Install](#installation-and-validation) · [Developer reference](#developer-reference)

---

## Civilization identity

Thragg leads a conquest empire with a catastrophe built into its progression. Elite Warriors create extraordinary military opportunities, but the guaranteed Scourge forces the player to consider what will remain after biological collapse. Conventional forces, prepared cities and genuine survivors make the recovery as important as the early expansion.

## Signature kit

**The core loop:** Conquer and build Momentum → develop the Bloodline → face the Scourge → endure quarantine or a dying crusade → recover.

| Element | Replaces / threshold | What it contributes |
| --- | --- | --- |
| Blood of Conquest | Qualifying land military kills | 15 HP healing normally, 10 during Dying Empire and none during quarantine. |
| Imperial Momentum | First foreign-city conquest | +15% military Production, +3 training XP and +5% city attack during a bounded timer. |
| Viltrumite Warrior | Replaceable Parts elite | 82 strength, 3 Movement, 1300 Production and native seven-tile deployment. |
| Auxiliary Infantry | Conventional alternative | Active ruleset Infantry statistics and requirements; outside biological casualty selection. |
| Breeding Complex | Military Academy replacement | Training support, once-per-original-city Population and a protected citizen in Scourge calculations. |

Campaign advice explains how to use the implemented mechanics. Numeric worked examples use Standard speed unless stated otherwise. Inherited base-unit and base-building statistics follow the active ruleset.

## Mechanics and reference

### Crisis route card

| Choice | Immediate Population retention | Bloodline casualties | Main crisis window, Standard | Recovery |
| --- | --- | --- | --- | --- |
| Quarantine | floor(25%), with capital/non-capital floors and Complex protection | Rounded 80%; at least two survivors if available | 20 turns: halted growth, -40% Production, additional -50% military Production, restricted Settler/trade-unit training and purchases | 20 turns of +25% Growth, +15% Production and +1 local Happiness per city |
| Crusade | floor(15%), with capital/non-capital floors and Complex protection | Rounded 90%; at least one survivor | 25 turns: -75% Growth, -50% Production, -10 global Happiness; ten-turn voluntary peace restriction | 15 turns of +15% Growth |

Quarantine survivors emerge at **25 HP** with Scourge-Hardened. Crusade survivors emerge at **10 HP** with Last Pureblood. First foreign conquests during Crusade shorten its crisis by one turn each. Timers scale with Game Speed; the detailed rules below record the survivor floors and exceptions.

### Read the Imperial Status panel

Use the top-center launcher to check countdowns and phases. Optional status controls hide in City View, diplomacy and full-screen popups; mandatory crisis decisions remain queued. A hidden optional launcher does not mean the countdown has stopped.

### Mechanics

| Mechanic | Implementation |
|---|---|
| Blood of Conquest | Battle participant snapshots distinguish actual land combat kills from civilians, barbarians and disbanding. Heals 15 HP, 10 during Dying Empire, zero during quarantine, capped at maximum HP. Air/interception deaths do not reward an unrelated defending land unit. |
| First foreign conquest | Save key includes plot coordinates, original owner and founding turn. Once per original city and Viltrum player: capital +1 Population, resistance reduced by rounded-up 20% (**minimum one turn if resistance exists**), Momentum. A matching melee capture context is required: CP also labels peace-ceded cities as conquests, and those must not award or consume rewards. History is consumed during quarantine too, preventing delayed recapture farming. Trades/liberation do not reward. Nil capitals are safe. |
| Imperial Momentum | Eight turns, additional first captures +3, maximum 18 remaining; speed-scaled. Dummy building gives +15% military Production, CityTrained grants +3 military XP, temporary promotion gives +5% city attack. Duration extends; bonus strength never stacks. |
| Garrisons | Hidden building: +1 Production, +1 local Happiness, +300 internal Defense (=3 strength). Movement refreshes garrisons; turn/capture refreshes repair state. Foreign owners have Viltrum dummy buildings removed. |
| Warrior | Infantry scalar and companion-table inheritance; explicit 82/3/1300/Replaceable Parts overrides and no resource requirements. DOMAIN_LAND, captures cities, free March, Bloodline, Flight, Execution and Planetbreaker. Standard Infantry model is reused; portrait and flag are custom. |
| Flight | Native IgnoreTerrainCost, HoveringUnit, CanCrossMountains and DropRange=7. Native friendly-territory deployment and visibility restrictions remain. ParadropAt resets the native made-attack flag after the engine leaves one movement point, allowing an attack. Coast/mountain pathfinding and animation require engine testing. |
| Execution / Planetbreaker | Before damage calculation, BattleJoined grants a temporary +15% strength against a combat target **strictly below 50 HP**, or +20% city attack against a city **strictly below half HP**. CombatResult identifies the combat actually resolving, including nested/queued defensive support. BattleFinished, the next battle start and load restoration clear target modifiers; abandoned withdrawal/abort contexts are bounded and cannot carry strength into later calculations. Personal Warrior city captures heal 35 HP. |
| Breeding Complex | Military Academy scalar and companion inheritance, plus +15 generic trained XP, +2 Production, +1 Food, +5% military Production. World-level original-city save key gives +1 Population only once, including after sale, transfer or reload. CityTrained grants land combat units persistent Conditioning. |
| Imperial Conditioning | Temporary +5% CombatPercent outside friendly territory; native +1 friendly/neutral healing HP, a rounded approximation of 5%. Persists through upgrades. |
| Great Purge | Once: Medieval+, two cities, 15 total Population, capital outside resistance. Strong choice: each city -1 Population (floor 1), existing military +10 XP, future land troops +3 XP, permanent +3% military Production, +1 combat experience/turn for 20 turns. Preservation choice: +10% Growth/20 turns, +1 Happiness/city/10 turns, Culture `round(75 × CulturePercent / 100 × (1 + .15 × era index))`. |
| AI Purge | Preserves population if Happiness is negative, over half its cities have Population <=3, fewer than four combat units exist, or a war score is below -30 / an enemy army is over 1.5 times stronger. Otherwise chooses the purge. |
| Guaranteed Scourge | Research turn is recorded by TeamTechResearched and a turn fallback. The first Warrior starts the countdown, or it starts after 12 turns without one. Outbreak follows eight turns later. All durations use `max(1, floor(base × TrainPercent / 100 + .5))`: Quick 8+5, Standard 12+8, Epic 18+12, Marathon 36+24. Starting with the tech records the initial turn. |
| Warnings | Countdown-start narrative, roughly three turns remaining, final one-turn warning; flags persist. Status panel shows the remaining turns. Warning Bloodline healing is slowed using native flat HP modifiers. |
| Casualties | Sort living Bloodline combat IDs, shuffle using synchronized Game.Rand, then kill an exact rounded share with survivor floors. Conventional units and civilians are untouched. Survivors are identified by permanent promotions, avoiding reused unit-ID save records. |
| Quarantine | Retain `max(capital ? 2 : 1, floor(pop × .25))`, plus one protected citizen with a Complex, capped at prior Population. Kill rounded 80%, retain at least two if available (one if only one). Survivors: 25 HP, Scourge-Hardened. For 20 turns: halt growth, -40% Production, an additional -50% military Production, slower healing, no kill/conquest rewards or Momentum, no training or purchasing new Settlers, Caravans or Cargo Ships. Workers, conventional troops and Warriors remain permitted by this veto; ordinary CP prerequisites still apply. Existing routes use CP RecallTrader(true). |
| Scourge-Hardened | Actual quarantine survivors only: +10% strength, +1 sight, native healing improvement approximating 20%. Preserved through upgrades. Outbreak runs once and cannot reselect these survivors. |
| Quarantine recovery | After the crisis: +25% Growth, +15% Production, +1 local Happiness/city for 20 turns. Only Warriors trained after the primary crisis ends receive Hardened Genome (+5% strength), never survivor promotions. The explicit recovered state and both crisis timers are checked, including CityTrained before PlayerDoTurn on the expiry turn. Existing units are not retroactively marked. |
| Crusade | Retain `max(capital ? 2 : 1, floor(pop × .15))`, plus Complex protection. Kill rounded 90%, floor one survivor. Survivors: 10 HP, Last Pureblood. End the Golden Age. For 25 turns: -75% Growth, -50% Production, -10 global Happiness; land troops cannot passively heal abroad. Kill healing becomes 10. Conquest rewards and Momentum continue; each first foreign-city conquest reduces the crisis by one turn. |
| Crusade peace restriction | Ten turns. Native temporary team war/peace flags block voluntary deals in CP's canChangeWarPeace; only mod-owned flags are removed. Pre-existing scenario flags remain. Native forced makePeace bypasses this gate. Save state restores/removes locks on load, expiry, elimination or forced peace. Post-state WarStateChanged uses team IDs; DeclareWar/MakePeace are not used because their CP hooks run before native war-state changes and their originating player can differ in chained wars. Only a Viltrum team with outstanding locks gets a turn fallback. PlayerCanMakePeace is dispatched by CP peace-deal validation and vetoes both teams, including teammates. |
| Last Pureblood | Actual crusade survivors only: +20% strength, +1 Movement, standard Blitz, +20% combat XP, another +20% strength when their own HP is below 50. Personally taking an enemy player's **current capital**, including a relocated capital fully heals the survivor. |
| Crusade recovery | Remove crisis Happiness/Production penalties; +15% Growth for 15 turns. No quarantine Production/Happiness recovery. Only Warriors trained after Dying Empire ends get Hardened Genome. Existing true survivors keep their persistent survivor promotions through upgrades and reloads. |
| Conceal the Extinction | Three speed-scaled turns after choice. Illusion costs max(speed-scaled 500, two turns of nonnegative net Gold income), granting 20 turns of +25% slower enemy tech theft and +10% city strength. Demonstration gives a capital Great General, genuine survivors +10 XP, at least five turns of Momentum, and up to two deterministic, valid-tile barbarian rebels near the weakest occupied city. Quarantine continues to suppress Momentum. No occupied city/valid space: rebels safely skip. |

---

## Campaign guide

### Before the crisis — build more than elites

Use conquest rewards and garrison benefits to build productive cities. Keep conventional troops, siege and an economy alongside Warriors. The Scourge selects Bloodline casualties; it does not delete ordinary support units. Replaceable Parts starts an unavoidable timetable even if you postpone producing a Warrior.

### At the decision — count the surviving empire

Read the mandatory choices and inspect Population, Complexes, treasury and ordinary forces. Quarantine preserves a larger share than Crusade but sharply limits growth, production and expansion. Crusade keeps conquest tools running through harsher losses and a peace restriction. Neither option erases the catastrophe.

### After the crisis — protect genuine survivors

Keep actual survivors alive to retain their unique promotions. Quarantine recovery supports rebuilding; Crusade recovery has a different package. Hardened Genome belongs to newly trained Warriors after the primary crisis ends, not to existing elites simply because time passed.

## Worked example

On Standard speed, Replaceable Parts with no Warrior starts the fallback countdown after **12 turns**; the outbreak follows **8 turns** later. Producing the first Warrior earlier begins that eight-turn countdown sooner. Refusing to build one does not avoid the Scourge. At Population **20**, quarantine retains **5** before Complex protection; Crusade retains **3**. A Complex adds one protected citizen, subject to the original Population cap.

## Field notes

### Can conventional Infantry avoid biological casualties?

Yes. Scourge casualties select Bloodline combat units; Auxiliary Infantry and other conventional units remain outside that selection.

### Does taking a city by peace deal trigger Momentum?

No. Rewards require a matching melee conquest context. CP's conquest-like peace-cession flag alone does not qualify.

### Does every new Warrior become a Scourge survivor?

No. Survivor promotions identify actual casualties' survivors. Hardened Genome is a separate post-primary-crisis training bonus.

---

## Installation and validation

This civilization ships with **all twelve civilizations in one Cool Wacky Civs package**. Install and enable the collection once; there is no separate per-civilization mod to enable.

1. Install Civilization V with **Brave New World** and the required **Community Patch**.
2. Put the collection's unpacked mod folder in the game's `MODS` directory, or import its `.civ5mod` package.
3. Enable Community Patch and **one version** of Cool Wacky Civs through the Mods menu.
4. Start a **new single-player game** and choose **The Viltrum Empire** for the human player. All collection civilizations are excluded from normal AI selection.

To validate or rebuild from source, run these commands from the **collection root**, one directory above this README:

```powershell
python tools/validate_viltrum_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

The first command focuses on this civilization; the second checks the complete collection. The builder writes an unpacked folder, ZIP and native LZMA `.civ5mod` under `dist/`, using the current version in [the project](../CoolWackyCivs.civ5proj). If development dependencies are missing, follow the [collection setup instructions](../README.md#build-and-validation).

**Testing boundary:** automated checks cover the database, packaging and applicable Lua behavior. A running Civ V match is still needed to confirm executable timing, combat previews, UI transitions and save/load behavior.

## Developer reference

<details>
<summary><strong>Expand implementation, artwork and detailed validation notes</strong></summary>

Ordinary setup is human-only. Any AI routines described here are retained fallback implementation, rather than permission for Civ V to select this civilization as an AI opponent.

### Growth halt and event costs

Quarantine now uses a native **-100%** growth policy. CP sums other bonuses before clamping at -100%, so a lone -100% policy can be offset by religion, WLTKD, Purge or VP Happiness. Fourteen hidden binary policies provide bounded compensation; only the amount needed to make each city's actual positive food surplus zero is applied. This runs on phase refresh and city-info dirty events with a reentrancy guard, never a frame update. Existing compensation stays until crisis expiry and is then cleared. CP only applies growth modifiers to positive surplus, preserving normal starvation. Stored food below threshold is untouched; food already at/above the smaller post-Scourge threshold is trimmed just below it to prevent a phantom citizen.

Garrison movement updates inspect only the moving unit's previously tracked city and current city. Full city refresh remains appropriate on load, ownership changes and phase/turn refreshes. Peace flags refresh on war-state changes, Crusade choice, load and outstanding-lock Viltrum turns; unrelated players and ordinary refreshes never run the global scanner.

Inheritance copies true `Unit_*` / `Building_*` companions and unit gameplay scripts. It does not duplicate foreign civilization overrides, promotion definitions or references granting free Infantry from another building. Warriors explicitly clear the scalar ResourceType and omit resource requirements/expenditure. Auxiliary Infantry preserves standard resource rules, scalar AI roles, companion AI roles and outgoing upgrades.

### Save compatibility

Save keys remain `VILTRUM:v1`; timers, capture/Complex history, choices and persistent unit promotions are preserved. Already-granted Genome from a v14 save is retained because that save has no trustworthy training-date record; only future training is corrected. New growth-lock policy types require the updated database. Real v14-to-v15 save loading has not been tested: back up saves and prefer a new game, as the collection already recommends. No previously earned rewards are revoked.

### Workarounds and limits

- **Healing percentages are approximations.** CP promotion columns are additive HP, not percentage multipliers. Warning: -5 friendly/-3 neutral/-3 enemy HP; quarantine: -10/-5/-5; Scourge-Hardened: +4/+2/+2; Conditioning: +1 friendly/neutral. These match or round ordinary CP field rates. Cities, medics, religions and VP's different rates can change the actual percentage. Combat/capture healing stays exact. No damage-monitoring UI event or frame polling is used.
- **Optional diplomatic hostility** is omitted: no stable custom-opinion contract is assumed. The rest of the optional event works. Its spy defense is implemented as slower enemy technology theft, not a universal modifier to every VP espionage mission.
- **AI tactics** use offensive/science/production flavors, subdued Warrior flavors, strong Complex training flavor and automated event choices. Runtime choices favor quarantine for weaker armies. Gold stockpiling, phase-specific war plans and individual survivor preservation are strategic guidance to the native AI, not scripted tactical guarantees; no unsupported flavor-reset/DLL calls are made.
- **Existing models/audio**: Infantry and Military Academy world models are inherited; Rome's soundtrack is explicitly reused. No new voice recordings or animated 3D flying Viltrumite model are supplied. All requested 2D slots have actual custom DDS art; related promotions share authored panels rather than unrelated Firaxis icons.
- **Single-player only.** A shared runtime validates popup choices and owns gameplay state, but the Lua UI choice dispatch is not a proven synchronized multiplayer transport. Deterministic casualty RNG alone does not make the mod multiplayer-safe.
- Native movement, the popup's game layout, forced diplomacy scenarios, balance and AI behavior still need real Civ V playtesting. A permanent-war flag changed by another script while our temporary lock is active cannot be distinguished from our flag; avoid scenario scripts that mutate that same flag mid-crisis.

### Validation

Run `python tools/validate_viltrum_mod.py`, `python tools/validate_all.py`, then `python tools/build_mod.py` from the repo. The validators use an in-memory copy of the installed CP database; they never edit the live cache.

Automated results and the remaining engine checklist are in [docs/Validation.md](docs/Validation.md). The supplied specification is preserved in [docs/OriginalDesign.md](docs/OriginalDesign.md). [docs/Files.md](docs/Files.md) lists every delivered file; [art-source/ViltrumEmpire](../art-source/ViltrumEmpire) preserves the concept, generated Thragg scene and preview.

</details>
