Implement a complete Civilization V: Brave New World custom civilization based on the Viltrum Empire from Invincible.

TARGET ENVIRONMENT
- Civilization V BNW
- Community Patch / Community Balance Patch compatible
- Assume Community Patch v151-style Lua/GameEvents functionality is available.
- Pure mod files only: XML / SQL / Lua / DDS / audio references.
- Do not require ModBuddy-specific code architecture.
- Do not modify the DLL.
- Do not change unrelated civilizations or existing systems in the repo.
- Prefer event-driven code.
- DO NOT implement rapid ContextPtr:SetUpdate polling or 0.1-second polling loops.
- Turn-based checks are acceptable where no direct event exists.
- Use deterministic synchronized RNG such as Game.Rand for gameplay-affecting randomness. Never use math.random for multiplayer gameplay.
- Persist every important state so saving/loading cannot duplicate bonuses or reset event timers.

Before changing anything:
1. Inspect the existing repository structure.
2. Reuse existing helper libraries/patterns if appropriate.
3. Inspect Community Patch database tables/hooks actually available in this environment rather than assuming vanilla-only behavior.
4. Avoid duplicate database rows and duplicate Lua listeners.
5. Keep SQL/XML IDs consistently prefixed, e.g. VILTRUM_.

==================================================
CIVILIZATION
==================================================

Civilization:
The Viltrum Empire

Short Description:
Viltrum

Adjective:
Viltrumite

Leader:
Grand Regent Thragg

Capital:
Viltrum

Preferred Victory:
Domination

Secondary preference:
Science

Colors:
Primary: deep crimson
Secondary: white/light gray

Civilization icon:
Use the supplied Viltrum emblem exactly as the basis of the civilization icon.

The icon is the white circular Viltrum-style emblem supplied in the art references.

Do not invent a replacement emblem.

==================================================
CORE DESIGN PHILOSOPHY
==================================================

Viltrum should NOT play like a normal domination civ.

It has three distinct stages:

1. IMPERIAL ASCENDANCY
   Powerful conquest civilization with strong sustain and elite military.

2. THE SCOURGE
   A catastrophic once-per-game collapse that destroys most Viltrumite population and Viltrumite units.

3. THE SURVIVING EMPIRE
   A much smaller civilization centered around a handful of incredibly powerful survivors and ordinary auxiliary forces.

The pre-Scourge civilization can intentionally be stronger than an average vanilla civ because the Scourge is a guaranteed existential disaster.

Do not remove any mechanic described below.

==================================================
UNIQUE ABILITY
BLOOD OF CONQUEST
==================================================

TRAIT NAME:
Blood of Conquest

------------------------------
A. RELENTLESS EXTERMINATION
------------------------------

Eligible Viltrum land combat units heal 15 HP whenever they personally destroy an enemy military combat unit.

Rules:
- Do not activate on civilian units.
- Do not activate from deleting/disbanding.
- Do not activate against Barbarians if that causes farming problems; if existing implementation makes Barbarians safe, allowing them is acceptable, but document it.
- Does not exceed maximum HP.
- Normally stacks with standard healing.
- Disabled or modified during the Scourge crisis as described later.

Prefer actual kill/combat events rather than scanning every unit.

------------------------------
B. SUBJUGATED WORLDS
------------------------------

The FIRST time Viltrum captures a particular foreign city:

- Viltrum's capital gains +1 Population.
- That captured city's resistance duration is reduced by 20%.
- Imperial Momentum activates.

This must only trigger once per original city.

Prevent:
- Capture -> lose -> recapture farming.
- Repeated liberation/reconquest farming.
- Save/reload duplication.

Persist captured-city history.

A stable plot-based identifier plus founding/original-owner information is acceptable if no better persistent city identity exists.

------------------------------
C. IMPERIAL MOMENTUM
------------------------------

Capturing a foreign city for the first time activates:

IMPERIAL MOMENTUM
Base duration:
8 turns on Standard Speed.

Effects:
- +15% Production toward military units in all Viltrum cities.
- Newly trained military units receive +3 XP.
- Military units receive +5% Combat Strength when attacking cities.

