You are implementing a highly ambitious Civilization V: Brave New World custom civilization called:

THE KINGDOMS

This mod is designed for Civ V BNW using the Community Patch / Vox Populi-compatible Lua API. Assume Community Patch v151-style hooks/events are available.

IMPORTANT DEVELOPMENT RULES
===========================

1. Use pure mod files only:
   - XML
   - SQL where useful
   - Lua
   - Civ V UI XML/Lua
   - DDS/audio assets as required
   - .modinfo
   - NO requirement for ModBuddy-specific project files.

2. Do NOT simplify or remove the requested mechanics simply because they are ambitious.
   If something cannot safely be represented literally in Civ V, simulate it faithfully.

3. Keep systems modular.
   Do not build one giant Lua file.

4. Avoid expensive polling.
   ABSOLUTELY DO NOT use UI checks every 0.1 seconds.
   Use game events, turn events, dirty events and explicit UI refresh calls.

5. Everything important must persist through saves and reloads.

6. Assume single-player is the priority.
   AI support is desirable and should be implemented where reasonable.

7. Do not change unrelated files/civilizations in the repository.

8. Add detailed Lua logging behind a DEBUG flag.

9. Fail gracefully if optional Community Patch events are unavailable.

10. Do not create a literal new civilization/player for each House or Civil War faction.
    Civil Wars should be simulated internally within The Kingdoms to avoid Civ V player-slot/save instability.

==================================================
CIVILIZATION
==================================================

Civilization:
The Kingdoms

Capital:
Kings Throne

Unique Ability:
The Kingdoms United

Leader:
There should NOT be a permanent named leader.

Because Civ V technically requires a LeaderType, create an internal placeholder:

LEADER_THE_THRONE

Visible identity:
"The Throne"

The player does NOT conceptually play as one King.
The player represents The Kingdoms as a civilization.

Actual rulers are dynamically generated through the custom House/Succession system.

The custom Kingdoms UI should prominently display the CURRENT RULER instead of presenting the placeholder leader as the civilization's true ruler.

Use an appropriate generic medieval diplomacy setup for the placeholder leader.

==================================================
CORE DESIGN PHILOSOPHY
==================================================

The Kingdoms should feel like:

Civilization V +
a lightweight Crusader Kings / Game of Thrones-inspired political simulator.

Every City is considered a KINGDOM.

Every Kingdom contains several competing noble HOUSES.

Houses:
- have personalities
- have loyalty
- have prestige
- have influence
- issue demands/quests
- form alliances and rivalries
- produce notable characters
- can split into new Houses
- can support claimants during succession
- can contribute candidates to the King's Guard
- can eventually become the ruling House

The civilization can become extremely powerful through prosperous Kingdoms and powerful Houses, but success creates increasing political complexity.

Population and expansion should therefore be both a strength and a danger.

==================================================
SYSTEM ARCHITECTURE
==================================================

Please create modular Lua systems along these lines:

Lua/KingdomsCore.lua
Lua/KingdomManager.lua
Lua/HouseManager.lua
Lua/CharacterManager.lua
Lua/DemandManager.lua
Lua/RulerManager.lua
Lua/SuccessionManager.lua
Lua/CivilWarManager.lua
Lua/KingsGuardManager.lua
Lua/HistoryManager.lua
Lua/KingdomsPersistence.lua
Lua/KingdomsEvents.lua
Lua/KingdomsAI.lua
Lua/KingdomsDebug.lua

UI/KingdomsOverview.lua
UI/KingdomsOverview.xml

Optional sub-panels:
UI/KingdomDetails.lua
UI/HouseDetails.lua
UI/SuccessionPanel.lua
UI/ChroniclePanel.lua
UI/KingsGuardSelection.lua

Exact file structure may be adjusted if there is a better Civ V architecture, but preserve modularity.

==================================================
PERSISTENCE
==================================================

All generated political data must survive save/load.

Persist things including:

- Kingdom data
- Houses
- House IDs
- House names
- House founders
- House parent/split lineage
- House Kingdom of origin
- House traits
- Loyalty
- Influence
- Prestige
- relationships
- current demands
- demand cooldowns
- completed demands
- House historical statistics
- rulers
- current ruler
- ruler traits
- ruler reign start
- previous rulers
- succession claims
- Civil War state
- Civil War factions
- faction strength
- King's Guard characters
- King's Guard House affiliation
- King's Guard traits
- history/chronicle entries
- generated character IDs
- generated House IDs

Use reliable persistent Civ V storage.

Never rely purely on Lua global variables.

==================================================
KINGDOM SYSTEM
==================================================

Every city belonging to The Kingdoms is a Kingdom.

When a city is:

- founded
- annexed
- puppeted
- acquired peacefully
- conquered

initialize it as a Kingdom if it does not already have Kingdom data.

Store:

