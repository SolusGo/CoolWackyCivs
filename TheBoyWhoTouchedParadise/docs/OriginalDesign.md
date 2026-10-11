# CODEX IMPLEMENTATION REQUEST
# Civilization V — Lionel Messi: The Boy Who Touched Paradise

## 1. Objective

Implement a complete, playable Civilization V civilization named **The Boy Who Touched Paradise**, inspired by Lionel Messi's brilliance, international heartbreaks, and eventual redemption at the 2022 FIFA World Cup.

Repository: https://github.com/SolusGo/CoolWackyCivs

Requirements:
- Civilization V: Brave New World.
- Community Patch v151 compatibility.
- Implement using SQL, Lua, XML and DDS assets.
- Integrate into the existing CoolWackyCivs collection.
- Human-playable only: `Playable = 1`, `AIPlayable = 0`.
- Single-player support is mandatory.
- Follow the existing repository's build, validation, event registration and packaging conventions.

**IMPORTANT: THIS IS A NEW, SEPARATE CIVILIZATION.**

The repository already contains `EternalNumberTen`, another Messi civilization with six career chapters, Legacy, La Masia, and football-inspired military mechanics.

DO NOT replace, rename, merge, rebalance or remove that civilization.

Both Messi civilizations must coexist and be selectable independently. Their gameplay states, UI, IDs, assets, save keys and effects must be isolated.

Inspect the repository before coding. Work with its actual schema, utilities, asset pipelines and Community Patch implementation rather than assuming vanilla Civ V behaviour.

Do not stop at a proposal or pseudocode. Implement the mod and run the available tests.

---

# 2. Creative direction

This civilization is NOT primarily about Messi's entire professional biography.

The existing Eternal Number Ten already covers that.

This civilization focuses on three powerful themes:

**BRILLIANCE → HEARTBREAK → REDEMPTION**

Its inspiration is the emotional meaning behind Peter Drury's commentary following Messi's World Cup triumph: Messi had always been extraordinary, including during the years when the ultimate international prize eluded him.

The player should experience:

1. The joy and wonder of an extraordinary footballing genius.
2. An increasingly difficult struggle beneath the weight of expectation.
3. A final opportunity to overcome those difficulties and achieve a lifelong dream.
4. The emotional satisfaction of redemption without erasing the greatness that preceded it.

Central philosophy:

**Messi's greatness does not come from winning the World Cup. The World Cup completes a dream that his greatness alone could not guarantee.**

Do not design this as another six-chapter permanent-stat progression system.

Do not reproduce the existing civilization's Legacy mechanic.

This civilization should feel like an interactive, three-act story with genuine decisions, changing pressures and a climactic resolution.

---

# 3. Civilization identity

Civilization: Argentina — The Boy Who Touched Paradise

Short Name: The Boy Who Touched Paradise

Leader: Lionel Messi

Capital: Buenos Aires

Second City: Rosario

UA: He Was Always the Point of Difference

UU: El Diez

UB: El Potrero (Amphitheater replacement)

Unique National Wonder: The Last Dance

Final Memorial: The Eternal Number Ten

Signature resources and systems:
- Dreams
- Moments of Magic
- The Weight of Expectation
- Heartbreak and Memories
- The Final Peak

Preferred victories: Culture and Diplomacy, with Science and military play remaining viable.

Visual identity:
- Argentine sky blue and white.
- Subtle gold accents representing fulfillment and immortality.
- Early-game art: warmth, sunlight, imagination and freedom.
- Middle-game art: solitude, shadows, expectations and heartbreak.
- Final art: golden light, celebration and relief.

The emotional tone must remain dignified. Avoid excessive melodrama or internet humour.

---

# 4. Unique Ability — He Was Always the Point of Difference

## Core principle

This Unique Ability must provide meaningful strength from the very beginning.

Messi must not become extraordinary only after reaching The Final Peak.

Implement the following baseline effects:

- +5% Great Person generation throughout the civilization from the start.
- +1 Culture in the capital from founding.
- Gain Dreams through significant achievements.
- Access Moments of Magic through El Diez.
- Unlock the special Weight of Expectation and redemption systems as the game progresses.

The baseline bonuses must remain active during every narrative act.

They must NEVER disappear because of an event, setback or phase transition.

## Dreams resource