Additional first-time city captures while Momentum is active:
+3 turns duration.

Maximum:
18 turns remaining.

Do NOT stack the numerical strength of the bonuses.

Only duration extends.

Scale durations appropriately for game speed.

The timer must persist through saves.

Provide a notification when Momentum activates and preferably show remaining turns through a tooltip/notification where practical.

------------------------------
D. IMPERIAL GARRISONS
------------------------------

Every Viltrum city with a military garrison receives:

+1 Production
+1 Local Happiness
+3 City Combat Strength

Implement through a hidden/dummy building or equivalent reliable CP-compatible method.

Update garrison state through proper unit/city events where possible.

A PlayerDoTurn safety refresh is acceptable.

Do not use frame-by-frame polling.

==================================================
UNIQUE UNIT
VILTRUMITE WARRIOR
==================================================

Replaces:
Infantry

Technology:
Replaceable Parts

Role:
Extremely expensive super-unit / strategic breakthrough unit.

IMPORTANT DESIGN RULE:

One Viltrumite Warrior should cost roughly the same Production as 3-4 standard Infantry.

Use:

Combat Strength:
82

Movement:
3

Production Cost:
1300

Normal Infantry reference cost:
approximately 375 in the intended ruleset.

Thus:
1 Viltrumite ≈ 3.47 Infantry in Production.

Do NOT lower the cost back toward 500-600.

This high cost is intentional.

No strategic resource requirement unless required by an existing CP Infantry replacement system.

The Viltrumite is NOT supposed to replace the entire army.

Ideal Viltrum armies should contain:
- a small number of Viltrumites
- conventional Infantry
- Artillery
- Anti-Air
- Fighters
- Bombers
- ordinary garrison forces

------------------------------
VILTRUMITE PROMOTIONS
------------------------------

FREE:
Viltrumite Bloodline
Viltrumite Flight
March
Relentless Execution
Planetbreaker

------------------------------
VILTRUMITE BLOODLINE
------------------------------

Hidden marker promotion.

Purpose:
- Identifies biologically Viltrumite units.
- Allows the Scourge system to target only Viltrumites.
- Persists through upgrades.
- Used to grant survivor promotions.

Retain on upgrade.

------------------------------
VILTRUMITE FLIGHT
------------------------------

The unit should behave like an extraordinarily mobile flying land combat unit.

Target behavior:
- Ignore normal terrain movement costs.
- Cross Mountains.
- Cross shallow water/coastal terrain without normal embark limitations where reasonably possible.
- 7-tile aerial/paradrop-style deployment.
- May attack after deployment if Civ V/CP supports this cleanly.

Use Community Patch promotion fields where available.

Investigate existing Helicopter/Paratrooper/CP mechanics before writing custom Lua.

Do not implement ugly tile-by-tile teleporting unless absolutely necessary.

The unit remains DOMAIN_LAND unless a better compatible implementation exists.

It must still capture cities.

------------------------------
MARCH
------------------------------

Standard March promotion.

Heal while acting.

------------------------------
RELENTLESS EXECUTION
------------------------------

+15% Combat Strength when fighting an enemy combat unit that currently has less than 50 HP.

This modifier applies based on the TARGET being wounded.

If no native promotion field exists, implement using a temporary dummy promotion through appropriate Community Patch combat hooks.

Do not permanently leave the promotion enabled.

------------------------------
PLANETBREAKER
------------------------------

+20% Combat Strength when attacking a city currently below 50% HP.

If Viltrumite Warrior personally captures a city:
Heal 35 HP.

Again, use appropriate combat/city hooks rather than polling.

==================================================
UNIQUE BUILDING
VILTRUMITE BREEDING COMPLEX
==================================================

Replaces:
Military Academy

Effects relative to normal Military Academy:

+15 XP to trained units
+2 Production
+1 Food
+5% Production toward military units

When constructed for the FIRST time in a city:
+1 Population.

Do not allow:
sell building -> rebuild -> gain another Population.

Persist the city's one-time population reward.

------------------------------
IMPERIAL CONDITIONING
------------------------------