KingdomID
CityPlotIndex or safe persistent city identifier
KingdomName
FoundingTurn
OriginalOwner
CurrentOwner
House list
Kingdom Stability
historical information

If the city changes ownership away from The Kingdoms:
preserve its historical data safely in case it is later recaptured, but disable active House processing while foreign-owned.

==================================================
HOUSES PER KINGDOM
==================================================

Population determines approximately how many politically important Houses are present.

Use this initial target model:

Population 1-3:
2 Houses

Population 4-6:
3 Houses

Population 7-9:
4 Houses

Population 10-13:
5 Houses

Population 14-18:
6 Houses

Population 19+:
7 Houses

This represents MAJOR political Houses, not every family.

Do NOT instantly spawn multiple Houses because population jumps several values in one turn.

Instead:
queue House formation events and space them out.

New Kingdoms should generally begin with 2 Houses.

House creation should feel organic.

==================================================
HOUSE CREATION
==================================================

Houses can originate in two primary ways:

1. NEW HOUSE RISES

Example event:

"A New House Rises

A wealthy and influential family has emerged within Stormwatch.

House Edran has been founded."

2. HOUSE SCHISM

Example:

"A House Divided

Disagreements within House Valen have become irreconcilable.

A branch of the family has broken away.

House Valencrest has been founded."

A split House should inherit some:
- prestige
- influence
- relationships
- historical connection
from its parent.

Store lineage:

ParentHouseID
FounderCharacterID
FoundedTurn
OriginKingdomID

House splitting should not occur excessively.

Use cooldowns and sensible limits.

==================================================
HOUSE NAMES
==================================================

Create a large fantasy House-name pool.

Examples only:

Valen
Torr
Marr
Edran
Corren
Aren
Vey
Ardyn
Dorran
Cael
Thorne
Roth
Halren
Morwyn
Valecrest
Storme
Darion
Cressen
Renwick
Aldren

Also support procedural variants for split Houses:

Valencrest
Valenmere
Valenhold
Valenford
Valenwatch

Avoid duplicate active House names.

==================================================
HOUSE STATS
==================================================

Each House needs at least:

HouseID
Name
KingdomID
ParentHouseID
Founder
CurrentHead
FoundedTurn

Loyalty
Prestige
Influence
Claim
Power

Two House personality traits

Relationships with other important Houses

CurrentDemand
DemandExpiry
DemandCooldown

Historical:
RulersProduced
KingsGuardsProduced
WarsSupported
DemandsCompleted
DemandsFailed

==================================================
HOUSE LOYALTY
==================================================

Use a range roughly:

-100 to +100

Suggested states:

80 to 100:
Devoted

50 to 79:
Loyal

20 to 49:
Supportive

-19 to 19:
Neutral

-49 to -20:
Discontent

-79 to -50:
Hostile

-100 to -80:
Rebellious

Clamp appropriately.

==================================================
HOUSE PRESTIGE
==================================================

Prestige represents historical status.

Gain Prestige from things such as:

- producing a ruler
- producing a King's Guard
- fulfilling major House ambitions
- successful wars
- House age
- political victories
- winning Civil Wars
- having allied claimants succeed

Prestige should decay VERY slowly if at all.

Prestige should create long-term historical Houses.

==================================================
HOUSE INFLUENCE
==================================================

Influence represents power within its Kingdom.

Influence affects:

- Kingdom Stability weighting
- Throne claims
- political events
- faction leadership
- impact of House happiness/anger

Influence between all Houses in one Kingdom should approximately normalize to 100%.

Do not make exact normalization mandatory every operation if that complicates calculations, but UI percentages should be normalized.

Population growth, wealth, completed objectives and political events can shift Influence.

==================================================
HOUSE PERSONALITIES
==================================================

Each House receives TWO persistent traits.

Create a substantial pool including:

Militaristic
Agrarian
Mercantile
Expansionist
Isolationist
Traditionalist
Religious
Scholarly
Ambitious
Loyalist
Opportunistic
Proud
Defensive
Maritime
Industrial
Diplomatic
Populist
Zealous
Cautious
Honourable

Traits affect:
- preferred demands
- Loyalty reactions
- alliance behaviour
- succession behaviour
- House passive bonuses/debuffs

Create a data-driven trait table instead of huge hardcoded if/elseif chains.

==================================================
HOUSE PASSIVE EFFECTS
==================================================

Every House should provide some small effect while politically relevant.

The effect may scale based on:
- House Loyalty
- Influence
- whether it is the ruling House

Examples:

Agrarian:
Food-related bonus

Militaristic:
unit Production or military XP

Mercantile:
Gold

Scholarly:
Science

Traditionalist:
Stability

Industrial:
Production

Religious:
Faith

These MUST remain modest per House because there can be many Houses.

Hostile Houses may invert or weaken part of their benefit.

The ruling House gets an enhanced version.

==================================================
HOUSE DEMANDS / QUESTS
==================================================

