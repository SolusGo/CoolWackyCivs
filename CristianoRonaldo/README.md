# Cristiano Ronaldo — The Relentless Seven

**Leader:** Cristiano Ronaldo, The Boy from Madeira Who Refused to Be Ordinary. **Capital:** Funchal. **Adjective:** Relentless. Deep Portuguese red and gold, with green and white. Intended victories: Domination and Culture; Diplomacy is secondary. Freedom fits the civilization's intended identity. **Player playable only:** `Playable=1`, `AIPlayable=0`; random AI selection excludes Ronaldo. The gameplay itself is automatic and does not require UI actions.

Inspired by Madeira, leaving home for Sporting, development in Manchester, prolific finishing in Madrid, Portugal's captaincy, adaptation at Juventus and Al-Nassr, and exceptional longevity. No retirement or future achievement is presumed. Strength comes from surviving veterans rather than newly produced advanced armies.

## Requirements and installation

Civilization V: Brave New World on Windows with **Community Patch v151 / 5.4.6**, the locally inspected release. CP source signatures and the installed schema were checked; other DLL releases need retesting. Unique components clone the **active** Cavalry and Barracks at database activation, including CP companion tables, so baseline statistics are not fixed to vanilla values. Activate CP before this civilization. Vox Populi balance changes are inherited when they load first, but the complete VP mod set has not been tested.

Choose one package:

- Collection: build `python tools/build_mod.py`, then extract `dist/Cool Wacky Civs (v 22).zip` under `Documents/My Games/Sid Meier's Civilization 5/MODS` and enable Cool Wacky Civs with CP.
- Standalone: build `python tools/build_ronaldo_mod.py`, then extract `dist/Cristiano Ronaldo - The Relentless Seven (v 1).zip` into the same MODS directory and enable it with CP. Its manifest blocks collection v22+, which already includes these definitions.

The scripts also produce Firaxis-compatible LZMA `.civ5mod` files. Disable older collection copies. Start a **new modded game**, manually select The Relentless Seven / Cristiano Ronaldo, and verify Funchal. Do not enable standalone and collection together. Generated DDS files and source definitions are checked in; asset generation is not required to play.

## Work Until Greatness Becomes Habit

Every military unit earns **+15% Combat Experience**, implemented by a native promotion. Genuine upgrades into a different unit type grant exactly one permanent Reinvention tier. Both the CP `UnitUpgraded` entitlement and the post-copy `UnitConverted(..., bIsUpgrade)` event are required. Administrative conversions, promotion changes and newly built advanced units do not grant tiers.

| Highest tier | Total strength | Healing per enemy kill |
|---|---:|---:|
| I | +2% | 3 HP |
| II | +4% | 6 HP |
| III | +6% | 9 HP |
| IV | +8% | 12 HP |

Only the highest tier exists on the unit. The initial cap is III; Chapter VI permits IV. Tiers survive upgrading and saves. Ordinary engine XP/promotion conversion is preserved before Chapter VI; afterward XP is restored to at least its pre-upgrade value without deleting any compensation XP the DLL grants for converted promotions.

## Ambition

Ambition accumulates and is never spent. All sources pass through one manager. Values below are Standard speed.

| Source | Ambition | Restriction |
|---|---:|---|
| Earned military promotion | 1 | Maximum 3 per turn; unselectable dummy promotions excluded |
| Enemy military defeat of comparable/greater base strength | 1 | Maximum 3 per turn; compare the larger of base melee/ranged strength |
| General or Admiral born | 3 | Genuine CP threshold-changing birth; no bare administrative creation |
| National Wonder completed | 2 | Production completion; no purchase or dummy building grants |
| World Wonder completed | 4 | Production completion; no purchase or dummy building grants |
| Golden Age begins | 3 | Native transition from no Golden Age to an active Golden Age |
| Capture original capital | 6 | Once per distinct enemy original-capital city |
| First city reaches 12, 24, 36 population | 2 each | Once per civilization per threshold |
| First military unit reaches Level 6 in an era | 3 | Once per era; unit must have been produced or earned a real promotion |

Level 6 milestones are resolved once per unit lineage. Carrying the same veteran into another era does not create a fresh milestone. Academy graduates also provide 1 Ambition under the training rules below.

Great Person detection records a pending General/Admiral at `UnitCreated` and checks its CP threshold after the birth finishes: at the next creation, player turn, or before a Great Person is killed/expended. Direct `InitUnit`, ownership transfer and upgrading do not change that threshold. Pending administrative creations are resolved before a subsequent real birth, and a Great Person expended on its birth turn is still rewarded. The DLL exposes neither an Admiral-created counter nor a separate birth event. External mods or teammates that change GP thresholds can interfere with this inference. This is an engine limitation, not a guaranteed universal birth hook.

