# The Kingdoms

A Civilization V: Brave New World civilization for Community Patch v151 or newer. Every city is a Kingdom. Noble Houses govern its wealth, press demands, compete for the Throne and carry their history into later eras.

- **Capital:** Kings Throne.
- **Diplomatic identity:** The Throne (`LEADER_THE_THRONE`). Actual kings and queens are generated, numbered and displayed prominently in the Overview.
- **UA — The Kingdoms United:** Persistent Houses, influence-weighted Stability, House and ruler benefits, demands, alliances, succession and painful internal civil wars.
- **UU — The King's Guards:** Longswordsman replacement, 28 Strength, up to seven living named champions. Candidate appointments, permanent personality promotions, House affiliation, normal military upgrades and individual loyalty decisions. Remains trainable in later eras.
- **UB — The Kingdom's Wall:** All active Walls effects, plus +1 local Happiness, +2 Production and +5 Kingdom Stability.
- **AI:** Playable by humans and AI. AI appointments, appeasement, faction funding and oath decisions require no human interaction. Single-player only.

Open **KINGDOMS** below the top panel. Overview shows the current ruler and Realm Stability. Kingdoms shows local Houses, demands, lineage and actions. Succession shows claims or wartime factions. Guards handles appointments and personal loyalty. Chronicle filters persistent events by category. Appointment panels open when an eligible human receives a new Guard; you can close them and return later. Pending Guards can defend but cannot attack.

Houses begin with two persistent traits. Influence percentages are normalized within each Kingdom; claims are relative political scores, not literal random probabilities. New cities begin with two Houses. Population targets are 2/3/4/5/6/7 at 1/4/7/10/14/19 population, with formations spaced across turns. A schism can temporarily exceed the population target by one House. Losing population does not erase established lineages.

Demands favor House personalities, check legal targets and limit simultaneous requests. Completing a request grants +18 Loyalty, +5 Prestige and +3 Influence. Expiry costs 12 Loyalty; refusal costs at least 22, depending on House/ruler personality. Invalidated targets are withdrawn without punishment. Treasury Gifts spend Gold, Estates temporarily reduce local Production, and Charters or Military Authority strengthen potentially dangerous claimants.

The Farm demand retains its existing **two new Farms** rule: the count of unpillaged Farms must increase by two from the count when the demand was issued. Farms must be on owned plots assigned to that Kingdom within its radius of three tiles; citizens need not work them. Existing valid Farms form the baseline and do not fulfill the new request. Pillaging, repairs and plot reassignment affect the current count, so progress measures the net increase rather than recording Worker build events.

Healthy successions crown the leading claimant. Stability below 45 brings a civil war; an extreme crisis at 10 or lower can depose a ruler. Coalitions form from claims, relationships, dynasty loyalty and personalities. Wars use internal scores, events, defections, player backing and limited Barbarian rebels, preserving Civ V player slots. Civil war costs **25% Food, 30% Production, 20% Gold, 15% Science, 15% combat strength and 3 global Happiness per Kingdom**. A dominant coalition can win after five Standard turns; maximum resolution is twenty. Defeated Houses retain political scars. All civil-war modifiers are removed at resolution.

Civil wars begin with **Neutral** royal backing. Supporting a coalition commits your backing and applies its normal House effects. Choosing **Remain neutral** withdraws that backing without changing House Loyalty, relations, coalition membership or strength; the usual action cooldown still applies, and existing timed supply/concession penalties expire normally. Guard opposition requires backing a valid rival coalition, low House Loyalty and the existing random check. Neutrality alone causes no oath crisis. Each unique hostile House pair costs two local Stability, capped at ten, even though relationships are stored in both directions.

Build the collection with `python tools/build_mod.py`. Alternatively, `python tools/build_kingdoms_mod.py` builds **The Kingdoms (v 1).civ5mod** and its ZIP from pure SQL, Lua, UI XML and DDS files. ModBuddy is optional. Enable either this standalone mod or Cool Wacky Civs v18, which includes it. Do not enable both.

See [Implementation report](docs/Implementation.md), [validation and engine checklist](docs/Validation.md), and the supplied [original design](docs/OriginalDesign.md). Automated SQL/Lua tests pass; actual Civ V gameplay and visual smoke tests remain to be run.
