CIVILIZATION: The Filthy Realm
LEADER: Filthy Frank
CAPITAL: The Rice Fields

ASSUMPTIONS:
- Civilization V: Brave New World
- Community Patch / Vox Populi DLL is available.
- XML/SQL and Lua can be used.
- Custom Lua UI is allowed.
- No additional DLL changes should be required.

==================================================
CORE DESIGN
==================================================

The Filthy Realm is a Culture/Domination hybrid civilization based around spreading "Filth" into foreign cities.

Filthy Frank intentionally interacts with other civilizations through Tourism, Trade Routes, pillaging and warfare. Foreign cities gradually accumulate Filth, which weakens their economy and gives Filthy Frank military advantages around heavily contaminated cities.

Filthy Frank also has a unique player resource called Filthy Points. Filthy Points are earned by warfare, cultural disruption, pillaging and provoking other civilizations.

Filthy Points can be spent through a custom "Filthy Realm" UI on several active abilities.

The civ should feel disruptive, chaotic and aggressive without simply receiving enormous direct yield bonuses.

==================================================
UNIQUE ABILITY
WELCOME TO THE RICE FIELDS
==================================================

Foreign cities may accumulate up to 5 levels of Filth.

Filth can be spread through:
- International Trade Routes originating from Filthy Frank.
- Tourism / cultural influence.
- Pillaging tiles belonging to another civilization.
- Killing enemy units close to their cities.
- Certain unique Filthy Realm abilities.

FILTH LEVELS:

Filth Level 1:
- -2% Culture in the city.

Filth Level 2:
- -3% Culture.
- -3% Gold.

Filth Level 3:
- -5% Culture.
- -5% Gold.
- -5% Production.

Filth Level 4:
- -7% Culture.
- -7% Gold.
- -7% Production.
- Filthy Frank military units receive +10% Combat Strength while close to this city.

Filth Level 5 — Absolutely Disgusting:
- -10% Culture.
- -10% Gold.
- -10% Production.
- -1 Local Happiness.
- Filthy Frank military units receive +15% Combat Strength while close to this city.

The military bonus from Filth should NOT stack between multiple nearby cities. Use the strongest applicable bonus.

Filth should be represented internally using dummy buildings in affected foreign cities.

==================================================
FILTH DECAY
==================================================

Filth is not permanent.

Every 10 turns, check contaminated foreign cities.

If a city has no meaningful active connection to Filthy Frank, remove 1 Filth level.

Connections that prevent decay include:
- An active Filthy Frank Trade Route involving the city.
- Significant Filthy Frank Tourism pressure.
- Nearby Filthy Frank military presence.

This gives opponents counterplay by isolating themselves from Filthy Frank.

==================================================
UNIQUE RESOURCE
FILTHY POINTS
==================================================

Filthy Frank has a custom player resource called Filthy Points.

Suggested Filthy Point generation:

Enemy unit killed:
+2 FP

Enemy unit killed inside enemy territory:
+3 FP instead.

Pillage an improvement:
+3 FP

Cause a foreign city to gain a new Filth level:
+2 FP

Establish an International Trade Route:
+5 FP

Create a Great Work:
+10 FP

Capture a city:
+20 FP

Another civilization denounces Filthy Frank:
+10 FP

Another civilization declares war on Filthy Frank:
+20 FP

A World Congress decision specifically targeting Filthy Frank successfully passes:
+25 FP

Filthy Points should be stored as a persistent player value through Lua.

The current amount should be visible through a small custom UI element.

==================================================
UNIQUE UI
THE FILTHY REALM
==================================================

Add a custom button to the main game interface:

"ENTER THE FILTHY REALM"

Opening it displays:
- Current Filthy Points.
- Available Filthy Realm abilities.
- Their costs.
- Their cooldowns.

Four abilities are available.

==================================================
FILTHY REALM ABILITY 1
SALAMANDER MAN
==================================================

Cost:
25 Filthy Points

Effect:
Spawn a temporary Salamander Man unit adjacent to the Capital.

Salamander Man:
- 5 Movement.
- Cannot attack.
- Cannot capture cities.
- Cannot be upgraded.
- Cannot be gifted.

Aura:
Adjacent enemy military units:
- -10% Combat Strength.
- -1 Movement.

Adjacent friendly military units:
- +1 Movement.

Duration:
5 turns.

After the duration expires, Salamander Man is automatically removed.

==================================================
FILTHY REALM ABILITY 2
REALM DISTORTION
==================================================

Cost:
40 Filthy Points

Target:
A foreign city currently containing at least 1 Filth.

