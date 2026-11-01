# Beyond the Sky - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../MasayaBeyondSky/README.md)

**Leader:** Masaya Hinata  
**Playstyle:** Exploration-driven mobile land warfare  
**Suggested victories:** Domination; Science or Culture supported by development

Earn Joy through productive exploration and survivable combat, then use Beyond the Sky as a planned operational window. The meter rewards activity; it does not make a poorly supported mounted army good at every task.

## Opening priorities

Scout safely and keep a defensive core. Use exploration to build Joy without abandoning improvements and research. Prepare the Horseman timing only if the map and strategic resources support it.

## Develop the engine

Use Prodigies to choose fights, reveal approaches and retreat after attacking. Training Rooms contribute infrastructure and Joy, while the first movement window helps new units deploy. Keep siege and ranged support for defended cities.

## Convert the advantage

Stage forces and an objective before the meter reaches its burst. Spend the six-turn window on decisive movement and attacks, then plan for the reset to 25 Joy rather than leaving an exhausted offensive unsupported.

## Pros

- Exploration and combat progression both feed the signature meter.
- Fast Prodigies can select engagements and threaten exposed logistics.
- Beyond the Sky gives a broad land-army mobility and attack window.

## Cons and opportunity costs

- The burst is temporary and is followed by a substantial meter rebuild.
- Prodigies have an explicit city-attack penalty.
- The early mounted plan is still constrained by normal resources, counters and support needs.

## Playing against this civ

- Protect caravans and vulnerable support with layered zones and anti-mounted forces.
- Avoid isolated high-experience targets that a Prodigy can exploit.
- Preserve the main defense through the burst, then punish an overextended army after it ends.

## Common mistakes

- Using Prodigies alone to assault strong cities.
- Reaching 100 Joy with the army still travelling or healing.
- Assuming the 50-Joy movement effect applies to every land class.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [The Capano Circuit](CapanoCircuit.md) | Mobility can deny repeated attacks against the same Project and expose wounded climbers. |
| Opportunity | [Pigeon Republic](https://github.com/SolusGo/CoolWackyCivs2/blob/main/docs/strategy/TheRepublicOfPigeons.md) | Caravan routes and lightly defended origins are natural targets for a mobile land force. |
| Threat | [Unrung Bell](https://github.com/SolusGo/CoolWackyCivs2/blob/main/docs/strategy/KingdomOfTheUnrungBell.md) | Prepared friendly-land defenders and inherited Pikeman counters make a direct mounted breakthrough expensive. |
| Threat | [The Threshold Court](https://github.com/SolusGo/CoolWackyCivs2/blob/main/docs/strategy/TheThresholdCourt.md) | A defended destination can receive an additional melee defender without using the long route Masaya hoped to exploit. |

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [MasayaBeyondSky/README.md](../../MasayaBeyondSky/README.md)
- [MasayaBeyondSky/SQL/00_Masaya_Core.sql](../../MasayaBeyondSky/SQL/00_Masaya_Core.sql)
- [MasayaBeyondSky/SQL/01_Masaya_Inheritance.sql](../../MasayaBeyondSky/SQL/01_Masaya_Inheritance.sql)
- [MasayaBeyondSky/SQL/02_Masaya_UniqueEffects.sql](../../MasayaBeyondSky/SQL/02_Masaya_UniqueEffects.sql)
- [MasayaBeyondSky/SQL/10_Masaya_Text.sql](../../MasayaBeyondSky/SQL/10_Masaya_Text.sql)
- [MasayaBeyondSky/Lua/MasayaRuntime.lua](../../MasayaBeyondSky/Lua/MasayaRuntime.lua)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
