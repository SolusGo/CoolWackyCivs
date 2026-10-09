HAHA YESSS. This might genuinely become one of your most ambitious Civ V mods yet. 🤣

I'm giving Codex the full implementation specification, not just a civilization description. The goal is to make it build actual working systems for civil wars, governors, succession, military defections, political reforms, and historical records.

I've also included instructions specifically for Community Patch v151, no ModBuddy, AI support, save compatibility, performance, and asset generation.

# CODEX MASTER PROMPT — CIVILIZATION V: THE SHATTERED EMPIRE

## YOUR MISSION

Create a complete, playable, highly ambitious Civilization V: Brave New World civilization mod called **The Shattered Empire**.

**Leader:** The Last Emperor\
**Capital:** Aeternum\
**Unique Ability:** The Weight of an Empire\
**Unique Unit:** Imperial Legion (replaces Warrior)\
**Unique Building:** Provincial Governor's Palace (replaces Monument)

The mod MUST be designed for **Civilization V: Brave New World with Community Patch (CP) v151**.

Use Lua, XML, SQL, custom UI contexts, and CP-supported hooks. Do not require ModBuddy or a custom DLL.

If an existing mod project is present in the working directory, inspect its structure first and integrate cleanly. Otherwise create a standalone mod folder containing everything necessary to install the civilization.

**This is an implementation task, not merely a design exercise. Create the actual files, scripts, definitions, UI, and documentation.**

The civilization's central philosophy:

> "Conquering the world was never the difficult part. Keeping it was."

The Shattered Empire begins unusually powerful but becomes increasingly difficult to govern. Its provincial Governors can become disloyal, its armies can defect, and succession crises can trigger catastrophic civil wars.

However, this must NOT be a civilization whose collapse is predetermined.

A skilled player should be able to maintain a stable empire indefinitely through intelligent political and military decisions.

Every campaign should tell a different story.

---

# 1. CORE DESIGN PRINCIPLES

Implement the following interconnected systems:

1. Imperial Authority
2. Procedurally generated Provincial Governors
3. Provincial Loyalty and Ambition
4. Provincial Demands and Events
5. Provincial Rebellions
6. Empire-wide Civil Wars
7. Military Allegiance and Defections
8. Imperial Government Reforms
9. Succession Crises and Dynasty History
10. Imperial Restoration
11. Persistent Historical Chronicle
12. AI decision-making
13. Custom Imperial Administration UI

All systems must interact meaningfully.

For example:

- Expansion increases administrative strain.
- Administrative strain damages Loyalty.
- Falling Loyalty increases rebellion risk.
- Ambitious Governors can exploit weakness.
- Military units develop loyalty toward their home provinces.
- Rebellions can trigger military defections.
- Civil wars weaken Imperial Authority.
- Successful reconquest can restore legitimacy.
- Political reforms change how these pressures operate.

Do not implement these as isolated bonuses.

## Technical requirements

- Assume CP v151, but inspect actual available APIs and existing project patterns.
- Do not invent Lua hooks or nonexistent DLL functions.
- Prefer verified `GameEvents` and `Events` hooks.
- Use persistent save data for gameplay state.
- Make game-state changes in gameplay contexts, not UI scripts.
- Avoid per-frame polling or frequent timers.
- Respect BNW's existing game systems and victory conditions.
- Support Quick, Standard, Epic and Marathon speeds.
- Support both human-controlled and AI-controlled civilizations.
- Ensure repeated initialization, reloads and turn events do not duplicate effects.
- Use deterministic event handling where practical.
- Avoid unbounded computations on Huge maps.
- Use modular, readable code and structured logging.

A crucial limitation: do not assume that Lua can dynamically create a fully independent major civilization or a new City-State during an ongoing game.

If genuine independent factions cannot be supported safely through the existing CP APIs, simulate them using persistent rebel factions, rebel military units, provincial resistance, local administration restrictions, and event-driven diplomacy.

Preserve the intended political gameplay rather than implementing dangerous engine workarounds.

---

# 2. STARTING EMPIRE

The Shattered Empire begins with three cities:

- Aeternum — Capital, 2 Population.
- Province I — 1 Population.
- Province II — 1 Population.

The provinces should receive procedurally generated city Governors.

Starting Imperial Authority: **82/100**.

The player starts with an Imperial Legion instead of the normal Warrior.

Do not grant free Workers, technologies, or extra buildings other than those normally supplied by game difficulty, traits or handicap settings.

## Placement rules

Implement a safe initial settlement system.

When the initial capital has been founded, attempt to establish two provincial cities using valid plots.

Requirements:

- Respect terrain restrictions.
- Respect minimum city distance.
- Avoid rival starting locations and occupied plots.
- Prefer workable land with reasonable resources.
- Avoid placing cities on impossible terrain.
- Respect map boundaries and wrapping.
- Avoid creating extra capital cities.
- Never create duplicate provincial cities upon reload.

If placing a complete city through verified APIs is unsafe or impossible, use a reliable fallback that grants Settlers for any uncreated provinces.

Never grant both a city and Settler for the same provincial entitlement.

The starting advantage must be balanced by early administrative maintenance, territorial exposure, and political obligations.

The empire should feel powerful, not automatically unbeatable.

---

# 3. UNIQUE ABILITY — THE WEIGHT OF AN EMPIRE

The civilization operates under Imperial Authority, a value between 0 and 100.

Authority represents political legitimacy and central government control.

| Authority | Condition         |
| --------- | ----------------- |
| 80–100    | Golden Empire     |
| 60–79     | Stable Empire     |
| 40–59     | Strained Empire   |
| 20–39     | Fractured Empire  |
| 0–19      | Imperial Collapse |

These states modify the empire's internal political mechanics.

At high Authority, Governors are less prone to disloyalty and provincial administration is more efficient.

At low Authority, provincial discontent increases, military allegiance becomes less reliable, and coordinated rebellion becomes more likely.

## Sources of Authority

Suggested Standard-speed starting balance, subject to playtesting:

**Positive events**

- Winning a major defensive battle: +1, with a per-turn cap.
- Capturing an enemy city: +4.
- Completing a provincial demand: +2.
- Successfully suppressing a provincial rebellion: +5.
- Defeating a major rebel claimant: +10.
- Completing a peaceful succession: +5.

**Negative events**

- Losing a city: −8.
- Losing the capital: −20.
- A Governor formally rebelling: −6.
- A major succession crisis: −10.
- Prolonged unsuccessful warfare: periodic penalty.
- Overextension: periodic penalty based on empire size and administrative capacity.

Implement sensible cooldowns and caps so individual actions cannot be exploited for unlimited Authority.

For example, repeatedly capturing and liberating the same settlement must not generate infinite legitimacy.

Authority must never drop below 0 or exceed 100.

A low Authority score must not automatically eliminate the player.

## Administrative Overextension

Expansion adds political pressure.

Use a system incorporating:

- Number of cities.
- Distance from capital.
- Governor personalities.
- Local Happiness conditions.
- War duration.
- Administrative reforms.

Avoid arbitrary punishment for merely having three starting cities.

The player should start feeling serious administrative pressure after sustained expansion.

Do not punish large empires so heavily that conquest becomes objectively nonviable.

---

# 4. PROCEDURAL GOVERNOR SYSTEM

Every non-capital city must have a Governor.

Each Governor contains persistent data:

- Unique identifier.
- Name.
- Assigned city identifier.
- Archetype.
- Loyalty (0–100).
- Ambition (0–100).
- Prestige.
- Appointment turn.
- Political history.
- Relationship with the Emperor.
- Rebel status.
- Relevant outstanding demands.

Governors should have names generated from appropriate imperial-themed name pools.

Avoid rerolling Governor characteristics on every reload.

## Governor Archetypes

### Loyalist

- Easier Loyalty maintenance.
- Lower Ambition growth.
- Modest economic bonuses.

### Militarist

- Improves provincial military Production.
- Gains Prestige from military victories.
- Greater risk of military coups.

### Merchant

- Improves provincial Gold generation.
- Prefers trade connections and economic prosperity.
- Becomes disloyal if economically restricted.

### Populist

- Improves Growth and local Happiness-related outcomes.
- Benefits from prosperous populations.
- Greater propensity toward independence.

### Ambitious

- Improves provincial Production.
- Accumulates Prestige more quickly.
- Becomes increasingly dangerous when highly influential.

## Starting Governor statistics

Suggested:

- Loyalty: 65–85.
- Ambition: 15–40.
- Prestige: 0–10.

Governors should have different strengths and weaknesses.

An Ambitious Governor should not automatically be disloyal.

An ambitious but loyal Governor can be extremely useful.

## Governor Prestige

Prestige increases from:

- Provincial prosperity.
- Military success.
- Population growth.
- Administrative accomplishments.
- Completing important provincial projects.

Prestige influences a Governor's political power and rebellion potential.

A powerful Governor with extremely high Loyalty should remain a valuable ally.

---

# 5. PROVINCIAL LOYALTY

Every province has Loyalty from 0 to 100.

Suggested Standard-speed periodic changes per five turns:

| Circumstance                  | Loyalty |
| ----------------------------- | ------- |
| Appropriate military garrison | +3      |
| Trade connection to capital   | +2      |
| Governor's Palace             | +2      |
| Provincial autonomy charter   | +3      |
| Great distance from capital   | −2      |
| Ungarrisoned province         | −2      |
| Governor Ambition above 70    | −3      |
| Negative empire Happiness     | −4      |
| Prolonged war                 | −3      |

Routine Loyalty movement should be capped to approximately ±8 per update.

Special events may bypass that cap.

Loyalty should not collapse merely because the city is far away.

Implement counterplay through:

- Garrisoning troops.
- Building administrative infrastructure.
- Completing Governor requests.
- Bribing Governors.
- Granting autonomy.
- Appointing more loyal Governors.
- Reducing war exhaustion.
- Increasing Imperial Authority.
- Adopting political reforms.

Use clear, deterministic calculations that the UI can explain to players.

The administration screen should show WHY Loyalty is increasing or decreasing.

---

# 6. GOVERNOR DEMANDS AND POLITICAL EVENTS

Governors periodically make requests.

Examples:

- Construct two Farms.
- Improve a strategic resource.
- Maintain a garrison.
- Establish a trade connection.
- Build a defensive structure.
- Eliminate a nearby Barbarian threat.
- Maintain peace for several turns.
- Increase provincial population.
- Provide financial assistance.
- Declare war against a specified rival, when politically appropriate.

All requests must be feasible.

Do not generate requests requiring nonexistent technologies, unavailable resources, unreachable enemies, or impossible improvements.

## Player decisions

Each political event should offer meaningful choices.

Example:

**Governor Lucius Draven demands military autonomy.**

Options:

1. Grant military autonomy.
   - +15 Loyalty.
   - +12 Ambition.
   - The Governor gains increased military influence.
2. Offer financial compensation.
   - Pay Gold.
   - +12 Loyalty.
3. Refuse the demand.
   - −12 Loyalty.
   - +10 Ambition.
4. Replace the Governor.
   - Pay an Authority cost.
   - Generate a new Governor.
   - Risk local unrest.

Gold payments must scale with game speed and economic circumstances.

The player should not encounter overwhelming popup spam.

Use an event queue or notification approach with clear deadlines.

AI rulers must evaluate demands automatically.

---

# 7. REBELLION SYSTEM

Provincial rebellions must develop in stages.

## Stage I — Discontent

Triggered when Loyalty falls below 45.

Effects:

- Small provincial economic penalties.
- Increased demand frequency.
- Warning in the Administration UI.

## Stage II — Defiance

Triggered when Loyalty falls below 25.

Effects:

- Reduced provincial Gold contribution.
- Increased resistance pressure.
- Greater chance of military unrest.
- Strong warning to the player.

## Stage III — Armed Revolt

Triggered when Loyalty remains critically low through two consecutive eligible checks.

Effects:

- Rebel units emerge near the province.
- Provincial unrest becomes active.
- Local military units may defect.
- Provincial yields are substantially reduced.
- The Governor is marked as a rebel leader.

## Stage IV — Secession Crisis

If a rebellion remains unresolved:

- It develops into a sustained regional conflict.
- Surrounding provinces receive additional disloyalty pressure.
- Rebel armies may receive reinforcement.
- The rebel Governor can demand independence or autonomy.

## Stage V — War of the Crowns

Multiple provinces can coordinate a major civil war.

Suggested conditions:

- Authority below 30.
- At least three provinces in severe unrest.
- At least one Governor with high Ambition.
- No existing active major civil war.

A prominent Governor declares himself the rightful Emperor.

Other disloyal Governors may join him.

The rebellion becomes a geographically coherent conflict rather than a collection of random Barbarian spawns.

## Rebel military simulation

Implement safe rebel factions within normal Civ V engine constraints.

Rebel units should have:

- A persistent faction identifier.
- A rebel Governor association.
- An originating province.
- Appropriate era-based unit types.
- A limited reinforcement budget.
- Clear suppression conditions.

Rebel military strength should scale with:

- Population of rebellious provinces.
- Local military infrastructure.
- Governor Prestige.
- Available rebel support.
- Game era.
- Difficulty and game speed.

Avoid spawning excessive numbers of units.

Use safe, validated plots for unit creation.

Do not destroy existing city infrastructure or change city ownership in unsupported ways.

The player must be able to end a rebellion through military suppression or a negotiated political resolution.

Provide safeguards against permanently stuck rebellion states.

---

# 8. THE WAR OF THE CROWNS

This is the civilization's most dramatic feature.

