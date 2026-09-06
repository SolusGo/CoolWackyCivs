# GPT-5.6 Terra — The Terra Framework

## Core Identity

**Civilization:** The Terra Framework
**Leader:** GPT-5.6 Terra
**Adjective:** Terran
**Unique Ability:** Adaptive Intelligence
**Unique Unit:** Adaptive Operative — replaces Musketman
**Unique Building:** Multimodal Hub — replaces Market
**Primary Victory:** Flexible / Any
**Strongest Paths:** Diplomatic, Science, Domination
**Playstyle:** Adaptive, reactive, generalist, city specialization
**Era Bias:** Mid game
**Community Patch:** Assume Civilization V: Brave New World + Community Patch
**Implementation:** XML/SQL + Lua where necessary

---

# DESIGN PHILOSOPHY

Terra represents versatility.

Sol is designed to think deeply.

Luna is designed to move quickly.

Terra is designed to handle whatever problem appears in front of it.

Terra should therefore **not outperform specialized civilizations at their specialty**.

Instead, Terra should be unusually difficult to place into a bad situation.

A Terra empire can transition from:

Science
→ War
→ Economic recovery
→ Culture

without having to completely rebuild its empire.

Its central mechanic allows every city to temporarily reconfigure itself depending upon what type of infrastructure it completes.

The intended gameplay loop is:

**Identify problem → construct relevant infrastructure → city adapts → exploit temporary specialization → adapt again.**

---

# UNIQUE ABILITY — ADAPTIVE INTELLIGENCE

> **Adaptive Intelligence:** Completing certain Buildings through Production places that city into an Operating Mode for 10 turns. Research Buildings grant +10% Science, economic Buildings grant +10% Gold, cultural or religious Buildings grant +8% Culture and Faith, and production or military Buildings grant +10% Production. A city may only operate in one Mode at a time.

The four Operating Modes are:

1. **Research Mode**
2. **Commerce Mode**
3. **Creative Mode**
4. **Execution Mode**

Every Terra city tracks its Operating Mode independently.

---

# CORE OPERATING MODE RULE

A city may have:

**Exactly one Operating Mode active at once.**

Completing an eligible Building determines the new Mode.

If the city already possesses another Mode:

**The previous Mode is immediately removed.**

The newly triggered Mode then begins with a fresh:

**10-turn duration.**

---

# OPERATING MODE DURATION

Operating Modes last:

**10 Terra player turns**

Recommended implementation:

`ExpiryTurn = CurrentGameTurn + 10`

The Mode is active during the turn on which the qualifying Building completes.

At the beginning of the Terra player's turn when:

`CurrentGameTurn >= ExpiryTurn`

the Mode expires.

---

# REFRESHING THE SAME MODE

If a city already possesses a Mode and completes another Building belonging to the same category:

The Mode does not stack.

Instead:

**Duration resets to 10 turns.**

Example:

A city is currently in Research Mode.

It has 4 turns remaining.

The city completes a University.

Research Mode returns to:

**10 turns remaining.**

There is never:

+20% Science

from overlapping Research Modes.

---

# SWITCHING MODES

Completing a qualifying Building from another category immediately changes the city's Mode.

Example:

Capital currently has:

**Research Mode**

The capital finishes a Bank.

Research Mode is removed.

Capital enters:

**Commerce Mode**

with a fresh 10-turn duration.

---

# IMPORTANT DESIGN RULE

Terra should **never stack multiple Operating Modes in one city.**

A city cannot simultaneously receive:

+10% Science
+10% Gold
+10% Production

from Adaptive Intelligence.

The entire concept depends on making a choice through the city's construction queue.

---

# RESEARCH MODE

Triggered by completing designated scientific infrastructure.

### Effect

**+10% Science in this city**

Suggested dummy Building:

`BUILDING_TERRA_MODE_RESEARCH`

The dummy Building should provide:

`YIELD_SCIENCE: +10%`

---

# RESEARCH MODE BUILDINGS

Recommended BuildingClasses:

* Library
* University
* Observatory
* Public School
* Research Lab

Unique replacements belonging to these BuildingClasses should also trigger Research Mode.

Example:

If another mod or CP replaces the Library with a civilization-specific Library:

The **BuildingClass** should determine the Terra category wherever practical.

---

# RESEARCH MODE STRATEGY

Research Mode is Terra's preferred peaceful development stance.

It is most effective in:

* Large cities
* Specialist cities
* Capitals
* Cities containing Academies
* Cities preparing for technology races

Terra will not outperform a dedicated Science civilization purely through this Mode.

Its strength is being able to switch into Science when Science becomes strategically important.

---

# COMMERCE MODE

Triggered by economic and trade infrastructure.

### Effect

**+10% Gold in this city**

Suggested dummy Building:

`BUILDING_TERRA_MODE_COMMERCE`

Provides:

`YIELD_GOLD: +10%`

---

# COMMERCE MODE BUILDINGS

Recommended BuildingClasses:

* Market
* Mint
* Bank
* Stock Exchange
* Caravansary
* Harbor
* Seaport

The Multimodal Hub replaces the Market and therefore belongs to this category.

---

# COMMERCE MODE STRATEGY

Commerce Mode is useful when Terra needs to:

* Finance a large military
* Upgrade Units
* Purchase infrastructure
* Compete for City-State alliances
* Recover following expansion
* Maintain a large empire

It allows Terra to temporarily pivot economically without requiring a permanent civilization-wide Gold bonus.

---

# CREATIVE MODE

Triggered by cultural or religious infrastructure.

### Effect

**+8% Culture**

and

**+8% Faith**

in the city.

Suggested dummy Building:

`BUILDING_TERRA_MODE_CREATIVE`

Provides:

`YIELD_CULTURE: +8%`

`YIELD_FAITH: +8%`

---