Houses occasionally issue political demands.

IMPORTANT:
Do NOT spam these.

Use:
- per-House cooldown
- global demand limits
- random delay
- only a limited number simultaneously active

Target Standard speed:
roughly 15-25 turns between possible demands from the same House.

Scale with GameSpeed.

Potential demand categories:

INFRASTRUCTURE
- Build 2 Farms in this Kingdom
- Build a Mine
- Improve a strategic resource
- Construct Barracks
- Construct Market
- Construct Library
- Construct religious building
- Build Walls / Kingdom's Wall

POPULATION
- Reach population X
- Grow Kingdom by X population

MILITARY
- Destroy a Barbarian Camp
- Kill X Barbarians
- Kill X enemy units
- Create X military units
- Station X units near this Kingdom

WAR
- Declare war on a chosen rival
- Capture an enemy city
- Remain at war for X turns
- Make peace after conditions are met

ECONOMY
- Accumulate Gold
- Establish Trade Route
- Reach X GPT

SCIENCE
- Research a technology
- Construct science building

CULTURE / FAITH
- generate a Great Person
- construct cultural/religious building
- accumulate Faith

EXPANSION
- found/acquire another Kingdom

Demands should depend strongly on House personality.

Do not issue impossible demands.

Verify valid targets before creating the demand.

==================================================
DEMAND INTERACTION
==================================================

Completing a demand:
+Loyalty
+Prestige
possibly +Influence
possibly +Kingdom Stability

Ignoring/expiring:
moderate Loyalty penalty

Explicitly refusing:
larger Loyalty penalty

Allow player appeasement options from House UI.

Examples:

TREASURY GIFT
Pay Gold
Gain Loyalty

GRANT ESTATES
Large Loyalty increase
temporary local Production penalty
House Influence increases

ROYAL CHARTER
Loyalty increase
House Prestige/Influence increase

MILITARY AUTHORITY
Militaristic House gains large Loyalty
House Claim and Influence increase

These should create tradeoffs.

Never make appeasement pure upside.

==================================================
KINGDOM STABILITY
==================================================

Each Kingdom has its own Stability.

Calculate Stability primarily from House Loyalty weighted by Influence.

Suggested range:
0-100

100 does not need to be easily reachable.

Suggested labels:

80-100:
United

60-79:
Stable

40-59:
Uneasy

20-39:
Fractured

0-19:
Rebellious

Factors:
- House Loyalty
- House rivalries
- recent demands
- ruler legitimacy
- local buildings
- occupation
- war weariness-style conditions
- Civil War
- Kingdom's Wall

==================================================
REALM STABILITY
==================================================

The civilization also has Realm Stability.

This should derive from:

- Kingdom Stability
- population weighting
- number of hostile Houses
- ruler legitimacy
- succession state
- wars
- House factionalism
- recent political events

Suggested states:

80-100:
UNITED

60-79:
STABLE

40-59:
UNEASY

20-39:
FRACTURED

0-19:
SUCCESSION CRISIS

Show this prominently in the custom UI.

Example:

REALM STABILITY: 37
FRACTURED

11 Loyal Houses
7 Neutral Houses
8 Hostile Houses

==================================================
THE THRONE
==================================================

There is always a current ruler unless in an active interregnum/succession resolution.

Generate rulers dynamically.

A ruler has:

CharacterID
Name
HouseID
Gender if used
Title
ReignStartTurn
Age or abstract reign-age system
Traits
Legitimacy
Historical stats

Examples:

King Aldric III of House Valen

Queen Mira I of House Torr

==================================================
RULER TRAITS
==================================================

Each ruler should receive 1-2 personal traits.

Examples:

The Conqueror
Architect
Scholar
Diplomat
Steward
Warrior
Pious
Popular

Negative/mixed:

Arrogant
Cruel
Indecisive
Greedy
Paranoid
Reckless
Weak
Unpopular

Implement effects data-driven.

Example:

Architect:
+10% building Production

Arrogant:
greater Loyalty penalty when refusing demands

Conqueror:
military benefits, but peace-oriented Houses lose Loyalty

Scholar:
Science benefit

Steward:
Gold/Production benefit

==================================================
RULER LIFETIME / SUCCESSION
==================================================

Rulers should NOT live forever.

Do not require literal historical age accuracy.

Use a game-speed-scaled reign duration system with randomized ruler lifespan.

A ruler may eventually die naturally.

Possible event:

THE KING IS DEAD

"King Aldric III has died after a reign of 37 years.

The Kingdoms await a successor."

Record death in History.

==================================================
THRONE CLAIM
==================================================

Every important House accumulates Claim.

Claim should derive from:

- Prestige
- Influence
- House age
- previous rulers
- King's Guards produced
- current ruler relation
- major military success
- House relationships
- ruling-House inheritance
- political events

Display succession likelihood as normalized percentages.

