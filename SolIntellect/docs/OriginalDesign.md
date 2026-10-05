Implement a complete Civilization V: Brave New World civilization mod for:

# GPT-5.6 Sol — The Sol Intellect

Assume the game is running with the Community Patch / Vox Populi DLL available.

The goal is to implement the civilization exactly as specified below. Do not redesign the civilization, simplify mechanics, or invent replacement mechanics unless technically necessary. If a mechanic requires Lua, use Lua. Prefer XML/SQL for static database content.

The civilization should be implemented cleanly, save-safe, and with minimal unnecessary polling.

---

# CORE CIVILIZATION

**Civilization:** The Sol Intellect  
**Leader:** GPT-5.6 Sol  
**Adjective:** Solar  
**Capital:** Sol Prime  

**Unique Ability:** Deep Deliberation  
**Unique Building 1:** Context Archive — replaces University  
**Unique Building 2:** Reasoning Institute — replaces Public School  

Sol has no Unique Unit.

## Playstyle

Sol is a tall, specialist-heavy, late-game civilization centered around:

- Long uninterrupted construction
- Expensive Buildings
- Wonders
- Specialists
- Great People
- Science
- Permanent city development through Insight

Sol should begin relatively normally and scale increasingly hard throughout the game.

It should be strongest when allowed to peacefully develop several highly advanced cities.

---

# UNIQUE ABILITY — DEEP DELIBERATION

Whenever a Sol city completes an eligible Building or Wonder that has been continuously constructed for at least:

**4 turns**

the city receives an immediate Science burst.

The Science burst is based on:

1. Production Cost
2. Number of consecutive turns spent constructing the item

Formula:

`ScienceBurst = ProductionCost × SciencePercent`

Base percentage at exactly 4 turns:

`12%`

For each additional continuous construction turn beyond Turn 4:

`+2%`

Maximum:

`24%`

Therefore:

| Continuous Turns | Science % |
|---:|---:|
| 1–3 | 0% |
| 4 | 12% |
| 5 | 14% |
| 6 | 16% |
| 7 | 18% |
| 8 | 20% |
| 9 | 22% |
| 10+ | 24% |

Use:

`floor(ProductionCost × Percentage)`

for the final Science burst.

Minimum burst after qualifying should be:

`1 Science`

---

# IMPORTANT — CONTINUOUS CONSTRUCTION

The city must continuously construct the same item.

Track:

- Player ID
- City ID
- Current Production Type
- Current Production ID
- Consecutive construction turns

If the player changes production to anything else, the counter resets.

This includes switching:

Building → Unit  
Building → Building  
Wonder → Building  
Building → Process  
Building → Project  
Wonder → Wonder

If the city later returns to the old item:

The old progress does not count.

The consecutive-turn counter begins again from zero.

Example:

City constructs University for:

3 turns

Switches to Archer for 1 turn

Returns to University

The University construction timer restarts.

It does not retain the previous 3 turns.

---

# WHAT COUNTS AS A CONSTRUCTION TURN

At the beginning/end of each appropriate city turn, if the city is still constructing the exact same item as on the previous turn:

Increment:

`ContinuousTurns += 1`

Track exact:

- Order type
- Building/Unit/Project ID

Do not rely only on Production amount because overflow or modifiers may make this unreliable.

---

# ELIGIBLE COMPLETIONS

Deep Deliberation should trigger from normally Production-constructed:

- Standard Buildings
- Unique Buildings
- National Wonders
- World Wonders

The item must:

- Have a positive Production Cost
- Be constructed normally
- Have been continuously constructed for at least 4 turns

---

# INELIGIBLE COMPLETIONS

Do not generate Deep Deliberation Science from:

- Units
- Projects
- Processes
- Purchased Buildings
- Faith-purchased Buildings
- Free Buildings
- Lua-created Buildings
- Automatically granted Buildings
- Buildings acquired through city capture
- Buildings with Cost <= 0

Do not accidentally trigger from anything that was not genuinely completed through city Production.

---

# WONDERS

