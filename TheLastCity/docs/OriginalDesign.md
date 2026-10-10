# CODEX TASK: Implement "The Last City" — A Complete Civilization V Survival Civilization

## 1. Your Role

You are an expert Sid Meier's Civilization V: Brave New World mod developer specializing in Community Patch (CP/VP), Lua, XML, SQL, custom gameplay mechanics, and Civilization V UI development.

**Your task is to fully implement a new civilization called "The Last City — Humanity's Final Refuge."**

This must be a complete, playable, sophisticated civilization, not a prototype, pseudocode, or partial implementation.

The civilization should fundamentally transform Civilization V into a single-city survival experience, featuring refugee management, rationing, morale, increasingly dangerous enemy invasions, persistent history, and a dedicated management interface.

**Target environment:**

- Civilization V: Brave New World
- Community Patch v151 (assume CP availability)
- Lua, XML, SQL and standard Civ V mod components
- No ModBuddy dependency
- Pure mod files with a correct `.modinfo` manifest
- Standard, Quick, Epic and Marathon game speeds
- All map sizes, including Huge maps
- Compatible with games containing 22 civilizations and numerous City-States
- Human and AI player support
- Save/load persistence

If working inside an existing Civilization V mod repository, inspect its directory structure, conventions, SQL, Lua architecture, `.modinfo` registration, and existing civilizations before implementing anything.

Create the civilization in an appropriately isolated directory. Avoid modifying unrelated civilizations.

Do not overwrite existing files unnecessarily.

---

# 2. Civilization Identity

**Civilization:** The Last City

**Leader:** The Warden

**Capital:** Last Light

**Unique Ability:** The Final Sanctuary

**Unique Unit:** Last Watch (replaces Spearman)

**Unique Building:** Sanctuary District (replaces Granary)

**Gameplay identity:** One-city survival, attrition, defense, refugee management, and humanitarian decision-making.

**Philosophy:**

"When the world fell, one city refused to die."

The player controls humanity's final sanctuary. Refugees continuously arrive, supplies must be rationed, morale fluctuates, and increasingly dangerous enemies attempt to destroy Last Light.

Every decision should have consequences.

A larger population is not automatically beneficial. Accepting refugees provides labour and expertise but increases supply consumption, housing pressure, and the danger of catastrophic shortages.

The civilization should be powerful at defensive survival but severely limited in conventional expansion and conquest.

Implement the following systems as interconnected mechanics rather than isolated yield bonuses.

---

# 3. Unique Ability — The Final Sanctuary

The civilization is restricted to one permanent city.

### 3.1 Founding Rules

- The player begins with a normal starting Settler.
- The starting Settler may found Last Light.
- Once the capital has been founded, no further Settlers may be trained or purchased.
- Prevent exploits involving captured Settlers, granted Settlers, and other settlement mechanics where supported.
- The civilization must not permanently retain additional conquered cities.
- Investigate CP hooks and DLL events to find the safest implementation of one-city ownership.
- Handle captured capitals, which ordinarily cannot be razed, carefully.
- Prefer preventing city acquisition or providing an appropriate liberation/return mechanism over deleting cities unsafely.
- Do not destroy another civilization's capital through unsupported Lua operations.
- Document any remaining engine limitations.

### 3.2 Defensive Bonuses

Units belonging to The Last City gain +15% Combat Strength while defending within three plots of their capital.

This bonus must not apply to distant offensive conquests.

For every successfully survived Major Siege, Last Light gains +2% City Defense.

Maximum permanent siege-derived City Defense bonus: +30%.

Persist the number of completed major sieges across saves and reloads.

### 3.3 Complete Collapse

The Last City loses through the normal civilization elimination process if Last Light falls and the civilization is eliminated.

Do not implement a second arbitrary game-over state that could bypass normal Civ V victory/defeat handling.

A capital without adequate supplies, morale, or military protection should naturally become vulnerable to invasion.

---

# 4. The Refugee System

This is one of the civilization's central mechanics.

Refugee caravans periodically arrive at Last Light.

Every caravan should have:

- A procedurally selected name or description.
- A population contribution.
- A survivor specialization.
- A Provisions requirement.
- Potential risks or special consequences.
- Multiple player decisions.
- Persistent consequences that can influence later events.

### 4.1 Arrival Timing

