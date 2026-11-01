# Sol Intellect - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../SolIntellect/README.md)

**Leader:** GPT-5.6 Sol  
**Playstyle:** Tall specialist science and patient construction  
**Suggested victories:** Science; Culture through a protected Great Person and Wonder economy

Commit to useful buildings long enough for Deep Deliberation, develop local Wonder Insight, and work specialists in strong research cities. The civilization rewards safe sustained investment rather than frequent emergency queue changes.

## Opening priorities

Secure food, workable land and an adequate defense before committing to a long build. Choose attainable infrastructure and Wonders. Finishing too quickly for the required streak can still be correct when the building is urgently needed.

## Develop the engine

Work specialists after Context Archives are established and place Wonder investment where Insight can remain protected. Keep the active queue head stable when pursuing a Deliberation reward; changing items resets that city's streak.

## Convert the advantage

Use mature research cities and Reasoning Institutes to reach the technologies needed for the chosen victory. Keep military technology current and defend Insight cities: capture destroys their accumulated Insight even if they are later recaptured.

## Pros

- Long qualifying building completions generate additional Science.
- World and National Wonders build a persistent local Insight engine.
- Archives reward several worked specialist types, not only Scientists.

## Cons and opportunity costs

- There is no direct military, expansion, Gold or Happiness protection.
- Queue switches and emergency unit production interrupt the construction streak.
- Insight is local and permanently lost on capture.

## Playing against this civ

- Apply credible pressure that forces a queue change before an expensive completion.
- Contest selected Wonders or threaten the city holding the most Insight.
- Use early territorial pressure or a decisive conquest instead of a passive technology race on Sol's preferred terms.

## Common mistakes

- Building an unnecessary item only to preserve a streak.
- Assuming purchases, units or a return to an old queue head retain Deliberation progress.
- Treating a recaptured city as if its previous Insight survived.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Unrung Bell](https://github.com/SolusGo/CoolWackyCivs2/blob/main/docs/strategy/KingdomOfTheUnrungBell.md) | A safe uninterrupted building and specialist programme can exploit a long peaceful research contest; war still removes Sable's economic stacks. |
| Opportunity | [The Last City](TheLastCity.md) | A conventional research victory can put pressure on a defender whose signature plan is local survival rather than outward expansion. |
| Threat | [Luna Network](LunaNetwork.md) | Early expansion and sustained production pressure can deny the safety and space Sol wants. |
| Threat | [Viltrum](ViltrumEmpire.md) | A successful conquest destroys local Insight and removes a heavily invested research centre. |

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [SolIntellect/README.md](../../SolIntellect/README.md)
- [SolIntellect/SQL/00_Sol_Core.sql](../../SolIntellect/SQL/00_Sol_Core.sql)
- [SolIntellect/SQL/01_Sol_Inheritance.sql](../../SolIntellect/SQL/01_Sol_Inheritance.sql)
- [SolIntellect/SQL/02_Sol_Effects.sql](../../SolIntellect/SQL/02_Sol_Effects.sql)
- [SolIntellect/SQL/10_Sol_Text.sql](../../SolIntellect/SQL/10_Sol_Text.sql)
- [SolIntellect/Lua/SolRuntime.lua](../../SolIntellect/Lua/SolRuntime.lua)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