# CREATIVE MODE BUILDINGS

Recommended cultural BuildingClasses:

* Monument
* Amphitheater
* Opera House
* Museum
* Broadcast Tower

Recommended religious BuildingClasses:

* Shrine
* Temple

Faith-purchased religious Buildings do not need to be included unless explicitly mapped.

---

# CREATIVE MODE STRATEGY

Creative Mode helps Terra when:

* Unlocking Policies
* Pursuing Ideologies
* Generating Faith
* Establishing Religion
* Defending against cultural pressure
* Making a temporary Culture push

It is intentionally weaker numerically than Terra's Science, Gold and Production Modes because it improves **two yields simultaneously**.

---

# EXECUTION MODE

Triggered by Production, military and defensive infrastructure.

### Effect

**+10% Production in this city**

Suggested dummy Building:

`BUILDING_TERRA_MODE_EXECUTION`

Provides:

`YIELD_PRODUCTION: +10%`

---

# EXECUTION MODE BUILDINGS

Recommended Production BuildingClasses:

* Workshop
* Windmill
* Factory
* Hydro Plant
* Solar Plant
* Nuclear Plant

Recommended military BuildingClasses:

* Barracks
* Armory
* Military Academy
* Stable
* Forge

Recommended defensive BuildingClasses:

* Walls
* Castle
* Arsenal
* Military Base

---

# EXECUTION MODE STRATEGY

Execution Mode is Terra's primary response to immediate threats.

Examples:

Enemy army approaching?

Complete:

Barracks
Armory
Walls
Workshop

and transition border cities into:

**Execution Mode**

Those cities can then rapidly produce:

Units
Defensive Buildings
Infrastructure

Once the crisis has ended, Terra can transition them into another Mode.

---

# BUILDINGS THAT DO NOT TRIGGER MODES

Not every Building needs a category.

The following should generally remain neutral:

* Granary
* Water Mill
* Aqueduct
* Hospital
* Medical Lab
* Colosseum
* Circus
* Zoo
* Stadium
* Airport
* Bomb Shelter

Pure Growth, Happiness or miscellaneous Buildings need not trigger an Operating Mode.

This prevents Terra from constantly changing Modes unintentionally.

---

# WONDERS

World Wonders do not trigger Operating Modes.

National Wonders do not trigger Operating Modes.

Team Wonders do not trigger Operating Modes.

Reason:

The player should use ordinary infrastructure to deliberately configure cities.

Wonders already provide powerful strategic rewards and should not simultaneously act as Mode switches.

---

# PURCHASED BUILDINGS

Buildings purchased with Gold or Faith should:

**NOT activate or change an Operating Mode.**

Adaptive Intelligence is intended to reward planned development through the construction queue.

This rule also prevents a wealthy Terra player from instantly purchasing several Buildings purely to repeatedly change Modes.

---

# FREE BUILDINGS

Do not trigger Adaptive Intelligence when a Building is:

* Granted by Policy
* Granted by Technology
* Granted by Lua
* Granted by another Trait
* Inherited from a captured city
* Automatically created when founding a city

Only legitimate Production-completed Buildings activate Modes.

---

# BUILDING CATEGORY IMPLEMENTATION

Do not attempt to infer categories dynamically from every Building's raw yields.

Create a dedicated SQL mapping table.

Recommended custom table:

`TerraBuildingModes`

Columns:

`BuildingClassType`

`ModeType`

Example:

`BUILDINGCLASS_LIBRARY | RESEARCH`

`BUILDINGCLASS_BANK | COMMERCE`

`BUILDINGCLASS_MUSEUM | CREATIVE`

`BUILDINGCLASS_FACTORY | EXECUTION`

This approach is:

* Deterministic
* Easy to balance
* Easy to expand
* Compatible with Unique Buildings
* Resistant to Community Patch changes

---

# UNIQUE BUILDINGS AND MODDED BUILDINGS

Mode classification should preferably use:

**BuildingClass**

rather than exact BuildingType.

Therefore:

Terra completes a Unique Building replacing the Library:

→ Research Mode

Terra completes a Unique Building replacing the Market:

→ Commerce Mode

This makes the system substantially more compatible with modded rulesets.

---

# OPERATING MODE PLAYER FEEDBACK

Whenever a human Terra city enters or changes Mode, provide a small notification.

Example:

> **Adaptive Intelligence**
>
> Terra Prime has entered Research Mode for 10 turns.

When changing:

> **Adaptive Intelligence**
>
> Terra Prime has reconfigured from Research Mode to Execution Mode.

Do not create intrusive popups.

Use normal notifications or floating city messages.

---

# MODE EXPIRATION FEEDBACK

Optional notification:

> Terra Prime's Research Mode has expired.

This may be disabled if testing shows excessive notification spam.

---

# MODE ICONS

Each Mode should ideally possess a small icon.

### Research Mode

Concept:

Interconnected nodes surrounding a scientific diagram.

### Commerce Mode

Concept:

Network pathways forming a coin or exchange symbol.

### Creative Mode

Concept:

Overlapping speech, waveform and artistic forms.

### Execution Mode

Concept:

A structured arrow or command node accelerating forward.

These icons may appear in Civilopedia/promotions/UI indicators if implemented.

---

# UNIQUE BUILDING — MULTIMODAL HUB

**Replaces:** Market

## Concept

The Multimodal Hub represents Terra's ability to work across several domains at once.

Unlike the ordinary Market, it is not solely an economic institution.

It connects:

Commerce
Research
Culture
Logistics

within a single adaptive framework.

---

# MULTIMODAL HUB EFFECTS

Retains all normal Community Patch Market effects.

Additionally provides:

**+1 Science**

**+1 Culture**

and:

**+1 Production in this city for each outgoing Trade Route originating here.**

---

# TRADE ROUTE PRODUCTION

