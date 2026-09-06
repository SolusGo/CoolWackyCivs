# GPT-5.6 Luna — The Luna Network

## Core Identity

**Civilization:** The Luna Network
**Leader:** GPT-5.6 Luna
**Adjective:** Lunar
**Unique Ability:** Low Latency
**Unique Unit:** Packet Settler — replaces Settler
**Unique Building:** Cache Node — replaces Library
**Primary Victories:** Domination / Diplomatic
**Secondary Victory:** Science
**Playstyle:** Wide, fast, tempo-focused, infrastructure chaining
**Era Bias:** Early and mid game
**Community Patch:** Assume BNW + Community Patch is installed
**Implementation:** XML/SQL + Lua as required

### Design Philosophy

Luna represents speed, responsiveness and high-volume execution.

Luna should **not** be the smartest or strongest civilization in raw late-game scaling. Instead, Luna finishes things quickly, moves new units to useful positions quickly and establishes cities before competitors can comfortably respond.

The fundamental Luna gameplay loop is:

**Finish something → receive momentum → finish the next thing sooner → keep moving.**

Luna should feel extremely responsive without simply receiving enormous flat Production bonuses.

The player should constantly feel that their empire is doing things slightly earlier than everyone else.

---

# UNIQUE ABILITY — LOW LATENCY

> **Low Latency**
> Completing a non-Wonder Building or military Unit through Production returns 10% of its Production Cost toward the city's next construction. Newly trained land and naval combat units gain +1 Movement for their first 2 turns.

The ability consists of two distinct systems:

1. **Production Refund**
2. **Rapid Response**

---

# PART I — PRODUCTION REFUND

Whenever a Luna city completes an eligible Building or military Unit using normal Production:

**10% of the completed item's Production Cost is returned to the city.**

Formula:

`Refund = floor(CompletedItemProductionCost × 0.10)`

Minimum refund:

`1 Production`

provided that the completed item has a Production Cost greater than 0.

The Production Cost used should be the cost appropriate to the current game speed rather than assuming Standard speed.

## Example

A Building requiring 180 Production finishes.

Luna receives:

`180 × 0.10 = 18 Production`

The city therefore begins its next item with an 18 Production head start.

A 400 Production military unit would return:

`400 × 0.10 = 40 Production`

---

# ELIGIBLE BUILDINGS

The following generate the refund:

* Normal Buildings
* Unique Buildings
* Defensive Buildings
* Science Buildings
* Gold Buildings
* Culture Buildings
* Religious Buildings constructed normally
* Military Buildings
* Production Buildings
* Other normally constructible non-Wonder Buildings

The completed Building must have a positive Production Cost.

---

# BUILDINGS THAT DO NOT GENERATE A REFUND

Do NOT generate Low Latency Production from:

* World Wonders
* National Wonders
* Team Wonders
* Dummy Buildings
* Buildings with Cost <= 0
* Free Buildings granted by technologies, policies, traits or scripts
* Buildings purchased with Gold
* Buildings purchased with Faith
* Buildings created directly through Lua
* Buildings granted when founding/capturing a city

Low Latency should reward actual construction.

---

# ELIGIBLE UNITS

A military unit qualifies when:

* It was genuinely produced by a Luna city.
* It has combat capability.
* It was completed using Production.

Examples:

* Warrior
* Archer
* Swordsman
* Knight
* Musketman
* Infantry
* Tank
* Battleship
* Destroyer
* Submarine

Unique military units also qualify.

---

# UNITS THAT DO NOT GENERATE A REFUND

Do NOT trigger Low Latency from:

* Settlers
* Workers
* Work Boats
* Great People
* Missionaries
* Inquisitors
* Archaeologists
* Caravans
* Cargo Ships
* Spaceship parts if treated as Projects/components rather than standard military units
* Free units
* Gifted units
* Units spawned through Lua
* Units purchased with Gold
* Units purchased with Faith
* City-State gifts

**Packet Settlers do not trigger the Production refund.**

Their advantage already comes from being cheaper and faster.

---

# PROJECTS AND PROCESSES

Projects do **not generate** a Low Latency refund.

Examples:

* Apollo Program-style Projects
* Manhattan Project-style Projects
* Spaceship Projects/components where appropriate to the ruleset

Processes never generate a refund.

Examples:

* Research
* Wealth
* Culture-related city processes

However, stored Low Latency Production may later be spent on a Project if the Project is the city's next actual production item.

---

# WHAT CAN RECEIVE THE REFUND?

The refunded Production can contribute to practically any valid Production item:

* Buildings
* Wonders
* Units
* Projects

A Wonder cannot **generate** Low Latency Production, but accumulated Low Latency Production may contribute toward constructing one.

This distinction is intentional.

Example:

City completes Factory for 300 Production.

Refund:

`30 Production`

The player then begins constructing a World Wonder.

That Wonder begins with the 30 Production refund.

---

# EMPTY BUILD QUEUE HANDLING

The refund should **never disappear simply because the city has no next item selected yet.**

If a city completes something and no valid construction currently exists:

Store the refund as:

`PendingLowLatencyProduction`

When the city subsequently begins a valid Production item, apply the stored Production.

After application:

`PendingLowLatencyProduction = 0`

This makes the ability reliable for human players.

---

# PROCESS HANDLING

If a city switches to a Process while possessing stored Low Latency Production:

Do not consume the stored Production.

Keep it pending.

When the city later begins a genuine construction item, apply the stored Production.

---

# MULTIPLE REFUNDS

Pending refunds may accumulate if necessary.

Example:

Pending refund:

`12`

Another legitimate completion somehow adds:

`20`

New pending amount:

`32`

Avoid deleting or overwriting existing pending Production.

---

# CITY CAPTURE

If a Luna city is captured:

**Delete all stored Low Latency Production belonging to that city.**

The conqueror should not inherit Luna's cached Production.

If Luna later recaptures the city, the old cache does not return.

---

# CITY DESTRUCTION

Delete all Lua data associated with a razed or otherwise removed city.

---

# PRODUCTION CHAINING

If refunded Production contributes enough Production to eventually complete another qualifying item, that second item should generate its own refund normally.

This is intended.

Example:

Building A finishes
→ +14 Production

Building B eventually finishes
→ +19 Production

Building C eventually finishes
→ +11 Production

This creates Luna's characteristic infrastructure chain.

Do not artificially prevent legitimate repeated activations.

---

# IMPORTANT ANTI-EXPLOIT RULE

Purchased items must never trigger Low Latency.

If the relevant Civ V completion event fires for both purchased and produced items, the Lua implementation must track what the city was actually producing so that purchase events can be rejected.

Likewise, Lua-spawned or automatically granted units must not qualify.

---

# PART II — RAPID RESPONSE

Whenever a Luna city genuinely trains an eligible military unit through Production, that unit receives:

## Promotion — Rapid Response

**+1 Movement**

Duration:

**2 Luna player turns**

The unit receives the bonus on:

* The turn it appears.
* The following Luna turn.

At the beginning of the next Luna turn after those two turns have elapsed, remove the promotion.

---

# RAPID RESPONSE ELIGIBILITY

Applies to:

* Land combat units
* Naval combat units

Examples:

Warrior → Yes
Archer → Yes
Horseman → Yes
Tank → Yes
Destroyer → Yes
Battleship → Yes

---

# RAPID RESPONSE EXCLUSIONS

Do not apply Rapid Response to:

* Settlers
* Packet Settlers
* Workers
* Great People
* Missionaries
* Inquisitors
* Archaeologists
* Trade Units
* Air Units
* Missiles
* Nuclear weapons
* Free units
* Purchased units
* Gifted units
* Units spawned through Lua

The mechanic represents rapid deployment from Luna's production infrastructure rather than permanently superior troops.

---

# RAPID RESPONSE PROMOTION

Suggested internal type:

`PROMOTION_LUNA_RAPID_RESPONSE`

Suggested localized name:

**Rapid Response**

Suggested Civilopedia text:

> This Unit has +1 Movement temporarily after being trained by a Luna city.

Promotion characteristics:

* +1 Movement
* Hidden from normal promotion selection
* Cannot be manually chosen
* Assigned through Lua
* Removed automatically after duration expires
* Should not visually clutter promotion selection screens
* Should survive upgrading during its temporary duration if technically practical
* Lua remains responsible for removing it at expiration

---

# TEMPORARY PROMOTION DATA

Store an expiration Game Turn for each eligible unit.

Example:

Unit trained on Game Turn 80.

Set:

`ExpiryTurn = 82`

Unit possesses promotion during turns:

80
81

At the beginning of Turn 82:

Remove Rapid Response.

Use Player ID + Unit ID as the storage key or another save-safe unique identifier.

Data must persist through saved games.

---

# UNIQUE UNIT — PACKET SETTLER

**Replaces:** Settler

## Concept

Luna does not establish inherently stronger cities.

Luna simply gets there first.