Dreams are a civilization-specific resource tracked by Lua, not a strategic resource.

Dreams are spendable, and Lifetime Dreams Earned is tracked separately.

Starting balance: 0.

Standard-speed Dream earnings:

| Achievement | Dreams |
|---|---:|
| Genuine Great Person birth | +2 |
| World Wonder constructed | +4 |
| First Golden Age started in each era | +3 |
| First new City-State alliance in each era | +2 |
| First El Potrero completed in each era | +1 |
| Completing a major recovery challenge | +5 |

Rules:
- Rewards must be real achievements, not dummy buildings or Lua-created fake events.
- No infinite rewards from repeatedly losing and regaining an alliance.
- Do not reward Golden Age extensions as new Golden Age starts.
- Prevent duplicate Great Person birth attribution.
- Respect the normal distinction between purchased, generated, and spawned Great People when necessary.
- World Wonder rewards must occur only for a legitimate new construction.
- All resource changes must be displayed in the UI.
- All changes must be persisted.

Store:
- Current Dreams.
- Lifetime Dreams Earned.
- Earned-source records and cooldowns.
- Per-era reward claims.

Use namespaced save keys unique to this civilization.

---

# 5. Unique Unit — El Diez

## Identity

A one-of-a-kind civilian hero representing Lionel Messi.

This is NOT the existing Eternal Number Ten's Great General replacement.

It should be a completely separate unit type.

El Diez is a noncombat inspirational unit, rather than a conventional attacking military unit.

## Creation and rules

- Spawn exactly one El Diez when the civilization establishes its first capital.
- Never allow normal production or purchases.
- Maximum one active copy.
- 2 Movement.
- No conventional attacks.
- No settlement, Citadel, Great Work, religion or Great Person expend actions.
- May enter friendly cities and lawful civilian-access tiles.
- Should never require strategic resources or gold maintenance.

If captured or destroyed:
- Record the incident as a narrative event when appropriate.
- Return El Diez to an eligible friendly city after 5 owner turns.
- Never duplicate the unit.
- Do not permit unit-deletion exploits to repeatedly earn Dreams or Memories.
- Handle elimination, lost capitals, save/load, capture transfers and missing cities correctly.

Do not invent engine hooks. Determine the reliable CP events for civilian capture and destruction before implementing recovery.

## Inspirational presence

While stationed in an owned city:

- +2 Culture each turn.
- +2 Golden Age Points each turn.
- +10% Great Person generation in that city.

Only one city may receive these benefits at a time.

Movement between cities must correctly remove and transfer the bonuses.

Use native CP effects or safely managed dummy buildings where possible rather than Lua-calculated approximations that ignore normal modifiers.

---

# 6. Moments of Magic

El Diez can perform extraordinary acts that change the course of a civilization.

These abilities should represent Messi's individual brilliance, not necessarily a World Cup victory.

Access them through a dedicated UI.

A Moment of Magic:
- Costs 6 Dreams.
- Requires El Diez in an owned city.
- Can be used once per civilization per era.
- Is selected manually by the human player.
- Applies exactly once.
- Must use authoritative gameplay validation.
- Must not consume Dreams if the action fails.

Three available choices:

## A. A Pass Nobody Saw

The genius to see a possibility that nobody else could.

Effect:
- Instantly provide Science equal to approximately 1.5 turns of the hosting city's current Science.
- Provide Culture equal to approximately 1.5 turns of its current Culture.

Minimum grant: 10 of each.

Use actual outputs or safely captured snapshots. Avoid recursively including the granted yield in its own calculation.

Balance the grant to avoid explosive yields in the late game.

## B. When All Hope Was Lost

The genius who can suddenly change an apparently hopeless situation.

For 8 Standard-speed owner turns, the hosting city receives:
- +20% Production.
- +15% defensive strength.

The effect should stack fairly with ordinary bonuses but not with duplicate casts of itself.

Expire it reliably on the intended turn.

If the exact city defense modifier is unavailable, inspect CP's supported alternatives and implement a close, documented substitute.

## C. The Beautiful Game

The ability to inspire admiration beyond borders.

Effects:
- Golden Age Points equal to `20 + 10 × current era index`, using Civ V's zero-based era index.
- +10 Influence with up to two eligible met City-States not at war with the player.

Prefer the two City-States with the lowest positive or neutral relations, selected deterministically.