On Standard speed, target a refugee arrival approximately every 8–14 turns.

Scale this interval for game speed.

Only begin refugee arrivals once Last Light has been founded.

Avoid generating multiple contradictory refugee events during the same turn.

Use controlled randomized timing rather than an exact repetitive interval.

### 4.2 Refugee Categories

Implement six survivor specializations.

**Engineers**
- Each assigned Engineer provides +3% Production.
- Maximum five assigned Engineers.
- Maximum bonus from Engineers: +15%.

**Scientists**
- Each assigned Scientist provides +3% Science.
- Maximum five assigned Scientists.
- Maximum bonus: +15%.

**Physicians**
- Reduce the probability and severity of disease crises.
- Improve recovery from medical emergencies.
- Maximum five assigned Physicians.

**Veterans**
- Improve military defensive training.
- Provide a modest defensive benefit to Last Watch and other city defenders.
- Maximum five assigned Veterans.

**Farmers**
- Each assigned Farmer generates +2 Provisions per turn.
- Maximum five assigned Farmers.

**Scholars**
- Each assigned Scholar provides +3% Culture.
- Improves Morale recovery during peaceful periods.
- Maximum five assigned Scholars.

Distinguish available experts from assigned experts.

The Sanctuary Council should allow players to assign or unassign specialists, subject to their availability and capacity.

These survivor specializations must not interfere with the normal Civ V specialist system.

Implement them through persistent counters and validated dummy buildings, promotions, or equivalent CP-compatible effects.

### 4.3 Refugee Decisions

Every refugee event should normally offer:

**Accept**
- Gain population.
- Receive relevant refugee expertise.
- Pay Provisions.
- Accept the full associated risk.

**Quarantine**
- Pay a smaller immediate Provisions cost.
- Delay acceptance by several turns.
- Reduce the probability of infectious complications.
- Require appropriate housing or temporary shelter.
- Some caravans may leave if delayed too long.

**Refuse**
- Receive no population or expertise.
- Preserve Provisions.
- Suffer a Morale penalty, typically −10.
- Potentially influence later narrative events.

All consequences must be applied exactly once.

Unavailable options should be clearly disabled or handled safely.

### 4.4 Example Event

**THE ENGINEERS OF ASH**

"A caravan of 38 survivors has reached the gates. Among them are engineers who once maintained the machinery of a fallen industrial settlement."

Accept:
- +2 Population
- +1 available Engineer
- −8 Provisions

Quarantine:
- −4 Provisions
- Delay processing by three turns.
- Reduce disease risk.

Refuse:
- −10 Morale.

Implement multiple narrative events, not just this example.

### 4.5 Refugee Complications

Possible complications:

- Infectious disease
- Smuggling
- Enemy infiltration
- Housing overcrowding
- Political unrest
- Food theft
- Skilled leadership
- Unexpected medical expertise
- A brilliant scientist
- A former military commander
- A survivor group carrying rare supplies

Complications should not all be negative.

Make the event pool varied and allow relevant earlier decisions to influence future outcomes.

### 4.6 Persistent Survivor History

Maintain a persistent record of meaningful refugee decisions.

An accepted group may reappear in a later crisis.

For example, accepting the Engineers of Ash might unlock an engineering solution during a gate failure.

Certain disasters may kill an available specialist or reduce expertise.

Do not allow expert counts to become negative or bonuses to stack indefinitely.

---

# 5. Provisions — The Survival Economy

Implement a completely new virtual resource called **Provisions**.

This is separate from Civilization V's normal Food yield.

Provisions represent stockpiled food, medicine, clean water, fuel, and other essential supplies.

Store the resource in persistent Lua data.

### 5.1 Starting Values

- Starting Provisions: 45
- Initial stockpile capacity: 200
- Initial Morale: 65
- Starting Housing Capacity: 12

These should be configurable in a centralized balancing file.

### 5.2 Provision Production

Initial suggested values:

- Base city production: +4 Provisions per turn.
- Sanctuary District: +2 Provisions per turn.
- Each completed owned Farm: +1 Provision per turn.
- Each completed owned Fishing Boat improvement: +1 Provision per turn.
- Each assigned Refugee Farmer: +2 Provisions per turn.

Additional late-game buildings or projects may increase production or storage.

Calculate eligible improvements efficiently.