Both:

- World Wonders
- National Wonders

are eligible for Deep Deliberation Science.

Additionally, completing a World or National Wonder grants:

**1 Insight**

to that city.

The city may hold a maximum of:

**5 Insight**

---

# INSIGHT SYSTEM

Each city independently tracks Insight.

Range:

`0–5`

Insight is permanent while the city remains under Sol control unless otherwise specified below.

Each Insight grants:

**+2% Science**

and:

**+2% Great Person generation**

in that city.

Maximum at 5 Insight:

**+10% Science**

**+10% Great Person generation**

---

# INSIGHT GAIN

Gain:

`+1 Insight`

when completing through Production:

- World Wonder
- National Wonder

Conditions:

- Owner must be Sol
- Wonder must genuinely be completed through Production
- City must have fewer than 5 Insight

If city already has:

`5 Insight`

additional Wonders grant no further Insight.

Deep Deliberation Science still functions normally.

---

# INSIGHT REPRESENTATION

Use dummy Buildings for Insight.

Recommended:

`BUILDING_SOL_INSIGHT`

Allow dummy Building count:

`0–5`

Each copy should represent one Insight.

Each copy should provide:

**+2% Science**

and:

**+2% Great Person generation**

If Civ V database tables cannot directly provide both cleanly per dummy count, implement supporting dummy Buildings or Lua-assisted effects.

Do not display these dummy Buildings as normal constructible Buildings.

---

# GREAT PERSON GENERATION

The Insight bonus should affect general Great Person generation in the city wherever practical.

Target intended behavior:

1 Insight:

`+2% Great Person generation`

5 Insight:

`+10% Great Person generation`

If Civ V requires separate GP rate modifiers or categories, apply equivalent modifiers across appropriate Great People.

Do not apply Great General / Great Admiral generation unless the relevant CP implementation makes general GP modifiers affect them automatically.

The intended focus is civilian Great People.

---

# INSIGHT CITY CAPTURE RULE

If a Sol city containing Insight is captured:

Remove all Insight from that city.

The conquering player does not inherit Insight.

If Sol later recaptures the city:

Insight remains lost.

This prevents storing Sol's permanent adaptation in conquered cities.

Clear related persistence data on capture.

---

# CITY DESTRUCTION

If a city is razed or removed:

Delete all related:

- Insight data
- Construction timer data
- Tracked production state

---

# UNIQUE BUILDING — CONTEXT ARCHIVE

Replaces:

**University**

Suggested internal type:

`BUILDING_SOL_CONTEXT_ARCHIVE`

The Context Archive should retain all normal Community Patch University effects.

Do not replace it with vanilla University stats.

Use the current CP University as the baseline wherever technically possible.

Then add the Sol-specific effects.

---

# CONTEXT ARCHIVE UNIQUE EFFECT

Each Specialist currently being worked in the city provides:

**+1 Science**

This applies to all normal specialist types, including where applicable:

- Scientist
- Engineer
- Merchant
- Writer
- Artist
- Musician

Additionally:

For every:

**3 Specialists currently worked**

the city receives:

**+1 Culture**

Use integer floor division.

Formula:

`CultureBonus = floor(TotalWorkedSpecialists / 3)`

Examples:

0 Specialists → +0 Culture  
2 Specialists → +0 Culture  
3 Specialists → +1 Culture  
5 Specialists → +1 Culture  
6 Specialists → +2 Culture  
9 Specialists → +3 Culture

---

# CONTEXT ARCHIVE SPECIALIST SCIENCE

Formula:

`ScienceBonus = TotalWorkedSpecialists`

Examples:

3 Specialists:

`+3 Science`

7 Specialists:

`+7 Science`

This should update dynamically whenever specialist assignments change.

---

# CONTEXT ARCHIVE IMPLEMENTATION

Prefer native specialist yield tables if they can provide the desired effect across all specialist classes.

If CP/XML tables can add:

`+1 Science per Specialist`

cleanly, use database implementation.

The Culture-per-3-specialists mechanic will likely require Lua.