If no eligible City-State exists, the Golden Age Points must still be awarded.

Do not award Influence to invalid, eliminated or permanently hostile targets.

## Design constraint

These abilities remain equally accessible in all three acts.

Messi's brilliance is not diminished by his career disappointments.

---

# 7. Unique Building — El Potrero

Replaces the Amphitheater.

Represents the humble local football grounds where a child's love of the game begins.

Inherit the active Amphitheater's CP and BNW baseline effects, including companion database rows as needed.

Additional bonuses:
- +1 Culture.
- +10% Great Person generation in the city.

The first completed El Potrero each era provides +1 Dream.

Requirements:
- Retain normal replacement-building functionality.
- No duplicate building effects when cities change ownership.
- Prevent free dummy constructions from generating Dreams.
- Properly handle building completion versus purchase, if the existing CP implementation requires separate event logic.
- Ensure all UI descriptions reflect the actual implemented behaviour.

El Potrero should remain useful through every age without outperforming expensive later buildings.

---

# 8. The Three-Act Journey

This system is the core identity of the civilization.

The stages progress with the game, but the player's accomplishments determine how they experience each stage.

## ACT I — HE WAS BEAUTIFUL

Era range: Ancient through Medieval.

Theme:
- Innocence.
- Joy.
- Creativity.
- Discovery.
- Unrestricted brilliance.

Gameplay:
- All starting UA and El Diez bonuses are active.
- The player generates Dreams and experiences Moments of Magic.
- A Journey interface records noteworthy achievements.
- There are no pressure penalties.
- The narrative gradually establishes the expectations surrounding Messi.

The player should feel capable and inspired.

At the Renaissance transition, trigger the first major story event.

## ACT II — THE WEIGHT OF EXPECTATION

Era range: Renaissance through Industrial.

Theme:
- The burden of greatness.
- The pressure of a nation.
- Heartbreak.
- Being brilliant while falling short of the ultimate dream.

This act must introduce genuine strategic difficulty.

Crucially, do not make El Diez weak or remove his abilities.

Instead, pressure affects the civilization around him.

### New mechanic: National Pressure

A persistent value from 0 to 100.

On first entering the Renaissance:
- Trigger a narrative event.
- Set Pressure to 25.
- Begin the Weight of Expectation system.

While Act II is active:
- Pressure increases by 1 every 3 owner turns.
- Meaningful setbacks may increase Pressure.
- Significant achievements reduce Pressure.

Apply Pressure levels:

| Pressure | Effect |
|---|---|
| 0–49 | No national yield penalty |
| 50–74 | -5% Culture and Production in cities |
| 75–100 | -10% Culture and Production in cities |

These are national-pressure penalties, not reductions to El Diez's inherent abilities.

Do not introduce extreme unavoidable empire-wide unhappiness, city destruction, forced military losses or permanent penalties.

Pressure should be challenging without making the game hopeless.

### Meaningful ways to reduce Pressure

Standard-speed examples:

- First genuine Great Person born during a new era: -8.
- First Golden Age start per era: -12.
- First new City-State alliance per era: -10.
- First new World Wonder per era: -10.
- Recovery challenge successfully completed: -20 or greater, depending on the specific event.

Apply appropriate source caps.

The mechanic must favour genuine progress, not intentional self-sabotage.

### Heartbreak events

Recognize major losses such as:
- Losing a previously owned city.
- Losing a long-standing City-State alliance.
- Losing an original capital.
- Failing a major national expectation challenge.

These incidents may create Heartbreak records and increase Pressure, but never reward deliberate repeatable losses.

For each qualifying setback, store a stable identifier so it cannot be farmed through repeatedly losing and recapturing something.

Limit major setback rewards or penalties per era.

### The mandatory turning point — A Dream Denied

On first entering the Industrial Era, trigger one major scripted national-expectation event.

This is a symbolic narrative challenge, not a forced city loss.

Increase Pressure by 40, capped at 100.

Display an emotional event describing another moment when the nation believed its greatest dream was within reach, only for its fulfillment to remain uncertain.

The player receives a 25-Standard-turn opportunity to complete ONE of several recovery objectives:

- Begin a genuine Golden Age.
- Generate a genuine Great Person.
- Complete a World Wonder.
- Obtain a new City-State alliance.