Duration:
5 turns.

Effects:
- Negative Filth yield effects in the target city are increased by 50%.
- Filthy Frank units within 2 tiles of the city ignore enemy Zone of Control.
- Enemy units trained in the target city receive -10 starting XP while the effect is active.

Cooldown:
10 turns.

Only one Realm Distortion should be active at a time.

==================================================
FILTHY REALM ABILITY 3
RAVIOLI RAVIOLI, WHAT'S IN THE POCKETOLI
==================================================

Cost:
60 Filthy Points

Target:
One foreign city.

The player selects one category to steal:
- Gold
- Science
- Culture
- Food
- Production

Do NOT make the effect random.

The amount stolen should scale moderately by Era.

Gold:
Steal an immediate quantity of Gold from the city's owner and give the same amount to Filthy Frank.

Science:
Remove an Era-scaled quantity of Science from the target civilization's current research progress if technically practical, otherwise simply grant Filthy Frank an Era-scaled amount of Science.

Culture:
Transfer an Era-scaled lump of Culture.

Food:
Remove Food from the city's Food storage and add an equivalent or balanced Food amount to Filthy Frank's Capital.

Production:
Remove Production from the city's current build progress and add an equivalent or balanced Production amount to Filthy Frank's Capital.

A particular foreign city cannot be targeted again for 15 turns.

==================================================
FILTHY REALM ABILITY 4
IT'S TIME TO STOP
==================================================

Cost:
80 Filthy Points

Cooldown:
20 turns.

Effect:
For the remainder of the current turn, enemy military units within 4 tiles of any Filthy Frank military unit:

- Lose their remaining Movement.
- Cannot attack.

This is NOT global.

Only enemy units inside the local affected areas are stopped.

Apply a temporary dummy promotion / status to affected units and remove it at the beginning of the appropriate next turn.

==================================================
UNIQUE UNIT
PEACE LORD
==================================================

Replaces:
Great War Infantry

Base Great War Infantry strength:
50

Peace Lord strength:
52

Peace Lord should otherwise retain the normal role and upgrade path of Great War Infantry.

Unique Promotion:
KNOW YOUR PLACE

Whenever a Peace Lord kills an enemy military unit:
- Gain +5 Filthy Points.
- Adjacent enemy military units receive -10% Combat Strength for 1 turn.

Unique Active Ability:
FILTHY INTERVENTION

Once per Peace Lord.

Target:
One adjacent enemy military unit below 30% HP.

Effect:
Force the target to retreat to the nearest valid tile away from the Peace Lord.

The target is NOT destroyed.

Filthy Frank gains:
+10 Filthy Points.

After use, that individual Peace Lord permanently loses access to Filthy Intervention.

If no valid retreat tile exists, the ability cannot be activated.

==================================================
UNIQUE BUILDING
FILTHY KITCHEN
==================================================

Replaces:
Broadcast Tower

Retains the normal Broadcast Tower effects.

Additional effects:
- +2 Tourism.
- Great Works located in this city contribute toward Filthy Point generation.
- Every 5 turns, each qualifying city containing a Filthy Kitchen may generate Filthy Points from its Great Works.
- International Trade Routes connected to a city with a Filthy Kitchen have an increased chance/rate of spreading Filth to the foreign destination.

COOKING WITH FRANK:

Whenever a Great Work is created in a city containing a Filthy Kitchen:
- Gain +25 Food in that city.
- Gain +10 Filthy Points from the normal Great Work Filthy Point effect.

Avoid excessively high passive Filthy Point income from large Great Work collections. Add a sensible cap or low periodic value if necessary.

==================================================
UNIQUE GREAT WORK FLAVOUR
==================================================

Filthy Frank may use custom Great Work names themed around his content.

Examples:
- Human Cake
- Hair Cake
- Ravioli
- Weeaboos
- People I Hate
- Loser Reads Hater Comments
- DizastaMusic
- Francis of the Filth

These are primarily flavour and should use normal Great Work mechanics.

Creating any Great Work generates +10 Filthy Points through the UA.

==================================================
DIPLOMATIC INTERACTION
NEGATIVE ATTENTION IS STILL ATTENTION
==================================================

Filthy Frank benefits when other civilizations publicly react against him.

One-time rewards:

Denounced by another civilization:
+10 Filthy Points.

War declared on Filthy Frank:
+20 Filthy Points.

World Congress resolution specifically harming/targeting Filthy Frank passes:
+25 Filthy Points.

Prevent obvious exploits such as repeatedly gaining points from the same unchanged diplomatic state.