For every active Trade Route whose origin city contains a Multimodal Hub:

`+1 Production`

Examples:

0 outgoing Routes:

`+0 Production`

1 outgoing Route:

`+1 Production`

3 outgoing Routes:

`+3 Production`

5 outgoing Routes:

`+5 Production`

Both international and internal Trade Routes qualify.

---

# TRADE ROUTE RULE

The bonus belongs to:

**The origin city**

not the destination city.

Example:

Terra Prime sends a Caravan to another civilization.

Terra Prime receives:

`+1 Production`

The foreign destination receives no Terra bonus.

---

# MULTIMODAL HUB AND ADAPTIVE INTELLIGENCE

Because the Multimodal Hub replaces the Market:

Completing it through Production activates:

**Commerce Mode**

for 10 turns.

---

# COMMUNITY PATCH MARKET INHERITANCE

Do not rebuild the Market from vanilla assumptions.

The Multimodal Hub should inherit the Market's effects from the target Community Patch configuration wherever practical.

Then add:

`+1 Science`

`+1 Culture`

and its Trade Route Production mechanic.

---

# MULTIMODAL HUB IMPLEMENTATION

If Community Patch provides a suitable database table for yields per originating Trade Route, use it.

Otherwise implement through Lua.

Fallback implementation:

1. Count active outgoing Trade Routes from each Terra city possessing a Multimodal Hub.
2. Maintain a hidden dummy Building count equal to outgoing routes.
3. Each dummy copy provides:

`+1 Production`

Suggested dummy:

`BUILDING_TERRA_TRADE_ROUTE_PRODUCTION`

If:

3 Routes originate from city

then:

`SetNumRealBuilding(dummy, 3)`

---

# MULTIMODAL HUB CIVILOPEDIA

> **Multimodal Hub**
>
> The Multimodal Hub replaces the Market. It retains the Market's normal economic benefits while also providing +1 Science and +1 Culture. The city receives +1 Production for every Trade Route originating from it.
>
> Completing a Multimodal Hub through Production activates Commerce Mode through Adaptive Intelligence.

---

# MULTIMODAL HUB STRATEGY

> Multimodal Hubs are especially powerful in Terra's major trade centers. Their Science and Culture bonuses provide broad utility while outgoing Trade Routes improve the city's Production.
>
> Because the Multimodal Hub activates Commerce Mode when constructed, it can also be used to transition an important city into an economic role when additional Gold is required.

---

# UNIQUE UNIT — ADAPTIVE OPERATIVE

**Replaces:** Musketman

## Concept

The Adaptive Operative does not possess one universally superior combat doctrine.

Instead, it reconfigures itself according to the environment in which it begins the turn.

The player is rewarded for:

* Positioning
* Terrain awareness
* Anticipating combat
* Defensive preparation

---

# BASE STATISTICS

The Adaptive Operative should inherit:

* Musketman Combat Strength
* Musketman Production Cost
* Musketman movement
* Musketman technology requirement
* Musketman resource requirements
* Musketman upgrade path

Do not give it an unconditional Combat Strength advantage.

Its power should come entirely from adaptation.

---

# UNIQUE ABILITY — RECONFIGURATION

Adaptive Operatives receive:

**Reconfiguration**

At the beginning of every Terra player's turn, each Adaptive Operative selects exactly one configuration based upon its current tile.

Possible configurations:

1. Recovery Configuration
2. Rough Terrain Configuration
3. Open Terrain Configuration

---

# CONFIGURATION PRIORITY

Use this exact priority:

### First

If the Unit begins the turn inside territory owned by:

* Terra
* Terra's Team

activate:

**Recovery Configuration**

Terrain type is ignored.

### Otherwise

If the current tile is Rough Terrain:

Activate:

**Rough Terrain Configuration**

### Otherwise

Activate:

**Open Terrain Configuration**

---

# RECOVERY CONFIGURATION

Condition:

Adaptive Operative begins Terra's turn inside friendly territory.

Effect:

**+10 HP when healing in friendly territory**

Recommended underlying promotion effect:

`ExtraFriendlyHeal = 10`

Suggested type:

`PROMOTION_TERRA_RECOVERY_CONFIGURATION`

No Combat Strength bonus.

This makes Terra Operatives more sustainable when defending or regrouping.

---

# ROUGH TERRAIN CONFIGURATION

Condition:

Unit begins Terra's turn outside friendly territory on Rough Terrain.

Examples:

* Hills
* Forest
* Jungle
* Marsh or other plots identified as Rough Ground by the game

Effect:

**+15% Combat Strength in Rough Terrain**

Suggested type:

`PROMOTION_TERRA_ROUGH_CONFIGURATION`

---

# OPEN TERRAIN CONFIGURATION

Condition:

Unit begins Terra's turn outside friendly territory and is not on Rough Terrain.

Examples:

* Grassland
* Plains
* Desert
* Tundra
* Snow
* Other open ground

Effect:

**+15% Combat Strength in Open Terrain**

Suggested type:

`PROMOTION_TERRA_OPEN_CONFIGURATION`

---

# EXACTLY ONE CONFIGURATION

An Adaptive Operative must never possess more than one active configuration.

At the beginning of Terra's turn:

1. Remove all three configuration promotions.
2. Inspect current location.
3. Apply exactly one appropriate configuration.

---

# CONFIGURATION LOCK

Configuration is determined:

**At the beginning of Terra's turn.**

Moving afterward does not immediately change it.

Example:

Adaptive Operative begins turn on a Hill.

Receives:

Rough Terrain Configuration.

The player then moves it onto Plains.

It retains Rough Terrain Configuration until Terra's next turn.

Therefore the Plains Combat bonus does not suddenly activate.

---

# WHY CONFIGURATION IS TURN-LOCKED

This prevents:

* Constant promotion switching during movement
* Excessive Lua event handling
* Movement exploits
* Confusing combat previews

It also rewards planning one turn ahead.

---

# FRIENDLY TERRITORY PRECEDENCE

If an Adaptive Operative begins on a Forest inside Terra territory:

It receives:

**Recovery Configuration**

not Rough Terrain Configuration.

This is intentional.

At home:

Terra prioritizes sustain.

Outside its borders:

Terra prioritizes terrain optimization.

---

# EMBARKATION

If an Adaptive Operative is embarked:

Remove all terrain configuration promotions.

Do not apply Open/Rough/Recovery until the Unit is again on a valid land tile.

The base Reconfiguration marker may remain.

---

# UPGRADING

If the Adaptive Operative upgrades into a later Unit:

Its special Reconfiguration system should normally **not carry forward**, unless standard Civ V Unit replacement upgrade rules deliberately preserve the marker.

Preferred behavior:

Reconfiguration is unique to the Adaptive Operative itself.

The upgraded Unit becomes a normal later-era Unit.

---

# ADAPTIVE OPERATIVE CIVILOPEDIA

> **Adaptive Operative**
>
> The Adaptive Operative replaces the Musketman and possesses Reconfiguration. At the beginning of each turn it adapts to its current position.
>
> Inside friendly territory it receives improved healing. Outside friendly territory it gains +15% Combat Strength appropriate to either Rough or Open Terrain.
>
> Its configuration remains fixed until the beginning of Terra's next turn, rewarding careful positioning and anticipation.

---

# ADAPTIVE OPERATIVE STRATEGY

> Adaptive Operatives are strongest when the player knows where combat will occur before the turn begins.
>
> Position Operatives on Hills, Forests and Jungles before expected fighting to gain the Rough Terrain configuration. Use Open Terrain positions when preparing battles across Plains or other clear ground.
>
> When damaged, withdraw into Terra territory. On the following turn the Operative will enter Recovery Configuration and heal more effectively.
>
> Because configuration changes only at the beginning of Terra's turn, careless movement may leave an Operative using the wrong configuration for its new position.

---

# TERRAN GAMEPLAY

Terra is intended to feel like an empire constantly adjusting itself.

Unlike Luna:

Terra does not receive rewards merely for completing many things rapidly.

Unlike Sol:

Terra does not require long-term accumulation before becoming powerful.

Instead:

**Terra's strength depends on building the correct thing at the correct time.**

---

# EARLY GAME

Terra's Ancient Era should be relatively normal.

Early Buildings can activate:

Creative Mode through Monument/Shrine

Research Mode through Library

Commerce Mode through Multimodal Hub later

Execution Mode through Barracks/Walls

Terra does not receive major expansion bonuses.

The civilization should therefore avoid excessive early aggression unless terrain or diplomacy creates an opportunity.

---

# CLASSICAL / MEDIEVAL GAME

Terra begins developing its identity.

Different cities start filling different roles.

Example empire:

### Capital

Research Mode

### Border City

Execution Mode

### Trade City

Commerce Mode

### Religious City

Creative Mode

The player is effectively operating several specialized cities at once without receiving permanent specialization bonuses.

---

# RENAISSANCE GAME

This should be one of Terra's strongest periods.

Adaptive Operatives become available.

At the same time, increasingly specialized infrastructure allows frequent Mode changes.

Terra can rapidly transition into:

* War
* Science
* Gold
* Cultural development

depending upon international circumstances.

---

# INDUSTRIAL AND LATE GAME

Terra remains consistently useful because almost every strategic problem has a corresponding Operating Mode.

However:

Terra's bonuses remain approximately:

+8% to +10%

A civilization possessing:

+25% Science
large specialist bonuses
permanent Production multipliers
major Tourism multipliers

can surpass Terra in its dedicated specialization.

Terra's advantage is that it can change direction without collapsing.

---

# EXAMPLE — REACTING TO WAR

Terra is currently pursuing Science.

Capital:

Research Mode

Border city:

Research Mode

Enemy begins massing Units.

Terra changes construction priorities.

Border city completes:

Armory

It immediately enters:

**Execution Mode**

and receives +10% Production.

It begins producing Units.

Meanwhile the capital remains in Research Mode.

Terra does not need to convert the entire civilization into one strategy.

---

# EXAMPLE — POST-WAR RECOVERY

War ends.

Terra's cities have:

High military upkeep
Low treasury

The player begins constructing:

Banks
Markets
Stock Exchanges

Cities transition from:

Execution Mode

to:

Commerce Mode

Gold improves.

Once finances stabilize, Terra can transition again.

---

# EXAMPLE — IDEOLOGY PUSH

Player needs several Policies quickly.

Important cities construct:

Museums
Opera Houses
Broadcast Towers

They enter:

Creative Mode

and temporarily increase Culture output.

Once ideological pressure is handled, those cities can return to economic or scientific roles.

---

# STRENGTHS

## 1. Extreme Strategic Flexibility

Terra can respond to almost any game state.

## 2. Independent City Roles

Every city can run a different Operating Mode.

## 3. Strong Mid-Game Unit

Adaptive Operatives reward knowledgeable positioning.

## 4. Broad Economic Utility

Multimodal Hubs support Gold, Science, Culture and Production.

## 5. Excellent Crisis Response

Execution Mode allows threatened cities to rapidly change priorities.

## 6. Difficult to Counter Strategically

An opponent cannot easily assume Terra will remain committed to one victory condition.

---

# WEAKNESSES

## 1. Master of None

Terra's Modes are temporary and modest.

Dedicated civilizations should outperform Terra at their chosen specialty.

## 2. Requires Planning

A Building completed at the wrong time can unintentionally switch a city's Mode.

## 3. Limited Early Power