Only achievements AFTER the challenge begins qualify.

Provide at least one attainable alternative if map settings, eliminated City-States or the late-game state make the normal objectives impossible.

Successful recovery:
- Reduce Pressure by 30.
- Award 5 Dreams.
- Create a permanent Memory.
- Mark the major challenge complete.

Failure:
- Increase Pressure by 15, capped at 100.
- Record the setback.
- Do not permanently lock redemption.

Offer a later alternative comeback objective after a reasonable cooldown.

The intended emotional arc is that the player might struggle but can recover through persistence and intelligent decisions.

The game should never secretly decide that the player must fail.

---

# 9. Memories — The Journey Remembers

Memories are permanent records of significant events.

They are not another spendable currency.

Each Memory should store:
- Unique event identifier.
- Narrative title.
- Turn and era.
- Event category.
- Short original narrative description.
- Relevant city or civilization when available.

Examples:
- The First Dream.
- A Moment of Genius.
- A Nation Falls Silent.
- The Burden of Expectation.
- We Rise Again.
- The Final Peak.

Do not record hundreds of trivial events.

Track major milestones and the strongest qualifying narrative event in each category or era.

Achievements should include success as well as hardship.

**A perfect no-loss playthrough must still be capable of completing the civilization.**

Memories need to be visible in the Journey UI and persist through saving and reloading.

They should not disappear when an era changes.

Create original narrative writing for these events, not copyrighted commentary transcripts.

---

# 10. ACT III — THE LAST DANCE

Begins when the player enters the Modern Era.

The player has experienced the height of brilliance and the weight of expectation.

One dream remains.

The civilization can now pursue a unique National Wonder:

**The Last Dance**

## Unlocking the final objective

Requirements:

1. Reach the Modern Era.
2. Earn at least 40 Lifetime Dreams.
3. Complete at least three distinct Legacy Objectives.

Possible Legacy Objectives:
- Generate 4 genuine Great People.
- Experience 2 genuine Golden Age starts.
- Construct World Wonders in at least two distinct eras.
- Obtain two distinct City-State alliances.
- Complete the major national recovery challenge.
- Complete significant cultural development through El Potrero and Great Works.

These are alternatives, not all mandatory.

Track progress throughout the entire game, including before the Modern Era.

Do not require a particular victory style, war, City-State availability or Wonder monopoly.

Ensure the final objective is reasonably achievable on Tiny Islands, Continents, Pangaea and other map types.

Do not consume current Dreams upon unlocking The Last Dance.

The purpose of Lifetime Dreams Earned is to recognize the complete journey, not punish players who used Moments of Magic.

## National Wonder implementation

The Last Dance must be an actual player-constructible National Wonder, not merely a simulated UI action.

Suggested base Production: 450 on Standard speed.

Available once per player.

Only buildable when eligibility conditions are met.

Use the proper Civ V National Wonder, building-class, prerequisite and Community Patch construction-validation systems.

Inspect the real event and SQL schema before implementing the dynamic conditions.

Do not let the player waste Production on an unavailable or invalid final project.

Building and completing the Wonder must be safe across save/load, city transfer, production interruption and simultaneous event callbacks.

---

# 11. THE FINAL PEAK — HE HAS SHAKEN HANDS WITH PARADISE

Upon successful completion of The Last Dance:

Trigger a special full-screen illustrated narrative event.

Title:

**HE HAS SHAKEN HANDS WITH PARADISE**

This moment represents Messi finally fulfilling the dream that had escaped him.

Do not merely print a notification and instantly apply bonuses.

The player should see:
- Unique celebration artwork.
- A special emotional narration.
- Their accumulated major Memories.
- A visual transition from sky-blue to gold.
- A clear summary of their new permanent bonuses.

Do not use copyrighted broadcaster audio or reproduce a lengthy Peter Drury quotation.

Use original narration inspired by the emotional meaning.

Suggested narration:

> The boy who once chased a ball through the streets of Rosario had become a legend long before this moment.
>
> He had known triumph. He had known heartbreak. He had carried the dreams of a nation through years of joy and sorrow.
>
> And now, at last, the dream was real.
>
> Yet the trophy did not make him extraordinary.
>
> It was the final chapter of a beauty the world had witnessed all along.
>
> The little boy had touched paradise.

## Gameplay rewards