Land military units trained in a city containing the Breeding Complex receive:

+5% Combat Strength outside friendly territory.
+5% faster healing while inside friendly OR neutral territory.

Promotion persists through upgrades.

------------------------------
SCOURGE PROTECTION
------------------------------

When the Scourge Virus strikes:

Cities with a Viltrumite Breeding Complex retain one EXTRA citizen beyond the standard minimum after population loss.

Example:

Without complex:
City would fall to Population 1.

With complex:
City may retain Population 2.

Capital minimum rules still apply.

==================================================
UNIQUE EVENT 1
THE GREAT PURGE
==================================================

Occurs once per game.

Trigger when ALL are true:

- Viltrum has reached Medieval Era.
- Viltrum owns at least 2 cities.
- Total empire Population >= 15.
- Capital is not currently in resistance.

Create a proper popup with two choices.

EVENT TEXT:

"The Great Purge

Viltrum has turned its strength inward. Those judged unworthy are being hunted by their own people. Entire cities have become battlegrounds as the Empire determines whether survival itself is proof of superiority.

The weak plead for protection. The warriors demand that the purge continue."

------------------------------
OPTION A
ONLY THE STRONG SHALL REMAIN
------------------------------

Every Viltrum city:
-1 Population
Minimum Population 1.

All existing Viltrum military combat units:
+10 XP.

Future land combat units:
+3 XP permanently for the remainder of the game.

Viltrum gains:
+3% military unit Production permanently.

For 20 Standard-speed turns:
+1 Great General progress/Combat Experience per turn.

Use player:ChangeCombatExperience or the correct CP equivalent.

Scale duration by game speed.

------------------------------
OPTION B
STRENGTH REQUIRES AN EMPIRE TO RULE
------------------------------

For 20 Standard-speed turns:
+10% Growth in all cities.

For 10 Standard-speed turns:
+1 Local/Global Happiness per city, whichever implementation matches intended behavior without abuse.

Immediate:
+75 Culture, scaled by game speed and modestly by current era.

Suggested calculation:

BaseCulture = 75
× game-speed CulturePercent
× (1 + 0.15 × EraIndex)

Document the final formula.

------------------------------
AI DECISION
------------------------------

Thragg normally prefers:
ONLY THE STRONG SHALL REMAIN.

However choose population preservation if one or more are true:

- Empire Happiness < 0.
- More than half of cities have Population <= 3.
- Viltrum is clearly losing a war.
- Viltrum owns fewer than 4 combat units.

==================================================
UNIQUE EVENT 2
THE SCOURGE VIRUS
==================================================

This is THE central civilization mechanic.

It happens ONCE.

It is guaranteed.

It cannot be avoided forever.

Do NOT use the old design where the outbreak simply occurs 15 turns after entering the Modern Era.

Use the newer Replaceable Parts/Viltrumite based trigger system.

------------------------------
SCOURGE TRIGGER
------------------------------

Researching Replaceable Parts begins eligibility.

Start the main Scourge countdown when EITHER:

A. Viltrum creates its first Viltrumite Warrior.

OR

B. 12 Standard-speed turns have passed since Viltrum researched Replaceable Parts.

Whichever happens FIRST.

Once the countdown begins:

The outbreak happens after:
8 Standard-speed turns.

Scale BOTH delay values by game speed.

Suggested rough scaling:

Quick:
8-turn delay equivalent -> 5
12-turn delay equivalent -> 8

Standard:
8
12

Epic:
12
18

Marathon:
24
36

Use the actual GameSpeed train/research/calendar percentages if a cleaner systematic scaling method exists.

The player must receive warnings.

------------------------------
FIRST WARNING
------------------------------

At countdown start:

"AN IMPOSSIBLE ILLNESS

Reports have arrived from the outer colonies. Viltrumites are collapsing from an unknown pathogen. Their strength is fading, their flight is failing, and injuries once considered trivial are proving fatal.

Imperial physicians insist the outbreak is contained.

They are lying."

While warning countdown is active:
Viltrumite units heal 25% slower.

Show remaining turns.

Provide another warning at roughly 3 turns remaining.

