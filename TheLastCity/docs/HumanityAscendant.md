# Humanity Ascendant — implementation report

Humanity Ascendant turns the survivors of the Final Night into an intentionally powerful one-city civilization. It rewards the accumulated expertise and defenses of Last Light, enabling ordinary victory pursuits while refugees, hunger, disease, crises and Endless Survival continue. It does not declare a conventional Civ V victory.

## 1. Files modified

- `Lua/LastCityConfig.lua`: separate post-Final Night virtual values; normal configuration remains intact.
- `Lua/LastCityEconomy.lua`: derived unlock, phase-aware infrastructure, medical power, ration growth, expert and legacy totals, mutually exclusive native building effects.
- `Lua/LastCityCore.lua`: include the phase in defense-cache invalidation.
- `Lua/LastCityInvasions.lua`: mutually exclusive amplified local promotions and immediate Final Night reconciliation.
- `SQL/02_LC_Effects.sql`: five new ASC dummy types, twelve ASC promotions, +100% Endures and Civilopedia concept.
- `SQL/03_LC_Art.sql`: ASC promotions reuse their corresponding original Last City custom icons, with unchanged atlas dimensions.
- `SQL/10_LC_Text.sql`: generated phase-aware Council, promotion, infrastructure and Civilopedia descriptions.
- `UI/SanctuaryCouncil.lua` and `.xml`: gold heading, subtitle, live expert contributions, phase-aware summaries, previews and works; taller expert rows fit two lines.
- `tools/create_lastcity_database.py` and `tools/lastcity_localization.py`: reproducible SQL/art registration/localization changes.
- `tools/validate_lastcity_mod.py`, `tools/tests/lastcity_ascendant.lua`, `tools/tests/lastcity_ui_assertions.lua`: actual-SQL-driven checks and fresh-runtime simulations.
- README, implementation/validation docs, and both checked-in manifests: explain mechanics and register current source hashes. No new runtime file, DLL, specialist slot, currency or project registration is needed.

## 2. Exact bonuses

| Mechanic | Survival phase | Humanity Ascendant |
|---|---:|---:|
| Assigned Scientist | +3% Science each; +15% at five | +100% each; +500% at five |
| Assigned Engineer | +3% Production each; +15% at five | +100% each; +500% at five |
| Assigned Scholar | +3% Culture each; +15% at five | +80% each; +400% at five |
| Assigned Veteran | +2% local Defense each; +10% at five | +10% each; +50% at five |
| Assigned Farmer | +2 Provisions/turn each; +10 at five | +12 each; +60 at five |
| Assigned Physician | 1 medical power each; 5 at five | 3 each; 15 at five |
| Hospital | +2 medical power | +2 medical power, total 17 with five Physicians |
| Humanity Endures | Inactive before final victory | +100% Production, replacing former +5% |
| United, Morale ≥80 | +10% Production, +5% local Defense | +100% Production, +20% local Defense |
| Generous | Add 15% of positive Food surplus | Add 50% of positive Food surplus |
| District Housing | +6 | +12 |
| Barracks Housing | +4 | +8 |
| Residential Quarter Housing | +8 | +16 |
| Underground Shelter Housing | +10 | +20 |
| All four, undamaged | Baseline 12 + 28 = 40 | Baseline 12 + 56 = 68 |
| Owned, completed, unpillaged Farm/Fishing Boats in city radius | +1 Provisions each | +3 each |
| Built Waterworks | +4 Provisions/turn | +16 |
| Storehouses capacity | +75 | +150 |
| Depot capacity | +100 | +200 |
| Both storage buildings | Baseline 200 + 175 = 375 | Baseline 200 + 350 = 550 |
| Sanctuary | +15% local Defense | +30% |
| Each completed Major Siege | +2% City Defense; cap +30% | +4%; cap +60% at fifteen |
| Each earned Last Watch rank | +3% local Defense; cap +15% at five | +6%; cap +30% at five |

At five Engineers and United Morale, +500% Engineers +100% Endures +100% United = **+700% Production** from these sources. Five Scientists give **+500% Science**, five Scholars **+400% Culture**. Without United, Production is +600%; Anxious/Unrest/Breaking yield +595%/+585%/+570% with five Engineers. Native effects from other buildings, policies, happiness and processes may further alter final yields.