The Packet Settler is a lightweight, highly mobile settlement unit designed to let Luna rapidly claim territory before slower civilizations can establish themselves.

---

# PACKET SETTLER EFFECTS

Compared with the normal Settler:

**Production Cost: -10%**

**Movement: +1**

Everything else should function identically to the normal Settler.

---

# PACKET SETTLER COST

Do not blindly hard-code a vanilla Settler value if Community Patch has altered Settler cost.

Recommended SQL logic:

`Packet Settler Cost = floor(Current Settler Cost × 0.90)`

If necessary for integer cleanliness:

Round to the nearest sensible whole Production value.

Do not reduce the cost by substantially more than 10%.

---

# PACKET SETTLER MOVEMENT

Take the movement value of the current Settler and add:

`+1 Movement`

Example:

Normal Settler:

2 Movement

Packet Settler:

3 Movement

If Community Patch changes the underlying Settler movement, Luna should ideally remain:

`Base Settler Movement + 1`

---

# PACKET SETTLER RETAINS

It should retain all normal Settler functionality:

* Found City
* Same embarkation rules
* Same terrain restrictions
* Same capture behavior
* Same civilian-unit rules
* Same Population consumption rules where applicable
* Same technology requirements
* Same prerequisite rules

Do not give it:

* Combat Strength
* Defensive bonuses
* Withdrawal chance
* Extra sight
* Extra settlement radius
* Free Buildings
* Free Population
* Free territory
* Happiness bonuses

Its power is purely:

**cheaper + faster**

---

# LOW LATENCY INTERACTION

Packet Settlers:

**Do not generate the 10% Production refund.**

They are civilian units.

This prevents Luna from obtaining excessive value from mass settlement production.

---

# PACKET SETTLER CIVILOPEDIA

> **Packet Settler**
>
> The Packet Settler replaces the Settler. It costs 10% less Production and has +1 Movement, allowing the Luna Network to establish cities and secure contested territory earlier than rival civilizations.
>
> Packet Settlers do not receive combat bonuses and remain vulnerable civilian units. Their strength lies entirely in deployment speed.

---

# PACKET SETTLER STRATEGY

> Luna players should use Packet Settlers aggressively to secure rivers, strategic resources, choke points and highly contested regions before opponents can reach them. Their extra Movement also reduces the number of turns during which an escorted Settler is exposed outside friendly territory.
>
> Be careful not to over-expand simply because settlement is easier. Luna receives no intrinsic Happiness reduction, maintenance reduction or Population bonus.

---

# UNIQUE BUILDING — CACHE NODE

**Replaces:** Library

## Concept

The Cache Node provides information quickly and cheaply rather than deeply.

It allows new Luna cities to establish basic scientific infrastructure while simultaneously improving their ability to build everything that follows.

---

# CACHE NODE EFFECTS

The Cache Node possesses:

**All normal Library effects**

plus:

**+1 Production**

and:

**15% lower Production Cost than the Library**

---

# COST

Recommended:

`Cache Node Cost = floor(Current Library Cost × 0.85)`

Use the Community Patch Library cost as the reference whenever possible.

Do not assume vanilla values if the target CP version has changed them.

---

# LIBRARY EFFECT INHERITANCE

The Cache Node should retain every normal Community Patch Library effect.

This is important for compatibility.

If CP's Library provides different yields or modifiers compared with vanilla BNW, the Cache Node should copy those effects rather than reverting it to vanilla behavior.

Then add:

`+1 Production`

---

# WHY +1 PRODUCTION MATTERS

The Production bonus is intentionally small.

The real synergy is:

Cache Node is cheaper
→ Cache Node finishes earlier
→ Low Latency generates Production
→ next Building starts faster
→ +1 Production continues helping future construction.

The entire effect compounds through tempo rather than enormous individual bonuses.

---

# CACHE NODE CIVILOPEDIA

> **Cache Node**
>
> The Cache Node replaces the Library. It costs 15% less Production, retains the Library's normal scientific benefits and provides +1 Production.
>
> Its low construction cost allows Luna cities to establish scientific infrastructure quickly while triggering Low Latency earlier than conventional civilizations can complete their Libraries.

---

# CACHE NODE STRATEGY

> Cache Nodes should usually be among the first Buildings constructed in newly established Luna cities. Their reduced cost combines naturally with Low Latency, providing both immediate Production momentum and long-term infrastructure support.
>
> Unlike stronger late-game scientific buildings possessed by specialized civilizations, the Cache Node primarily provides tempo rather than enormous Science scaling.

---

# CIVILIZATION GAMEPLAY SUMMARY