Example:

House Valen       32%
House Torr        24%
House Edran       19%
House Marr        14%
Other             11%

These percentages should be understandable but do not need to literally represent RNG probability if the system is score-based.

==================================================
PEACEFUL SUCCESSION
==================================================

If Realm Stability is healthy when a ruler dies:

perform peaceful succession.

Highest legitimate claim should generally win, modified by:
- alliances
- ruler legitimacy
- ruling dynasty bonus
- political event modifiers

Then:

"Queen Mira I of House Valen ascends the Throne."

Update:
- ruling House
- ruler
- House Prestige
- loyalty of supporters/opponents
- History

==================================================
CIVIL WAR
==================================================

Civil War is the signature crisis mechanic.

If succession occurs while Realm Stability is sufficiently low, or an extreme political event occurs:

begin Civil War.

IMPORTANT:
Do NOT split actual Civ V players.

Instead simulate Civil War with:
- internal political factions
- faction scores
- severe empire penalties
- rebel unit events
- House defections
- Kingdom unrest
- random battle/political events
- player influence

==================================================
CIVIL WAR FACTIONS
==================================================

Powerful Houses form factions.

Example:

ROYALISTS
House Valen
House Aren
House Corren

Claimant:
Mira Valen

NORTHERN LEAGUE
House Torr
House Marr
House Dorran

Claimant:
Garrick Torr

KINGMAKERS
House Edran
House Vey

Claimant:
Edric Edran

Houses choose factions based on:
- relationships
- alliances
- rivalries
- loyalty
- personalities
- Claim
- prestige
- opportunism
- current ruling House

Allied Houses should often join together.

Rivals should avoid supporting the same claimant unless circumstances strongly justify it.

The leading House in a coalition becomes claimant.

==================================================
CIVIL WAR STRENGTH
==================================================

Each faction has a War Strength / Succession Score.

Normalize UI display to percentages.

Example:

Valen Coalition:
43%

Torr Coalition:
37%

Edran Coalition:
20%

Strength changes through events and player actions.

==================================================
CIVIL WAR PENALTIES
==================================================

Civil War should be EXTREMELY painful.

Initial target values:

-25% Food empire-wide
-30% Production empire-wide
-20% Gold
-15% Science
-15% general Combat Strength
large Unhappiness penalty

Implement in a robust Civ V-compatible way.

Prefer dummy buildings/promotions/player effects if necessary.

Do not permanently corrupt yields.

All Civil War penalties MUST cleanly disappear when the war ends.

Scale numbers if Civ V implementation requires slightly different values, but keep approximately this severity.

==================================================
CIVIL WAR EVENTS
==================================================

Create a reusable event framework.

Examples:

THE BATTLE OF RED FIELDS

"House Torr's armies have defeated forces loyal to House Valen."

Torr faction:
+12 Strength

----------------

THE LORDS OF STORMWATCH DEFECT

House Marr abandons House Torr.

House Marr joins House Edran.

----------------

ROYAL TREASURY SEIZED

Lose Gold.

Enemy faction gains War Strength.

----------------

A KINGDOM DECLARES FOR THE CLAIMANT

A local Kingdom's Houses consolidate around one faction.

Faction Strength increases.

Local Stability changes.

----------------

THE PEOPLE RIOT

Spawn rebel/barbarian units near an unstable Kingdom.

Food/Production penalty temporarily worsens.

==================================================
PLAYER CIVIL WAR INTERACTION
==================================================

The player can influence the outcome.

Examples:

"House Valen requests funds."

OPTION A:
Send Gold
Valen +15 War Strength

OPTION B:
Provide military support
temporary military/Production cost
Valen +25 War Strength

OPTION C:
Remain Neutral
no immediate effect

Other actions:

- bribe Houses
- support claimant
- negotiate alliance
- distribute treasury
- send military supplies
- denounce faction politically
- grant concessions

Supporting a faction should have consequences with rival factions.

==================================================
REBELS
==================================================

Civil War may generate hostile rebel units.

Use Barbarian ownership or another safe hostile mechanism.

Do NOT spawn absurd quantities.

Spawn probability should depend on:

- local Kingdom Stability
- hostile House Influence
- Civil War severity

Prefer units appropriate to the current era.

Avoid spawning them directly on occupied tiles.

==================================================
ENDING THE CIVIL WAR
==================================================

Civil War ends when:

- one faction reaches sufficient dominance
OR
- rival factions collapse below thresholds
OR
- maximum duration resolution is required

Example event:

THE WAR OF THREE CROWNS HAS ENDED

"After twelve years of bloodshed, House Torr has defeated its rivals.

Garrick Torr has seized Kings Throne."

Effects:

- winning claimant becomes ruler
- winner gains major Prestige
- allies gain Prestige/Influence
- opponents lose Prestige
- hostile Houses may split
- Realm Stability partially recovers
- Civil War penalties removed
- History records everything

