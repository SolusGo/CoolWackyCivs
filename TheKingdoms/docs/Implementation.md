# Implementation report

The Kingdoms is included in Cool Wacky Civs v18 and also has an independently buildable pure-file manifest. Its permanent leader is The Throne; the generated reigning character is the visible ruler of the political UI. There is no new player slot per House or coalition.

## Files and systems

`SQL/00_Kingdoms_Core.sql` defines the civilization, placeholder leader, trait, Longswordsman replacement and Walls replacement by cloning the active BNW/CP definitions. `01_Kingdoms_Inheritance.sql` copies unit/building companion relations, including resource requirements and the ruleset's upgrade chain. `02_Kingdoms_Effects.sql` defines removable political buildings, Guard promotions and atlases. `10_Kingdoms_Text.sql` contains localization, city names, diplomacy and Civilopedia text.

The sixteen gameplay modules are `KingdomsCore`, `KingdomsData`, `KingdomsDebug`, `KingdomsPersistence`, `KingdomsEffects`, `KingdomsEvents`, `KingdomsAI`, `KingdomManager`, `HouseManager`, `CharacterManager`, `DemandManager`, `RulerManager`, `SuccessionManager`, `CivilWarManager`, `KingsGuardManager`, and `HistoryManager`.

The Overview UI XML/Lua hosts five tabs, scrolling lists and action panels. One InGameUIAddin owns the gameplay runtime for every Kingdoms player, including AI players. Opening and closing the UI does not advance politics. A context-local include guard prevents duplicate event handlers. Fresh Lua contexts rebuild runtime functions and load stored political state.

The 22 DDS textures include civilization/ability/unit/building medallions at nine icon sizes, alpha identity atlases, a Guard flag, map presentation, Dawn of Man and a static citadel leader scene. Native Longswordsman 3D art and animations are retained. Source artwork, prompts and the editable crown/sword silhouette live in `art-source/TheKingdoms`.

## Persistence

`Modding.OpenSaveData()` stores versioned, deterministic, length-prefixed snapshots. Snapshots include every Kingdom, House, character, demand, cooldown, relationship, claim, Guard, pending candidate selection, civil-war faction, action timer, historical war and Chronicle entry. IDs are monotonic counters stored in the same snapshot. Political randomness uses a saved generator state.

Strings are split into 6,000-byte chunks in alternating banks. Counts and checksums validate each bank; the active pointer changes only after the new bank is written. Loading a damaged current bank falls back to the previous valid bank. The decoder interprets data only, never executable Lua. Version/default migration handles saves lacking newly introduced optional fields. A future unknown schema is rejected rather than silently discarded.

Cities use X/Y, founding turn and original owner rather than transient city IDs. Foreign ownership deactivates House processing and removes political dummies while retaining the original House history. Razing/refounding creates a different identity. The original capital receives a saved loss/restoration state, legitimacy shock and twenty-turn Stability penalty.

Guards use native unit ID/birth turn, one of seven persistent native slot promotions, and a namespaced ScriptData identity marker, preserving other ScriptData content. CP copies names/promotions on upgrade but does not copy ScriptData. Conversions transfer the saved identity before the original unit's final death callback. Slot-promotion reconciliation identifies upgraded Guards exactly and restores their ScriptData when the optional conversion event is missing; pending appointments use the same slot mechanism. Upgraded Guards and pending appointments count toward seven. A completion-time backstop rejects any excess Guard and refunds 50% of its speed-scaled base Production cost as Gold, avoiding the native production reset. Transfers out of the realm retire the character and remove native political promotions; ordinary deaths release the place.

## Hooks and performance

The runtime uses `PlayerDoTurn`, `PlayerCityFounded`, `CityCaptureComplete`, `SetPopulation`, `CityConstructed`, `UnitCreated`, `CityTrained`, `PlayerCanTrain`, `UnitConverted`, `UnitPrekill`, `BarbariansCampCleared`, `CombatEnded`, and `TeamTechResearched`. Optional hooks are checked before registration. SQL enables the relevant CP event options. Core CP v151 contracts for founding, capture, training, conversions, prekill and combat are checked against local DLL source snapshots.