## Career Chapters

Chapters unlock in sequence as soon as both cumulative Ambition and the era requirement are met. Earlier chapters never disappear. Large gains can unlock multiple eligible chapters in one event. Every chapter has its specified historical narrative in the Career screen and an automatic human-player popup.

| Chapter | Ambition | Earliest era |
|---|---:|---|
| I — The Island Boy | 20 | Ancient |
| II — Alone in Lisbon | 45 | Classical |
| III — The Theatre of Dreams | 80 | Renaissance |
| IV — The Standard of Madrid | 120 | Industrial |
| V — The Captain's Crown | 165 | Modern |
| VI — Different League, Same Standard | 215 | Atomic |
| VII — Beyond Time | 275 | Information |

**I:** Capital gains 1 Food and 1 Production. One Sporting Academy is granted in the current capital once its active technology and construction requirements are satisfied. If that capital already has one, the entitlement is fulfilled; changing capitals does not grant another. The first military unit produced in the capital each era gains 5 XP. Workers produced there gain 1 Sight.

**II:** Produced military units gain 5 XP. A real earned promotion heals 10 HP, once per unit per turn. Sporting Academies gain another 1 Production. Capital and civilization training XP stack when both qualify.

**III:** Level 4+ military units receive Explosive Athlete: ignore river attacks; +5% attacking strength while **standing on** open ground; +1 Movement on turns begun above 90 HP. The extra maximum movement is toggled only once at `PlayerDoTurn`, before CP resets unit movement, and is not repeatedly added as HP changes. Major unit movement events update the open-ground condition. Great Generals generate 10% faster. Military Gold purchases receive an immediate rounded 5% rebate. CP's native discount also affects civilians, so the purchase screen requires the full price and the tooltip cost is not reduced. Purchased units receive neither chapter training XP nor academy graduate eligibility.

**IV:** Level 4+ units gain 5% strength against wounded units and 5% against cities. During battles against major-civilization **units**, a temporary native promotion adds 15% Great General points. It is removed at battle finish; city combat does not qualify. An experienced captor gains Culture and Golden Age Points equal to 3 × the city's current population after capture losses, and heals 15 HP, with one civilization-wide 25-turn cooldown. `CombatResult` supplies authoritative attacker/defender identities before resolution; `BattleJoined` alone does not identify ordinary unit combat reliably in this CP release. The captor is that actual attacking unit, including while it still stands outside the city. Genuine melee combat is required even if CP flags a peace cession as a conquest. Peaceful transfers and recaptures during cooldown do not qualify.

**The Decisive Night:** Once per distinct original capital captured after IV: a 2-turn Golden Age and 3 XP to surviving friendly military war participants. A participant is a military unit recorded in the attacker or defender role of a CP battle with an identifiable opponent belonging to the previous owner's team **since the latest declaration of that war**. Garrisoning, merely being nearby and anonymous city-bombardment callbacks do not qualify. Unit lineages retain participation across upgrades. The capital Ambition reward and this chapter reward have separate saved entitlements: a capital first taken before IV can earn its Decisive Night reward upon its first qualifying later conquest.

**V:** The ordinary native General aura gains 3 percentage points. Military units within two tiles of at least one friendly General receive Captain's Standard: 5% defensive strength, 5% ranged defensive strength, and 3 HP healing at the beginning of the turn. CP exposes ranged defense as a strength modifier, rather than a separate flat post-calculation damage-resistance percentage; this is the compatible implementation of the requested 5% ranged resistance. Multiple Generals do not multiply this promotion or healing. Movement and General death refresh the aura. When a foreign civilization declares war on Ronaldo, gain 50 Golden Age Points and heal military units on Ronaldo-owned tiles by 5 HP; civilization-wide cooldown 30 turns. Defensive-pact/vassal chains where the DLL reports a different originating player require in-game verification.

**VI:** Military upgrades cost 15% less through a native policy. Reinvention IV becomes available. All upgrade XP is retained. Upgrading below 35% HP heals 15 HP. Global Legacy gives the first three currently eligible owned overseas cities 1 Gold, 1 Culture, 3% Military Production and 1 Tourism after Flight. A continent is a connected Civ V **land area**, compared with the current capital's area. The first eligibility order is saved. Losing/razing an eligible city allows the next current eligible city to fill the slot; founding, capture, capital relocation and Flight re-evaluate eligibility. Coordinates plus founding turn identify cities, so a razed and refounded city is a new candidate. Ownership transfers remove all dummy city effects, including from non-Ronaldo owners. Razing is reconciled on the next player turn.