Do NOT fully reset House state.

Civil Wars should leave lasting political scars.

==================================================
HOUSE RELATIONSHIPS
==================================================

Implement House-to-House relationships.

Range roughly:
-100 to +100

Relationship states:

Blood Feud
Rivals
Distrustful
Neutral
Friendly
Allied
Marriage Alliance

Relationships may change through events.

Use relationships for:
- Civil War factions
- succession
- House splits
- demands
- political event outcomes

You do NOT need to simulate actual marriages/genealogy in enormous detail.

"Marriage Alliance" can simply be a political relationship state with historical entries.

==================================================
LINEAGE SYSTEM
==================================================

The House lineage/history system is important.

Each House should track:

Founder
Current House Head
Parent House
Founded Turn
Split descendants
Notable rulers
King's Guards
major historical events

Do NOT generate hundreds of invisible NPC family members.

Generate characters when politically relevant:

- ruler
- claimant
- House head
- King's Guard candidate
- notable event character

This keeps the simulation performant.

==================================================
CHARACTER NAMES
==================================================

Create reusable fantasy medieval name pools.

Male and female pools.

Allow regnal numbering:

Aldric I
Aldric II
Aldric III

when rulers share the same first name.

Support titles:

King
Queen

and King's Guard naming:

Ser Garrick Valen
Lady Mira Torr

depending on chosen naming style.

==================================================
CHRONICLE OF THE REALM
==================================================

This is a MAJOR feature.

Create a persistent HISTORY / CHRONICLE UI.

Record important events.

Examples:

4000 BC
Kings Throne was founded.

3760 BC
House Valen was founded in Kings Throne.

3120 BC
House Marr rose to prominence.

1840 BC
House Valen divided.
House Valencrest was founded.

620 BC
Aldric Valen became King.

240 AD
The First War of Succession began.

280 AD
House Marr emerged victorious.

280 AD
Garrick Marr was crowned King.

1080 AD
Ser Edric Torr joined the King's Guard.

1640 AD
The War of Five Houses began.

1700 AD
House Edran seized Kings Throne.

Chronicle entries must survive saves.

Allow scrolling/filtering if practical.

Potential filters:

ALL
RULERS
HOUSES
CIVIL WARS
KING'S GUARD
KINGDOMS

==================================================
UNIQUE UNIT
THE KING'S GUARDS
==================================================

Unique Unit:
The King's Guards

Replaces:
Longswordsman

Unlocked:
Medieval Era / normal Longswordsman tech

IMPORTANT:
Once unlocked, The King's Guards should remain constructible in all future eras.

They must NOT disappear simply because Longswordsmen obsolete.

Maximum:
SEVEN living King's Guards at once.

Hard cap:
7.

Cannot train an 8th.

Communicate this clearly in:
- Civilopedia
- unit tooltip
- production UI if possible

==================================================
KING'S GUARD BASE STRENGTH
==================================================

Normal Longswordsman:
21 Combat Strength

Initial King's Guard target:
28 Combat Strength

Approximately 33% stronger.

Retain sensible Longswordsman movement/cost characteristics unless balance testing suggests otherwise.

They are intentionally elite because only seven can exist.

==================================================
KING'S GUARD CANDIDATE EVENT
==================================================

When a King's Guard finishes production:

DO NOT immediately treat it as a generic unit.

Open a candidate selection event.

Example:

A KING'S GUARD MUST BE CHOSEN

"Noble warriors from throughout The Kingdoms have travelled to Kings Throne seeking appointment."

Generate approximately 3 candidates.

Candidates should come from DIFFERENT eligible Houses where possible.

Candidate example:

SER ALARIC VALEN
House Valen
Kings Throne

Trait:
HONOURABLE

+10% Combat Strength while adjacent to another King's Guard.

Appointment:
House Valen +15 Loyalty
House Valen +8 Prestige

----------------

SER GARRICK MARR
House Marr
Stormwatch

Trait:
BRUTAL

+20% Combat Strength against wounded units.

Appointment:
House Marr +15 Loyalty
House Marr +8 Prestige

----------------

LADY MIRA EDRAN
House Edran
Riverhold

Trait:
PROTECTOR

+25% Combat Strength while defending friendly Cities.

Appointment:
House Edran +15 Loyalty
House Edran +8 Prestige

==================================================
KING'S GUARD PERSONALITIES
==================================================

Create a data-driven King's Guard trait pool.

Examples:

Honourable
Brutal
Protector
Duelist
Commander
Unyielding
Rider
Siegebreaker
Veteran
Guardian
Aggressive
Cautious
Loyal
Ambitious

Translate traits into valid Civ V promotions.

If needed:
create hidden promotions.

Do not attempt effects impossible for Civ V without heavy polling if a similar safe effect exists.

==================================================
KING'S GUARD IDENTITY
==================================================