These are additive native percentages. With no other modifiers, +700% corresponds to an 800% multiplier, not three successive multipliers. CP 5.4.6 `SetNumRealBuildingTimed` passes the count delta to `processBuilding`; the latter multiplies each building's yield modifier by that delta. The accumulator adds the values and `getBaseYieldRateModifier` adds 100. Counts above one are preserved by `GetNumBuilding`. This was verified from the source matching installed CP v151, commit `dcb33a654cd9e8efb038a0733b4025e19cbcd8ba`; it has not been observed in a running Civ V game. [Count processing](https://github.com/LoneGazebo/Community-Patch-DLL/blob/dcb33a654cd9e8efb038a0733b4025e19cbcd8ba/CvGameCoreDLL_Expansion2/CvBuildingClasses.cpp#L5960), [yield processing](https://github.com/LoneGazebo/Community-Patch-DLL/blob/dcb33a654cd9e8efb038a0733b4025e19cbcd8ba/CvGameCoreDLL_Expansion2/CvCity.cpp#L14610), [base multiplier](https://github.com/LoneGazebo/Community-Patch-DLL/blob/dcb33a654cd9e8efb038a0733b4025e19cbcd8ba/CvGameCoreDLL_Expansion2/CvCity.cpp#L23006).

## 3. Trigger

Only `s.dawn == 'ENDURES'` activates the bonuses. The existing legitimate Final Night resolution remains responsible for that phase: all tagged spawned attackers must be confirmed defeated, and the final force must meet its existing eligibility threshold. ResolveWave then invalidates local defense inputs and reconciles effects. Inside a player-turn transaction reconciliation occurs at its completion; direct resolution reconciles immediately. No extra payment, project or decision is introduced.

`s.achievement` still prevents repeated Humanity Endures history/notifications, but cannot activate Ascendant independently. Dawn construction, pending or active Final Night, failed/undersized final encounters and twelve ordinary victories retain normal effects.

## 4. Duplicate prevention

Normal +3% expert counts are zero after Ascension; amplified counts equal assignments, 0–5. Before Ascension, amplified counts are zero and normal counts equal assignments. United and siege-legacy dummy variants also replace one another. Endures has exactly one copy when active.

Local Sanctuary, United Resolve, Veteran training and Watch-rank active promotions clear every unselected tier and variant. Persistent earned-rank markers do not change. Movement, creation, upgrades, assignment changes and load reconciliation select current ownership/radius/phase; foreign conversion strips sanctuary effects and transferred ranks. Repeated calls assign exact counts/flags instead of adding effects. Council refreshes only read state. `lastTurn` guards Food/economy mutation and fractional Food is saved.

## 5. Older saves

Existing completed saves automatically gain amplified effects during Initialize/LoadScreenClose reconciliation. Native normal buildings/promotions are removed, historical siege counts and earned Watch ranks gain their new values, and Housing/capacity are recalculated. Stockpiles, assignments, pending events, cooldowns, achievement, history and turn identity are retained. Capacity growth grants no Provisions. No schema bump or new persisted flag is required; existing schema-1 migration and schema-2 checksum protection remain.

All earlier Dawn phases keep the pre-Final Night mechanics. Reload does not process a turn, grant ranks, replay the achievement or re-register handlers.

## 6. Preserved balance and conditions

Normal expert SQL remains +3% per Engineer/Scientist/Scholar; normal Veteran training is +2%, Sanctuary +15%, United +10% Production/+5% local Defense, siege legacy +2% and Watch rank +3%. All normal virtual values and ration policies remain intact. Negative Morale effects remain −5%/−15%/−30% Production. The former +5% Endures effect changes only after victory.

Assignment cap remains five and reserve cap 50. Only assignments contribute. Local unit bonuses require owned eligible defenders within three plots, and Watch ranks must have been earned. Housing/storage/Waterworks bonuses require their buildings; improvements require ownership, completion, no pillage and native city radius. Damage is subtracted after Housing amplification. Baselines remain 12 Housing, 200 capacity, four income and two District income. Ration consumption, Morale, cooldown and shortage penalties are unchanged. Disease retains positive probability, cost, duration and mortality floors; strong protection does not eliminate outbreak events. The Hospital remains two medical power.