Do not scan the entire world every turn when checking improvements near Last Light.

Use owned plot iteration, caching where appropriate, and event-triggered invalidation when possible.

### 5.3 Consumption

Base consumption on:

- Population
- Maintained military units
- Active rationing policy

Suggested formula:

`BaseConsumption = ceil(Population × 0.6 + OwnedMilitaryUnits × 0.4)`

Apply the selected ration multiplier afterward and round up.

Only count valid maintained combat units for the military component. Exclude civilian units and ensure the calculation cannot be exploited through free temporary units.

Scale costs appropriately with game speed where necessary, but preserve sensible per-turn economics.

### 5.4 Rationing Policies

Implement four mutually exclusive policies.

| Policy | Consumption | Morale effect | Growth modifier |
|---|---|---|---|
| Generous | 150% | +0.3 Morale/turn | +15% |
| Standard | 100% | Neutral | Neutral |
| Strict | 75% | −0.4 Morale/turn | −15% |
| Emergency | 50% | −0.9 Morale/turn | −35% |

Accumulate fractional Morale changes internally and apply appropriately.

Use CP-compatible growth modifiers or a verified alternative.

Changing ration policies should have a five-turn cooldown on Standard speed, scaled reasonably by game speed.

Prevent rapidly switching policies to exploit bonuses.

All policies must appear within the Sanctuary Council interface.

### 5.5 Starvation

At zero Provisions:

- Begin a starvation counter.
- Apply progressively increasing Morale penalties.
- Apply Growth penalties.
- After sustained shortages, introduce a controlled probability of population loss.
- Allow medical expertise to mitigate secondary illnesses.
- Reset or recover starvation progression when supply becomes adequate.

Do not instantly destroy the civilization when Provisions reach zero.

Prolonged starvation should create a dangerous downward spiral, not an unavoidable instantaneous defeat.

### 5.6 Stockpile Capacity

Default: 200 Provisions.

Add late-game projects that increase maximum storage by 50–100.

Prevent negative values and stockpiles exceeding capacity.

Display current stockpile, capacity, income, consumption, and projected net change in the UI.

---

# 6. Housing and Overcrowding

Housing is distinct from actual population.

Starting Housing Capacity: 12.

The Sanctuary District increases Housing Capacity by 6.

Additional infrastructure and projects can increase it further.

If population exceeds housing capacity, introduce progressively stronger overcrowding penalties.

Suggested penalties:

- 1–2 above capacity: Minor Morale penalty.
- 3–5 above capacity: Increased disease probability and greater Morale loss.
- 6+ above capacity: Severe unrest and medical risk.

Do not let housing penalties scale without a reasonable cap.

Refugee arrivals should meaningfully interact with housing.

Introduce expansion projects, such as:

- Refugee Barracks
- Expanded Residential Quarter
- Underground Shelter
- Emergency Field Hospital

Each must have an actual Production cost and a meaningful benefit.

---

# 7. Morale — Humanity's Will to Survive

Implement a persistent Morale value from 0 to 100.

Starting Morale: 65.

Morale changes based on:

- Rationing
- Refugee treatment
- Siege victories
- Military casualties
- Starvation
- Overcrowding
- City damage
- Infrastructure destruction
- Medical disasters
- Crisis decisions
- Specialization bonuses

### Morale Thresholds

**80–100: United**
- +10% Production
- Improved defensive resolve

**60–79: Stable**
- No penalties

**40–59: Anxious**
- −5% Production

**20–39: Unrest**
- −15% Production
- Possibility of unrest events

**0–19: Breaking Point**
- −30% Production
- Higher desertion and riot risk

Morale must influence the actual game, not merely exist as a number on a UI.

Use validated dummy buildings or other proven methods to apply yield changes.

Ensure bonuses refresh when Morale crosses thresholds.

Prevent duplicate dummy buildings and runaway stacking.

Implement gradual recovery when conditions improve.

Keep Morale logically distinct from ordinary Civ V Happiness.

---

# 8. The Endless Siege — Enemy Invasion System

This is the civilization's signature military mechanic.

Last Light must periodically defend itself against increasingly dangerous waves of enemies.

### 8.1 Wave Scheduling

Suggested Standard-speed baseline:

- First wave: approximately turn 24
- Subsequent waves: approximately every 20–24 turns
- Later eras may shorten the interval.
- Each fifth wave is a Major Siege.

Scale all scheduling by game speed.

Make timing configurable.

The player should receive a warning approximately three turns before an invasion.

### 8.2 Three Phases

**Phase 1 — Warning**
- Notify the player of an approaching attack.
- Display estimated threat strength.
- Allow defensive preparations.
- Update the Sanctuary Council's invasion countdown.

**Phase 2 — Assault**
- Spawn a valid hostile force outside the immediate capital territory.
- Select units appropriate for the current era and threat level.
- Include varied roles: melee attackers, ranged support, siege units, and mobile raiders.
- Attempt to direct pressure toward Last Light.

**Phase 3 — Aftermath**
- Detect when the relevant invading force has been defeated or the encounter otherwise resolves.
- Award appropriate survival rewards.
- Increase siege history counters.
- Apply Morale changes.
- Schedule the next wave.

### 8.3 Enemy Evolution

**Ancient — Starving Scavengers**
- Basic attackers.
- Focus on pillaging nearby infrastructure.

**Classical — Marauder Warbands**
- More coordinated melee and ranged attacks.

**Medieval — Siege Cults**
- Siege engines capable of seriously threatening city defences.

**Renaissance — The Plaguebound**
- Combat and pillaging can create disease-related consequences.

**Industrial — Iron Reavers**
- Stronger units and infrastructure-destroying attacks.

**Modern — The Remnants**
- Combined-arms military assaults.

**Atomic and beyond — The Harbingers**
- Highly dangerous elite troops and major boss invasions.

These may use appropriate existing unit types with special promotions or custom definitions.

Do not require new external unit models for the mechanics to function.

### 8.4 Threat Scaling

Enemy strength should depend on:

1. Current world/game era.
2. Total waves survived.
3. Current difficulty.
4. A limited adjustment based on Last Light's military strength.

Do not scale enemy armies so aggressively that upgrades become meaningless.

Do not allow intentionally deleting units to completely trivialize the adaptive difficulty.

Use bounded threat scaling.

Consider the player's military technology and era availability when selecting actual unit definitions.

### 8.5 Spawning Requirements

Use verified Civ V/CP-compatible unit creation.

When generating invasion units:

- Select passable plots.
- Respect land and naval domains.
- Avoid occupied plots.
- Avoid impassable terrain.
- Avoid invalid ice and mountain spawns.
- Avoid spawning directly inside cities.
- Avoid overwhelming other civilizations merely because they occupy the same region.
- Handle coastal and island capitals.
- Handle maps with limited available space.
- Retry alternative valid positions if necessary.
- Never enter an infinite spawn loop.

For island maps, use relevant naval invasion compositions.

Do not spawn landlocked melee armies that can never reach the target.

Tag units belonging to each wave, using persistent identifiers.

Use unit ownership and IDs safely, including cases where units are killed, upgraded, captured, or IDs are reused.

Investigate the actual limitations of barbarian AI.

Do not claim that scripted units can execute custom tactical AI unless the selected API supports it.

Use the best reliable CP-compatible alternative.

Implement stuck-wave detection and an appropriate timeout or retreat resolution.

### 8.6 Major Sieges

Every fifth wave triggers a Major Siege.

Major Sieges should:

- Have increased total threat.
- Introduce a named commander or boss.
- Feature specialized enemies.
- Trigger custom notifications and aftermath events.
- Award +2% permanent capital defense, subject to the +30% cap.

Victory must be awarded only for genuinely resolved sieges, not from failing to spawn enemies.

### 8.7 Example Boss — The Harrower

A powerful commander with exceptional siege capabilities.

The Harrower:

- Is stronger than normal enemies of the same era.
- Provides a combat bonus to nearby invasion troops.
- Is especially dangerous to city defenses.
- Provides a significant Morale reward when defeated.

Implement the Harrower as a reusable special unit or dynamically promoted commander, depending on proven CP capabilities.

Create additional boss variations if feasible.

---

# 9. Unique Unit — Last Watch

**Replaces:** Spearman

The Last Watch is the elite protector of humanity's final sanctuary.

### Abilities