Each King's Guard must have persistent character identity.

Store:

CharacterID
Name
HouseID
Trait
AppointmentTurn
Kills
Battles if trackable
CurrentUnitID / persistent matching information
Alive/dead state

Rename the unit in-game if Civ V APIs permit.

Example:

Ser Garrick Marr

rather than simply:

King's Guard

==================================================
KING'S GUARD UPGRADING
==================================================

CRITICAL:

King's Guards must remain relevant through later eras.

Allow them to upgrade through normal military progression:

King's Guard
-> Musketman-equivalent
-> Rifleman
-> Great War Infantry
-> Infantry
-> Mechanized Infantry

Exact upgrade chain should respect the active Civ V ruleset.

Their special identity and King's Guard trait MUST survive upgrades.

Their House affiliation MUST survive upgrades.

Their King's Guard status MUST survive upgrades.

Do not accidentally count the upgraded unit as no longer one of the seven.

The original King's Guard build option should remain available after later technologies so dead Guards can be replaced.

If necessary:
create era-appropriate King's Guard replacement templates internally.

Prefer the cleanest implementation.

==================================================
KING'S GUARD DEATH
==================================================

When one dies:

record:

"Ser Garrick Marr, member of the King's Guard, has fallen."

Add Chronicle entry.

Free one slot from the seven-unit cap.

The player may eventually appoint a replacement.

==================================================
KING'S GUARD AND CIVIL WAR
==================================================

Each King's Guard remains affiliated with a House.

During Civil War, if their House opposes the Crown, occasionally trigger:

A QUESTION OF LOYALTY

Example:

"Ser Garrick Torr's family has declared against the Crown.

The King's Guard must decide where his loyalty lies."

Outcome should consider:

- Guard trait
- House Loyalty
- years serving
- ruling House relationship
- Prestige
- random component

DO NOT randomly delete or steal a highly invested unit without player interaction.

Possible event options:

REMAIN TRUE TO THE CROWN
cost/consequence

ALLOW HIM TO RETURN TO HIS HOUSE
unit is removed or transformed in a fair way
House relations affected

DEMAND AN OATH
risk/reward outcome

The player's agency matters.

==================================================
UNIQUE BUILDING
THE KINGDOM'S WALL
==================================================

Unique Building:
The Kingdom's Wall

Replaces:
Walls

Retain normal Wall effects.

Additional effects:

+1 Happiness
+2 Production
+5 local Kingdom Stability

If direct Stability isn't an XML yield:
implement through the political Lua system.

Show the Stability effect in tooltip/Civilopedia.

Keep this UB comparatively simple because the UA is already extremely complex.

==================================================
RULING HOUSE BONUS
==================================================

The current ruling House should provide an enhanced version of its House trait.

Example:

Normal Agrarian House:
small Food bonus weighted by Influence

Agrarian House while ruling:
stronger empire-level Food bonus

Similarly:

Militaristic ruler House:
strong military Production/XP benefit

Scholarly:
Science

Mercantile:
Gold

Traditionalist:
Stability

etc.

The player should genuinely notice when a different House takes the Throne.

==================================================
RULER PERSONAL BONUS
==================================================

Ruler traits stack separately with House effects.

Therefore:

House Valen may traditionally be Agrarian + Ambitious,

but:

King Aldric Valen:
The Conqueror

could produce a very different reign than:

Queen Mira Valen:
The Scholar

This distinction is important.

==================================================
CUSTOM UI
==================================================

Create a major custom UI accessible from an icon/button.

Call it something like:

THE KINGDOMS

Main Overview should show:

CURRENT RULER

King Aldric III
House Valen
Reign: 31 turns
Legitimacy: 78

Traits:
Architect
Arrogant

----------------

REALM STABILITY

37
FRACTURED

Loyal Houses: 11
Neutral Houses: 7
Hostile Houses: 8

----------------

SUCCESSION

House Valen       32%
House Torr        24%
House Edran       19%
House Marr        14%
Other             11%

----------------

KINGDOM LIST

Kings Throne
Population: X
Houses: X
Stability: X

Stormwatch
Population: X
Houses: X
Stability: X

etc.

==================================================
KINGDOM DETAIL SCREEN
==================================================

Selecting a Kingdom displays:

Kingdom Name
Population
Stability

House list:

House Valen
Influence: 34%
Loyalty: +62
Prestige: 81
Demand: Build 2 Farms

House Marr
Influence: 27%
Loyalty: -18
Prestige: 45
Demand: Declare War

etc.

Allow selecting individual Houses.

==================================================
HOUSE DETAIL SCREEN
==================================================

Show:

House name
crest/icon if generated from generic palette
origin Kingdom
founder
current head
founded turn/year
parent House
House age

Traits

Loyalty
Prestige
Influence
Claim

Current Demand

Relations

Rulers Produced
King's Guards Produced