One-time:
- Begin a 15-turn Golden Age on Standard speed.
- Set National Pressure to 0.
- End all active negative Pressure effects.
- Grant 2 Global Happiness.
- Trigger a celebration event in every currently owned city.

Permanent:
- +10% Culture civilization-wide.
- +10% Great Person generation civilization-wide.
- Receive a special capital memorial, The Eternal Number Ten.
- Additional Tourism from the memorial.

The memorial:
- Is a hidden or special unique building granted to the current capital.
- Provides +4 Tourism and +2 Culture.
- Is granted once.
- Can safely follow a legitimate capital relocation without duplicating empire-wide benefits.

The Finale must NOT automatically win the match.

It should make Argentina a stronger Culture and Diplomacy contender, but still require the player to secure a conventional Civilization V victory.

## IMPORTANT

El Diez retains every Moment of Magic.

The UA retains its original bonuses.

Dreams continue being earned and spent.

The beauty of Messi's play does not end because the final dream is complete.

The Final Peak is about fulfillment, not suddenly becoming talented.

---

# 12. Post-Redemption — The Epilogue

After completing The Final Peak:

- The civilization enters a permanent Fulfilled state.
- National Pressure can no longer return.
- Previously earned Memories remain.
- The Journey UI gains its final completed chapter.
- Dreams and Moments of Magic continue.
- The player may still pursue conventional victory conditions.

Do not add an escalating infinite bonus engine.

The final state should feel peaceful, rewarding and satisfying without becoming a runaway exploit.

Add one special concluding Journey entry:

**The Dream Is Complete. The Beauty Remains.**

---

# 13. Dedicated Interface — The Journey

Create a polished custom UI.

Working title: **THE JOURNEY**

It should not duplicate the existing Eternal Number Ten Legacy Panel.

Use distinct XML, Lua contexts, assets and UI identifiers.

## Main overview

Display:
- Current Act.
- Current Dreams.
- Lifetime Dreams Earned.
- National Pressure, if relevant.
- Current El Diez location and recovery status.
- Moment of Magic availability.
- Progress toward The Final Peak.
- Redemption status.

## Memories tab

A chronological scrapbook of significant events.

Each major Memory should have:
- Title.
- Era or turn.
- Brief description.
- Appropriate visual icon.

## Moments of Magic tab

Three usable abilities.

Show:
- Costs.
- Exact effects.
- Current availability.
- Reason an action is unavailable.
- El Diez's current hosting city.
- Once-per-era usage status.

Controls must actually execute the actions.

Do not implement decorative buttons that do nothing.

## Final Peak tab

Before completion:
- Eligibility requirements.
- Lifetime Dream progress.
- Completed Legacy Objectives.
- Current Wonder eligibility and completion status.

After completion:
- Completed journey.
- Final Peak artwork.
- Epilogue summary.
- List of permanent bonuses.

## UI performance requirements

VERY IMPORTANT based on previous issues with other civilization UIs:

Do not create a rapid polling loop that checks visibility or state every 0.1 seconds.

Do not perform expensive full-map or full-city scans every frame.

Use event-driven state updates.

Refresh on legitimate gameplay state changes, player turn boundaries and panel opening.

The main launcher should only appear in normal gameplay where appropriate.

Do not obstruct Diplomacy, City View, Culture Overview, other fullscreen screens or important controls.

Use normal Civ V UI contexts and appropriate modal handling.

The UI should work across common screen resolutions, with scrolling for long Memory lists.

Closing the UI must never stop the gameplay runtime.

A UI load failure should not corrupt the civilization's saved state.

---

# 14. Artwork and Assets

Create the complete artwork required for a polished Civ V civilization.

You may use available image-generation capabilities in the development environment or generate original assets programmatically.

Artistic inspiration:
- Watercolour and cinematic illustration.
- Sky-blue and white Argentine palette.
- Warm gold for the conclusion.
- The contrast between youthful joy, lonely expectation and ultimate fulfillment.

Required artwork:
- Civilization icon.
- Civilization alpha icon.
- Leader portrait.
- Dawn of Man image.
- Map/loading image.
- El Diez portrait and unit icon.
- El Diez unit flag.
- El Potrero icon.
- The Last Dance National Wonder icon.
- Final memorial icon.
- Three Moments of Magic icons.
- The Journey interface artwork.
- Heartbreak artwork.
- Final Peak celebration artwork.