**VII:** Immediately begin a 6-turn Golden Age, gain one free Social Policy, give existing military units 8 XP and full healing, and add 2 turns of We Love the King Day in every city. During Golden Ages: 5% Military Production, 5% Culture, 5% Tourism; Level 4+ veterans heal another 3 HP per turn. Native Golden Age modifiers handle Culture/Tourism, and city dummy buildings handle military production. Captain and veteran healing can legitimately stack.

**The Story Is Still Being Written:** After VII, each additional 60 Ambition grants a 1-turn Golden Age, Culture equal to 15 × the current zero-based Civ V era number (Information = 7, hence 105 Culture), and **both** 1% permanent Military Production and 1% Tourism. Each percentage caps independently at 5%. Golden Age and Culture rewards continue forever after the caps. Every milestone and the exact Ambition baseline at VII are saved. Extending an existing Golden Age does not award another Golden-Age-start Ambition bonus.

## Complete Forward

Replaces Cavalry. Clones the active CP baseline's strength, requirements, resource usage, upgrade path, production AI and standard Cavalry world model. Costs 20% more Production (rounded up), moves one tile farther, and can move after attacking. It gains no extra defensive strength.

Relentless Finisher: +15% strength against wounded units, no river attack penalty, 8 HP healing after a genuine military enemy kill. The first kill each turn restores one movement point **after** the DLL pays attack movement costs. No extra attacks are granted. The kill and movement entitlements are saved per unit lineage; duplicate pre-kill callbacks cannot repeat them. Original-capital captures and civilian captures are not military kill rewards.

Upon a Forward's real upgrade, Finisher and its move-after-attacking helper are removed; Veteran Finisher grants only +8% against wounded units and 5 HP healing on kills. That retained promotion survives later upgrades. It is never applied to a unit that did not have a recorded Complete Forward lineage. Reinvention and Finisher healing combine once each, clamped to legal HP.

## Sporting Academy

Replaces Barracks. Retains all active Barracks scalar and companion-table effects, including standard free experience. Adds 1 Production and 1 Culture. Produced military units gain a permanent 5% Combat Experience promotion and First In, Last Out. This XP stacks with the UA for 20% Combat Experience. Gold/Faith purchases are excluded from these added training effects.

At a graduate's first arrival at Level 4, its original city gains 15 Production and 10 Culture (city border progress and empire Culture), and the civilization gains 1 Ambition. At most one graduate per training city per era receives this reward. The original city must still exist, have the same founding identity, and belong to the original trainer. An invalid city or an already-used city/era opportunity resolves that unit's milestone without deferring it into a later era. Training origins and resolution follow the unit through upgrades and ownership transfers, preventing repeat rewards.

## Speed scaling

Ambition uses saved hundredths to avoid rounding away Quick-speed rewards. Chapter thresholds, the 60-Ambition repeatable step, and one-time Ambition sources scale with `TrainPercent`. Per-promotion and per-kill Ambition remains 1 with caps of 3 per turn; these recurring activities already occur more often in longer games. At the standard BNW factors (Quick 67%, Standard 100%, Epic 150%, Marathon 300%), Chapter I is 13.4/20/30/60 Ambition. One-time Academy Ambition follows the same factor.

Instant Production uses `ConstructPercent`; Culture uses `CulturePercent`; Golden Age Points, durations and We Love the King Day use `GoldenAgePercent`. Durations and cooldowns round to the nearest whole turn, minimum one. Cooldowns use `TrainPercent`. Flat healing and XP represent unit development and remain unchanged. Combat percentages, movement, HP qualification thresholds, unit levels, Reinvention caps, percentage caps and passive yields do not scale.

## Interface and persistence

The small **CR7 | Ambition | Chapter** button below the top panel opens the Career screen. Scroll the chapter list, select a chapter to read its narrative, requirements and bonuses, and inspect completion/legacy progress. Unlock popups queue multiple chapters and close with Continue or Escape. The interface hides during city view, leader view and standard game popups including Culture. It uses events and clicks; there is **no `SetUpdate` or timer polling**. The UI context reads the gameplay context and never writes save data or synchronized state.