Provide a final warning at 1 turn remaining.

==================================================
SCOURGE CHOICE A
ENFORCE TOTAL QUARANTINE
==================================================

Immediate effects:

CITY POPULATION:
Every Viltrum city loses 75% of current Population.

Round appropriately.

Minimums:
Capital cannot fall below 2 Population.
Other cities cannot fall below 1 Population.

Breeding Complex:
Retains +1 additional citizen beyond normal calculated minimum where applicable.

VILTRUMITE CASUALTIES:
Destroy 80% of all living units with Viltrumite Bloodline.

Use deterministic synchronized Game.Rand.

Important survivor floor:

If Viltrum owned at least 2 Viltrumite units:
At least 2 must survive.

If Viltrum owned only 1:
That one may survive.

Survivors:
Set to 25 HP.

OTHER:
- Recall/cancel Viltrum trade routes where API safely allows it.
- Immediately end Imperial Momentum.

------------------------------
TOTAL QUARANTINE
20 STANDARD TURNS
------------------------------

During Quarantine:

- Population growth completely halted.
- -40% general Production.
- Additional -50% Production toward military units.
- Unit healing reduced by 50%.
- Blood of Conquest kill healing disabled.
- Capturing cities does NOT grant +1 Capital Population.
- Capturing cities does NOT activate Imperial Momentum.
- Resistance reduction from Subjugated Worlds disabled.
- Settlers cannot be trained.

Scale duration by game speed.

------------------------------
SCOURGE-HARDENED
------------------------------

Viltrumite units that actually survive the outbreak receive:

+10% Combat Strength
+20% Healing Rate
+1 Sight
Immunity to any later Scourge casualty logic.

This promotion is only for TRUE original survivors.

New units do not receive it.

Track survivors persistently even if they later upgrade.

------------------------------
REPOPULATION PROGRAM
------------------------------

After Quarantine ends:

For 20 Standard turns:

+25% Growth
+15% Production
+1 Happiness per city

New Viltrumite Warriors trained after the Scourge receive:

HARDENED GENOME
+5% Combat Strength.

Scale duration.

==================================================
SCOURGE CHOICE B
CONTINUE THE CRUSADE
==================================================

Immediate:

CITY POPULATION:
Lose 85% of current Population.

Capital minimum:
2

Other cities:
1

Breeding Complex:
+1 protected citizen where applicable.

VILTRUMITE CASUALTIES:
Destroy 90%.

At least ONE Viltrumite survives if any existed before the event.

Survivors:
10 HP.

Empire receives:
-10 Global Happiness.

End current Golden Age if possible.

------------------------------
DYING EMPIRE
25 STANDARD TURNS
------------------------------

Effects:

-75% Growth.
-50% Production.

Viltrumite/eligible military units:
Cannot passively heal outside friendly territory.

Blood of Conquest:
Healing reduced from 15 -> 10 HP.

Imperial Momentum remains active/usable.

First-time foreign city captures:
Still give +1 Capital Population.
Still activate/extend Imperial Momentum.
Still apply normal capture effects unless explicitly disabled above.

For first 10 Standard turns of this crisis:
Viltrum cannot voluntarily make or accept Peace.

Do not break forced diplomatic systems or scenario peace rules; apply only where safe.

Every new foreign city captured during the crisis:
Reduce remaining Dying Empire duration by 1 turn.

------------------------------
LAST PUREBLOOD
------------------------------

Every Viltrumite unit that ACTUALLY survives Continue the Crusade receives:

+20% Combat Strength
+1 Movement
Blitz
+20% XP from combat
+20% Combat Strength while the Viltrumite itself is below 50 HP

If that survivor personally captures an enemy capital:
Fully heal it.

Only actual outbreak survivors receive this.

New units never receive Last Pureblood.

------------------------------
AFTER THE CRUSADE
------------------------------

When Dying Empire ends:

Remove -10 Happiness.

For 15 Standard turns:
+15% Growth.

New Viltrumite Warriors gain:
Hardened Genome
+5% Combat Strength.

Do NOT grant the larger Total Quarantine recovery bonus.