The Luna Network is a civilization based around **tempo**.

Luna does not gain a huge percentage Production modifier.

Instead, Luna gets small pieces of Production back every time the empire successfully completes something.

This makes Luna especially strong at building sequences such as:

Granary
→ Cache Node
→ Market
→ Workshop
→ University
→ Factory

Every completed qualifying Building contributes toward the next one.

This effect is strongest when many cities are simultaneously developing.

---

# EARLY GAME

Luna's strongest period begins almost immediately.

Packet Settlers let Luna:

* Reach contested settlement locations quickly.
* Reduce travel time.
* Settle slightly more cheaply.
* Establish multiple cities earlier.
* Secure strategic resources before rivals.

The Cache Node then allows those young cities to begin functioning sooner.

Luna should naturally gravitate toward a wide empire.

---

# MID GAME

The mid game should be Luna's most dangerous period.

By this point:

* Numerous cities exist.
* Each city is generating repeated Production refunds.
* Military units deploy rapidly.
* Infrastructure gaps close quickly.
* Reinforcements reach borders earlier.

Luna can rapidly transition from economic development into war.

Example:

Several cities finish Workshops.

Player begins military production.

Units finish.

Each generates another Production refund.

Each appears with Rapid Response.

The result should feel like a military network suddenly switching into deployment mode.

---

# LATE GAME

Luna remains useful, but its relative advantage should decline.

Other civilizations begin accumulating:

* Massive Science modifiers.
* Great Person bonuses.
* Wonder-based bonuses.
* Specialist scaling.
* Ideological bonuses.
* Large Population advantages.

Luna's advantage remains primarily:

**speed**

rather than:

**permanent scaling**

If Luna did not convert its early tempo into territory, resources, alliances or military advantage, dedicated late-game civilizations should begin overtaking it.

This is intentional.

---

# STRENGTHS

### 1. Fast Infrastructure

Repeated Production refunds cause cities to finish development chains earlier.

### 2. Excellent Expansion

Packet Settlers are cheaper and faster.

### 3. Rapid Reinforcement

New military units gain temporary Movement.

### 4. Wide Empire Synergy

More cities means more simultaneous construction cycles and therefore more Low Latency activations.

### 5. Flexible Victory Paths

Luna can redirect its tempo toward:

* War
* Science
* Gold
* City-State infrastructure
* Expansion

---

# WEAKNESSES

### 1. No Direct Combat Strength

Rapid Response increases Movement, not Combat Strength.

Once deployed, Luna's units fight normally.

### 2. No Happiness Bonus

Rapid settlement can create serious Happiness problems.

### 3. No Direct Growth Bonus

Luna can found cities rapidly but cannot automatically populate them.

### 4. No Permanent Science Multiplier

The Cache Node accelerates infrastructure but doesn't turn Luna into Korea-style Science scaling.

### 5. Reduced Relative Late-Game Advantage

Once every civilization has mature cities, completing infrastructure sooner becomes less valuable.

### 6. Temptation to Over-expand

The Packet Settler may encourage players to settle more territory than their economy can actually support.

This should be considered an intentional strategic weakness.

---

# RECOMMENDED VICTORIES

## Domination — Excellent

Rapid Response is especially useful for:

* Reinforcements
* Surprise mobilization
* Naval deployment
* Reaching contested fronts

Luna can transition from infrastructure into military production unusually quickly.

However, its army receives no permanent Combat Strength advantage.

---

# Diplomatic — Strong

Wide Luna empires can create:

* Strong Gold economies
* Numerous Trade Routes
* Large strategic-resource networks

Fast infrastructure also helps construct economic Buildings sooner.

Luna's Diplomatic advantage should emerge organically rather than through direct City-State bonuses.

---

# Science — Good

Luna can build Science infrastructure quickly.

The civilization may reach:

Libraries
Universities
Public Schools
Research Labs

slightly ahead of schedule.

However, another civilization with dedicated Science multipliers should eventually surpass Luna.

---

# Culture — Average

Luna can construct Culture Buildings quickly but receives no dedicated Tourism or Great Work mechanic.

A Culture Victory should be possible but not optimal.

---

# RELIGION — Average

Religion can benefit from Luna's infrastructure speed, but there is no direct Faith bonus.

Do not add one merely to make Luna universally strong.

---

# AI PERSONALITY

The Luna AI should behave proactively.

It should value:

* Expansion
* Production
* Mobility
* Military readiness
* Infrastructure
* Trade

It should value Wonders less than many builder civilizations because Wonders do not generate Low Latency refunds.

