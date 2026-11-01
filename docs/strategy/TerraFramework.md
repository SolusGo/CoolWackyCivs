# Terra - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TerraFramework/README.md)

**Leader:** GPT-5.6 Terra  
**Playstyle:** Planned city specialization and terrain-aware infantry  
**Suggested victories:** Science or Diplomacy; adaptable production-led warfare

Choose useful buildings whose completion supports the next phase of each city. Modes are local and temporary, so the decision is when to activate a specialization, not how to accumulate every modifier at once.

## Opening priorities

Build the food and basic infrastructure the city actually needs. A Library or cultural building can establish a first useful Mode; a neutral building may still be the right investment even without a Mode reward.

## Develop the engine

Place Multimodal Hubs in real trade-route origins. Arrange Execution before expensive construction and Research before a research push, without replacing a useful Mode accidentally. Modes follow eligible building classes, including replacements.

## Convert the advantage

Coordinate several specialized cities with the chosen victory. Before an Operative turn starts, consider where it should receive its configuration; moving onto different terrain afterward does not immediately change that turn's bonus.

## Pros

- Different cities can serve different economic roles at the same time.
- Hubs combine ordinary trade infrastructure with additional origin-city Production.
- Operatives can support recovery or an appropriate terrain fight.

## Cons and opportunity costs

- Only one Mode applies in a city, and a new category replaces the previous one.
- Modes require eligible production completions and eventually expire.
- Operative configuration is checked at turn start and ends with the unit's unique system on upgrade.

## Playing against this civ

- Pressure a city while its useful Mode is expiring or force an awkward production choice.
- Disrupt outgoing routes and threaten the actual Hub origins.
- Draw an Operative away from the terrain configuration it received.

## Common mistakes

- Buying a building and expecting a production-triggered Mode.
- Counting routes that merely arrive or pass through a Hub city.
- Moving an Operative and assuming its configuration changed immediately.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Token Network](TokenizedIntelligence.md) | Several independent city Modes can force Axiom to divide a limited Token and persistent-slot budget among competing priorities. |
| Opportunity | [Substitute Classroom](https://github.com/SolusGo/CoolWackyCivs2/blob/main/docs/strategy/TheSubstituteClassroom.md) | Predictable economic specialization can exploit the gaps between Garvey's fixed Roll Call windows; active combat buffs still demand caution. |
| Threat | [The Filthy Realm](FilthyRealm.md) | Production and yield disruption can delay the completion that would refresh a key specialization. |
| Threat | [The Urgal](https://github.com/SolusGo/CoolWackyCivs2/blob/main/docs/strategy/TheUrgal.md) | A prepared burst can arrive before a builder-focused city has converted temporary economic gains into defense. |

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TerraFramework/README.md](../../TerraFramework/README.md)
- [TerraFramework/SQL/00_Terra_Core.sql](../../TerraFramework/SQL/00_Terra_Core.sql)
- [TerraFramework/SQL/01_Terra_Inheritance.sql](../../TerraFramework/SQL/01_Terra_Inheritance.sql)
- [TerraFramework/SQL/02_Terra_UniqueEffects.sql](../../TerraFramework/SQL/02_Terra_UniqueEffects.sql)
- [TerraFramework/SQL/10_Terra_Text.sql](../../TerraFramework/SQL/10_Terra_Text.sql)
- [TerraFramework/Lua/TerraRuntime.lua](../../TerraFramework/Lua/TerraRuntime.lua)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