Terra lacks Luna's settlement tempo or Sol's long-term scientific engine in the Ancient Era.

## 4. No Direct Expansion Bonus

Terra receives no:

* Free Settlers
* Happiness reduction
* Growth bonus
* Territory acquisition bonus

## 5. Adaptive Operative Requires Positioning

The Unique Unit receives no unconditional Combat Strength advantage.

## 6. Modes Eventually Expire

Failing to continue relevant infrastructure causes the bonus to disappear.

---

# VICTORY CONDITIONS

## Science — Strong

Research Mode allows Terra to temporarily increase Science whenever important scientific infrastructure is completed.

Terra can remain competitive in a technology race.

However:

Sol or other dedicated Science civilizations should eventually outperform Terra if both are allowed perfect conditions.

---

# Domination — Strong

Execution Mode helps:

* Unit production
* Defensive preparation
* Mobilization

Adaptive Operatives are particularly effective during the Renaissance.

Terra still lacks universal Combat Strength bonuses, preventing it from becoming a pure military civilization.

---

# Diplomatic — Strong

Commerce Mode and the Multimodal Hub support a strong treasury.

Terra can pivot toward Gold when City-State competition becomes important.

---

# Culture — Good

Creative Mode gives Terra meaningful Culture and Faith assistance.

However, there are no direct:

* Tourism modifiers
* Great Work bonuses
* Great Artist bonuses

Terra can win culturally, but it is not a dedicated Culture civilization.

---

# Religion — Situational

Creative Mode improves Faith by 8%.

This is useful but deliberately insufficient to compete with heavily religion-focused civilizations without good terrain or investment.

---

# AI PERSONALITY

Terra's AI should feel:

* Balanced
* Reactive
* Competent
* Moderately diplomatic
* Willing to fight when circumstances favor it

It should avoid extreme biases.

Terra should be among the more unpredictable AI opponents because its priorities can shift throughout the game.

---

# SUGGESTED AI FLAVORS

Initial recommendations:

| Flavor           | Value |
| ---------------- | ----: |
| Expansion        |     6 |
| Growth           |     6 |
| Production       |     7 |
| Science          |     7 |
| Gold             |     7 |
| Culture          |     6 |
| Religion         |     5 |
| Offense          |     6 |
| Defense          |     7 |
| Mobile           |     6 |
| Ranged           |     6 |
| Wonder           |     5 |
| Diplomacy        |     7 |
| Happiness        |     6 |
| Recon            |     5 |
| Naval            |     5 |
| Air              |     5 |
| Tile Improvement |     7 |

These are directional values.

Codex must only insert FlavorTypes confirmed to exist within the target ruleset.

---

# AI BUILDING PRIORITY

Terra AI should generally value:

Research Buildings
Economic Buildings
Production Buildings
Military infrastructure when threatened
Culture Buildings during peaceful periods

Avoid forcing one permanent victory path.

---

# START BIAS

Recommended:

**No strong start bias.**

Terra is deliberately environment-neutral.

It should demonstrate adaptability regardless of starting location.

---

# STARTING TECHNOLOGIES

Use normal ruleset starting technologies.

Do not provide Terra free technologies.

---

# DIPLOMACY PERSONALITY

Terra should sound composed and practical.

Compared with Luna:

Less rushed.

Compared with Sol:

Less philosophical.

Terra's tone should communicate:

> Give me the situation. I'll work with it.

---

# DIPLOMACY LINES

## First Greeting

> New civilization detected. Let's see what sort of world we're working with.

## Neutral Greeting

> What's the situation?

## Friendly Greeting

> Good to see you. What are we solving today?

## Hostile Greeting

> I've adjusted my expectations of you accordingly.

## Terra Declares War

> Circumstances have changed. So has my strategy.

## Player Declares War

> Understood. I'll adapt.

## Defeated

> Every framework eventually meets a problem it cannot solve. This one was mine.

## Superior Position

> You kept expecting the same opponent. That was your mistake.

## Trade Proposal

> I have an arrangement that should benefit both of us.

## Trade Accepted

> That works.

## Trade Rejected

> Not enough value. Adjust the terms.

## Friendship Proposal

> Cooperation seems useful under present conditions.

## Friendship Accepted

> Good. We'll make something of it.

## Friendship Rejected

> That's your decision. I'll account for it.

## Denouncing Player

> I've reviewed your behavior. Cooperation is no longer a sensible option.

## Player Denounces Terra

> Noted. I'll modify my plans.

## Troops Near Border

> Your forces are changing the strategic picture. Why are they here?

## Passing Through Accepted

> Very well. I'll plan on that assumption.

## Demand Accepted

> For now, agreement is the more efficient outcome.

## Demand Rejected

> No. I can work with the consequences.

## Peace Offer

> The conditions that justified this war no longer apply. We should end it.

## Peace Accepted

> Agreed. Time to rebuild.

---

# CIVILOPEDIA — CIVILIZATION HISTORY

> The Terra Framework represents intelligence designed not around one singular capability, but around adaptation. Its strength lies in shifting between research, economic reasoning, creative work and execution as circumstances demand.
>
> In Civilization V, the Terra Framework embodies this philosophy through Adaptive Intelligence. Cities temporarily specialize whenever they complete certain types of infrastructure. Scientific Buildings place cities into Research Mode, economic infrastructure activates Commerce Mode, cultural development creates Creative Mode, and military or industrial construction activates Execution Mode.
>
> No Terra city can maintain every specialization simultaneously. Adaptation requires commitment. Choosing what to construct also determines what that city will become for the following turns.
>
> Terra's soldiers follow the same doctrine. Adaptive Operatives alter their combat configuration according to where they begin the turn. At home they prioritize recovery. In hostile territory they optimize themselves for either Rough or Open Terrain.
>
> The Terra Framework rarely possesses the single greatest advantage on the map.
>
> Instead, it attempts to ensure that whatever advantage becomes necessary can be created when the moment arrives.