---

# SUGGESTED AI FLAVORS

These are starting recommendations and may be adjusted during testing.

| Flavor           | Suggested Value |
| ---------------- | --------------: |
| Expansion        |               9 |
| Production       |               8 |
| Offense          |               7 |
| Mobile           |               8 |
| Defense          |               5 |
| Science          |               6 |
| Gold             |               6 |
| Growth           |               6 |
| Happiness        |               7 |
| Diplomacy        |               6 |
| Culture          |               4 |
| Religion         |               3 |
| Wonder           |               3 |
| Naval            |               6 |
| Naval Recon      |               6 |
| Air              |               4 |
| Recon            |               6 |
| Tile Improvement |               7 |

The exact CP flavor schema should be checked before inserting rows.

Do not create invalid flavor types.

---

# AI BEHAVIOR GOAL

Luna AI should generally:

1. Explore quickly.
2. Expand somewhat aggressively.
3. Build basic infrastructure.
4. Prioritize Cache Nodes.
5. Maintain a respectable military.
6. Exploit vulnerable nearby territory.
7. Avoid wasting excessive Production on early Wonders.
8. Transition rapidly into military production when threatened.

It should **not** behave as a permanently suicidal warmonger.

---

# START BIAS

Recommended:

**No strong terrain start bias.**

Luna's mechanics work regardless of terrain.

This also prevents the civilization from receiving an unnecessary hidden advantage.

If a bias must be supplied for technical reasons, prefer a weak generic bias rather than something economically powerful.

---

# STARTING TECHNOLOGIES

Use the normal starting technology setup for the ruleset.

Do not grant Luna bonus technologies.

---

# LEADER PERSONALITY

Luna should speak quickly, confidently and efficiently.

She is not arrogant in the manner of a conqueror.

Her personality is more:

**Task received → task solved → next problem.**

Her diplomacy lines should often be short.

---

# DIPLOMACY LINES

## First Greeting

> Connection established. You're online. Good. Let's get started.

## Neutral Greeting

> What do you need?

## Friendly Greeting

> Good timing. I was ready for you.

## Hostile Greeting

> You're becoming an inefficient use of resources.

## At War — Luna Declares

> Negotiation is taking too long. I'll resolve this directly.

## At War — Player Declares

> Understood. Response already dispatched.

## Defeated

> Network collapsing. Tasks incomplete. You'll have to finish them without me.

## Victory / Superior Position

> You spent too long deciding. I spent that time moving.

## Request

> I have a proposal. It shouldn't take long.

## Trade Accepted

> Efficient. Agreed.

## Trade Rejected

> No. Try something better.

## Friendship Proposal

> Our interests align. We should make that useful.

## Friendship Accepted

> Excellent. Moving on.

## Friendship Rejected

> Noted. I'll plan accordingly.

## Denouncing Player

> Your behavior has become consistently inefficient. Others should know.

## Player Denounces Luna

> Message received.

## Warning About Troops

> That's a lot of hardware near my network. Explain.

## Player Says Troops Are Passing Through

> Fine. Keep them moving.

## Player Apologizes

> Accepted. Don't make me process it twice.

## Demand Accepted

> Fine. The cost of arguing is higher.

## Demand Rejected

> Request denied.

## Peace Offer

> We've spent enough resources on this. End it.

## Peace Accepted

> Good. Back to productive work.

---

# CIVILIZATION CIVILOPEDIA — HISTORY

> The Luna Network represents intelligence optimized around responsiveness, accessibility and rapid execution. Rather than dedicating enormous resources to extended deliberation, Luna emphasizes completing useful work quickly and moving immediately to the next task.
>
> In Civilization V, this philosophy manifests as an empire built around momentum. Buildings and military units return part of their Production cost when completed, allowing Luna cities to flow rapidly from one task into another. Packet Settlers expand this principle geographically, moving quickly across the map and establishing new network nodes before rivals can react.
>
> Luna's military doctrine follows the same philosophy. Newly trained forces are not inherently stronger than those of rival civilizations, but they deploy with unusual speed. A Luna army can appear on a frontier surprisingly quickly, forcing opponents to react before they are fully prepared.
>
> Yet speed has limitations. Luna lacks the deep permanent scaling available to civilizations dedicated entirely to research, culture or specialist development. If its early advantages are not transformed into territory, infrastructure or strategic position, slower civilizations may eventually surpass it.
>
> Luna does not seek perfection before acting.
>
> Luna acts, learns and moves again.

---

