# PaulsoaresJr — The First Night

A love letter to the generation who learned Minecraft while it was still mysterious, and to the patient guide who helped them survive their first nights. This is a fictional nostalgic civilization, not a claim of real historical nationhood.

## How to Survive & Thrive

Memories are permanent, cannot be spent, and can each be acquired once per player. They record their acquisition era. On entering a later era, each older Memory grants **3 Culture and 3 Science × its age in eras**. Ancient Memories grant 3 of each in Classical, 6 in Medieval, and so on. One consolidated Old Memories notification reports the recall total. Era narratives accompany Classical, Medieval, Renaissance and Industrial; Information concludes with **Do You Remember?**, without an extra arbitrary reward.

| Memory | Trigger | Immediate reward, Standard speed |
| --- | --- | --- |
| The First Shelter | First Starter House, including free buildings | 10 Culture |
| The First Night | First owner turn after the original Capital was founded/observed | 5 Culture, 5 Science |
| The First Danger | First Barbarian killed, attributed by UnitPrekill | 10 Culture |
| The First Mine | Complete a Mine with PlayerBuilt | 10 Science |
| The First Harvest | Complete a valid improvement on a visible bonus/luxury with Food in Resource_YieldChanges | 5 Food in current Capital, 5 Culture |
| The First Journey | Any unit reaches 10 tiles from current Capital | 10 Culture, 10 Science |
| The First Friend | First contact with another major civilization or City-State | 10 Culture |
| The First Wonder | Discover a Natural Wonder | 15 Culture, 10 Science |
| A World Beyond Home | Own at least two cities, founding or acquisition | 15 Culture |
| Something New | Enter Classical after starting the game | 10 Culture, 10 Science |

The journey threshold is `min(10, max(4, floor(min(map width, map height) / 3)))`, keeping it attainable on tiny maps. All instant yields use a single helper with the respective GameSpeed CulturePercent, ResearchPercent and GrowthPercent, rounded to the nearest whole yield. Science goes to current team research, or research overflow if none is selected. XP is not speed-scaled.

## Survivor

Replaces the Scout, copying its active cost, strength, terrain promotions, prerequisites, AI roles, art model and upgrade class from BNW/CP/VP at activation. Movement is 2. Learning the World survives upgrades and grants:

- 5 XP for a ruin bonus when the DLL identifies a surviving discovering unit.
- 10 XP for an attributed Natural Wonder discovery. DLL event variants lacking discovering-player/unit parameters still grant the civilization Memory, but cannot grant unit XP.
- 10 XP for first arrival on each non-starting landmass; revisiting it never pays again. Water areas do not count.
- 15 XP if this Survivor triggers First Journey.
- +5 additional normal healing in neutral/enemy territory. Native `NeutralHealChange` and `EnemyHealChange` preserve normal movement, embarkation and other healing restrictions. Friendly territory has no extra healing.

A Survivor identified during Ancient that remains in the same player's service from Modern onwards gains **Been Here Since the Beginning**: +1 Sight and +10% Defense. Newly produced later units do not qualify. Same-owner upgrades explicitly preserve identity, landmass history, Ancient qualification and return history.

After ten consecutive owner turns outside your territory, returning within two tiles of the current Capital grants **15 Culture**, speed-scaled, once in that unit's lifetime. Returning to your territory before ten turns resets the trip; completing ten turns preserves its qualification until it returns near the Capital. A unit cannot accumulate multiple trips or redeem on multiple turns. Returning Home remains available to that Survivor's upgraded descendants.

## Starter House and Home

Replaces Monument at its active cost, keeping the Monument building class and companion effects, with exactly +2 base Culture. The first Starter House in the **original Capital** records its era. Home I/II/III add 1/2/3 Culture and global Happiness at ages 2/4/6 eras. Only one hidden dummy tier exists at a time.

Home is anchored to coordinates, original owner and foundation turn. Moving the Palace does not move it. Its bonus requires your ownership and a Starter House; losing the city suspends it, regaining it restores its age, and rebuilding the House never resets that age. Razing destroys Home; a new city on the same tile cannot inherit it. Dummies are hidden, unbuildable, never captured and never supplied to unrelated cities.

## Strategy

Explore naturally, collect different first experiences, keep the original Survivor alive through upgrades, and establish a lasting Home. Avoid rushing through the early game: small early Memories gradually support strong Culture and Science development. Paul favors exploration, growth, friendly trade and defensive preparedness, with low war/deception and wonder competition.

> There will be time for great cities later.
>
> For now, enjoy not knowing what lies beyond the hill.

## Implementation and compatibility

Requires BNW and Community Patch v151 or compatible APIs. Four ordered SQL files register, inherit, specialize and localize the civilization. `Lua/PSJRuntime.lua` is one InGameUIAddin in the collection manifest. Pure SQL/Lua/XML/DDS files are playable without ModBuddy; the project is maintained only to match the collection's existing build pipeline. Run `python tools/build_mod.py` for the deployable folder, ZIP and `.civ5mod` under `dist/`.

Persistent player state uses the repository's `Modding.OpenSaveData()` pattern under `PSJ_V1_*`. Unit state uses a namespaced `[PSJ1:...]` ScriptData segment and save-backed serials rather than reusable engine unit IDs; unrelated ScriptData is preserved. UnitUpgraded snapshots state before conversion, and UnitConverted restores it after native promotion copying. Capture/gifting to another owner removes the personal history and custom promotions, including between two Paul players. Unit death requires no periodic cleanup of dead engine references.

Gameplay is event-driven with one owner-turn fallback for free buildings, contact, First Night, Home tiers, veteran eligibility and returning explorers. No per-frame timers or polling. A single load-time map scan recognizes already revealed Natural Wonders without inventing unit attribution. Important reward and turn markers are persisted before applying their effects. Logs use `[PSJ]` and only describe acquisitions, era changes, recalls and veteran awards.