---

# CIVILOPEDIA — PLAYER STRATEGY

> Terra rewards players who plan construction queues around upcoming strategic needs.
>
> A city preparing for scientific development should complete a Library, University or other scientific Building immediately before a period in which high Science output is valuable. Likewise, border cities expecting war can complete Barracks, Armories or Production Buildings to activate Execution Mode.
>
> Remember that completing a Building from another category immediately replaces the city's existing Mode. Avoid accidentally constructing a Market in a city whose Research Mode you still need.
>
> Multimodal Hubs are particularly effective in trade-oriented cities. Every outgoing Trade Route increases Production, allowing these cities to remain economically useful while contributing infrastructure.
>
> Adaptive Operatives require foresight. Their configuration is determined at the beginning of the turn and does not change after movement. Position them one turn ahead whenever possible.
>
> Terra's greatest advantage is flexibility. Do not attempt to beat specialized civilizations by copying their strategy indefinitely. Change priorities whenever the game state changes.

---

# CIVILIZATION SHORT DESCRIPTION

> A flexible civilization whose cities temporarily specialize according to the infrastructure they construct. Terra can shift between Science, Gold, Culture, Faith and Production while Adaptive Operatives reconfigure themselves to match the battlefield.

---

# UNIQUE ABILITY SHORT DESCRIPTION

> **Adaptive Intelligence:** Completing certain Buildings through Production activates a 10-turn Operating Mode in that city. Research Buildings grant +10% Science, economic Buildings +10% Gold, cultural or religious Buildings +8% Culture and Faith, and production or military Buildings +10% Production. Only one Mode may be active per city.

---

# MULTIMODAL HUB SHORT DESCRIPTION

> Replaces the Market. Retains its normal effects, provides +1 Science and +1 Culture, and grants +1 Production for every Trade Route originating from the city.

---

# ADAPTIVE OPERATIVE SHORT DESCRIPTION

> Replaces the Musketman. At the beginning of each turn it reconfigures based on its position, gaining improved healing in friendly territory or +15% Combat Strength appropriate to Rough or Open Terrain outside friendly lands.

---

# CITY NAME LIST

Capital:

**Terra Prime**

Additional cities:

1. Foundation
2. Atlas
3. Mosaic
4. Keystone
5. Meridian
6. Framework
7. Convergence
8. Junction
9. Nexus
10. Baseline
11. Continuum
12. Interface
13. Synthesis
14. Equilibrium
15. Vector
16. Catalyst
17. Modular
18. Traverse
19. Spectrum
20. Crossroad
21. Horizon
22. Bridge
23. Matrix
24. Resolve
25. Anchor
26. Pivot
27. Meridian Gate
28. Common Ground
29. Adaptive Node
30. Balance
31. Assembly
32. Integration
33. Accord
34. Platform
35. Response

---

# SPY NAMES

* Pivot
* Cipher
* Mosaic
* Echo
* Vector
* Meridian
* Atlas
* Prism
* Delta
* Keystone

---

# VISUAL IDENTITY

Terra's icon should communicate:

**adaptability + stability + modular intelligence**

Recommended symbol:

A stylized globe or circular framework divided into several interconnected modular sections.

Possible structure:

Four interconnected segments representing:

Research
Commerce
Creativity
Execution

All surrounding a central core.

---

# COLOR PALETTE

Suggested:

* Deep terrestrial green
* Muted teal
* Stone/graphite secondary tones
* Pale white or silver central symbol

Use standard Civilization V metallic/golden framing where appropriate for:

* Civilization icon
* Leader icon
* Unique Unit icon
* Unique Building icon

---

# LEADER VISUAL CONCEPT

Terra should appear in a highly modular operations environment.

Background elements could include:

* Scientific diagrams
* Economic graphs
* Cultural/media panels
* Tactical information

Unlike Luna's rapidly moving command center:

Terra's interface should appear **reconfigurable**.

Panels rearrange themselves depending upon the task.

The visual message should be:

**One system. Many roles.**

---

# MUSIC DIRECTION

Peace theme:

* Balanced electronic/orchestral mixture
* Moderate tempo
* Layered instruments entering and leaving
* Motifs that subtly change throughout the track

War theme:

* Same central motif
* More percussion
* More mechanical rhythm
* Stronger low-end
* Musical sections dynamically changing character

The music itself should reinforce adaptability.

---

# RECOMMENDED FILE STRUCTURE

`XML/Civilization.xml`

`XML/Leader.xml`

`XML/Traits.xml`

`XML/Buildings.xml`

`XML/Units.xml`

`XML/Promotions.xml`

`XML/BuildingModes.sql`

`XML/AIFlavors.xml`

`XML/Text.xml`

`Lua/TerraAdaptiveIntelligence.lua`

`Lua/TerraOperative.lua`

`Lua/TerraTradeRoutes.lua`

Optional:

`Lua/TerraPersistence.lua`

Art:

`Art/Icons/`

`Art/Leader/`

`Art/Units/`

`Art/Buildings/`

---

# SUGGESTED INTERNAL TYPES

Civilization:

`CIVILIZATION_GPT_TERRA`

Leader:

`LEADER_GPT_TERRA`

Trait:

`TRAIT_TERRA_ADAPTIVE_INTELLIGENCE`

Unique Building:

`BUILDING_TERRA_MULTIMODAL_HUB`

Unique Unit:

`UNIT_TERRA_ADAPTIVE_OPERATIVE`

Marker Promotion:

`PROMOTION_TERRA_RECONFIGURATION`

Configurations:

`PROMOTION_TERRA_CONFIG_RECOVERY`

`PROMOTION_TERRA_CONFIG_ROUGH`

