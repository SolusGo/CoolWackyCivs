# The Tokenized Intelligence

A twelfth civilization in **Cool Wacky Civs**, led by **Axiom, Keeper of Context**.
Requires Civilization V: Brave New World and Community Patch v151 (5.4.2+) like
the rest of the collection. AI selection and automated Token spending are enabled.

Build the collection with `python tools/build_mod.py`. Extract the generated
`dist/Cool Wacky Civs (v 16)` directory into the game's `MODS` directory, or import
the `.civ5mod`. Enable only one version of Cool Wacky Civs alongside Community
Patch and BNW, then start a **new single-player game**. No ModBuddy step is needed.
Do not add this civilization to an existing save: it adds database types and state.

## Context Window

Each city produces 10 Tokens/turn plus 2 per citizen. Scientists add 15, Engineers
10, Merchants 8, and Writers, Artists and Musicians 5. Begin with 250 Tokens on
Standard. Storage and costs scale by the current Game Speed's TrainPercent;
per-turn income remains constant so accumulation takes proportionally longer
on Epic/Marathon. All durations, cache windows and cooldowns use the same scaling.
Research Query uses the actual speed-adjusted team technology cost.

| Era | Base Context (Standard) | Model | Persistent slots |
|---|---:|---|---:|
| Ancient | 1,000 | Small | 1 |
| Classical | 1,500 | Small | 1 |
| Medieval | 2,250 | General | 1 |
| Renaissance | 3,250 | General | 1 |
| Industrial | 4,500 | Reasoning | 1 |
| Modern | 6,000 | Large | 2 |
| Atomic | 8,000 | Frontier | 2 |
| Information | 10,000 | General Intelligence | 3 |

Buildings add capacity before speed scaling. Overflow is discarded, including
when losing a city or building reduces storage. The Token button beneath the
top panel shows current storage and income; its tooltip explains every source,
modifiers, saturation, cache, active effects and Clear Context cooldown.

## Prompt Console

Click the Token button, choose a category and Prompt, choose an owned city/unit
when needed, then execute. Costs below are Standard-speed starting prices.
Unavailable Prompts stay visible and disabled with requirement tooltips.

| Prompt | Tokens | Effect | Turns | Earliest model |
|---|---:|---|---:|---|
| Optimize Production | 500 | Up to 100 Production in one city | Instant | Small |
| Optimize Gold | 800 | +10% Gold in all cities | 5 | Small |
| Optimize Growth | 700 | +20% gross Food in one city | 5 | Small |
| Optimize Trade | 700 | Origin city +2 Gold/+1 Science per outgoing route | 5 | General |
| Research Query | 750 | Up to 5% of current technology cost | Instant | Small |
| Research Optimization | 1,200 | +10% Science in all cities | 5 | General |
| Tactical Analysis | 400 | One combat unit +15% strength/+1 Sight | 3 | Small |
| Route Optimization | 300 | One mobile non-trade unit +2 movement this turn | Instant | Small |
| Combat Simulation | 700 | One combat unit +25% strength | 2 | General |
| Happiness Optimization | 750 | +5 empire Happiness | 5 | General |
| Cultural Analysis | 750 | All cities +15% Culture | 5 | General |
| Emergency Administration | 1,500 | +8 Happiness, all cities +10% Production | 5 | Reasoning |
| Strategic Forecast | 3,000 | All owned combat units +6 Sight; needs 5,000 capacity | 2 | Reasoning |
| Grand Strategy Simulation | 5,000 | All cities +15% Science/Production/Gold, combat units +10% strength; needs 8,000 capacity | 5 | Reasoning |
| Clear Context | 0 | Restore 25% capacity, cancel every persistent Prompt/cache/saturation | Instant | Small |

Instant grants are capped **one point short of current item/technology
completion**, so the normal turn completes them and no mod-created overflow
can be transferred to another item. Research Query is limited to once per own
turn, regardless of switching technologies or clearing. Route Optimization is
limited to once per unit per own turn; it changes remaining movement, not base
movement. Processes cannot receive Production grants. Clear Context has a
15-turn speed-scaled cooldown and cannot erase these instant-action restrictions.