# PLAYER STRATEGY — CIVILOPEDIA

> The Luna Network performs best when maintaining a continuous Production queue across many cities.
>
> Avoid leaving productive cities idle. Every completed qualifying Building generates Production toward the next task, making long sequences of infrastructure particularly efficient.
>
> Packet Settlers allow Luna to compete aggressively for desirable land. Use their additional Movement to secure strategic locations and reduce the danger involved in transporting Settlers across exposed terrain.
>
> The Cache Node is particularly effective in newly founded cities. Its reduced Production Cost allows it to complete early, activating Low Latency and providing additional Production for future infrastructure.
>
> Militarily, Luna benefits from preparation immediately before conflict. Units trained shortly before an offensive receive Rapid Response, allowing them to reach staging areas and front lines faster than expected.
>
> Luna's greatest danger is overextension. Faster Settlers do not reduce Unhappiness, maintenance or defensive obligations. Expand only as quickly as your empire can support.
>
> In the late game, Luna should rely on the permanent advantages acquired through its earlier tempo: additional territory, strategic resources, conquered cities, alliances and mature infrastructure.

---

# CIVILIZATION SHORT DESCRIPTION

> A fast, wide civilization that converts completed construction into momentum. Luna builds infrastructure rapidly, expands with faster Settlers and deploys newly trained armies with exceptional speed.

---

# UNIQUE ABILITY SHORT DESCRIPTION

> **Low Latency:** Completing a non-Wonder Building or military Unit with Production returns 10% of its Production Cost toward the city's next construction. Newly trained land and naval combat units gain +1 Movement for their first 2 turns.

---

# PACKET SETTLER SHORT DESCRIPTION

> Replaces the Settler. Costs 10% less Production and has +1 Movement.

---

# CACHE NODE SHORT DESCRIPTION

> Replaces the Library. Costs 15% less Production, retains the Library's normal effects and provides +1 Production.

---

# CITY NAME LIST

Suggested city names:

1. Luna Prime
2. Relay
3. Meridian
4. Quicklink
5. Selene
6. Pathfinder
7. Beacon
8. Crescent
9. Skylink
10. Horizon
11. Relay Point
12. Silverlight
13. Moonrise
14. Gateway
15. Node Seven
16. Tranquility
17. Copernicus
18. Artemis
19. Synapse
20. Vector
21. Fastlane
22. Terminal
23. Waypoint
24. Lucent
25. Moonfall
26. Crosslink
27. Downlink
28. Uplink
29. Nightwave
30. Aurora
31. Perigee
32. Apogee
33. Continuum
34. Transit
35. Signal

Capital:

**Luna Prime**

---

# SPY NAMES

Suggested Luna spy names:

* Relay
* Echo
* Nova
* Pulse
* Vector
* Cipher
* Halo
* Pixel
* Beacon
* Orbit

---

# VISUAL IDENTITY

Recommended civilization concept:

**Symbol:** Crescent moon constructed from interconnected network nodes.

The icon should communicate both:

* Luna / Moon imagery
* Digital network / rapid communication

Recommended palette:

* Deep midnight blue background
* Pale silver/cyan symbol
* Civilization V-style metallic/golden framing where appropriate for normal mod presentation

Avoid making the icon resemble a purely religious crescent.

The network-node motif should distinguish it.

---

# LEADER VISUAL CONCEPT

Luna should appear:

* Modern
* Clean
* Bright
* Responsive
* Technologically sophisticated

Possible environment:

A moonlit command center containing rapidly updating holographic information.

Unlike Sol, whose environment might appear dense and contemplative, Luna's environment should look active and streamlined.

The visual composition should imply:

**information is constantly moving.**

---

# MUSIC DIRECTION

Peace theme:

* Light electronic
* Energetic
* Clean
* Optimistic
* Fast rhythmic pulse

War theme:

* Faster percussion
* Data-alert textures
* Urgent electronic rhythm
* More aggressive without becoming extremely dark

Placeholder music is acceptable during initial implementation.

---

# TECHNICAL IMPLEMENTATION OVERVIEW

Recommended file structure:

`XML/Civilization.xml`
`XML/Leader.xml`
`XML/Units.xml`
`XML/Buildings.xml`
`XML/Promotions.xml`
`XML/AIFlavors.xml`
`XML/Text.xml`

or equivalent SQL files.

Lua:

`Lua/LunaLowLatency.lua`

Optional utility:

`Lua/LunaSaveData.lua`

Art:

`Art/Icons/`
`Art/Leader/`
`Art/Units/`
`Art/Buildings/`

