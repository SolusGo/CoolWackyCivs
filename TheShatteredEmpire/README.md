# The Shattered Empire

**Leader:** The Last Emperor · **Capital:** Aeternum · **UA:** The Weight of an Empire

**UU:** Imperial Legion (Warrior) · **UB:** Provincial Governor's Palace (Monument)

For Civilization V: Brave New World with Community Patch v151. Human selection is enabled and AI selection is disabled (`Playable = 1`, `AIPlayable = 0`). Start a new single-player game. Multiplayer and hotseat are disabled in both packages.

## Install

Build either package without ModBuddy, from the collection repository:

```powershell
python tools/build_mod.py
python tools/build_shattered_mod.py
```

For the collection, extract `dist/Cool Wacky Civs (v 20).zip` into `%USERPROFILE%/Documents/My Games/Sid Meier's Civilization 5/MODS/`. For the standalone civilization, extract `dist/The Shattered Empire (v 1).zip` there instead. The resulting folder must directly contain its `.modinfo`. Alternatively, place the corresponding `.civ5mod` in MODS and let Civ V extract it.

Enable Community Patch and **one** package in the game's Mods menu, continue through the modded setup, and choose The Shattered Empire / The Last Emperor. Remove or disable older collection versions. Do not enable standalone and collection together: their manifests block duplicate registration. No ModBuddy or additional DLL is needed. Nothing in the build scripts writes into the installed game.

## Rule the Empire

The first capital is raised to at least 2 population. Two population-1 provinces are founded on connected land within eight tiles through CP's normal `CanFound` and `Found` pipeline. Fog alone does not prevent placement: only a selected eligible tile is temporarily revealed, failed candidates return to fog, and successful cities retain their normal native sight. Natural and pseudo-natural wonders are excluded before revelation. A bounded local flood cannot cross sea or mountain barriers. Occupancy, minimum city spacing, terrain, wrapping and rival starting sites are respected. Each unavailable provincial entitlement grants one Settler instead. Saved pending grants recover interrupted founding, revelation and unit callbacks without duplication. Loading into an established campaign does not grant a new starting empire.

Authority starts at 82 and remains between 0 and 100. Golden (80+), Stable (60+), Strained (40+), Fractured (20+) and Collapse affect provincial Loyalty. Conquests reward 4 Authority once per plot, defensive victories reward 1 with a cap of 2 per turn, demands reward 2, and suppression rewards 5 (7 under Monarchy). Military-only civil wars add 10 Authority. A clean mixed restoration adds `floor(10 × suppressed factions / participating factions)`; negotiated-only, exhausted or failed wars add no completion bonus. Settlement costs and consequences remain unchanged. Diplomatic reunification still qualifies for Imperial Restoration; the Chronicle and Overview distinguish the outcomes. City loss costs 8; capital loss costs 20. Each province costs 1 Gold in administrative maintenance.

Every non-capital city receives a persistent named Governor with Loyalty, Ambition, Prestige, an imperial relationship and a short political history. Loyalists provide +5% Gold; Militarists +10% military Production; Merchants +10% Gold; Populists +10% Food and 1 local Happiness; Ambitious Governors +10% Production. Rebel Governors lose those bonuses. High Ambition with high Loyalty remains useful.

Political updates occur every five Standard-speed turns. Garrisoning, capital connections, Palaces, charters, Authority, personalities, Happiness, distance, prolonged war and overextension change Loyalty, capped at ±8 per update. Administrative capacity begins at five cities and grows by two per era, so the starting three-city empire is manageable. The Governors tab shows the actual factors used in the previous update.

Governors request garrisons, connections, Walls, growth, additional Farms, feasible strategic improvements, nearby camp removal, peace, financial assistance or autonomy. Only one new petition per player turn generates a notification. Pay, fulfill, refuse, replace or grant a charter through the Decisions tab. Each payment scales with population, income and speed. Changes have cooldowns and ownership/identity/affordability checks.

Peacetime charters require a Palace and a loyal or discontented province: pay 50% of its normal Gold price and 5 Authority for +15 Loyalty, +12 Ambition and ongoing autonomy. Wartime autonomy requires the Palace, 200% Gold and 10 Authority, including when an already autonomous province rebels again. It ends that faction, raises Loyalty to at least 70 and adds 20 Ambition. Permanent hereditary privileges add another 0.5 Ambition each political interval and survive replacing the Governor. Other civil-war participants keep fighting until separately resolved. Reconciliation remains 15 Authority, and existing petition/war completion rewards remain. AI uses the same affordability checks. Decisions show actual costs and consequence tooltips.

Autonomous Governors cannot request another charter. Technology, resources, build legality, ownership and targets are checked when petitions are issued and while they remain active. A petition that becomes impossible is withdrawn without a Loyalty/Ambition penalty; completion and deadlines remain persistent. A financial request supplies the reliable fallback.