When a major civil war begins, generate a named historical event.

Example:

**THE WAR OF THE THREE CROWNS**

"General Cassian Varro has proclaimed himself Emperor of the Western Provinces. Several Governors have rallied behind his banner. The Imperial Legions now march against one another."

The event should involve:

- Several rebel provinces.
- A named claimant.
- Coordinated rebel forces.
- Regional unrest propagation.
- Possible military defections.
- Severe Authority consequences.
- Strategic choices for the Emperor.

The player may attempt:

- Military suppression.
- Negotiated autonomy.
- Financial concessions.
- Political reconciliation.

The claimant should gain support based on Governor relationships, Ambition, Prestige and regional conditions.

Civil wars should be genuinely threatening but not impossible.

There must be a reasonable recovery path even after a major collapse.

## Civil war historical records

Track:

- War name.
- Start turn.
- End turn.
- Rebel leader.
- Involved provinces.
- Rebel troop count.
- Result.
- Provinces restored.
- Authority lost and recovered.

Do not repeatedly create new major civil wars while one is already active.

A civil war must have a definite resolution state.

---

# 9. MILITARY ALLEGIANCE

Every land combat unit belonging to The Shattered Empire has an Oath of Allegiance rating between 0 and 100.

Track:

- Unit ID and stable identity.
- Home province.
- Oath rating.
- Associated Governor.
- Veteran status where appropriate.

Suggested rating categories:

| Oath   | Status                     |
| ------ | -------------------------- |
| 80–100 | Fanatically loyal          |
| 60–79  | Reliable                   |
| 40–59  | Questionable               |
| 20–39  | Mutiny risk                |
| 0–19   | Likely defection candidate |

## Allegiance mechanics

Oath is influenced by:

- Home province Loyalty.
- Imperial Authority.
- Governor Prestige.
- Governor archetype.
- Imperial reforms.
- Successful imperial military campaigns.

If a Governor rebels, qualifying units associated with that province may defect.

Defection must be limited by clear rules.

Examples:

- Do not defect unique one-of-a-kind units belonging to unrelated mods.
- Do not cause uncontrolled deletion loops.
- Avoid converting units in an invalid location.
- Ensure transfer logic preserves reasonable experience/promotions when safe.
- Avoid exploiting upgrade events to reset Oath.
- Put caps on the number of military defections during one rebellion.
- Do not trigger defections without an active political crisis.

If transferring unit ownership is not reliably supported, safely replace eligible defectors with equivalent rebel forces.

Document the exact approach.

---

# 10. UNIQUE UNIT — IMPERIAL LEGION

Replaces the Warrior.

Suggested stats:

- Combat Strength: 10.
- Production Cost: +15% relative to Warrior.
- Movement: unchanged.

Unique promotion: **Imperial Discipline**

Effect:

+15% Combat Strength when fighting in friendly territory while Imperial Authority is at least 60.

This ability must work for both attacking and defending, subject to what verified CP combat hooks reliably support.

The promotion must persist when the unit upgrades.

Do not permanently apply and remove Combat Strength modifiers in ways that stack accidentally.

Imperial Legions participate in the Oath of Allegiance system.

Their early power helps establish the empire, but highly experienced Legions can become dangerous if their province rebels.

Ensure the unit is correctly defined, appears in the Civilopedia, has appropriate art/icons, and upgrades normally.

---

# 11. UNIQUE BUILDING — PROVINCIAL GOVERNOR'S PALACE

Replaces the Monument.

Retains the Monument's normal effects and cost.

Additional effects:

- +1 Gold.
- +2 provincial Loyalty per five Standard-speed turns.
- Enables relevant local administrative decisions.

In the capital:

- Provides +1 Imperial Authority every ten Standard-speed turns instead of the provincial Loyalty effect.

Avoid accidentally doubling Monument yields through inheritance errors.

The building must work for both human and AI civilizations.

Do not create an infinite Authority farming exploit through selling and reconstructing buildings.

---

# 12. IMPERIAL REFORMS

Create an **Imperial Reforms** panel with three mutually exclusive government approaches.

Reforms should modify existing gameplay systems, not replace the normal Social Policy interface.

## Absolute Monarchy

Centralize power in the Emperor.

Benefits:

- +10% military unit Production in the capital.
- Stronger Authority recovery from suppressed rebellions.

Disadvantages:

- Distant provinces suffer −2 Loyalty per interval.
- Rebellions become more militarized.

## Imperial Federation

Grant greater independence to provinces while preserving the Imperial Throne.

Benefits:

- +3 Loyalty per interval in chartered provinces.
- Less frequent Governor demands.