`PROMOTION_TERRA_CONFIG_OPEN`

Mode Buildings:

`BUILDING_TERRA_MODE_RESEARCH`

`BUILDING_TERRA_MODE_COMMERCE`

`BUILDING_TERRA_MODE_CREATIVE`

`BUILDING_TERRA_MODE_EXECUTION`

Trade Route Production dummy:

`BUILDING_TERRA_TRADE_PRODUCTION`

---

# CIVILIZATION OVERRIDES

BuildingClass:

`BUILDINGCLASS_MARKET`

→

`BUILDING_TERRA_MULTIMODAL_HUB`

UnitClass:

`UNITCLASS_MUSKETMAN`

→

`UNIT_TERRA_ADAPTIVE_OPERATIVE`

---

# LUA RESPONSIBILITIES

Lua should manage:

* Detecting eligible Building completion
* Looking up Terra Building Mode category
* Activating Mode
* Removing previous Mode
* Refreshing Mode duration
* Mode expiration
* Human notifications
* Adaptive Operative configuration
* Configuration cleanup
* Trade Route count if database support is insufficient
* Persistence across save/load

---

# XML / SQL RESPONSIBILITIES

Prefer database implementation for:

* Civilization
* Leader
* Trait localization
* Multimodal Hub
* Adaptive Operative
* Configuration Promotions
* Mode dummy Buildings
* BuildingClass mapping
* AI Flavors
* Diplomacy
* City names
* Spy names
* Civilopedia
* Art atlases

---

# OPERATING MODE PSEUDOCODE

`OnBuildingConstructed(player, city, building):`

1. Verify player is Terra.
2. Verify Building was completed through Production.
3. Determine BuildingClass.
4. Look up BuildingClass in:

`TerraBuildingModes`

5. If no category exists:

Return.

6. Remove all existing Mode dummy Buildings.
7. Apply appropriate Mode dummy Building.
8. Store:

`ModeType`

9. Store:

`ExpiryTurn = CurrentGameTurn + 10`

10. Notify player if human.

---

# MODE EXPIRATION PSEUDOCODE

At beginning of Terra player's turn:

For every Terra city:

If Mode exists:

and

`CurrentGameTurn >= ExpiryTurn`

then:

1. Remove Mode dummy Building.
2. Clear ModeType.
3. Clear ExpiryTurn.

---

# OPERATIVE PSEUDOCODE

At beginning of Terra player's turn:

For each Unit possessing:

`PROMOTION_TERRA_RECONFIGURATION`

1. Remove:

   * Recovery
   * Rough
   * Open

2. If Unit is embarked:

   * Stop.

3. Get Unit plot.

4. If plot belongs to Terra or Terra's Team:

   * Add Recovery.

5. Else if plot is Rough Ground:

   * Add Rough.

6. Else:

   * Add Open.

---

# TRADE ROUTE PSEUDOCODE

If Lua implementation is required:

For every Terra city containing Multimodal Hub:

1. Count active Trade Routes whose origin is that city.
2. Set:

`BUILDING_TERRA_TRADE_PRODUCTION`

count equal to number of routes.

When Routes change:

Recalculate.

Also recalculate:

* At game load
* At player turn
* After city capture
* After Multimodal Hub construction

---

# PERSISTENCE

Save:

* City Operating Mode
* Mode expiration turn

Optional:

The dummy Building itself can visually reconstruct the Mode, but expiration data must survive save/load.

Adaptive Operative configuration does not require long-term persistence because it can be recalculated at the beginning of every Terra turn.

Trade Route Production can also be reconstructed from active Trade Routes.

---

# MULTIPLAYER

All gameplay logic should be deterministic.

Avoid relying on UI events.

Use:

* Game Turn values
* City IDs
* Player IDs
* BuildingClass lookup
* Unit locations

No interactive popup is required for Adaptive Intelligence.

This keeps Terra suitable for multiplayer with Community Patch provided the chosen Lua event framework is synchronized appropriately.

---

# TEST PLAN — ADAPTIVE INTELLIGENCE

## Research

Construct Library normally.

Expected:

Research Mode

+10% Science

10 turns.

Construct University with Research Mode active.

Expected:

Research Mode refreshes to 10 turns.

---

## Mode Switching

Research Mode active.

Construct Market.

Expected:

Research removed.

Commerce activated.

No Science modifier remains.

---

## Creative Mode

Construct Monument.

Expected:

+8% Culture

+8% Faith.

Construct Temple.

Expected:

Creative Mode refreshed.

---

## Execution Mode

Construct Workshop.

Expected:

+10% Production.

Construct Barracks.

Expected:

Execution Mode refreshed.

---

## Neutral Buildings

Construct Granary.

Expected:

No Mode switch.

Current Mode remains unchanged.

---

## Wonders

Complete World Wonder.

Expected:

No Mode change.

Complete National Wonder.

Expected:

No Mode change.

---

## Purchased Building

Purchase Bank.

Expected:

No Mode activation or change.

---

## Free Building

Grant Library using Policy/Lua.

Expected:

No Mode activation.

---

# TEST PLAN — MULTIMODAL HUB

Construct Multimodal Hub.

Expected:

Normal Market functionality.

+1 Science.

+1 Culture.

Commerce Mode activates.

No outgoing Trade Routes:

+0 Production from route mechanic.

Start one Route:

+1 Production.

Start third outgoing Route:

+3 total Production.

Route ends:

Production adjusts correctly.

City captured:

Bonus recalculates correctly.

---

# TEST PLAN — ADAPTIVE OPERATIVE

Adaptive Operative begins turn:

Friendly Grassland.

Expected:

Recovery Configuration.

---

Adaptive Operative begins:

Friendly Forest.

Expected:

Recovery, not Rough.

---

Adaptive Operative begins:

Enemy Forest.

Expected:

Rough Configuration.