==================================================
PLAYSTYLE
==================================================

Early Game:
Relatively normal.

Build cities, establish Trade Routes and begin developing Culture.

Filth should spread slowly during this phase.

Mid Game:
International connections become increasingly important.

Use Trade Routes, Tourism and occasional conflict to establish Filth in neighbouring civilizations.

Filthy Points begin giving the player access to active disruption abilities.

Industrial / Modern:
The civilization reaches its main power spike.

Filthy Kitchens increase cultural pressure.

Peace Lords become available.

Heavily contaminated cities become favourable invasion targets.

Late Game:
The Filthy Realm functions as a Culture/Domination hybrid.

A player may pursue a Culture Victory by spreading influence across the world or use high-Filth cities as military weak points for conquest.

==================================================
COUNTERPLAY
==================================================

Enemies should be able to limit Filth by:
- Cancelling or avoiding Trade Routes with Filthy Frank.
- Closing Borders.
- Maintaining strong Culture/Tourism defence.
- Destroying Filthy Frank's International Trade Routes.
- Keeping Filthy Frank's military away from their cities.
- Allowing existing Filth to decay.
- Attacking Filthy Frank before his Filthy Kitchen / Peace Lord power spike.

Filth alone should inconvenience and weaken foreign cities but should NOT completely destroy their economy.

==================================================
AI PERSONALITY
==================================================

Preferred Victories:
1. Culture
2. Domination
3. Diplomatic
4. Science

AI tendencies:

High:
- Culture
- Offense
- Pillaging
- International Trade Routes
- Espionage
- Boldness
- Diplomatic interaction

Moderate:
- Expansion
- Science
- City-State interaction

Low:
- Pure defensive play
- Wonder obsession

The AI should strongly favour maintaining contact and interaction with other civilizations because most of the civilization's mechanics depend on foreign exposure.

==================================================
ART / UI ASSETS
==================================================

Civilization:
The Filthy Realm

Leader:
Filthy Frank

Civilization Icon:
A circular stylized icon consisting ONLY of Filthy Frank's face.

Primary icon theme:
Pink / dark accents.

Required major art assets:
- Leader Scene: Filthy Frank inside his messy bedroom / room.
- Leader Icon.
- Civilization Icon.
- Dawn of Man image.
- Peace Lord unit icon.
- Filthy Kitchen building icon.
- Civilization Map image.
- Filthy Point icon.
- Filthy Realm UI button/icon.
- Salamander Man unit icon if implemented as a visible unit.

Dawn of Man theme:
Filthy Frank presiding over the Filthy Realm / Rice Fields with Pink Guys or followers around him.

Map theme:
Chaotic settlements, rice fields and Filthy Realm imagery.

==================================================
IMPLEMENTATION NOTES
==================================================

Use Lua + dummy buildings for Filth levels.

Suggested structure:
BUILDING_FILTH_LEVEL_1
BUILDING_FILTH_LEVEL_2
BUILDING_FILTH_LEVEL_3
BUILDING_FILTH_LEVEL_4
BUILDING_FILTH_LEVEL_5

Only one Filth dummy building should exist in a city at once.

Use saved player data for:
- Current Filthy Points.
- Filthy Realm cooldowns.
- Ravioli city cooldowns.
- Peace Lord Filthy Intervention usage.
- Temporary ability duration tracking.

Use temporary promotions for:
- Know Your Place.
- It's Time to Stop.
- Realm Distortion related combat effects where appropriate.

Use Lua events / periodic turn processing for:
- Unit kills.
- Pillaging.
- War declarations.
- Filth spread.
- Filth decay.
- Trade Route checks.
- Great Work checks.
- Temporary ability durations.
- Salamander Man expiration.
- Peace Lord retreat targeting.

Do not require additional DLL modifications beyond Community Patch functionality.

==================================================
SHORT CIVILOPEDIA DESCRIPTION
==================================================

Filthy Frank leads the Filthy Realm, a civilization that thrives through cultural contamination, provocation and chaos. Foreign cities exposed to Frank's trade, culture and warfare accumulate Filth, gradually weakening their economies and making them increasingly vulnerable to his armies. Acts of disruption generate Filthy Points, which may be spent through the Filthy Realm to summon bizarre allies, distort contaminated cities, steal resources or simply force the enemy to stop.

The Peace Lord turns battlefield humiliation into additional Filthy Points, while the Filthy Kitchen transforms Great Works and Tourism into yet another means of spreading Frank's influence. The Filthy Realm is strongest when constantly interacting with the rest of the world: trading with it, offending it, contaminating it and, eventually, conquering it.