Create the corresponding DDS formats, mipmaps, atlases and textures needed by the actual game and repository build pipeline.

Use distinct filenames, atlases and identifiers from the existing Messi civilization.

For the unit's map appearance, prefer a suitable original civilian model or safe compatible existing model. Do not leave an invisible or broken unit.

Do not generate a large inventory of unnecessary decorative assets.

Do not require users to run an image-generation script merely to install the mod.

Include finished game-ready textures in the packaged build.

If portrait-generation restrictions prevent a direct portrayal of Messi, create a recognizably football-inspired but non-identifiable artistic Number Ten figure rather than using unsuitable copyrighted photographs or broken placeholders.

All art should feel like part of one coherent, beautiful civilization.

---

# 15. Dawn of Man

Write an original, emotionally resonant opening narration.

It should describe:
- A little boy in Rosario.
- His love for football.
- The beauty of his gift.
- The expectations that followed him.
- The heartbreaks still to come.
- The dream of one day touching paradise.

Do not reveal the whole ending in the opening narration.

Finish with an invitation to guide Argentina through its own story.

Also write:
- Leader greeting.
- Defeat message.
- Civilopedia entry.
- Strategy entry.
- UA, UU, UB and Wonder descriptions.
- Help text for all custom mechanics.
- Narrative event descriptions.
- Final Peak cinematic text.

Avoid lengthy direct quotations from real sports commentary.

---

# 16. Implementation and architecture

Inspect how the existing collection handles:
- Civilization and leader registration.
- Community Patch dependency registration.
- InGameUIAddin loading.
- Lua gameplay runtimes.
- SaveData persistence.
- SQL cloning.
- Icon atlases and art defines.
- New-game initialization.
- Game-speed scaling.
- Building and project validation.
- Optional UI contexts.
- Tests and build scripts.

Suggested new folder:

`TheBoyWhoTouchedParadise/`

Suggested structure:

- `SQL/`
- `Lua/`
- `UI/`
- `Art/`
- `README.md`

Use uniquely prefixed database identifiers, such as:
- `CIVILIZATION_BOY_TOUCHED_PARADISE`
- `LEADER_PARADISE_MESSI`
- `TRAIT_PARADISE_POINT_OF_DIFFERENCE`
- `UNIT_PARADISE_EL_DIEZ`
- `BUILDING_PARADISE_POTRERO`

Use a consistent `PARADISE_` namespace for the remaining policies, buildings, promotions, Lua global state and localization keys.

Do not reuse any existing `MESSI_` IDs or `Messi|...` save keys.

Register all SQL, Lua and UI files in the collection project and packaging pipeline.

Update the root README and civilization roster.

Increase the collection version using the repository's established conventions.

Preserve existing Mod ID and all unrelated civilizations.

## Save compatibility

Prioritize stability.

- All major states must survive save and reload.
- No duplicate El Diez units.
- No repeat Final Peak rewards.
- No reset Dreams, Pressure or Memories.
- No recurring opening events.
- No repeated unit-spawn awards.
- No duplicated city dummy buildings.
- No orphaned modifiers after a city changes ownership.
- No incorrect bonuses for another civilization.
- Never assume the human player is always player zero.

If safely adding this civilization to the collection requires a new game, document that explicitly.

Do not falsely claim that ongoing games can adopt a newly added civilization without issues.

## Event handling

Use CP v151-compatible events and verify signatures.

Prefer event-driven logic and incremental tracking.

Protect all rewards against duplicate callbacks, including pre-kill/battle-finalization or repeated creation events.

Use per-player and per-unit identities where applicable.

Never award genuine-event bonuses based only on detecting that an object exists.

The mod must not cause a global performance regression when another civilization is selected.

Use an early civilization-type guard for expensive gameplay logic.

---

# 17. Balance and game-speed rules

Standard speed is the baseline for the numbers in this prompt.

Scale appropriately for Quick, Epic and Marathon:
- Turn durations.
- Ability cooldowns.
- Story deadlines.
- Temporary effects.
- Pressure growth.
- El Diez recovery time.
- Golden Age duration where necessary.

Use the active CP game's speed modifiers when possible rather than inventing a global hardcoded multiplier.