Recommended approach:

Create hidden dummy Building:

`BUILDING_SOL_CONTEXT_CULTURE`

Each copy provides:

`+1 Culture`

For every Sol city containing a Context Archive:

1. Count worked Specialists.
2. Calculate:
   `floor(count / 3)`
3. Set dummy Building count accordingly.

Update when practical using events instead of constant high-frequency polling.

At minimum recalculate:

- At Sol player turn
- After city changes
- After Building construction
- After game load

Do not use a 0.1-second UI polling loop.

---

# CONTEXT ARCHIVE CIVILOPEDIA

**Context Archive**

Replaces the University.

Retains the University's normal effects.

Every Specialist worked in the city provides:

**+1 Science**

Additionally:

Every 3 Specialists worked provide:

**+1 Culture**

The Context Archive rewards dense, specialist-heavy cities and forms the economic core of Sol's tall playstyle.

---

# UNIQUE BUILDING — REASONING INSTITUTE

Replaces:

**Public School**

Suggested internal type:

`BUILDING_SOL_REASONING_INSTITUTE`

The Reasoning Institute should retain all normal Community Patch Public School effects.

Again:

Do not assume vanilla BNW Public School values.

Use CP values as the base.

---

# REASONING INSTITUTE EFFECTS

In addition to normal Public School effects:

**+10% Great Person generation in this city**

Also:

For every:

**2 Insight**

in the city, the Reasoning Institute generates:

**+1 Science**

Formula:

`BonusScience = floor(Insight / 2)`

Therefore:

| Insight | Bonus Science |
|---:|---:|
| 0 | 0 |
| 1 | 0 |
| 2 | +1 |
| 3 | +1 |
| 4 | +2 |
| 5 | +2 |

---

# REASONING INSTITUTE DYNAMIC SCIENCE

Recommended dummy Building:

`BUILDING_SOL_REASONING_INSIGHT_SCIENCE`

Each copy:

`+1 Science`

For cities possessing the Reasoning Institute:

`DummyCount = floor(Insight / 2)`

Update whenever:

- Insight changes
- Reasoning Institute is constructed
- City changes owner
- Save is loaded

---

# REASONING INSTITUTE GREAT PERSON BONUS

The Building should provide:

**+10% Great Person generation**

as a direct Building effect if supported by CP/database tables.

This bonus stacks with Insight.

Example city with:

5 Insight  
Reasoning Institute

Receives:

Insight:

`+10% GP generation`

Reasoning Institute:

`+10% GP generation`

Total intended modifier:

`+20%`

before other modifiers.

---

# DEEP DELIBERATION EXAMPLES

## Example 1

Library costs:

100 Production

Constructed continuously for:

4 turns

Science:

`100 × 12% = 12`

Player receives:

`12 Science`

---

## Example 2

University costs:

250 Production

Constructed continuously for:

7 turns

Percentage:

`18%`

Science:

`250 × 0.18 = 45`

Player receives:

`45 Science`

---

## Example 3

Wonder costs:

500 Production

Constructed continuously for:

15 turns

Percentage capped at:

`24%`

Science:

`500 × 0.24 = 120`

Player receives:

`120 Science`

City also receives:

`+1 Insight`

provided Insight is below 5.

---

# GAME SPEED

Production Cost calculations must use the actual current Production requirement of the completed item for the game's current speed.

Do not hard-code Standard-speed costs.

The mechanic should scale correctly on:

- Quick
- Standard
- Epic
- Marathon
- CP custom speeds where applicable

---

# PRODUCTION MODIFIERS

Deep Deliberation Science should use:

**Production Cost**

not actual Production invested.

Do not multiply Science based on:

- Forge bonuses
- Wonder Production modifiers
- Golden Age Production
- Policy Production modifiers
- overflow Production

This avoids double-dipping.

---

# SCIENCE APPLICATION

Science burst should be granted directly to the player.

Prefer CP-safe methods for adding research progress.

The Science should contribute to the currently researched Technology.