Below 45 Loyalty, a province suffers discontent; below 25, defiance. Two consecutive critical political checks permit armed revolt. Rebels are tracked barbarian military units associated with a Governor and province, with era-appropriate strength, safe spawning, finite recruitment and clear resolution. Destroy the tracked army or negotiate autonomy, compensation or reconciliation. An inaccessible revolt eventually exhausts its support and accepts autonomy, costing Authority.

A War of the Crowns can begin below 30 Authority when at least three severely disloyal provinces are geographically close to an ambitious claimant. It records the claimant, provinces, armies, defections, dates, resolution and restoration. Other estranged nearby Governors can join. Only one major war can be active; a cooldown follows resolution.

Land combat units have persistent lineage identities, home provinces and Oaths. A recruiting Governor's disloyalty erodes Oaths; victories improve them. Eligible standard units with Oaths below 40 can defect only during an active rebellion. Garrisoned troops, civilians, cargo, embarked units and other mods' unique units are protected. Defection creates a valid rebel replacement before removing the imperial unit, retaining experience and safe permanent promotions. CP conversion hooks preserve Oaths and lineage through upgrades.

Ordinary recruitment stays capped at eight per faction. Defections have a separate persistent allowance of two per faction, six across active factions and the shared cap of 24 tracked live rebels. Exhausting recruitment cannot protect a disloyal veteran. Repeat calls/reloads cannot replenish spent allowances. Rebels retain eligible experience/promotions but lose imperial bonuses; upgrades and ownership changes immediately refresh conditional promotions.

The Legion has strength 10 and costs 15% more than the active Warrior, rounded up. Its persistent Discipline grants +15% strength in friendly territory when Authority is at least 60, for attack and defense through the native promotion. The Palace inherits the active Monument exactly once, adds 1 Gold, supports provincial Loyalty and enables charters. In the capital it awards 1 Authority per ten Standard-speed turns.

From the Classical Era, choose one reform, paying 10 Authority with a thirty-turn cooldown: Absolute Monarchy improves capital military production and suppression but alienates distant provinces; Federation supports chartered provinces and adds capacity but reduces their Production; Dictatorship adds 15 effective Legion Oath while active and strengthens counterinsurgency while growing militarist ambitions. Era transitions can call a succession Council after a forty-turn minimum reign interval. Blood, Steel and Council successors have persistent candidates, costs and benefits. Choose in Dynasty; the Council/AI decides when a deadline expires.

After recovering from a major collapse or civil war, sustain Authority 75+, average Loyalty 80+, and freedom from rebellions/succession for twenty Standard-speed turns to earn **The Empire Reborn**: +10% Production and Culture in all cities. Renewed instability makes these bonuses dormant. Further rebellions remain possible.

Open **Imperial Administration** near the top panel for Overview, Governors, Decisions, Military Oaths, Reforms, Dynasty and Chronicle. The screen refreshes on events and hides in City View, diplomacy and other popups. AI rulers use the same costs, loyalty rules and rebellion mechanics, make political decisions automatically and direct nearby idle soldiers toward garrisons when at peace. Civ V's tactical AI controls combat against rebels.

## Validation and limits

Run `python tools/validate_shattered_mod.py` or `python tools/validate_all.py`. Automated tests use real BNW/CP SQL definitions and Lua 5.1 mocks; they do **not** execute Civ V. See [Validation.md](docs/Validation.md) for confirmed checks and the required in-game checklist, and [Implementation.md](docs/Implementation.md) for engine contracts and compromises.

The updates retain version-1 save keys, fill missing defection/start fields and rebuild transient effect caches on reload. Active older wars reconstruct resolved outcomes from retained faction records; undocumented resolutions receive no invented military credit. Completed historical war records and previous rewards remain unchanged. High-frequency commits update dirty cities/units and combine nested synchronous callbacks into one final snapshot; completed player actions are still saved immediately. See the implementation report for the exact changed files and remaining engine uncertainties.

Custom armies use the stock Warrior model and inherited upgrades. The leader is an original static painting. Rebel factions share the barbarian slot and cannot conduct independent diplomatic negotiations; political negotiations are explicit Administration actions. Dictatorship's native +10% modifier also applies to ordinary barbarians. Demands do not force declarations of foreign war. Full Huge-map engine testing, AI tactical behavior and balance remain unverified.

Artwork masters and exact built-in ImageGen prompts are in [art-source/TheShatteredEmpire](../art-source/TheShatteredEmpire/PROMPTS.md); compiled assets are in `Art/`. The complete original request is preserved in [OriginalDesign.md](docs/OriginalDesign.md).