==================================================
OPTIONAL FOLLOW-UP EVENT
CONCEAL THE EXTINCTION
==================================================

Implement if event UI architecture permits cleanly.

Trigger:
3 turns after the Scourge outbreak.

EVENT TEXT:

"The galaxy must not know how few Viltrumites remain. If subject worlds discover the truth, rebellion will spread faster than the virus itself."

CHOICE A:
MAINTAIN THE ILLUSION

Pay Gold approximately equal to two turns of current empire Gold income.

Minimum Standard-speed cost:
500 Gold.

For 20 turns:
+25% Spy Defense
+10% City Combat Strength

Avoid an additional diplomatic collapse.

CHOICE B:
FEAR REQUIRES A DEMONSTRATION

All known civilizations gain an additional negative diplomatic modifier toward Viltrum.

Viltrum receives:
Free Great General in capital.
Surviving Viltrumites gain +10 XP.
Imperial Momentum activates for 5 turns.

Spawn:
2 Rebel/Barbarian military units near Viltrum's least-defended occupied/non-core city.

Use deterministic placement and do not spawn in invalid tiles.

If custom diplomatic modifiers are too unstable with CP, document that clearly and implement the rest without introducing unstable DLL assumptions.

==================================================
AI BEHAVIOR
==================================================

Target personality roughly:

Offense: 10
Defense: 7
City Defense: 7
Expansion: 9
Military Training: 10
Science: 7
Production: 9
Gold: 6
Culture: 3
Diplomacy: 2
Wonder: 2
Air: 8
Nukes: 8
Naval: 5

AI priorities:

- Domination preferred.
- Attack weaker military powers.
- Build Barracks/Armory/Breeding Complex aggressively.
- Maintain conventional units alongside Viltrumites.
- Do NOT spend all Production on Viltrumites.
- Stockpile Gold after Replaceable Parts.
- Become defensive during Total Quarantine.
- Remain extremely aggressive during Continue the Crusade.
- Preserve Last Pureblood/Scourge-Hardened units when possible.

==================================================
DIPLOMACY TEXT
==================================================

Introduction:
"You have mistaken independence for strength. Your world now belongs to Viltrum."

Neutral:
"Speak. The Empire has permitted you a moment of its attention."

Friendly:
"You have demonstrated value. Continue to do so."

Hostile:
"Every day you remain free is an administrative delay."

Declare War:
"Your species has been measured. It has been found unnecessary."

Attacked:
"You have saved us the inconvenience of inventing a justification."

Demand:
"Surrender what has been requested. Refusal will only increase the final cost."

Defeated:
"Viltrum is not a world. It is blood. So long as one of us remains, the Empire remains."

==================================================
DAWN OF MAN TEXT
==================================================

"The Viltrum Empire was built upon a single truth: strength confers the right to rule.

The weak among your own people were purged. The survivors crossed the stars, bringing countless worlds beneath the Viltrumite banner. Their armies broke, their governments surrendered, and their resources sustained an empire that appeared invincible.

Yet something now moves unseen through Viltrumite blood. An enemy too small to strike, too numerous to conquer, and too patient to intimidate.

Grand Regent Thragg, will you build an empire capable of surviving its own extinction? Will the galaxy witness the death of Viltrum—or learn that even a handful of Viltrumites are enough to rule the stars?"

==================================================
CITY LIST
==================================================

Use:

Viltrum
Argall's Reach
Regent's Citadel
Kregg's Bastion
Conquest's Rest
Anissa's Spear
Thula's Vigil
Lucan's March
Vidor Prime
The Gene-Forges
Red Sun Colony
Dominion's Edge
Purity World
Unbroken Sky
Planetbreaker Station
The Regent's Hand
Bloodline Nexus
The Fifty's Refuge
Ascendant World
Last Horizon
Imperial Crucible
Silent Conquest
The Outer Dominion
Argall's Legacy
Throne of Worlds

==================================================
ART ASSETS
==================================================

Concept art has already been created.

Required art slots:

1. Civilization Icon
2. Leader Portrait / Leader Scene
3. Dawn of Man image
4. Dawn of Man map image
5. UA Icon - Blood of Conquest
6. UU Icon - Viltrumite Warrior
7. UB Icon - Viltrumite Breeding Complex
8. Unit flag icon for Viltrumite Warrior
9. Civilization/city flag icon
10. Great Purge event icon if separate art exists
11. Scourge Virus event icon
12. Imperial Momentum icon
13. Scourge-Hardened promotion icon
14. Last Pureblood promotion icon
15. Hardened Genome promotion icon
16. Imperial Conditioning promotion icon
17. Viltrumite Flight promotion icon if needed
18. Planetbreaker promotion icon if needed
19. Relentless Execution promotion icon if needed

The supplied civilization emblem MUST remain the civilization/city identity.

Do not substitute another symbol.

Set up correct Civ V IconTextureAtlases at appropriate sizes.

Typical atlases should include required dimensions such as:
256
128
80
64
45
32
24
as applicable to the specific UI element.

If actual DDS files are not yet present:
- create correct database references/placeholders
- clearly document expected filenames
- do not silently point to unrelated Firaxis art.

==================================================
LEADER / CIVILOPEDIA / STRATEGY
==================================================

Add proper Civilopedia entries for:

- Viltrum Empire
- Thragg
- Blood of Conquest
- Viltrumite Warrior
- Viltrumite Breeding Complex
- Viltrumite Bloodline
- Viltrumite Flight
- Relentless Execution
- Planetbreaker
- Imperial Conditioning
- Imperial Momentum
- Great Purge
- Scourge Virus
- Scourge-Hardened
- Last Pureblood
- Hardened Genome

STRATEGY DESCRIPTION:

Explain clearly that:
- Viltrum is strongest before the Scourge.
- The player should conquer aggressively but not build only Viltrumites.
- Viltrumites are extremely expensive.
- Conventional troops survive the biological catastrophe.
- Breeding Complexes protect population.
- Players should stockpile Gold and defensively position before the Scourge.
- Quarantine is safer.
- Continue the Crusade creates much stronger individual survivors but carries massive risk.

==================================================
SAVE / LOAD REQUIREMENTS
==================================================

Persist at minimum:

- Great Purge triggered flag.
- Great Purge choice.
- Great Purge temporary durations.
- Permanent Purge military bonuses.
- Replaceable Parts research turn.
- Whether Scourge countdown has started.
- Scourge countdown start turn.
- Warning notifications already displayed.
- Scourge outbreak triggered flag.
- Scourge option selected.
- Remaining Quarantine/Dying Empire turns.
- Repopulation recovery turns.
- First-time captured city records.
- Breeding Complex one-time Population reward by city.
- Individual Scourge survivors.
- Survivor promotion status.
- Imperial Momentum remaining turns.
- Follow-up extinction event state.
- Any city/garrison dummy state needed to prevent duplication.

Use stable keys.

Do not assume unit IDs alone can never be reused after death.

If necessary combine player ID/unit ID/creation marker or persist promotions directly and only store data needed for event logic.

==================================================
MULTIPLAYER SAFETY
==================================================

Important:

- Never use math.random for casualty selection.
- Use Game.Rand.
- All gameplay decisions must be synchronized.
- Event choices must not desync clients.
- Avoid asynchronous UI-only state controlling gameplay.
- Do not run gameplay state only inside a local popup context.
- Lua gameplay logic should live in gameplay-safe Lua where practical.
- Popup UI sends the selected result to the synchronized gameplay system.

If multiplayer-safe custom choice synchronization cannot be guaranteed with the existing architecture, document the limitation clearly rather than pretending it works.

==================================================
LOGGING
==================================================

Add a DEBUG constant.

When enabled, log:

[VILTRUM]

Examples:
[VILTRUM] Imperial Momentum activated: 8 turns
[VILTRUM] Captured city already rewarded, ignoring
[VILTRUM] Great Purge triggered
[VILTRUM] Replaceable Parts researched on turn X
[VILTRUM] First Viltrumite created
[VILTRUM] Scourge countdown started
[VILTRUM] Scourge outbreak triggered
[VILTRUM] Total Bloodline units: X
[VILTRUM] Scourge casualties: X
[VILTRUM] Scourge survivors: X
[VILTRUM] Quarantine remaining: X
[VILTRUM] Last Pureblood granted to unit X