Late-era starts establish the current era as the baseline and receive no retroactive Memories, era recall, skipped-era narratives or Ancient veterans. First Night still follows capital founding; advanced/free Starter Houses are recognized on the owner turn. If debug tools skip eras, only the entered era receives its correctly aged recall. No Barbarians, no Ruins and One City Challenge simply leave the corresponding Memories unavailable. Both AI and multiple Paul instances receive independent bonuses; notifications are only shown for the active human player. Gameplay never assumes Player 0.

The **collection** continues to disable multiplayer and hotseat pending synchronization testing of all its civilizations. This runtime avoids UI-dependent gameplay and uses deterministic state, but has not been certified for network multiplayer. The optional Memory panel is deferred; the Civilopedia Memories concept explains every trigger and notifications show rewards.

## Art and audio

Finished art is in `Art/`; authored PNGs, reference provenance, prompts and preview are in `art-source/PaulsoaresJr/`. `python tools/make_psj_assets.py` recompiles real DDS files. No DDS headers/payloads are fabricated. DXT5 is used for dimensions divisible by four, legacy RGBA DDS for odd atlas sizes, matching the repository. Circular portraits have gold rims and transparent corners; alpha/flags are white silhouettes without rims.

| Slot | Dimensions / atlas |
| --- | --- |
| Civilization / leader | `PSJIcon{size}.dds`, 2×1 cells, indexes 0/1; sizes 256,128,80,64,48,45,32,24,16 |
| Civilization alpha | `PSJAlpha{size}.dds`, 1×1 at the same sizes |
| Survivor / Starter House / Learning / Beginning | `PSJObjects{size}.dds`, 4×1 indexes 0/1/2/3; sizes 256,128,80,64,45,32,16 |
| Survivor unit flag | `PSJUnitFlag32.dds`, 32×32 |
| Diplomacy / Dawn | `PSJLeader.dds` / `PSJDawn.dds`, 1600×900 |
| Setup map | `PSJMap.dds`, 360×412 |

The Learning torch/book symbol is also suitable for a future UA/Memory panel. The current collection has no separate trait portrait field or PSJ UI to bind it to. Survivor uses the actual Scout 3D model and inherited strategic-view art; the custom flag/portrait distinguish it.

No Paul or Minecraft audio is bundled. Dawn narration is localized text; DawnOfManAudio is empty. Legal base-game America soundtrack references are retained. Custom licensed peace/war tracks and an authorized narration could be supplied later, with audio XML and manifest hooks added then.

## Validation and practical engine test checklist

`python tools/validate_psj_mod.py` checks SQL in a disposable clone of the BNW cache with installed CP schema; every populated Scout/Monument companion table; override/trait registration; yield totals; promotion healing/defense; dummy tiers; localization; duplicate IDs; atlas dimensions and alpha; Lua 5.1 behavior; all ten Memory triggers; replay prevention; era sums; unit upgrades/capture; Home capture/regaining/rebuilding/Palace relocation/refounding; AI; late starts; save-backed context reload; and independent speed channels. `python tools/validate_all.py` additionally checks the whole collection, DDS decoding with DirectXTex, XML, load ordering and existing civ regressions.

Automated mocks are not a running Civ V match. Complete these in-engine smoke tests on a new game with logging enabled:

- **Setup:** choose Paul; check name, trait, both uniques, icons at setup/Civilopedia/production, leader scene, map and Dawn paragraphs. Found Home normally; after the first full turn verify 5 Culture/Science once. Save before and after it, reload, and ensure no duplicate.
- **House:** construct the first House, then another; verify 10 Culture once and Monument policy/class requirements. Test free Monuments, sell/rebuild, capture/regain, relocate Palace, raze/refound.
- **Memories:** independently kill a Barbarian, finish a Mine, improve Wheat/Fish/another valid Food resource, travel the threshold, meet a major and a City-State, reveal a Natural Wonder, found/acquire a second city, and enter Classical. Check exact immediate yields, acquired era in Lua.log, notification and repeat prevention. Save/reload around each.
- **Survivor:** check Scout cost/strength, 2 moves, terrain abilities, ruins, attributed wonders and new landmasses. Revisit tiles. Wound it and compare normal stationary healing abroad (+5) with movement/embarkation restrictions. Upgrade it; inspect promotions/history and Lua.log.
- **Return:** spend nine turns abroad and return (no reward); spend ten consecutive turns abroad and return within two tiles of current Capital (15 Culture once). Repeat after upgrade, save/reload and capture; verify no farming.
- **Era aging:** with IGE/debug enter each era; verify ages and one consolidated recall. Nine Ancient Memories yield 27/27 in Classical, plus Something New's 10/10; those nine plus a Classical Memory yield 57/57 in Medieval. Check all Home tiers and no stacking.
- **Modern:** preserve an Ancient Survivor and its upgrade; compare a later-built Survivor. Only the Ancient lineage gains +1 Sight/+10% Defense. Check capture between different Paul players.
- **Information:** see Do You Remember? once, followed by ordinary recall, without extra finale yields. Reload before/after the transition.
- **Edge settings:** tiny map, Classical/Modern/Information start, advanced start, no Barbarians, no Ruins, OCC, pre-revealed Natural Wonder, multiple Paul players, and AI observer/autoplay. Compare Quick/Standard/Epic/Marathon reward scaling.
- **Long game:** review Lua.log, database.log and xml.log through several eras; verify AI gains bonuses and no missing art, SQL failures or nil-reference crashes. Network/hotseat testing must precede enabling those collection flags.