Disadvantages:

- −10% Production in chartered provinces.
- Initial adoption costs 10 Authority.

## Military Dictatorship

The Legions become the foundation of Imperial government.

Benefits:

- +15 Oath for Imperial Legions.
- +10% Combat Strength against rebel forces.

Disadvantages:

- Generals and militarist Governors accumulate Ambition more quickly.
- Increased danger of military coups.

## Reform rules

- Reforms must be unlockable through a clearly defined game progression.
- Only one major reform can be active at a time.
- Changing reforms must have a cooldown and political cost.
- The UI should show active bonuses and disadvantages.
- AI rulers must choose reforms.
- Save/load must preserve the adopted reform and cooldown.
- No duplicate or permanently stacking modifiers.

The three government types should support meaningfully different playstyles.

---

# 13. IMPERIAL SUCCESSION SYSTEM

The Emperor does not rule forever.

Beginning after the Ancient Era, succession events can occur at era transitions.

Use a sensible minimum cooldown scaled by game speed.

A succession crisis must never be triggered repeatedly by reloads.

Generate successors with persistent:

- Names.
- Archetypes.
- Personal traits.
- Historical relationships.
- Succession dates.

## Succession candidates

### Heir of Blood

- +15 Authority.
- Ambitious Governors resent hereditary rule.

### Heir of Steel

- +15 military Oath.
- Some civilian Governors become disloyal.

### Council's Choice

- +10 Loyalty throughout the empire.
- −15 Authority.
- Temporary Production penalty.

Each succession becomes a historical event.

Example:

"Emperor Aurelius III has died. The Imperial Council has assembled in Aeternum. Three claimants now seek the Eternal Throne."

Do not attempt to change the actual diplomatic leader model midgame unless proven safe.

The displayed civilization leader can remain The Last Emperor.

The succession system tracks the ruling Emperor internally and displays their current identity in the custom UI.

## Dynasty history

Track every Emperor:

- Name.
- Beginning of reign.
- End of reign.
- Reign length.
- Major wars.
- Rebellions faced.
- Provinces acquired or lost.
- Government reforms adopted.
- Circumstances of succession.

Aim for a persistent dynasty system that makes each game feel historically unique.

---

# 14. THE IMPERIAL RESTORATION

The civilization must have a comeback mechanism.

After surviving a major collapse or major civil war, the player can begin restoring Imperial unity.

Requirements:

- Imperial Authority at least 75.
- Average provincial Loyalty at least 80.
- No active rebellions.
- At least one previously resolved major collapse.
- Requirements sustained for 20 Standard-speed turns.

When restoration succeeds, unlock:

**THE EMPIRE REBORN**

Effects:

- +10% Production in imperial cities.
- +10% Culture in imperial cities.

These effects remain active while the empire is stable.

If the empire suffers another serious political crisis, Restoration bonuses can become dormant.

Do not permanently disable rebellion mechanics after Restoration.

The Empire must remain politically alive.

---

# 15. HISTORICAL CHRONICLE

Create a persistent Imperial Chronicle.

This should be one of the civilization's most distinctive features.

Log meaningful events such as:

- The founding of Aeternum.
- Appointment and replacement of Governors.
- Major conquests.
- Province rebellions.
- Civil wars.
- Governor betrayals.
- Military defections.
- Succession events.
- Political reform adoption.
- Imperial restoration.
- Major territorial losses.

Example entries:

**Turn 52 — The Conquest of Valoria**\
"The Imperial Legions conquered Valoria during the reign of Emperor Aurelius I."

**Turn 107 — The Betrayal of Cassian Varro**\
"Governor Cassian Varro renounced his allegiance to the Eternal Throne."

**Turn 158 — The Restoration of the Western Provinces**\
"The forces of Aeternum defeated the usurper and restored Imperial authority."

Store the Chronicle efficiently.

Use a reasonable maximum event count and compact persistent records.

The Chronicle should survive save/reload.

Do not create duplicate Chronicle events.

---

# 16. CUSTOM IMPERIAL ADMINISTRATION UI

Create a professional interface matching Civilization V's visual style.

The interface should be accessible through a custom button in the normal strategic interface, ideally near the top panel if this can be integrated safely.

The UI must not obstruct Diplomacy View, City View, Culture View, or other special screens.

Do not poll UI visibility every 0.1 seconds.

Use supported game-view events, popup state transitions, or explicit user actions as appropriate.

## Required tabs

### Overview

Display:

- Imperial Authority.
- Current political condition.
- Number of loyal provinces.
- Number of discontented provinces.
- Number of active rebellions.
- Current Emperor.
- Active reform.
- Major warnings.