- Retains appropriate Spearman functionality.
- Receives +15% Combat Strength while defending within three plots of Last Light.
- Gains +3% defensive strength for each Major Siege survived.
- Maximum five veteran siege stacks (+15%).
- Unique defensive benefits persist when upgraded to later unit types.
- Does not receive excessive benefits while attacking distant cities.

Track veteran status carefully.

Determine whether individual Last Watch units were present during an actual siege before granting their veteran progression.

Do not grant unlimited bonuses from merely creating new Last Watch units after several sieges.

Implement promotions and upgrade persistence appropriately.

Ensure combat text and Civilopedia descriptions reflect actual effects.

Avoid accidentally doubling the civilization-wide +15% defensive bonus when computing the unit-specific bonus unless this is explicitly chosen and balanced. Treat the Last Watch's local bonus as its signature application of the UA defensive effect, not an extra duplicate copy.

---

# 10. Unique Building — Sanctuary District

**Replaces:** Granary

Retain the underlying Granary functionality.

Additional effects:

- +6 Housing Capacity.
- +2 Provisions per turn.
- Helps process refugee arrivals.
- Unlocks further Sanctuary infrastructure projects.

Ensure it has correct prerequisite technology, Production cost, building class, Civilopedia data, icons, and AI compatibility.

Do not remove normal Granary mechanics accidentally.

---

# 11. Crisis and Narrative Event System

Implement a diverse system of weighted crises.

Events must feel like consequences of living in the last surviving sanctuary.

Initial event categories:

1. Infectious outbreak
2. The gates are breaking
3. Food store theft
4. Military desertion
5. Refugee protests
6. A missing scientist
7. Broken water infrastructure
8. A desperate caravan
9. The last functioning hospital
10. Internal political conspiracy
11. A heroic act by the Last Watch
12. Discovery of abandoned supplies
13. The sudden loss of an expert
14. The rebuilding of a damaged residential district
15. A child born during a siege

Give events multiple choices and gameplay consequences.

For each event, implement:

- Trigger conditions
- Relevant narrative text
- Affected resources
- Available choices
- Resolution code
- Persistent consequences where appropriate

Events should be state-driven, rather than purely random spam.

For example, food theft should be more likely when the population is starving, and disease outbreaks should be more likely when overcrowding is severe.

Use cooldowns, event weighting, and sensible frequency limits.

**Example: The Gates Are Breaking**

Choice A:
Recruit emergency militia.
Lose one Population.
Spawn a temporary defensive unit.
Gain temporary City Defense.

Choice B:
Reinforce the gates.
Spend 20 Provisions and an appropriately implemented Production cost.
Restore defensive capabilities.

Choice C:
Abandon the outer wall.
Preserve resources.
Lose 15 Morale.
Receive a temporary City Defense penalty.

Use legitimate game-state modifications. Do not invent a nonexistent direct Production-spending API; implement costs through a safe verified mechanism.

---

# 12. Sanctuary Council — Dedicated Gameplay UI

This civilization MUST have a custom Lua-based management interface.

Do not replace this requirement with ordinary notifications.

Create an accessible button that opens a dedicated Sanctuary Council panel.

The panel should feel like a survival game's management dashboard integrated into Civ V.

### Main Dashboard

Display:

- Population
- Housing Capacity
- Current Provisions
- Maximum Provisions
- Provision production
- Provision consumption
- Net Provisions per turn
- Morale
- Morale status
- Rationing policy
- Next invasion countdown
- Current invasion wave
- Completed major sieges
- Available and assigned refugee expertise
- Active crises

### Refugee Management

Show:

- Pending refugee caravans
- Refugee group descriptions
- Their skill categories
- Associated risks
- Accept / Quarantine / Refuse decisions
- Current specialist assignments
- Available assignment capacity

### Rationing Panel

Allow selection between:

- Generous
- Standard
- Strict
- Emergency

Display projected resource and Morale consequences before confirming.

### Siege History

Track:

- Total invasions survived
- Major Sieges survived
- Bosses defeated
- Important losses
- Major historical events
- Current defensive legacy bonuses

### Crisis Log

Maintain an accessible history of recent meaningful events.

### Performance Requirements

The UI must be event-driven where possible.

**Do not implement 0.1-second polling loops.**

Do not continuously scan map plots, units, and city data just to refresh the interface.

Avoid the performance regressions associated with frequent UI polling.

Refresh when:

- A relevant player turn begins.
- Resources change.
- A policy is selected.
- A refugee decision is made.
- A siege state changes.
- The panel is opened or reopened.

Use safe context-visibility management for gameplay modes.

Do not leave the interface over unrelated diplomacy, city, or major modal views.

Do not register duplicate handlers on reload.

Only display this civilization-specific UI to the relevant human player.

---

# 13. The Dawn Initiative — Narrative Endgame

Implement a unique late-game objective.

**Name:** The Dawn Initiative

**Narrative description:**

"Humanity has survived. Now it must learn to live again."

### Unlock Conditions

- Reach the Atomic Era or an appropriate late-game technological prerequisite.
- Survive at least 12 invasions.
- Maintain at least 55 Morale.
- Accumulate at least 150 Provisions.
- Complete a substantial unique Production investment.

Suggested Standard-speed base Production cost: 900, subject to balancing.

### The Final Night

Completing the Dawn Initiative triggers a final defensive sequence.

This should be the most dangerous invasion encountered during the game.

It may include:

- Several coordinated enemy groups.
- A named final commander.
- Siege equipment.
- Elite attackers.
- A special warning event.

If Last Light survives, display the narrative achievement:

**HUMANITY ENDURES**

Present an appropriate aftermath screen or event.

Allow the player to continue in Endless Survival Mode.

Do not falsely register a normal Science or Culture Victory.

Investigate whether a proper custom victory is viable with the available CP/DLL environment.

If it is not reliable, implement a narrative completion and document the limitation.

Never jeopardize ordinary game stability by forcing unsupported victory logic.

---

# 14. AI Support

The Last City must remain functional under AI control.

Do not assume all special systems will be controlled by a human.

For AI-controlled Last City:

- Automatically resolve refugee events.
- Evaluate housing and Provisions.
- Change rationing policies intelligently.
- Prioritize defensive infrastructure.
- Construct Last Watch units when threats are approaching.
- Avoid excessive offensive warfare.
- Avoid leaving the capital undefended.
- Assign useful refugee specialists.
- Respond to starvation and low Morale.
- Prioritize survival over ordinary expansion.

AI decisions should not require any Lua popup.

Human popups must never block AI turns.

Prevent AI from repeatedly attempting to build prohibited Settlers or acquire impossible cities.

The mod should also remain stable if The Last City is an opponent in a normal multi-civilization game.

---

# 15. Game-Speed and Difficulty Scaling

All time-based systems should respect game speed.

This includes:

- Refugee arrival frequency
- Invasion frequency
- Warning duration
- Temporary buff duration
- Crisis cooldowns
- Ration policy cooldown
- Project costs
- Relevant resource costs

Use actual GameSpeed data when available.

Verify property names against the game's database rather than assuming them.

If necessary, define explicit fallback multipliers, approximately:

- Quick: 0.67
- Standard: 1.0
- Epic: 1.5
- Marathon: 3.0

Apply the correct multiplier to the correct class of values.

Do not automatically scale every per-turn resource quantity just because the game is Marathon.

Ensure economic costs and accumulated production remain reasonably balanced.

Difficulty should modify enemy strength and crisis pressure without creating unavoidable death spirals.

Centralize balancing values in a dedicated configuration module.

---

# 16. Persistence and Save Compatibility

All important mechanics must survive saving and reloading.

Persist at minimum:

- Provisions
- Stockpile capacity
- Morale and fractional changes
- Housing capacity modifiers
- Rationing policy
- Policy cooldown
- Starvation progression
- Refugee expert availability and assignments
- Refugee arrivals
- Pending quarantine decisions
- Major refugee history
- Active crises
- Active invasion state
- Current wave number
- Wave-unit records
- Invasion countdown
- Siege victories
- Veteran unit progression
- Permanent defensive bonuses
- Dawn Initiative progression
- Narrative history

Use appropriate persistent Civ V save data facilities supported by the target environment.

Implement schema versioning and sensible defaults.

Do not reset resources simply because the UI reloads.

Do not repeat completed event rewards after loading.

Avoid unnecessary serialization every frame.

Existing saves must fail gracefully when introduced to a newer version of the mod, subject to normal Civ V mod compatibility limitations.

---

# 17. Art and Presentation

Create or prepare a complete set of Civilization V assets.

Required assets include:

- Civilization icon
- Leader portrait
- Dawn of Man background
- Dawn of Man map
- Unique Ability icon
- Last Watch unit icon
- Last Watch unit flag icon
- Sanctuary District building icon
- Appropriate Alpha icons
- Necessary DDS icon atlas definitions
- Civilopedia imagery
- Optional UI illustrations for refugee events and major invasions

Visual direction:

Dark fantasy, post-apocalyptic humanity, huge fortified city walls, desperate refugees, exhausted defenders, firelight against darkness, and a faint sense of hope.

The Warden should appear as humanity's last protector, not as a conventional imperial conqueror.

Use appropriate Civilization V art dimensions and DDS formats.

You may generate original art/assets if the available tools support it.

If art generation is unavailable, implement the gameplay with valid existing fallback assets and provide a specific missing-art manifest.

Do not reference nonexistent DDS files or invent completed assets.

Include functional art atlas references and unit flags.

---

# 18. Civilopedia and Text

Provide complete English localization for:

- Civilization
- Leader
- Unique Ability
- Unique Unit
- Unique Building
- Dawn of Man
- Strategy
- History
- Gameplay mechanics
- Survivor types
- Major events
- Invasion alerts
- The Dawn Initiative

Every gameplay description should reflect actual implemented effects.

Include appropriate diplomacy greetings and responses.

Suggested Dawn of Man text:

"The world has fallen.

Great nations have vanished. Their cities are silent, their armies scattered, and their histories reduced to ash.

Yet behind the walls of Last Light, humanity still breathes.

They come to you hungry, wounded, and afraid. Every soul at your gates carries the memory of a world that no longer exists.

You are the Warden.

You will decide who receives shelter, who receives food, and who must stand upon the walls when darkness comes.

The enemies of humanity will return. The stores will empty. Your people will despair.

But so long as the light remains, humanity is not yet lost."

---

# 19. Architecture and File Organization

Use a clean modular structure similar to:

```text
TheLastCity/
  TheLastCity.modinfo
  README.md
  SQL/
    Civilization.sql
    Units.sql
    Buildings.sql
    Promotions.sql
    Localization.sql
    ArtDefines.sql
  Lua/
    LastCity_Config.lua
    LastCity_Core.lua
    LastCity_Persistence.lua
    LastCity_Refugees.lua
    LastCity_Provisions.lua
    LastCity_Morale.lua
    LastCity_Housing.lua
    LastCity_Invasions.lua
    LastCity_Crises.lua
    LastCity_AI.lua
    LastCity_Dawn.lua
  UI/
    LastCity_Council.lua
    LastCity_Council.xml
  Art/
    ...
```

This structure is illustrative. Adjust it based on established repo conventions and actual Civ V UI requirements.

Do not blindly load every Lua file in the same way.

Inspect which scripts belong in gameplay contexts and which belong in UI contexts.

Ensure correct `.modinfo` registration and load order.

Avoid duplicate event initialization.

Use namespaced variables, database IDs, and save keys to prevent conflicts with other mods.

---

# 20. Validation and Testing

After implementing the civilization, conduct a static code review and as much automated validation as possible.

Verify the following.

### Civilization Setup
- Civilization appears in setup.
- Leader displays correctly.
- Capital name is correct.
- Starting Settler works.
- Subsequent Settlers are prohibited.
- Normal civilizations remain unaffected.

### Refugees
- Arrivals are scheduled.
- Decisions produce correct rewards.
- Quarantine persists.
- Specialists do not exceed caps.
- Rejected caravans do not grant rewards.
- Save/reload does not duplicate population.

### Provisions
- Resource production matches improvements and assignments.
- Consumption matches population, troops, and rationing.
- Stockpile values cannot become negative.
- Starvation progresses appropriately.
- Changing policies respects cooldowns.

### Morale
- Threshold effects are applied.
- Morale remains within 0–100.
- Dummy buildings do not stack incorrectly.
- Policies and crises affect Morale correctly.

### Invasions
- Wave timing scales properly.
- Units spawn on valid plots.
- Invasions work on islands.
- Major Sieges occur every fifth wave.
- Bosses receive correct combat effects.
- Rewards cannot be claimed twice.
- Unit IDs are tracked safely.
- Failed spawns do not grant victories.
- Invasions do not freeze turn processing.

