# The Filthy Realm

Filthy Frank leads a Culture/Domination civilization built around sustained contact with foreign cities. International Trade Routes, cultural influence, pillaging, and kills near enemy cities apply up to five levels of Filth. The hidden Filth buildings impose the exact percentage penalties from the design; levels four and five grant nearby Filthy military units the strongest applicable combat bonus, never a stack of multiple bonuses.

## Filth and Filthy Points

- Trade Routes spread one Filth every 6 turns, or every 4 turns when their origin has a Filthy Kitchen.
- Familiar-or-better cultural influence spreads Filth to a foreign capital every 10 turns.
- Pillaging and enemy kills near their cities spread Filth immediately.
- Every 10 turns, a contaminated city loses one level unless it has a Filthy trade connection, meaningful tourism pressure, or nearby Filthy military presence.
- New Filth levels, kills, pillaging, routes, Great Works, city captures, denunciations, and declarations of war generate persistent Filthy Points.

The top-screen `ENTER THE FILTHY REALM` button opens a panel with the current point total, cooldowns, valid targets, and all active abilities:

- Salamander Man (25 FP): creates a non-combat 5-Movement aura unit beside the capital for five turns.
- Realm Distortion (40 FP, 10-turn cooldown): increases one contaminated city's penalties by 50% for five turns, lets nearby Filthy units ignore Zone of Control, and removes up to 10 starting XP from units trained there.
- Ravioli Ravioli, What's in the Pocketoli (60 FP): steals a player-selected Gold, Science, Culture, Food, or Production amount scaled by era. A city has a 15-turn target cooldown.
- It's Time to Stop (80 FP, 20-turn cooldown): exhausts enemy military units within four tiles of Filthy military units and prevents their attacks for the rest of that game turn.

AI Filthy Frank prioritizes Stop during war, then Ravioli, Realm Distortion, and Salamander Man.

## Unique objects

The Peace Lord replaces Great War Infantry at 52 Combat Strength. Its kills grant 5 extra FP and impose a one-turn -10% Combat Strength debuff on adjacent enemies. Each Peace Lord can use Filthy Intervention once through the Realm panel: an adjacent enemy below 30 HP retreats to a valid tile farther away, and Frank gains 10 FP.

The Filthy Kitchen replaces the Broadcast Tower, retains inherited Brave New World/Community Patch effects, and adds 2 Tourism. New Great Works in its city add 25 Food as well as the normal 10 FP. Every five turns it also contributes one FP per Great Work, capped at three per city.

## Implementation

- `SQL/00_Filthy_Core.sql` creates the civilization, leader, unique objects, art atlases, and temporary promotions.
- `SQL/01_Filthy_Inheritance.sql` clones every BNW/Community Patch companion-table row for Great War Infantry and the Broadcast Tower.
- `SQL/02_Filthy_UniqueEffects.sql` defines the ten mutually exclusive normal/distorted Filth buildings, AI flavor, city list, and supporting effects.
- `Lua/FilthyRuntime.lua` owns save data and gameplay state. Unit script markers preserve temporary effects without overwriting other mods' script data.
- `UI/FilthyPanel.xml` is the only entry point; it includes the runtime before presenting controls.
- `docs/OriginalDesign.md` preserves the supplied design brief, while `docs/ART_GENERATION.md` records the art pipeline.

The World Congress reward uses the Community Patch `ResolutionResult` event and applies when a passed enactment has the `EmbargoPlayer` effect and targets Filthy Frank. Denunciation rewards are detected as state transitions, which prevents repeated points from one unchanged diplomatic state.