### Governors

Display:

- Province name.
- Governor name.
- Archetype.
- Loyalty.
- Ambition.
- Prestige.
- Current demands.
- Active unrest state.

Allow selecting individual provinces.

### Provincial Decisions

Allow:

- Governor appointments/replacements.
- Bribery.
- Autonomy concessions.
- Responses to demands.
- Political reconciliation.

Only show valid available actions.

### Military Allegiance

Show:

- Units grouped by home province.
- Average Oath rating.
- Units at risk of defection.
- Military reforms and effects.

### Imperial Reforms

Show all reform choices, current policy, bonuses, penalties, and cooldowns.

### Dynasty

Show current Emperor, previous rulers and their reigns.

### Chronicle

Show historical events in chronological order.

## UI engineering rules

- Use properly registered UI contexts.
- Use event-driven state refreshes.
- Avoid unnecessary turn-by-turn rebuilding of every element.
- Handle missing or destroyed cities safely.
- Ensure the interface still works after saving and reloading.
- Keep game-state mutations in validated gameplay handlers.
- Validate player ownership and action affordability on the gameplay side.
- Never allow a UI button to execute the same costly action multiple times accidentally.
- Do not create global popup spam.
- Ensure AI-controlled civilizations do not require opening the UI.

---

# 17. AI SUPPORT

This mod MUST work when The Shattered Empire is controlled by the AI.

The AI should:

- Evaluate Governor Loyalty.
- Maintain garrisons.
- Complete reasonable provincial demands.
- Choose appropriate reforms.
- Bribe or replace dangerous Governors.
- Manage succession.
- Respond to rebellions.
- Suppress nearby rebel forces.
- Negotiate when politically appropriate.
- Attempt Imperial Restoration.

AI decisions should use heuristics based on:

- Economy.
- Military strength.
- Provincial unrest.
- Number of existing wars.
- Current Authority.
- Reform type.
- Governor personalities.

Do not give the AI unrestricted immunity to political collapse.

However, the AI should be competent enough that the civilization does not consistently self-destruct in the early game.

Test the AI under extended Huge-map games with many rival civilizations.

---

# 18. GAME SPEED SCALING

Support:

- Quick
- Standard
- Epic
- Marathon

Use Standard as the balancing baseline.

Scale:

- Event intervals.
- Succession cooldowns.
- Rebellion escalation durations.
- Restoration durations.
- Political decision deadlines.
- Economic costs.
- Temporary effects.

Do not blindly scale everything.

For example, a +15% combat modifier should remain +15% regardless of game speed.

Loyalty and Authority remain bounded within 0–100.

Read the actual game-speed configuration instead of making assumptions based purely on game-speed names.

---

# 19. SAVE COMPATIBILITY AND PERSISTENCE

Persistent gameplay state must include:

- Imperial Authority.
- Political condition.
- Governor data.
- City/Governor relationships.
- Provincial Loyalty.
- Governor Ambition and Prestige.
- Active provincial demands.
- Rebellion stages.
- Active rebel factions.
- Rebel military metadata.
- Military unit allegiance.
- Imperial reforms.
- Reform cooldowns.
- Emperor and succession history.
- Imperial Restoration.
- Chronicle records.
- Initialization flags.

Use reliable save mechanisms appropriate to Civ V.

Add a save schema version and safe migration handling.

Important:

- No repeated starting city creation after reload.
- No repeated starting Legion creation.
- No duplicated Governors.
- No duplicated rebel armies.
- No repeated succession events.
- No repeated reward bonuses.
- No permanently stuck rebellion flags.
- No orphaned military allegiance records after unit death.
- No unbounded save-data growth.

If old saves lack new data fields, apply sensible defaults instead of crashing.

---

# 20. PERFORMANCE REQUIREMENTS

Assume the civilization may be used in a Huge map with approximately 22 civilizations and many units.

This is extremely important.

Use event-driven programming.

Do not:

- Scan every unit every frame.
- Scan every city every 0.1 seconds.
- Rebuild every UI element continuously.
- Check every map plot every turn without a specific need.
- Repeatedly create expensive database queries.
- Generate unbounded rebel armies.

Prefer:

- Cached city and Governor references.
- Turn-based political updates.
- Targeted city event handling.
- Staggered calculations where appropriate.
- Efficient unit metadata cleanup.
- Compact save structures.
- Logging that can be disabled outside debugging.

The system should remain responsive throughout an extended game.

---

# 21. ART AND ASSETS

Generate or prepare the required artwork wherever the available project environment supports it.

Visual direction:

**A glorious ancient imperial civilization slowly falling into ruin.**

Themes:

- Gold and deep crimson.
- Fractured crowns.
- Imperial eagles.
- Broken marble.
- Burning palaces.
- Ancient legions.
- Civil war.
- Faded imperial grandeur.

Required assets:

- Civilization icon and alpha icon.
- Leader portrait.
- Dawn of Man illustration.
- Unique Ability icon.
- Imperial Legion unit icon.
- Imperial Legion unit flag.
- Provincial Governor's Palace building icon.
- Appropriate Atlas definitions.
- Required size variants.
- Appropriate Civilopedia imagery.

Optional but highly desirable:

- Civil war event illustration.
- Succession event illustration.
- Restoration illustration.
- Imperial Administration decorative elements.

Use original, generated or appropriately licensed assets.

If image generation is unavailable, create technically valid fallback assets where possible and document remaining art requirements honestly.

Do not leave references to missing image files.

Correctly configure ArtDefine references, icon atlases, alpha atlases and unit flags.

---

# 22. CIVILOPEDIA, DIPLOMACY AND FLAVOR

Provide complete English localization.

Include:

- Civilization name.
- Leader name.
- Civilization adjective.
- City list.
- Unique Ability description.
- Unique Unit description.
- Unique Building description.
- Civilopedia history.
- Civilopedia strategy.
- Leader diplomacy responses.
- First contact greeting.
- Defeat response.

Example diplomacy greeting:

"Behold the Eternal Throne. Kingdoms rise and fall, but our Empire shall endure. Tell me, stranger, do you come as a friend—or as another enemy seeking our ruins?"

Example defeat response:

"The banners have fallen. The Legions have scattered. Yet remember this, conqueror: even shattered empires leave shadows upon the earth."

Example Civilopedia strategy:

"The Shattered Empire excels at early territorial expansion but must carefully balance military conquest with political stability. Powerful Governors can transform provinces into prosperous administrative centers—or rally them against the Emperor during periods of weakness."

---

# 23. FOLDER STRUCTURE

Use a maintainable folder structure approximately like:

TheShatteredEmpire/

- TheShatteredEmpire.modinfo
- README.md
- CHANGELOG.md
- SQL/
- XML/
- Lua/
  - ImperialCore.lua
  - ImperialStartingCities.lua
  - ImperialGovernors.lua
  - ImperialLoyalty.lua
  - ImperialLegions.lua
  - ImperialRebellions.lua
  - ImperialSuccession.lua
  - ImperialReforms.lua
  - ImperialChronicle.lua
  - ImperialPersistence.lua
  - ImperialAI.lua
- UI/
  - ImperialAdministration.lua
  - ImperialAdministration.xml
  - ImperialEvents.lua
  - ImperialEvents.xml
- Art/
- Localization/
- Tests/

Adjust this structure if an existing repository uses a better-established pattern.

Ensure every required file is correctly registered and loaded.

Inspect the modinfo carefully.

Include proper SQL/XML loading configuration, UI add-ins, art definitions and localization.

---

# 24. TESTING REQUIREMENTS

Build a concrete testing plan and execute all checks possible in the current environment.

At minimum, validate:

## Basic installation

- Mod loads with CP v151.
- Civilization appears in selection.
- Leader portrait loads.
- Unique Unit appears.
- Unique Building appears.
- Localization is valid.

## Starting empire

- Correct capital behavior.
- Two extra provinces or safe fallback.
- No invalid settlement plots.
- No duplicate cities on reload.
- Starting Imperial Legion correctly replaces Warrior.

## Governor systems

- Governors generated.
- Names persist.
- Loyalty and Ambition update.
- Demands are feasible.
- Decisions change values correctly.
- Destroyed or captured cities are handled.

## Rebellions

- Loyalty thresholds work.
- Rebellion warnings appear.
- Rebel units spawn safely.
- Military defections are bounded.
- Rebellions can be resolved.
- Multiple simultaneous rebellions are handled.
- Major civil wars do not repeatedly retrigger.

## Succession

- Successors are generated.
- Succession effects apply once.
- History persists.
- Cooldowns work.
- Reloading does not reroll successors.

## Reforms

- Correct bonuses apply.
- Reform changes remove old effects.
- No permanent stacking.
- AI can adopt reforms.

## Restoration

- Trigger conditions work.
- Restoration rewards apply once.
- Bonuses become inactive when appropriate.
- Another collapse remains possible.

## AI

- AI manages Governors.
- AI responds to rebellions.
- AI can complete restoration.
- AI avoids repetitive decision loops.

## Stability