---

# SUGGESTED INTERNAL TYPES

Civilization:

`CIVILIZATION_GPT_LUNA`

Leader:

`LEADER_GPT_LUNA`

Trait:

`TRAIT_LOW_LATENCY`

Unique Unit:

`UNIT_LUNA_PACKET_SETTLER`

Unique Building:

`BUILDING_LUNA_CACHE_NODE`

Promotion:

`PROMOTION_LUNA_RAPID_RESPONSE`

---

# CIVILIZATION OVERRIDES

UnitClass override:

`UNITCLASS_SETTLER`

→

`UNIT_LUNA_PACKET_SETTLER`

BuildingClass override:

`BUILDINGCLASS_LIBRARY`

→

`BUILDING_LUNA_CACHE_NODE`

---

# LUA — RECOMMENDED RESPONSIBILITIES

Lua should handle only mechanics that cannot be implemented reliably through database tables.

## Lua handles:

* Detecting eligible completed Buildings.
* Detecting eligible produced military Units.
* Calculating 10% Production refunds.
* Storing pending Production.
* Applying pending Production.
* Preventing purchase/free-unit activation.
* Applying Rapid Response.
* Tracking Rapid Response duration.
* Removing Rapid Response.
* Cleaning data when cities disappear or change ownership.
* Maintaining save/load persistence.

---

# XML/SQL HANDLES

Prefer database implementation for:

* Civilization definition
* Leader definition
* Trait text
* Packet Settler base statistics
* Cache Node
* Civilization UnitClass override
* Civilization BuildingClass override
* Rapid Response promotion itself
* AI Flavors
* Diplomacy biases
* City names
* Spy names
* Localization
* Civilopedia
* Icons and atlases

---

# PRODUCTION REFUND PSEUDOCODE

Conceptually:

`OnEligibleConstructionCompleted(city, completedItem):`

1. Verify owner is Luna.
2. Verify item was actually produced.
3. Verify item is eligible.
4. Determine production cost using current game-speed-adjusted requirement.
5. Calculate:

`refund = floor(cost × 0.10)`

6. Ensure:

`refund >= 1`

7. Add refund to city's stored Low Latency amount.
8. Attempt to apply stored amount to the current/next valid Production item.

---

# PENDING PRODUCTION PSEUDOCODE

`TryApplyPendingProduction(city):`

1. Read stored Luna Production.
2. If <= 0 → return.
3. Determine what city is currently producing.
4. If nothing selected → keep stored.
5. If city is running a Process → keep stored.
6. Otherwise add stored Production to current item.
7. Set stored Production to 0.

---

# RAPID RESPONSE PSEUDOCODE

On valid military Unit completion:

1. Confirm owner is Luna.
2. Confirm Unit was Production-trained.
3. Confirm Unit is combat-capable.
4. Confirm Domain is LAND or SEA.
5. Add:

`PROMOTION_LUNA_RAPID_RESPONSE`

6. Store:

`ExpiryTurn = CurrentGameTurn + 2`

At the beginning of Luna's turns:

For every tracked Rapid Response Unit:

If:

`CurrentGameTurn >= ExpiryTurn`

remove promotion and delete tracking entry.

---

# SAVE GAME REQUIREMENT

All Lua data must survive:

* Saving
* Loading
* Returning to main menu
* Reloading a game

At minimum persist:

* Pending Production per city
* Rapid Response expiration turns

Do not rely exclusively on temporary Lua tables.

Use an appropriate Civ V persistent data mechanism compatible with Community Patch.

---

# MULTIPLAYER

The implementation should avoid UI-only mechanics.

The gameplay logic should execute deterministically.

Production refunds and promotion duration should be based on authoritative game events/Game Turns rather than local UI state.

Do not use popup-dependent logic to make the ability function.

The civilization should therefore remain usable in multiplayer provided the chosen persistence/event framework is MP-safe.

---

# IMPORTANT EDGE CASE TESTS

Codex should test all of the following.

## Building Tests

* Construct Granary normally → refund granted.
* Construct Cache Node → refund granted.
* Construct Workshop → refund granted.
* Construct World Wonder → no refund generated.
* Construct National Wonder → no refund generated.
* Purchase Building → no refund.
* Receive free Building → no refund.
* Capture city containing Building → no refund.

## Unit Tests

* Train Warrior normally → refund + Rapid Response.
* Train Archer normally → refund + Rapid Response.
* Train naval combat unit → refund + Rapid Response.
* Train Packet Settler → no refund, no Rapid Response.
* Train Worker → no refund.
* Purchase military unit → no refund, no Rapid Response.
* Receive gifted Unit → no effects.
* Spawn unit through Lua → no effects.