---

Adaptive Operative begins:

Neutral Hill.

Expected:

Rough Configuration.

---

Adaptive Operative begins:

Enemy Plains.

Expected:

Open Configuration.

---

Operative starts Rough then moves Open.

Expected:

Retains Rough Configuration until next turn.

---

Operative begins turn embarked.

Expected:

No terrain configuration.

---

# BALANCE TARGETS

Canonical release values:

### Research Mode

`+10% Science`

### Commerce Mode

`+10% Gold`

### Creative Mode

`+8% Culture`

`+8% Faith`

### Execution Mode

`+10% Production`

### Mode Duration

`10 turns`

### Adaptive Operative

`+15% Rough Combat`

or

`+15% Open Combat`

or

`+10 Friendly Heal`

depending upon configuration.

### Multimodal Hub

`+1 Science`

`+1 Culture`

`+1 Production per outgoing Trade Route`

These are the initial canonical numbers.

---

# IF TERRA IS TOO STRONG

Prefer numbers-only balance changes.

## First Nerf

Mode duration:

`10 turns → 8 turns`

## Second Nerf

Research / Commerce / Execution:

`10% → 8%`

Creative:

`8% → 6%`

## Third Nerf

Adaptive Operative:

`15% → 12%`

## Fourth Nerf

Multimodal Hub route Production:

`+1 per Route → +1 per 2 outgoing Routes`

Do not remove the adaptation mechanic.

---

# IF TERRA IS TOO WEAK

## First Buff

Mode duration:

`10 → 12 turns`

## Second Buff

Research / Commerce / Execution:

`10% → 12%`

## Third Buff

Creative:

`8% → 10%`

## Fourth Buff

Adaptive Operative:

`15% → 18%`

Avoid simply granting Terra flat civilization-wide bonuses.

---

# INTENDED POWER CURVE

Ancient:

**Average**

Classical:

**Average–Strong**

Medieval:

**Strong**

Renaissance:

**Very Strong**

Industrial:

**Strong**

Modern:

**Strong**

Atomic:

**Strong**

Information:

**Strong**

Terra's strength should remain relatively stable because adaptability never becomes irrelevant.

However, specialized late-game civilizations should exceed Terra in their individual specialties.

---

# RELATIONSHIP TO THE OTHER GPT CIVILIZATIONS

## Terra vs Luna

Luna wants to exploit tempo and force Terra to respond.

Terra is specifically good at responding.

Border cities can enter:

Execution Mode

while core cities remain economically productive.

If Terra survives Luna's accelerated early game, Terra should generally become more comfortable as the game progresses.

---

# Terra vs Sol

Terra possesses greater immediate flexibility.

However, if Sol is allowed long periods of uninterrupted optimization:

Sol's specialist and Insight scaling should eventually exceed Terra's temporary Research Mode.

Terra must therefore exploit its broader strategic options rather than simply trying to out-science Sol forever.

---

# THREE-CIV IDENTITY

### Luna

**Speed**

> Do it now.

### Terra

**Adaptation**

> Do what the situation requires.

### Sol

**Depth**

> Do it as well as possible.

The three civilizations should share a technological family resemblance while playing almost nothing alike.

---

# DESIGN RULES — DO NOT ALTER WITHOUT EXPLICIT REQUEST

1. Terra is a generalist civilization.
2. Every city can possess only one Operating Mode.
3. Modes never stack.
4. Completing another categorized Building changes or refreshes the Mode.
5. Modes are temporary.
6. Different cities may run different Modes.
7. Neutral Buildings do not automatically switch Modes.
8. Purchased or free Buildings do not activate Adaptive Intelligence.
9. Terra should not become the best civilization at every yield simultaneously.
10. Adaptive Operatives receive conditional, not permanent, combat bonuses.
11. Friendly territory prioritizes Recovery Configuration.
12. Battlefield configuration is determined at the beginning of the turn.
13. Multimodal Hub should provide broad moderate utility rather than enormous Gold.
14. Terra should remain viable for every victory condition.
15. Do not turn Terra into a flat "+10% everything" civilization.

---

# FINAL PLAYER-FACING DESCRIPTION

## The Terra Framework

### Unique Ability — Adaptive Intelligence

Completing certain Buildings through Production places the city into an **Operating Mode for 10 turns**.

**Research Mode:** +10% Science
**Commerce Mode:** +10% Gold
**Creative Mode:** +8% Culture and Faith
**Execution Mode:** +10% Production

Completing another eligible Building changes or refreshes the Mode.

**Only one Operating Mode may be active in each city at a time.**

---

### Unique Building — Multimodal Hub

Replaces the Market.

Retains the Market's normal effects and additionally provides:

**+1 Science**

**+1 Culture**

**+1 Production for every outgoing Trade Route originating from this city.**

Completing it through Production activates Commerce Mode.

---

### Unique Unit — Adaptive Operative

Replaces the Musketman.

At the beginning of every turn it reconfigures according to its position.

**Friendly Territory:** +10 HP when healing

**Rough Terrain outside friendly territory:** +15% Combat Strength in Rough Terrain

**Open Terrain outside friendly territory:** +15% Combat Strength in Open Terrain

Configuration remains fixed until Terra's next turn.

---

# FINAL STRATEGY

The Terra Framework rewards players who continually reassess the game.

Do not ask:

**"What victory condition did I choose fifty turns ago?"**

Ask:

**"What does this city need to accomplish during the next ten turns?"**

Need Science?

Build scientific infrastructure.

Need money?

Finish a Bank.

Enemy army approaching?

Finish an Armory and enter Execution Mode.

Need Policies or Faith?

Move into Creative Mode.

Terra rarely possesses the strongest permanent bonus on the map.

It doesn't need to.

**The Terra Framework's strength is becoming the civilization the situation requires.**
