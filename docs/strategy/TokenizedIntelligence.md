# Token Network - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TokenizedIntelligence/README.md)

**Leader:** Axiom, Keeper of Context  
**Playstyle:** A shared resource economy with selectable tactical and economic tools  
**Suggested victories:** Science; flexible Culture, Diplomacy or supported Domination

Grow Token income and capacity, then buy the effect that matters to the current plan. A large balance is useful only if the selected Prompt, target, persistent slot and saturation cost all fit the next few turns.

## Opening priorities

Support population and productive cities while accumulating a reserve. Use an early instant grant where it advances an important real order, and retain enough resources for an unexpected defense. Instant grants stop short of completing the item or technology.

## Develop the engine

Develop specialist cities and Inference infrastructure. Coordinate repeated Prompt types with Cached Responses, but do not refresh an unhelpful effect merely to keep a discount. Persistent target-specific effects still consume the appropriate limited slots.

## Convert the advantage

Use higher models and capacity to support a deliberate research, economic or military timing. Check the spending tier before stacking purchases. Clear Context is an emergency reset of balance and effects, not a way to remove saturation.

## Pros

- One income system can fund several different strategic responses.
- Infrastructure and specialists expand both generation and late capacity.
- Caching and later models can make a coherent repeated plan more efficient.

## Cons and opportunity costs

- Persistent slots and a shared balance limit simultaneous answers.
- Heavy spending reduces subsequent generation through saturation.
- Capacity loss can discard overflow, and Clear Context removes active persistent benefits and cache.

## Playing against this civ

- Create threats on several fronts so one budget and a few slots cannot answer everything.
- Bait an expensive response, disengage, and attack while resources or generation are strained.
- Threaten specialist and inference cities that support capacity and income.

## Common mistakes

- Expecting instant Production or research grants to finish the current item themselves.
- Assuming Clear Context removes saturation or per-turn action limits.
- Buying a strong buff too early for its short duration to affect the real battle.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [The Capano Circuit](CapanoCircuit.md) | Paid movement and selectable unit support can help a threatened Project target withdraw or change the terms of an engagement. |
| Opportunity | [Terra](TerraFramework.md) | Prompt choice can respond directly to a current emergency while Terra's strongest local Mode is tied to its construction plan. |
| Threat | [Luna Network](LunaNetwork.md) | Several expanding production fronts can force competing demands on a single Token reserve. |
| Threat | [The Filthy Realm](FilthyRealm.md) | Economic disruption and a well-timed shutdown can force defensive spending just when saturation makes recovery harder. |

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TokenizedIntelligence/README.md](../../TokenizedIntelligence/README.md)
- [TokenizedIntelligence/SQL/00_Token_Core.sql](../../TokenizedIntelligence/SQL/00_Token_Core.sql)
- [TokenizedIntelligence/SQL/01_Token_Inheritance.sql](../../TokenizedIntelligence/SQL/01_Token_Inheritance.sql)
- [TokenizedIntelligence/SQL/02_Token_Effects.sql](../../TokenizedIntelligence/SQL/02_Token_Effects.sql)
- [TokenizedIntelligence/SQL/10_Token_Text.sql](../../TokenizedIntelligence/SQL/10_Token_Text.sql)
- [TokenizedIntelligence/Lua/TokenRuntime.lua](../../TokenizedIntelligence/Lua/TokenRuntime.lua)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