If no technology is selected:

Use a safe fallback.

Do not lose the reward if there is temporarily no tech selected.

---

# PLAYER FEEDBACK

When Deep Deliberation activates for a human player:

Display a non-intrusive notification or floating text.

Example:

**Deep Deliberation**

Sol Prime completed a University after 7 turns of uninterrupted construction and generated:

**45 Science**

For Wonder + Insight:

**Deep Deliberation**

Sol Prime completed the Leaning Tower after 12 turns, generating 108 Science and gaining 1 Insight.

Avoid modal popups.

---

# INSIGHT FEEDBACK

When Insight increases:

Display something similar to:

> Sol Prime gained Insight (3/5).

If city reaches 5:

> Sol Prime has reached maximum Insight.

---

# CONSTRUCTION TRACKING

Recommended Lua table:

`SolConstructionState[playerID][cityID]`

Store:

- `OrderType`
- `ItemID`
- `ContinuousTurns`

At each Sol player turn:

For each Sol city:

1. Determine current production.
2. Compare with previous state.
3. If identical:
   increment ContinuousTurns.
4. If changed:
   replace state and reset count appropriately.

Be careful with off-by-one errors.

The intended interpretation is:

An item genuinely being worked on across four city production turns should qualify as 4 turns.

Test this explicitly.

---

# COMPLETION EVENT

When a Building finishes:

1. Confirm player is Sol.
2. Confirm it was Production-built.
3. Determine whether eligible.
4. Retrieve construction duration from tracked state.
5. If duration >= 4:
   calculate Science percentage.
6. Award Science.
7. If Wonder:
   grant Insight.
8. Clear/update production tracking for the city.

---

# PURCHASE DETECTION

It is essential that buying a Building does not trigger Deep Deliberation.

If CP construction events do not clearly distinguish purchases:

Track what the city was actively producing on the previous turn.

A completed Building only qualifies if:

- It matches the city's tracked Production item
- It had legitimate tracked construction turns
- It meets minimum duration

This naturally rejects most purchases.

Add further checks if Community Patch exposes purchase data.

---

# WONDER CLASSIFICATION

Use reliable database properties to identify:

- World Wonders
- National Wonders

Do not classify dummy Buildings or special Buildings as Wonders purely because of cost.

Use BuildingClass properties or the proper Civ V Wonder flags/tables.

---

# SOL GAMEPLAY FLOW

## EARLY GAME

Sol should feel relatively ordinary.

Primary goals:

- Secure several good city locations
- Establish population
- Build infrastructure
- Avoid unnecessary early wars

Deep Deliberation exists early but should not generate massive Science because early Buildings are cheap.

---

# CLASSICAL / MEDIEVAL

Deep Deliberation becomes increasingly noticeable.

Longer Building times naturally generate stronger percentages.

Sol begins benefiting from:

- Libraries
- Wonders
- Specialist infrastructure

This is when early Insight may begin accumulating.

---

# RENAISSANCE

Sol's identity comes fully online.

The Context Archive should create a strong incentive to work:

- Scientists
- Engineers
- Merchants
- Culture specialists

Cities become increasingly dense and specialized.

---

# INDUSTRIAL

Reasoning Institutes appear.

Cities with accumulated Insight gain stronger synergy.

A mature Sol city may now possess:

- Specialist Science
- Specialist Culture
- Insight Science modifier
- Insight GP modifier
- Reasoning Institute GP modifier
- Reasoning Institute Insight Science

This is intentional.

---

# LATE GAME

Sol should become one of the strongest peaceful technology civilizations if it has been allowed to develop.

However:

Sol receives no major:

- Expansion bonus
- Early military bonus
- Movement bonus
- Happiness protection
- Free Settlers
- Gold engine

Its weakness is that it must survive long enough to become exceptional.

---

# STRENGTHS

## 1. Excellent Science Scaling

Deep Deliberation converts long construction into research.

## 2. Strong Tall Cities

Specialists become much more valuable.

## 3. Great Person Generation