### Unique Components
- Last Watch replaces Spearman correctly.
- Veteran bonuses respect the cap.
- Promotions survive valid upgrade paths.
- Sanctuary District retains Granary functionality.

### UI
- Council opens and closes.
- Displayed resources update correctly.
- Decisions modify real game state.
- UI does not appear during unrelated major views.
- No excessive polling.
- No duplicated handlers.

### AI
- AI makes refugee decisions.
- AI handles starvation.
- AI prepares for invasions.
- AI turns do not get stuck.

### Save/Load
- All important values persist.
- Pending events survive reloads.
- Crises and sieges do not retrigger incorrectly.
- UI reloads without resetting game state.

### Performance
- Avoid full-map per-turn scans.
- Avoid high-frequency timers.
- Avoid redundant database queries.
- Avoid expensive iteration over all players and units unless necessary.
- Maintain performance in Huge games.

---

# 21. Community Patch Compatibility

Assume Community Patch v151.

Before using any CP-specific Lua hook:

1. Verify that the hook actually exists.
2. Confirm its parameters.
3. Confirm whether it can veto an action or only observe it.
4. Confirm its execution context.
5. Check the supported return type.
6. Confirm whether a standard Civ V alternative is required.

Do not invent API calls or event names.

Do not assume UI contexts have direct access to gameplay-state functions that belong elsewhere.

Use properly registered communication between gameplay scripts and the UI.

Avoid unsupported city deletion, DLL calls, or game-state manipulation.

Where a requested mechanic cannot be implemented exactly, implement the closest robust equivalent and document the compromise.

Favor a fully working mod over an ambitious but fragile system.

---

# 22. Implementation Expectations

**Do not stop after writing a proposal. Implement the files.**

Work through the complete implementation in logical stages:

1. Inspect repository and dependencies.
2. Register civilization, leader, UA, UU and UB.
3. Implement core persistent state and configuration.
4. Implement Provisions and Housing.
5. Implement Morale and rationing.
6. Implement refugee decisions and expertise.
7. Implement invasion scheduling, spawning and resolution.
8. Implement major bosses and siege bonuses.
9. Implement crisis events.
10. Implement Sanctuary Council.
11. Implement AI decision-making.
12. Implement Dawn Initiative.
13. Integrate art, localization and Civilopedia.
14. Validate SQL/Lua/XML, manifests, and persistence.
15. Review edge cases and optimize performance.
16. Write comprehensive documentation.

Do not mark a feature as implemented unless it is connected to the game and produces its intended effects.

Avoid placeholder implementations that only print debug messages.

Use feature flags where appropriate to keep incomplete advanced systems from breaking the rest of the civilization.

Keep configurable values centralized.

If coding time or environment limitations prevent completion of a feature, explicitly report its status instead of claiming everything works.

---

# 23. Deliverables

Provide:

1. Complete source files for the civilization.
2. Correct `.modinfo` packaging.
3. Implemented gameplay systems.
4. Working Sanctuary Council UI.
5. All required localization.
6. Art assets or verified fallback assets.
7. A comprehensive README.
8. A testing checklist.
9. A balance summary.
10. A list of engine limitations and implementation compromises.

The README should explain:

- Civilization background
- Unique Ability
- Unique Unit
- Unique Building
- Refugee system
- Provisions and rationing
- Morale
- Housing
- Invasion system
- Major Sieges
- Endgame
- Recommended strategy
- Difficulty settings
- Known limitations
- Installation instructions

At the end of implementation, provide a concise report separating:

- Fully implemented mechanics
- Partially implemented mechanics
- Untested mechanics
- Known issues
- Recommended future improvements

Do not claim in-game testing was performed if only static validation was possible.

## FINAL DESIGN DIRECTIVE

The Last City should not play like a normal one-city Civilization V civilization with occasional barbarian attacks.

It should play like a fully realized survival strategy game.

The player's greatest enemies should be scarcity, attrition, desperation, and the difficult decisions required to keep humanity alive.

Every refugee should matter.

Every soldier should matter.

Every Provisions shortage should matter.

Every invasion should become a meaningful story.

The civilization should gradually transform from a desperate refugee settlement into an enormous fortified sanctuary, carrying the memories of everything it has endured.

**Above all, the player should feel that humanity's survival is entirely in their hands.**

Implement The Last City now.