Do not multiply percentage bonuses by game speed.

Dream rewards and lifetime milestone requirements should remain proportionate and reasonably achievable across speeds.

The civilization should be:
- Above average in peaceful early development.
- Strong at generating Great People.
- Not exceptionally strong in direct military combat.
- Vulnerable to its national expectation pressures during the middle game.
- Rewarded for intelligent recovery.
- A powerful but not unstoppable late-game cultural contender after redemption.

The Final Peak must feel momentous, but it should not invalidate all other civilizations.

---

# 18. Testing and validation

Implement automated checks compatible with the repository's test architecture.

At minimum validate:

### Initialization
- Both Messi civilizations can exist independently.
- All database IDs are unique.
- All required icons/textures are packaged.
- New civilization selection works.
- Exactly one El Diez is created.
- No runtime leaks bonuses into other civilizations.

### Dreams
- Every legitimate reward source works.
- Repeated callbacks cannot duplicate a reward.
- No infinite farming through repeated alliances or Golden Age changes.
- Spending Dreams preserves Lifetime Dreams Earned.
- Failed abilities do not consume Dreams.

### El Diez
- Moving between cities updates bonuses.
- Capture and recovery work.
- Deletion and recreation cannot duplicate the unit.
- Save/reload preserves recovery.
- No invalid respawn when the civilization is eliminated.

### Moments of Magic
- Each ability applies the described effect.
- Only one ability is usable per era.
- Invalid targets are rejected safely.
- Temporary effects expire correctly.
- City capture removes unsupported effects.

### Three Acts
- Acts transition once.
- Industrial crisis triggers exactly once.
- Pressure is bounded between 0 and 100.
- No penalties before Act II.
- Penalties are correctly removed as Pressure falls.
- Recovery objectives only count achievements after activation.
- Failure does not permanently block progression.

### Final Peak
- All eligibility conditions function.
- Lifetime Dreams are tracked correctly.
- The Wonder cannot be built twice.
- Rewards occur once and survive reload.
- Pressure disappears permanently.
- The memorial cannot duplicate.
- El Diez retains his abilities.

### Compatibility
- Existing Eternal Number Ten functionality is unchanged.
- Existing civilizations still validate.
- Build and packaging scripts include all new files.
- UI contexts do not conflict.
- No unnecessary periodic polling is introduced.
- Human-only settings remain consistent with the collection.

Run existing full validation scripts as well as new dedicated tests.

Where an engine-dependent behaviour cannot be proven through unit tests, provide a concise FireTuner or in-game smoke-test checklist.

Do not report in-game testing as completed unless it was actually performed.

---

# 19. Documentation and delivery

Produce a complete README containing:
- Civilization overview.
- UA, UU, UB and Wonder.
- Dreams earnings and costs.
- The Three Acts.
- National Pressure.
- Heartbreak and recovery.
- Final Peak requirements.
- Numerical bonuses.
- Game-speed behaviour.
- UI instructions.
- Compatibility notes.
- Known limitations.
- Install and test instructions.

Update the collection's root README and build outputs.

At completion, report:
1. Exactly what was implemented.
2. Files created or modified.
3. Tests and validation results.
4. Known issues or approximations.
5. Any features requiring live Civ V verification.

Do not quietly omit a requested mechanic.

If an exact behaviour is technically impossible under CP v151, choose the closest stable, fair implementation, explain the deviation and preserve the intended gameplay experience.

Do not replace a complicated feature with a cosmetic placeholder.

---

# 20. Final creative requirement

This is the most important instruction in the entire project.

The player should feel three very different emotions across the game:

**At the beginning:**

"This civilization is extraordinary. I can create beautiful things."

**In the middle:**

"Why does achieving the one thing I want feel so difficult, even when I have so much talent?"

**At the end:**

"I finally did it. After everything that happened, the dream is complete."

And when the player finally reaches The Final Peak, they should understand:

Messi was already brilliant.

He was brilliant before the heartbreak.

He was brilliant during the heartbreak.

And he remained brilliant after his redemption.

**The dream was finally achieved. But the greatness had always been there.**

Make that philosophy visible in the mechanics, interface, narrative, balance and concluding event.

Implement this civilization fully, preserve the existing Messi civilization, and make The Boy Who Touched Paradise a distinct, memorable experience within CoolWackyCivs.