Production and unit lifecycle events reconcile units immediately. Turn processing checks only Kingdoms players, known Kingdoms, active Houses and owned units. Improvement demands inspect a city's radius-three plots; new nearby-camp demands inspect radius eight. There is no whole-map turn scan and no `ContextPtr:SetUpdate` polling. Same-turn simulation callbacks are idempotent. UI refreshes follow explicit state changes, opening, turn and view events. It hides during city view, diplomacy and other game popups. Debug logging is disabled by `DEBUG_KINGDOMS = false` in `KingdomsDebug.lua`.

Political modifiers use binary dummy buildings, changing native counts only when necessary. House yield effects normalize Influence, grow modestly with the number of Houses, and invert at hostile loyalty. Ruling-House effects and ruler-personal effects are separate. All tracked cities receive cleanup, including foreign-held cities. Civil-war combat penalties apply to owned combat units, including new creations; native upgrade/gift flags and conversion cleanup prevent leakage.

## Balance values (Standard speed)

| Mechanic | Initial value |
| --- | --- |
| House formation | Two founding Houses; one new House every 8–12 turns toward the population target |
| House schism | Low-probability discontent trigger; 60–75-turn cooldown; at most eight local Houses |
| House traits | Two of twenty; weighted small effects, with a 12% per-House scaling increase beyond the first two, capped at +60% |
| House Loyalty | -100 to +100 |
| Demands | At most one new demand per turn; 2–5 active realm-wide; 15–25-turn House cooldown; 25–35-turn deadline |
| Successful demand | +18 Loyalty, +5 Prestige, +3 Influence |
| Expiry / refusal | -12 / at least -22 Loyalty |
| Gifts / Estates / Charter / Authority | Base 80 / 150 / 120 / 100 Gold; costs also rise 20% per era |
| House actions | Ten-turn local cooldown; Estates: -10% Production for twelve turns |
| Ruler lifespan | 25–50-turn randomized reign |
| Architect | +10% building Production |
| Peaceful succession threshold | Realm Stability at least 45 |
| Extreme deposition | Stability at most 10; fifty-turn crisis cooldown |
| Civil war | 2–3 coalitions; events every 3–5 turns; 70% dominance after five turns or twenty-turn maximum |
| Civil war penalties | -25% Food, -30% Production, -20% Gold, -15% Science/combat; -3 global Happiness per Kingdom |
| Rebels | At most four spawned units per war, era-appropriate, on empty owned land |
| Faction funding / supplies | Base 100 / 50 Gold; +15 / +25 strength; four-turn action cooldown |
| Supply cost | -10% empire Production for five turns |
| Guard appointment | House +15 Loyalty/+8 Prestige; passed candidates' Houses -3 Loyalty |
| Guard oath | Paid retention: base 80 Gold; voluntary retirement: 50 speed-scaled Gold; failed oath: wounds/movement loss, never automatic removal |

Turn durations and costs use the active game's `TrainPercent`. Prestige age gain and abstract character aging also adjust by game speed. Generated regnal names, current House heads, founder/descendant lineage and retained ancient Houses remain relevant in all eras. Active House lists are cached by Kingdom and invalidated on formation and city reconciliation, keeping influence/stability calculations local rather than repeatedly scanning all Houses.

## Practical limits

This is a lightweight political simulation, not a full genealogy engine. Coalitions remain internal; rebels are safely owned by the existing Barbarian player. House heads, claimants, rulers and Guard candidates are generated when relevant, without invisible family trees. One House's heraldry is a persistent symbol/background/color combination displayed as a textual blazon; the mod does not need hundreds of textures.

Guard traits use safe native equivalents: Honourable grants adjacency strength near a friendly combat unit, rather than only another Guard; Protector uses city defense rather than a custom friendly-city radius condition. Loyal uses capital defense, and Commander heals adjacent units. The inherited upgrade chain varies with the active ruleset. Existing unit models provide reliable 3D presentation; the new art appears in portraits, flags and static screens. No new speech/music assets are required.

AI uses military value and political benefit for appointments, affordable gifts for influential hostile Houses, funding for the dominant faction and paid/oath retention. Ordinary city/build/war decisions remain Civ V AI decisions; it does not micromanage every political demand. Missing optional hooks reduce immediate reporting or some combat statistics; turn reconciliation keeps the core simulation active. The Chronicle retains all events, so exceptionally long games may create large saved snapshots and longer Chronicle render times.

Automated tests validate SQL, Lua 5.1 behavior and UI callback wiring. Actual Firaxis rendering, mod activation, AI production orders, additive combat modifiers, auto-upgrade behavior in production queues and balance require the documented engine smoke tests. Multiplayer/hotseat are disabled.