- Test loading and reloading.
- Test late-game city counts.
- Test unit death and upgrades.
- Test capital loss.
- Test city capture and recapture.
- Test different map sizes.
- Test Quick and Marathon.
- Test a Huge-map scenario with approximately 22 civilizations.

Where Civ V runtime execution is unavailable, perform static checks, Lua syntax validation and database checks where feasible, and provide a manual in-game testing checklist.

Never claim to have successfully run Civ V if you cannot actually execute it.

---

# 25. BALANCING GOALS

The Shattered Empire must be powerful, dangerous and rewarding.

Expected power curve:

**Ancient Era:** Strong early territorial position and Imperial Legions.

**Classical Era:** Growing economic and military capability, with manageable provincial tensions.

**Medieval Era:** Governor Prestige and provincial ambitions become increasingly relevant.

**Renaissance Era:** Major imperial reforms, territorial ambitions and possible succession conflicts.

**Industrial Era:** Large-scale civil wars become possible if political mismanagement has accumulated.

**Modern Era and beyond:** A restored empire may become extremely powerful, but instability remains a legitimate threat.

Do not hardcode civil wars to occur at a particular turn or era.

An exceptionally well-managed empire must be capable of avoiding collapse.

A reckless expansionist empire should face meaningful consequences.

Civil wars should result from accumulated conditions and player choices.

Do not remove mechanics simply because balancing them is difficult.

Prefer adjusting numbers, cooldowns, thresholds and limits.

---

# 26. IMPLEMENTATION PRIORITIES

Implement complete vertical slices in this order:

**Phase 1 — Fully playable civilization**

- Civilization definitions.
- Leader.
- Unique Ability infrastructure.
- Imperial Legion.
- Governor's Palace.
- Initial city setup.
- Localization and art registration.

**Phase 2 — Political systems**

- Imperial Authority.
- Governors.
- Loyalty.
- Ambition.
- Provincial demands.
- Persistent state.

**Phase 3 — Internal conflict**

- Rebellion stages.
- Rebel units.
- Military Allegiance.
- Coordinated civil wars.
- Resolution logic.

**Phase 4 — Long-term progression**

- Succession.
- Government reforms.
- Restoration.
- Historical Chronicle.

**Phase 5 — Complete presentation**

- Imperial Administration UI.
- Notifications.
- Civilopedia.
- AI handling.
- Testing, optimization and documentation.

Do not stop after writing scaffolding.

Complete each connected system to the greatest extent possible before moving on.

If an engine limitation blocks a feature, implement the closest safe gameplay equivalent, explain the compromise and continue.

---

# 27. FINAL DELIVERABLES

Produce:

1. A complete installable Civ V mod.
2. Working XML/SQL definitions.
3. Complete Lua gameplay modules.
4. Custom Imperial Administration interface.
5. Appropriate icons and artwork.
6. Full Civilopedia and localization.
7. AI support.
8. Persistent save-state handling.
9. README with mechanics and strategy.
10. CHANGELOG.
11. Testing instructions and results.
12. Documentation of CP-dependent hooks and limitations.

At completion, provide:

- Files created and modified.
- Overview of implemented systems.
- Exact mod installation instructions.
- Confirmed tests performed.
- Known issues and limitations.
- Features requiring actual in-game validation.
- Any unavoidable deviations from this design.

**Do not describe incomplete or simulated functionality as fully functional unless the actual implementation supports it.**

## THE ULTIMATE GOAL

I want this civilization to produce emergent historical stories.

One game, a wise Emperor may keep the Empire united for thousands of years.

Another game, an ambitious Governor might betray the throne and lead three provinces into rebellion.

Another game, an entire Imperial army may defect during a succession crisis.

Another game, the Empire may fall apart, lose most of its territory, and then rise again under a legendary ruler.

The player should remember the names of the Governors who served them, the traitors who betrayed them, the Emperors who restored order, and the civil wars that nearly destroyed everything.

**The Shattered Empire is not simply a civilization with instability penalties.**

**It is a miniature political grand-strategy simulation inside Civilization V.**

Build it accordingly.

## One important implementation decision

I deliberately instructed Codex to simulate rebel factions using supported game systems, rather than attempting to force Civ V to create entirely new playable civilizations midgame.

That distinction is important because we want the political system to be ambitious and reliable, especially in your massive CP games.

There's also one future feature I think would make this even more incredible: Governor Rivalries.

Imagine two loyal Governors who absolutely hate each other. One secretly funds unrest in the other's province. Eventually you're forced to pick a side, potentially turning your most powerful ally into your worst enemy.

I'd make that a later expansion once the core civilization is stable.