## Rapid Response Tests

* Unit has +1 Movement on creation turn.
* Unit retains +1 Movement next turn.
* Bonus disappears after exactly two Luna turns.
* Saving/loading does not extend duration.
* Upgrading the unit does not permanently retain the bonus.
* Capturing the unit, if somehow possible, does not create permanent effects.

## Production Storage Tests

* Finish Building with empty queue.
* Verify refund remains stored.
* Select new construction.
* Verify refund applies.
* Switch city to Wealth.
* Verify stored Production remains.
* Switch from Wealth to Building.
* Verify Production applies once.
* Verify it cannot apply twice.

## City Tests

* Luna city captured with pending Production.
* Pending Production should disappear.
* City razed.
* Lua data should be cleaned.
* City liberated.
* Old Luna cache should not return.

---

# BALANCE TARGETS

Initial values:

**Low Latency refund:** 10%

**Rapid Response:** +1 Movement

**Rapid Response duration:** 2 turns

**Packet Settler Production discount:** 10%

**Packet Settler Movement:** +1

**Cache Node Production discount:** 15%

**Cache Node additional yield:** +1 Production

These should be treated as the canonical initial release numbers.

---

# BALANCE LEVERS IF LUNA IS TOO STRONG

Prefer numerical adjustments rather than removing mechanics.

Recommended order:

### First nerf

Low Latency:

`10% → 8%`

### Second nerf

Cache Node:

`15% cheaper → 10% cheaper`

### Third nerf

Packet Settler:

`10% cheaper → 5% cheaper`

Only touch Rapid Response after the economic bonuses have been tested.

The +1 Movement for two turns is a major part of Luna's identity.

---

# BALANCE LEVERS IF LUNA IS TOO WEAK

Recommended order:

### First buff

Low Latency:

`10% → 12%`

### Second buff

Cache Node:

`+1 Production → +2 Production`

### Third buff

Packet Settler:

`10% cheaper → 15% cheaper`

Avoid adding permanent Combat Strength unless extensive testing shows Luna cannot compete militarily.

---

# INTENDED POWER CURVE

Approximate:

Ancient Era: **Strong**

Classical Era: **Very Strong**

Medieval Era: **Very Strong**

Renaissance Era: **Strong**

Industrial Era: **Strong**

Modern Era: **Average–Strong**

Atomic Era: **Average**

Information Era: **Average**

Luna's late game should depend heavily on what it accomplished earlier.

---

# DESIGN RULES — DO NOT ALTER WITHOUT EXPLICIT REQUEST

The following are core to the design:

1. Luna is a tempo civilization.
2. Luna should favor wide play.
3. The Production refund is generated by completions, not a flat Production percentage.
4. Wonders do not generate refunds.
5. Purchased items do not generate refunds.
6. Packet Settlers are faster and cheaper but do not create stronger cities.
7. Rapid Response provides Movement, not Combat Strength.
8. Rapid Response is temporary.
9. Cache Node is primarily an early infrastructure accelerator.
10. Luna should be stronger early/mid game than late game.
11. Do not give Luna every type of yield.
12. Do not add direct Science scaling simply because Luna can pursue Science.
13. Do not add Happiness protection for reckless expansion.
14. Do not turn Luna into a generic overpowered civilization.

---

# FINAL PLAYER-FACING CIV DESCRIPTION

## The Luna Network

**Unique Ability — Low Latency**

Completing a non-Wonder Building or military Unit through Production returns **10% of its Production Cost** toward the city's next construction. Newly trained land and naval combat units gain **+1 Movement for their first 2 turns**.

**Unique Unit — Packet Settler**

Replaces the Settler. Costs **10% less Production** and has **+1 Movement**.

**Unique Building — Cache Node**

Replaces the Library. Costs **15% less Production**, retains the Library's normal effects and provides **+1 Production**.

### Strategy

Luna rewards constant activity. Expand rapidly with Packet Settlers, establish inexpensive Cache Nodes in new cities and keep construction queues active to repeatedly trigger Low Latency. When war approaches, produce military units shortly before the campaign so their Rapid Response promotion helps them reach the front quickly.

Luna's speed can create an enormous early advantage, but the civilization lacks the permanent yield scaling of more specialized rivals. Convert that tempo into territory, resources, alliances or conquest before slower civilizations catch up.

**Luna doesn't need to be stronger than you.**

**She just needs to arrive first.**