Do not spam Lua.log every frame.

==================================================
IMPORTANT EDGE CASES
==================================================

Explicitly protect against:

- Save/reload giving +1 Population again.
- Selling/rebuilding Breeding Complex for infinite Population.
- Repeated city recapture triggering Capital Population.
- Multiple Great Purges.
- Multiple Scourge outbreaks.
- Multiple survivor promotions.
- Scourge deleting ALL units despite minimum survivor rules.
- Destroying civilian/non-Viltrumite units accidentally.
- Nil capital during capture events.
- Capital being captured during the Scourge.
- Zero cities.
- A city at Population 1.
- Newly conquered cities during the event.
- Razed cities.
- Liberated cities.
- Viltrumite upgrades losing Bloodline.
- Last Pureblood upgrades losing promotion.
- Momentum exceeding 18 turns.
- Event duration becoming negative.
- Multiplayer RNG desync.
- Invalid city/unit references after destruction.
- Units on embarked/water/mountain tiles when the event changes state.
- Player elimination.
- Player revival if CP allows it.

==================================================
TEST PLAN
==================================================

After implementation, thoroughly test and report results.

Test at minimum:

1. Start as Viltrum normally.
2. Spawn units with IGE and test Blood of Conquest.
3. Kill military target -> +15 HP.
4. Kill civilian -> no heal.
5. Capture new city -> +1 Capital Pop.
6. Lose and recapture same city -> no second Population.
7. Momentum activates for 8 turns.
8. Second new city extends by 3.
9. Momentum cannot exceed 18.
10. Garrison bonuses appear/disappear correctly.
11. Breeding Complex gives +1 Population exactly once.
12. Selling/rebuilding does not duplicate.
13. Imperial Conditioning granted to trained units.
14. Viltrumite Warrior correctly costs 1300.
15. Viltrumite Strength = 82.
16. Movement = 3.
17. Flight/mountain/coast behavior.
18. 7-tile deployment.
19. March.
20. Relentless Execution only against <50 HP units.
21. Planetbreaker only against <50% city HP.
22. City capture heal = 35.
23. Great Purge triggers exactly once.
24. Both Great Purge choices.
25. Research Replaceable Parts.
26. First Viltrumite starts Scourge countdown.
27. No Viltrumite -> fallback countdown starts after 12 turns.
28. Warning notifications.
29. Quarantine destroys ~80% Bloodline units.
30. Minimum 2 survivor rule.
31. Quarantine Population loss.
32. Breeding Complex protects +1 citizen.
33. Quarantine disables Momentum/capture bonuses.
34. Scourge-Hardened granted only to survivors.
35. Recovery period works.
36. Crusade destroys ~90%.
37. Minimum 1 survivor.
38. Last Pureblood works.
39. Capital capture full-heals Last Pureblood.
40. Crusade city capture reduces crisis by 1 turn.
41. Crisis does not end below zero.
42. Hardened Genome granted only to post-Scourge Viltrumites.
43. Save during every major stage and reload.
44. Verify no state resets.
45. Verify no Lua errors.
46. Verify no SQL/XML database errors.
47. Verify another civilization can play normally with Viltrum present as AI.
48. Verify AI can survive and use the Scourge event.
49. Verify existing civilizations in the repository remain unchanged.
50. Verify Community Patch compatibility.

==================================================
FINAL DELIVERABLE
==================================================

When finished:

1. Summarize every file created or modified.
2. Explain how each mechanic was implemented.
3. Call out any mechanic that required a workaround.
4. Identify anything that Community Patch cannot support exactly.
5. Report all discovered bugs and fixes.
6. Report test results.
7. Do not claim functionality was tested if it was not actually tested.
8. Leave the mod in a clean, loadable state with no obvious database/Lua errors.

The final result should feel like:

"Viltrum is terrifying because each Viltrumite is an enormous investment and an enormous threat — but the Empire knows that eventually almost all of them are going to die."