Refugees, crises, hunger, disease, expert losses and Endless Survival remain active. Enemy strength, spawning, timers, normal victory availability and one-city/no-conquest restrictions are unchanged. Percentages, per-turn Provisions, capacities and medical power do not scale by speed. Existing interval, lump-cost and gradual attrition scaling is preserved.

## 7. Council and Civilopedia

The launcher and title display gold **HUMANITY ASCENDANT**; Overview begins with **“We were the last. Now we shall be the first.”** It shows current Housing/capacity, income/consumption/net, upcoming or active invasion, current Morale bonuses, amplified legacy and expert totals, medical protection and the additive Production total including negative Morale penalties.

Experts show live assigned contributions and phase-correct tooltips. Ration previews use the same growth/shortage calculation as the economic tick. Works show amplified values after Ascension. The Chronicle preserves existing achievement/history. Civilopedia explains the unlock, exact values and conditions. Seven tabs and event-driven updates remain; there is no frame polling or new UI state owner. Existing original custom art is reused for corresponding amplified promotions.

## 8. Automated validation

Validation is against the actual BNW/CP SQL schema and Lua 5.1 with stateful API mocks. The focused suite adds ten fresh-runtime Ascendant cases and four speed profiles to the existing suite, plus Council transition/value checks. It covers:

- 0/1/3/5 assignments, native SQL modifier inputs, unassignment, cap rejection and expert losses.
- Every specified bonus, old values before all four earlier phases, achievement-flag independence, negative Morale and conditional United.
- Legitimate final transition, failure/early construction, historical completed and pending saves, repeated reloads, achievement deduplication and continued invasions.
- Owned local defense at distance three/four, new units, earned rank amplification, upgrades, foreign transfer/return, tier exclusivity and siege cap/exactly-once rewards.
- Incremental Housing/storage construction, damage, no free stock, owned/unowned/remote improvements, pillage/repair and built/unbuilt/disrupted Waterworks.
- Fractional Generous Food and repeated turn callbacks, unchanged other rations and shortage penalties.
- Triple Physician power, unchanged Hospital, disease probability floors, positive costs and bounded duration, possible severe untreated infection, starvation mortality, reserve cap and all 45 crisis decisions after Ascension.
- Quick/Standard/Epic/Marathon, normal inland, tiny-island naval and crowded 22-player mock maps with bounded spawn work.
- Live Council heading, subtitle, expert tooltips/totals, infrastructure, ration preview, Morale/legacy totals and 100 refreshes without compounding.

The full collection run, real Firaxis manifest-task check and both package builds are recorded in [Validation.md](Validation.md). Tests do not edit installed mods or game caches.

## 9. Engine limitations

Generous growth remains the established stored-Food adjustment based on positive native surplus, not a new native Growth setter. Native growth, Happiness and turn ordering still govern Population and threshold handling.

Siege legacy keeps the established `GlobalDefenseMod` field. CP applies it to the team's city building-defense modifier: +60% here is not a promise of +60% to total displayed city strength, which includes other sources. A shared-team setup can inherit this existing city-defense effect. The requested numerical field values are implemented exactly; unit bonuses remain local and owned. [Native team defense path](https://github.com/LoneGazebo/Community-Patch-DLL/blob/dcb33a654cd9e8efb038a0733b4025e19cbcd8ba/CvGameCoreDLL_Expansion2/CvTeam.cpp#L755).

Humanity Endures remains a saved narrative achievement, not a Steam achievement or new DLL victory. The mod retains single-player support and inherited animated unit/world models. Native enemy AI, barbarian ransom, other-mod interactions and save storage remain subject to the existing implementation limits.

## 10. Unverified in-game behavior

Civilization V was not launched for this task. Native Science/Production/Culture tooltips and final yields, displayed city strength, actual combat results, Council rendering/wrapping, stored-Food growth thresholds, native save-slot restoration, tactical AI and Huge-map timing need in-game checks. Source verification, mocked tests, SQL activation and real SDK manifest generation are distinct from gameplay testing.

Install the rebuilt standalone v1 or collection v23 package, enable just one package with BNW/CP, and reload an existing Last City game to test old-state reconciliation. Use a pre-final save and a completed save, then check native values at 0/1/3/5 assignments, Morale 80/79 and repeated reloads. Complete a legitimate Final Night in a new run and verify the immediate transformation, unchanged city restriction and later invasions. See the expanded native checklist in [Validation.md](Validation.md).