Namespaced `Modding.OpenSaveData` keys persist Ambition, each chapter, milestones, cooldowns, per-turn caps, city order, completion events, unit lineages, training origins, upgrade entitlements and repeatable rewards. Fresh unit creation gets a new identity even if the DLL recycles its ID. Upgrade/ownership conversion transfers that identity. Loading restores policies and city/unit representations without repeating XP, healing, free policy, WLTKD or chapter rewards. Keep the same mod identity when updating, and back up saves before changing DLL/mod versions.

## Strategy and weaknesses

Build Sporting Academies early, train units in several cities, and preserve graduates until Level 4. Fight opponents with comparable base strength to build Ambition. Upgrade existing forces rather than replacing their veterans with fresh advanced units. The Renaissance unlock favors fast attacks from open ground; the Industrial chapter rewards decisive city captures with carefully timed cooldowns. Generals support veteran survival, while overseas cities and Golden Ages provide late Culture/Tourism.

Early rushes, veteran losses, anti-mounted units, ranged attrition, multiple fronts, difficult terrain and enemies withdrawing their wounded units all threaten this strategy. Losing centuries-old veterans meaningfully weakens the civilization. Flavors map to real Civ V fields, but AI selection is disabled by request.

## Art and limitations

Original imagegen artwork supplies the veteran Ronaldo leader and cinematic journey Dawn; no official photographs or club logos are bundled. Original code-drawn icons supply all seven chapters, UA, Ambition, unique components, promotions, civilization emblem and transparent unit flag. The Dawn map is an explicitly illustrative route map. Leader art is a static fallback scene; the Forward uses standard Cavalry animations/model. See `art-source/CristianoRonaldo/README.md` for the generation prompt and asset slots.

The military purchase rebate, ranged defense interpretation and inferred GP birth timing are described above. Lua gameplay is deterministic where practicable, but ordinary Civ V UI-addin gameplay and OpenSaveData are **not certified for network multiplayer or hotseat**; manifests disable those modes. No runtime Civ V gameplay, selection-screen, popup layout, save-file, FPS, turn-time or game-log verification has been performed. Automated Lua mocks are not a substitute for actual DLL playtesting.

## Verification and practical in-game checklist

Run `python tools/validate_ronaldo_mod.py` for installed-schema SQL, inherited baseline checks, DDS decoding/DirectXTex, Lua 5.1 syntax, and deterministic event-sequence regression tests. `python tools/validate_all.py` validates the combined collection. Read `docs/Validation.md` for the actual recorded results.

1. Start with CP + one package. Confirm manual selection works, random AI excludes Ronaldo, Funchal is first, all portrait/flag/DOM art appears, and the CR7 button opens/closes at the supported screen size.
2. Train versus purchase units. Confirm the Academy retains baseline Barracks XP, graduates carry the right origin, XP bonuses stack, and one Level 4 reward per city/era survives an upgrade and reload.
3. Earn more than three promotions and comparable kills in one turn; save/reload mid-turn and confirm limits persist. Check weaker-unit/civilian defeats do not award combat Ambition.
4. Exercise every Ambition source, especially General/Admiral births, genuine Wonder completion, population milestones, Level 6 per era and repeated original-capital captures. Inspect `Lua.log` and `Database.log` for relevant errors.
5. Cross every threshold before and after its era gate. Confirm popup queues, permanent bonuses, capital Academy tech gating, military rebate, full VII healing/XP/free policy/WLTKD, and legacy rewards after the fifth percentage increment.
6. Upgrade the same surviving unit repeatedly. Check one Reinvention tier, cap III before VI, cap IV afterward, pre/post-VI XP behavior and healing below 35% HP. Save/reload after each upgrade.
7. With a Forward, verify wounded-target strength, rivers, one movement refund per turn, no additional attack, 8 HP healing and the reduced 5 HP/8% promotion after upgrade. Combine with Reinvention and ensure no tier is counted twice.
8. Check fresh-turn movement at 90/91 HP, wounded/city attacks, open-ground source tile, major-unit General points, experienced city-capture cooldowns and the documented war-participant XP selection.
9. Move two Generals in/out of range and kill one/both. Check no duplicated aura/healing, native +3 General aura, ranged defense and the 30-turn defensive war response.
10. Found/capture/lose/raze/refound overseas cities, relocate the capital and research Flight. Confirm no city outside the three eligible slots or under foreign ownership retains a dummy bonus.
11. Repeat representative tests on Quick/Epic/Marathon, load real saves, and compare FPS and turn time with the Career screen hidden and open. Report unsupported DLL behavior before treating this version as runtime verified.