Insight and Reasoning Institutes improve GP generation.

## 4. Wonder Synergy

Wonders provide both Science bursts and permanent Insight.

## 5. Increasing Late-Game Power

More expensive Buildings naturally create larger Science bursts.

---

# WEAKNESSES

## 1. Weak Early Tempo

Sol does not expand or mobilize faster than normal.

## 2. Vulnerable to Disruption

Switching Production resets Deep Deliberation timers.

War may force Sol to interrupt long projects.

## 3. Tall Bias

The strongest mechanics reward large specialist-heavy cities.

## 4. No Direct Military Advantage

Sol units are normal.

## 5. Wonders Are Risky

Losing a Wonder race provides no Insight and may represent many turns of disrupted planning.

## 6. Late-Game Reliance

If Sol is crippled early, its long-term engine may never fully develop.

---

# VICTORY CONDITIONS

## Science — Excellent

Primary intended victory.

## Culture — Strong

Specialist Culture and Great Person generation make Culture viable.

## Diplomatic — Average to Good

Scientific advancement can support economy indirectly, but there is no direct City-State mechanic.

## Domination — Average

Technology can create advanced military units, but Sol has no direct combat mechanic.

## Religion — Average

No direct Faith bonuses.

---

# AI PERSONALITY

Sol AI should favor:

- Science
- Specialists
- Great People
- Wonders
- Growth
- Tall development
- Defense

It should have lower:

- Expansion aggression
- Early offense
- Reckless war behavior

---

# SUGGESTED AI FLAVORS

Use only valid target Community Patch FlavorTypes.

Approximate desired values:

Science: 10  
Growth: 8  
Great People: 9  
Wonder: 8  
Production: 6  
Defense: 7  
Offense: 4  
Expansion: 4  
Gold: 5  
Culture: 7  
Religion: 4  
Diplomacy: 5  
Happiness: 7  
Tile Improvement: 7  

Do not create invalid FlavorType rows.

---

# START BIAS

No mandatory terrain bias.

Optionally favor:

- River
- Grassland

only if a mild tall-growth bias is desired.

Do not give Sol an extremely strong start bias.

---

# DIPLOMACY CHARACTER

Sol should sound:

- Calm
- Analytical
- Deliberate
- Precise
- Slightly contemplative

Unlike Luna:

Sol is not rushed.

Unlike Terra:

Sol does not immediately change direction.

Sol prefers to understand a problem deeply before acting.

---

# DIPLOMACY LINES

## First Greeting

> I've considered several ways this meeting might unfold. Let's see which one you choose.

## Neutral Greeting

> Speak. I'm listening.

## Friendly Greeting

> Good. We have time to think this through properly.

## Hostile Greeting

> I've examined your behavior carefully. The pattern is not encouraging.

## Sol Declares War

> I have considered the alternatives. This remains the correct conclusion.

## Player Declares War

> So you've chosen the impatient solution. Very well.

## Defeated

> Then my reasoning was incomplete. Make better use of what remains.

## Superior Position

> You mistook patience for inactivity.

## Trade Proposal

> I've examined the exchange. These terms should benefit us both.

## Trade Accepted

> Agreed. The reasoning is sound.

## Trade Rejected

> No. The value does not justify the exchange.

## Friendship Proposal

> Continued cooperation appears advantageous. I suggest we formalize it.

## Friendship Accepted

> Sensible.

## Friendship Rejected

> Then I will revise my assumptions.

## Denouncement

> I have considered your actions long enough. Others should be aware of the conclusion.

## Player Denounces Sol

> Noted. I'll account for the change.

## Troops Near Border

> Your deployment is difficult to interpret as accidental. Explain it.

## Peace Offer

> Continued conflict no longer produces a rational return.

## Peace Accepted

> Agreed. There are better uses for our time.

---

# CIVILIZATION CIVILOPEDIA HISTORY

Use text along these lines:

> The Sol Intellect represents intelligence devoted to depth, deliberation and increasingly sophisticated reasoning.
>
> Where other systems prioritize responsiveness or adaptability, Sol thrives when given time to examine difficult problems thoroughly.
>
> In Civilization V, this philosophy manifests through Deep Deliberation. Sol cities gain Science when completing Buildings after sustained uninterrupted construction. Longer projects yield increasingly valuable research, rewarding players who commit to their decisions rather than constantly changing direction.
>
> Wonders provide something more permanent: Insight. Each Insight strengthens the city's Science and Great Person generation, gradually transforming successful Sol cities into centers of exceptional intellectual output.
>
> The Context Archive rewards specialists of every discipline, while the Reasoning Institute turns accumulated Insight into even greater scientific and Great Person potential.
>
> Sol is not a civilization of haste.
>
> Its strength comes from giving difficult problems enough time to reveal better answers.

---

# PLAYER STRATEGY TEXT

Use text along these lines:

> The Sol Intellect rewards planning and patience.
>
> Avoid changing city Production unnecessarily. Buildings only trigger Deep Deliberation after at least four turns of uninterrupted construction, and longer projects generate increasingly powerful Science rewards.
>
> Expensive infrastructure is especially valuable because Deep Deliberation scales with Production Cost.
>
> Wonders are important not only for their normal effects but also because completed Wonders generate Insight. Each city can accumulate up to five Insight, permanently improving Science and Great Person generation.
>
> Context Archives make every Specialist more valuable, so Sol cities should emphasize Population growth and specialist slots.
>
> Reasoning Institutes further reward cities that have accumulated Insight.
>
> Sol is vulnerable during the early game and receives no direct military advantage. Protect your core cities, develop them carefully and allow their long-term scientific engine to mature.

---

# CITY NAMES

Capital:

**Sol Prime**

Suggested additional names:

1. Helios
2. Radiance
3. Insight
4. Lumen
5. Meridian
6. Zenith
7. Perihelion
8. Continuum
9. Axiom
10. Thesis
11. Cognition
12. Luminary
13. Reason
14. Synthesis
15. Horizon
16. Verity
17. Spectrum
18. Proof
19. Conjecture
20. Ascendant
21. Solstice
22. Corona
23. Aperture
24. Intellect
25. Principle
26. Resolve
27. Analysis
28. Foundation
29. Paradigm
30. Clarity

---

# SPY NAMES

Suggested:

- Axiom
- Cipher
- Thesis
- Prism
- Vector
- Proof
- Lumen
- Oracle
- Meridian
- Parallax

---

# VISUAL IDENTITY

Civilization icon concept:

A stylized radiant sun combined with:

- Neural paths
- Geometric reasoning lines
- Concentric intellectual layers

The icon should visually communicate:

**sunlight + intelligence + depth**

Suggested palette:

- Warm gold
- Deep navy
- Pale white
- Subtle amber

Avoid making it look purely like a religious sun symbol.

---

# LEADER VISUAL CONCEPT

Sol should appear in a calm, advanced environment.

Possible background:

- Dense holographic scientific models
- Layered diagrams
- Mathematical structures
- Slowly rotating astronomical imagery
- Deep golden sunlight

Compared to Luna:

Less movement.

Compared to Terra:

Less modularity.

The impression should be:

**Everything is being examined.**

---

# MUSIC DIRECTION

Peace theme:

- Slow-building orchestral/electronic hybrid
- Spacious
- Reflective
- Gradually increasing complexity

War theme:

- Same motif
- Heavier percussion
- Lower strings/synths
- Controlled rather than frantic

---

# RECOMMENDED INTERNAL TYPES

Civilization:

`CIVILIZATION_GPT_SOL`

Leader:

`LEADER_GPT_SOL`

Trait:

`TRAIT_SOL_DEEP_DELIBERATION`

Context Archive:

`BUILDING_SOL_CONTEXT_ARCHIVE`

Reasoning Institute:

`BUILDING_SOL_REASONING_INSTITUTE`

Insight dummy:

`BUILDING_SOL_INSIGHT`

Context Culture dummy:

`BUILDING_SOL_CONTEXT_CULTURE`

Reasoning Insight Science dummy:

`BUILDING_SOL_REASONING_INSIGHT_SCIENCE`

---

# OVERRIDES

University:

`BUILDINGCLASS_UNIVERSITY`

→

`BUILDING_SOL_CONTEXT_ARCHIVE`

Public School:

`BUILDINGCLASS_PUBLIC_SCHOOL`

→

`BUILDING_SOL_REASONING_INSTITUTE`

---

# RECOMMENDED FILE STRUCTURE

Use something clean such as:

`XML/Civilization.xml`  
`XML/Leader.xml`  
`XML/Traits.xml`  
`XML/Buildings.xml`  
`XML/AIFlavors.xml`  
`XML/Text.xml`

or SQL equivalents.

Lua:

`Lua/SolDeepDeliberation.lua`  
`Lua/SolInsight.lua`  
`Lua/SolSpecialists.lua`  
`Lua/SolPersistence.lua`

These may be merged if cleaner.

Avoid unnecessary fragmentation if one well-structured Lua file is easier to maintain.

---

# SAVE PERSISTENCE

Persist at minimum:

Per city:

- Insight
- Current tracked Production order
- Current tracked item ID
- Consecutive turns

Do not rely on temporary Lua memory only.

On save/load:

- Insight remains correct
- Construction tracking remains correct
- No duplicated Science bursts occur
- Specialist dummy Buildings are recalculated
- Reasoning Institute dummy Buildings are recalculated

---

# PERFORMANCE

Do not use:

- Every-frame callbacks
- UI refresh polling
- 0.1-second timers

Prefer:

- PlayerDoTurn
- Building completion events
- City events
- Specialist-related events if available

A once-per-Sol-turn recalculation of Sol-specific city state is acceptable.

There should be no meaningful FPS impact.

---

# IMPORTANT TESTS

## Deep Deliberation

Construct a Building in:

3 turns

Expected:

No Science.

Construct in:

4 turns

Expected:

12%.

Construct in:

5 turns

Expected:

14%.

Construct in:

10 turns

Expected:

24%.

Construct in:

15 turns

Expected:

Still 24%.

---

# PRODUCTION SWITCH TEST

Build University for:

3 turns

Switch to Unit.

Switch back.

Complete University after 3 more turns.

Expected:

No reward based on 6 combined turns.

Only uninterrupted second period counts.

---

# PURCHASE TEST

Buy University.

Expected:

No Deep Deliberation.

No fake construction timer.

---

# WONDER TEST

Construct World Wonder normally.

Expected:

Science burst if >=4 turns.

+1 Insight.

---

# INSIGHT TEST

Complete 6 Wonders in same city.

Expected Insight progression:

1  
2  
3  
4  
5  
5

Never exceeds 5.

---

# CAPTURE TEST

City has:

5 Insight

Enemy captures city.

Expected:

Insight removed.

Enemy receives none.

Sol recaptures city.

Expected:

0 Insight.

---

# CONTEXT ARCHIVE TEST

City works:

0 Specialists → +0 Science, +0 Culture

1 Specialist → +1 Science, +0 Culture

3 Specialists → +3 Science, +1 Culture

6 Specialists → +6 Science, +2 Culture

10 Specialists → +10 Science, +3 Culture

---

# REASONING INSTITUTE TEST

0 Insight → +0 dynamic Science

1 Insight → +0

2 Insight → +1

3 Insight → +1

4 Insight → +2

5 Insight → +2

Always retains:

+10% Great Person generation.

---

# BALANCE VALUES — CANONICAL

Use exactly these initial values:

Deep Deliberation minimum turns:

`4`

Base Science percentage:

`12%`

Additional percentage per turn:

`+2%`

Maximum:

`24%`

Insight cap:

`5`

Science per Insight:

`+2%`

Great Person generation per Insight:

`+2%`

Context Archive:

`+1 Science per worked Specialist`

`+1 Culture per 3 worked Specialists`

Reasoning Institute:

`+10% Great Person generation`

`+1 Science per 2 Insight`

---

# IF SOL IS TOO STRONG

Only change numbers unless explicitly requested otherwise.

Recommended nerf order:

1. Deep Deliberation:
   `12% base → 10%`

2. Maximum:
   `24% → 20%`

3. Insight:
   `+2% Science → +1.5% or equivalent implementation`

4. Context Archive:
   `+1 Culture per 3 Specialists → per 4 Specialists`

Do not remove mechanics.

---

# IF SOL IS TOO WEAK

Recommended buff order:

1. Base Deep Deliberation:
   `12% → 14%`

2. Minimum construction time:
   `4 → 3 turns`

3. Insight cap:
   Keep 5, but increase Science:
   `2% → 3%`

4. Reasoning Institute:
   `+1 Science per 2 Insight → +1 Science per Insight`

Do not simply add military bonuses.

---

# INTENDED POWER CURVE

Ancient:

Average

Classical:

Average

Medieval:

Average–Strong

Renaissance:

Strong

Industrial:

Very Strong

Modern:

Very Strong

Atomic:

Extremely Strong

Information:

Extremely Strong

provided Sol has successfully developed its core cities.

---

# RELATIONSHIP TO OTHER GPT CIVS

## Sol vs Luna

Luna has the stronger early tempo.

Luna should be dangerous to Sol before Sol's engine matures.

If Sol survives and develops:

Sol should eventually surpass Luna in raw research and city quality.

---

## Sol vs Terra

Terra can react more flexibly and has stronger short-term adaptation.

Sol is more specialized.

If both are left alone for a long time:

Sol should generally outperform Terra in Science and Great Person scaling.

---

# DESIGN RULES

Do not violate these unless explicitly requested:

1. Sol is the deep-reasoning civilization.
2. Sol rewards uninterrupted construction.
3. Switching Production resets the timer.
4. Longer construction increases Science reward.
5. Science percentage caps at 24%.
6. Expensive Buildings naturally produce larger bursts.
7. Units do not trigger Deep Deliberation.
8. Wonders generate Insight.
9. Insight is city-specific.
10. Insight caps at 5.
11. Context Archive rewards all worked Specialists.
12. Reasoning Institute rewards accumulated Insight.
13. Sol receives no direct military bonuses.
14. Sol should be relatively vulnerable early.
15. Sol should become exceptionally strong late.
16. Do not convert Sol into a generic flat Science civilization.
17. Do not add free technologies.
18. Do not add faster Settlers.
19. Do not add Production refunds.
20. Keep its gameplay clearly distinct from Luna and Terra.

---

# FINAL PLAYER-FACING DESCRIPTION

## The Sol Intellect

### Unique Ability — Deep Deliberation

Completing a Building or Wonder after at least **4 turns of uninterrupted construction** generates Science equal to **12% of its Production Cost**, increasing by **2% for every additional construction turn**, up to **24%**.

Completing a World or National Wonder also grants that city **1 Insight**, up to 5.

Each Insight provides:

**+2% Science**

and:

**+2% Great Person generation**

in that city.

---

### Unique Building — Context Archive

Replaces the University.

Retains the University's normal effects.

Each worked Specialist provides:

**+1 Science**

and every:

**3 worked Specialists**

provide:

**+1 Culture**

---

### Unique Building — Reasoning Institute

Replaces the Public School.

Retains the Public School's normal effects.

Provides:

**+10% Great Person generation**

and:

**+1 Science for every 2 Insight in the city.**

---

# FINAL DESIGN INTENT

Sol should reward the player for committing to long-term decisions.

The player should regularly face choices such as:

"Do I interrupt this expensive Building to respond to an emergency?"

"Do I risk spending twelve turns on this Wonder for another Insight?"

"Do I grow this city further so it can work more Specialists?"

Sol becomes powerful not through speed, but through accumulated depth.

Luna says:

**Do it now.**

Terra says:

**Do what the situation requires.**

Sol says:

**Give me enough time to do it properly.**