Historical timeline

Actions:

Treasury Gift
Grant Estates
Royal Charter
Military Authority

Only display valid actions.

==================================================
SUCCESSION / CIVIL WAR PANEL
==================================================

During normal rule:
show Claims.

During Civil War:
replace with Faction panel.

Example:

WAR OF THREE CROWNS

VALEN COALITION
43%

Claimant:
Mira Valen

Members:
Valen
Aren
Corren

TORR COALITION
37%

Claimant:
Garrick Torr

etc.

Show:
- current leader
- recent events
- player support
- Civil War penalties

==================================================
UI PERFORMANCE
==================================================

CRITICAL.

Do NOT constantly rebuild UI.

Refresh UI when:

- opening panel
- turn changes
- ruler changes
- House data changes
- demand changes
- city/Kingdom changes
- Civil War state changes
- explicit dirty event fires

Never use a 0.1 second ContextPtr:SetUpdate loop to process the political simulation.

If an update loop is unavoidable for visual reasons:
use it minimally and NEVER for gameplay processing.

==================================================
HOUSE CRESTS
==================================================

Do not require hundreds of unique DDS files.

Use:
- generic House icon templates
- several heraldic symbols
- several backgrounds
- color combinations

The UI may associate Houses with generated combinations:

Lion
Stag
Tower
Sword
Wolf
Crown
Raven
Tree
Horse
Sun
Moon
Dragon-like heraldic beast
Eagle
Rose

Do not infringe directly on Game of Thrones heraldry.

Create original fantasy heraldry.

==================================================
ART
==================================================

Use the provided concept art as VISUAL INSPIRATION for the civilization.

The visual direction is:

- medieval stone fortress
- enormous royal citadel
- red/orange tower roofs
- long fortified bridges
- banners and heraldry
- dark red
- gold
- stone
- regal medieval fantasy
- united noble Houses beneath one Crown

Required Civ V art/assets include at minimum:

Civilization icon
UA icon
UU icon
UB icon
Civ/map icon
unit flag icon for King's Guard
Dawn of Man image
leader/loading presentation if required by Civ V

If Codex can generate or prepare suitable original assets, do so.

Do not directly copy copyrighted Game of Thrones artwork.

The civilization is inspired by feudal dynastic politics, not directly by GOT characters/houses.

==================================================
CIVILOPEDIA
==================================================

Add polished entries for:

The Kingdoms
The Kingdoms United
The King's Guards
The Kingdom's Wall

Civilopedia should explain the core political systems sufficiently.

Example concept:

"Every City is a Kingdom inhabited by competing noble Houses. Houses possess Loyalty, Influence and Prestige, issue demands and compete for the Throne. Prosperous Kingdoms produce more Houses and greater benefits, but political instability may trigger devastating wars of succession."

==================================================
AI SUPPORT
==================================================

If The Kingdoms is controlled by AI:

The political simulation MUST continue working.

AI should automatically make reasonable political decisions.

For example:

- occasionally appease powerful hostile Houses
- favour affordable demands
- support a dominant Civil War faction
- appoint King's Guards based on military value + House politics

Do not require human UI interactions for AI turns.

Candidate events should auto-resolve for AI.

==================================================
GAME SPEED SCALING
==================================================

Scale:

- demand cooldowns
- ruler lifespan
- event intervals
- Civil War duration
- temporary modifiers
- House-generation cooldowns

according to GameSpeed.

Do not hardcode all behaviour around Standard speed.

==================================================
ERA SCALING
==================================================

Political mechanics should remain relevant from Ancient to Information Era.

Do not disable Houses after Medieval.

The civilization should evolve through the entire game.

Even in the Information Era:
ancient Houses may still exist with thousands of years of history.

This is intentional.

==================================================
BALANCE GOAL
==================================================

The Kingdoms should be powerful when politically stable.

Strengths:

- cumulative House bonuses
- strong rulers
- elite King's Guards
- Kingdom's Wall
- ability to leverage noble factions

Weaknesses:

- political demands
- unstable successions
- complex expansion
- Civil Wars
- House rivalries
- severe internal penalties during crises

The civilization should NOT be permanently stronger than normal civilizations without meaningful risk.

Expansion creates more Kingdoms.

Population creates more Houses.

More Houses means:
more bonuses
AND
more political problems.

That is the core balance loop.

==================================================
EVENT FREQUENCY
==================================================

Do not turn every turn into a popup simulator.

Events should feel meaningful.

Prefer:
- passive updates silently
- important events as notifications
- major decisions as popups
- minor House changes only visible in UI/history

==================================================
NOTIFICATIONS
==================================================

Use Civ V notifications appropriately.

Examples:

New House Founded
House Split
House Demand Issued
Demand Completed
Demand Failed
Ruler Died
New Ruler Crowned
Realm Stability Critical
Civil War Began
House Changed Allegiance
King's Guard Appointed
King's Guard Killed
Civil War Ended