Refresh an already active Prompt at its new price without consuming another slot.
Targeted Prompts occupy a slot each; an Agent's Adaptive modes share one slot.
Other Prompts can stack if slots permit (for example Tactical plus Simulation).

## Cached Responses and Compute Saturation

Repeat the same Prompt within 10 scaled turns: normal price, then 75%, then
approximately 58%. The minimum is 50% of the model-adjusted normal price.
Switching Prompt types resets the chain; using the same type on another target
preserves it. Frontier and General Intelligence also reduce normal prices by 10%.

Spending accumulates within your own turn relative to maximum Context capacity:

| Spending | Generation penalty | Duration |
|---|---:|---:|
| Below 10% | None | — |
| 10–30% | -10% | 2 turns |
| 30–60% | -25% | 3 turns |
| 60%+ | -40% | 4 turns |

Atomic/Information reduce severity by one tier. Saturation replaces/extends an
existing level rather than adding penalties. Clear Context removes congestion
but retains this turn's spending total: immediately spending again can congest
the freshly cleared Context. Temporary effects expire at the beginning of the
owner's turns, with a persisted per-player clock and duplicate-turn guard.

## Unique infrastructure and military

**Inference Cluster** replaces University, preserving all installed BNW/CP
properties and companion effects. Adds +75 Context, +15 Tokens/turn, and +5
Tokens per Scientist **in that city**, including Scientists employed elsewhere
in the city. **Data Centre** replaces Research Lab with +500 Context, +50
Tokens/turn and +10% total local Token generation. These benefits belong to
the Token civilization even when a captured city retains one of the buildings.

**Inference Agent** replaces Infantry with identical baseline strength, cost,
prerequisites, resource requirements, upgrade path and native Infantry model.
Its flag and portrait are original. Adaptive Inference modes last 3 scaled turns:
Offensive +20% attack (250 Tokens), Defensive +20% defense (250), Mobility +1
Movement (250), or Target +25% against land units (300). Only one per Agent;
switching replaces it and spends Tokens. Mobility changes base movement while
active; the extra point becomes available at the next unit movement refresh.
Expiry does not reclaim movement already granted that turn. Death, capture and
upgrade invalidate targeted effects and release their slots.

## AI, compatibility and implementation

AI prioritizes Happiness while unhappy, defensive analysis for wounded forces
at war, and spending near capacity on major research/production needs. It makes
at most one successful decision per own turn and saves when below 25% storage.
There is no AI UI dependency or random selection. Axiom's database flavors favor
Science, specialists and infrastructure, with selective warfare.

All state uses `Modding.OpenSaveData()` under versioned per-player keys. City
identities include owner, original owner, founding turn and coordinates; unit
identities include owner, ID, creation turn and type. Capacity/income are derived
from game state and cached only until relevant events or explicit interaction.
The UI is an InGameUIAddin and includes the runtime once, including for AI players.
Enable `T.TOKEN_DEBUG` in `Lua/TokenRuntime.lua` for transaction/turn logs.

Yield effects are native hidden buildings; military effects are native temporary
promotions. Happiness is applied once in the capital using UnmoddedHappiness.
New/captured cities and created/converted units are reconciled on gameplay hooks.
The UI closes/hides on city, diplomacy and popup transitions and never uses
`ContextPtr:SetUpdate`, timers, or periodic visibility polling.

Known limitations: multiplayer/hotseat remain disabled at collection level.
Player pools are isolated, but UI transactions have no synchronized network
transport. Strategic Forecast uses live +6 unit Sight instead of scripted map
visibility, ensuring native removal when it expires; it does not reveal around
every territory tile and previously explored terrain remains mapped. Optimize
Trade rewards origin cities rather than rewriting trade-route packets. Growth
modifies gross Food, not surplus. No one-time research reward or custom music is
needed. Static leader diplomacy art and native Infantry animations are deliberate
stable Civ V conventions. UI text is English only.

See [validation](docs/Validation.md) for automated evidence and remaining engine
smoke tests. Passing mocks and database checks does not prove a live game session.