==================================================
HISTORY YEAR DISPLAY
==================================================

Where possible, convert turns to Civ V's displayed historical year/date.

If safe access to game turn year is unavailable in a context:
store turn number and convert for UI when displayed.

==================================================
DEBUG MODE
==================================================

Add:

local DEBUG_KINGDOMS = false

Logging categories:

[KINGDOMS]
[HOUSE]
[DEMAND]
[RULER]
[SUCCESSION]
[CIVILWAR]
[KINGSGUARD]
[HISTORY]
[PERSISTENCE]
[UI]

Provide useful traces without flooding logs when DEBUG is false.

==================================================
ROBUSTNESS
==================================================

Protect against:

- dead players
- razed cities
- city capture
- House references to deleted Kingdoms
- duplicate House IDs
- missing unit IDs
- King's Guard upgrades
- save/reload during Civil War
- save/reload during candidate selection
- invalid demand targets
- civ elimination
- capital capture
- no eligible House candidates
- generated names exhausted
- UI opened before initialization
- old saves lacking new fields

Use versioned save data if practical.

==================================================
CAPITAL CAPTURE
==================================================

Kings Throne is politically important.

If the capital is captured:

- large temporary Realm Stability loss
- ruling House loses Prestige/Legitimacy
- succession Claim disruption
- Chronicle entry

Do NOT immediately destroy the civilization.

If the capital is later retaken:
create a restoration event.

==================================================
TESTING
==================================================

Create a test checklist covering at least:

1. Civ loads without SQL/XML errors.
2. Capital is Kings Throne.
3. New city becomes Kingdom.
4. Starting Kingdom creates Houses.
5. Population thresholds create new Houses gradually.
6. House split works.
7. House traits persist.
8. Loyalty persists after reload.
9. Prestige persists.
10. Influence calculations work.
11. Demands are generated.
12. Invalid demands are avoided.
13. Completed demands resolve.
14. Failed demands resolve.
15. House appeasement actions work.
16. Kingdom Stability updates.
17. Realm Stability updates.
18. Ruler generated.
19. Ruler death works.
20. Peaceful succession works.
21. Claims update.
22. Civil War triggers.
23. Factions form.
24. House alliances influence factions.
25. Civil War penalties apply.
26. Civil War penalties are removed afterward.
27. Civil War events work.
28. Rebel units spawn safely.
29. Player can support faction.
30. Winner becomes ruler.
31. Chronicle records events.
32. Chronicle persists after save/reload.
33. King's Guard unlocks Medieval.
34. King's Guard remains constructible later.
35. Cap of seven works.
36. Candidate selection works.
37. Candidate House effects apply.
38. Guard receives correct trait promotion.
39. King's Guard upgrade retains identity.
40. King's Guard death frees slot.
41. King's Guard Civil War loyalty event works.
42. Kingdom's Wall gives +1 Happiness/+2 Production.
43. Kingdom's Wall Stability bonus works.
44. UI opens and closes correctly.
45. UI does not show during inappropriate screens if that would obstruct Civ V interfaces.
46. No constant polling/FPS degradation.
47. AI can use the civilization.
48. Save during Civil War and reload.
49. Save with seven King's Guards and reload.
50. City capture/recapture does not corrupt Kingdom data.

==================================================
IMPLEMENTATION PRIORITY
==================================================

Build in stages, but implement the complete system.

Recommended order:

PHASE 1
Base civilization
UA/UU/UB database definitions
persistence framework

PHASE 2
Kingdoms
Houses
House traits
Loyalty
Prestige
Influence

PHASE 3
House demands
Stability
House actions

PHASE 4
Rulers
Claims
Succession

PHASE 5
Civil War

PHASE 6
King's Guard candidate/character system

PHASE 7
Chronicle

PHASE 8
Full UI

PHASE 9
AI support
balance
testing
performance profiling

==================================================
FINAL DELIVERY
==================================================

When complete:

1. Review every XML/SQL file for database errors.
2. Review every Lua file for syntax/runtime issues.
3. Check all include/import paths.
4. Check .modinfo entries.
5. Check InGameUIAddin configuration.
6. Ensure no UI context polls every frame/0.1 seconds.
7. Ensure every persistent table reloads correctly.
8. Ensure Civil War dummy modifiers are completely cleaned up.
9. Ensure King's Guard identity persists through upgrades.
10. Ensure House IDs never collide.
11. Ensure AI turns never trigger human-only UI.
12. Ensure all text has localization entries.
13. Ensure the mod can start a fresh game without requiring IGE.
14. Produce a concise implementation report explaining:
    - files created
    - major systems
    - persistence method
    - UI architecture
    - CP hooks used
    - known limitations
    - balance values
    - testing performed

Do not merely create placeholder TODO systems.

Implement the civilization as fully as Civ V safely allows.