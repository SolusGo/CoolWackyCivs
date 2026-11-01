# Cool Wacky Civs

18 human-only civilizations for Civilization V: Brave New World and Windows **Community Patch v151**. One collection package, with separate pure-file options for The Kingdoms, The Shattered Empire, The Last City and The Relentless Seven.

**Current source:** mod version 28 - **Civilopedia and strategy handbook**. [Patch notes](PATCHNOTES.md)

**Start here:** [Choose a playstyle](docs/StrategyGuide.md) · [Who pressures whom](docs/Matchups.md) · [Installation and builds](#build-and-validation)

Every guide includes opening priorities, development, late-game conversion, pros, cons, mistakes, counterplay and four named matchup examples. The in-game civilization and leader Civilopedia pages show practical guidance before their preserved lore.

Named custom-civ matchups are conditional theorycraft or scenario comparisons, not tested win rates. All custom civs are human-only, and multiplayer/hotseat are unsupported. General counterplay advice still applies against normal single-player opponents.

## Civilization roster

| Civilization | Leader | Playstyle | Guide |
| --- | --- | --- | --- |
| Rou'ls Ascendancy | Trent Rou'ls, the Unbodied | Veteran attrition and positional warfare | [Strategy](docs/strategy/RoulsAscendancy.md) · [Full rules](RoulsAscendancy/README.md) |
| Luna Network | GPT-5.6 Luna | Wide expansion and construction tempo | [Strategy](docs/strategy/LunaNetwork.md) · [Full rules](LunaNetwork/README.md) |
| Terra | GPT-5.6 Terra | Planned city specialization and terrain-aware infantry | [Strategy](docs/strategy/TerraFramework.md) · [Full rules](TerraFramework/README.md) |
| The Capano Circuit | Enrico Capano | Patient combat projects and terrain-trained veterans | [Strategy](docs/strategy/CapanoCircuit.md) · [Full rules](CapanoCircuit/README.md) |
| The Filthy Realm | Filthy Frank | Foreign-city disruption and timed active control | [Strategy](docs/strategy/FilthyRealm.md) · [Full rules](FilthyRealm/README.md) |
| The Dual Order | Grandmaster Severin | Faith-supported military infrastructure and defensive campaigning | [Strategy](docs/strategy/DualOrder.md) · [Full rules](DualOrder/README.md) |
| RomanGladius Network | Lachlan "RomanGladius" | Population management and a stable wide economy | [Strategy](docs/strategy/RomanGladiusNetwork.md) · [Full rules](RomanGladiusNetwork/README.md) |
| Eternal Number Ten | Lionel Messi | Great People, diplomacy and a permanent career progression | [Strategy](docs/strategy/EternalNumberTen.md) · [Full rules](EternalNumberTen/README.md) |
| Beyond the Sky | Masaya Hinata | Exploration-driven mobile land warfare | [Strategy](docs/strategy/MasayaBeyondSky.md) · [Full rules](MasayaBeyondSky/README.md) |
| The First Night | PaulsoaresJr | Exploration and early memories with later recall | [Strategy](docs/strategy/PaulsoaresJr.md) · [Full rules](PaulsoaresJr/README.md) |
| Viltrum | Grand Regent Thragg | Conquest momentum with an unavoidable biological crisis | [Strategy](docs/strategy/ViltrumEmpire.md) · [Full rules](ViltrumEmpire/README.md) |
| Token Network | Axiom, Keeper of Context | A shared resource economy with selectable tactical and economic tools | [Strategy](docs/strategy/TokenizedIntelligence.md) · [Full rules](TokenizedIntelligence/README.md) |
| The Kingdoms | The Throne | Political stability, controlled expansion and named guards | [Strategy](docs/strategy/TheKingdoms.md) · [Full rules](TheKingdoms/README.md) |
| Sol Intellect | GPT-5.6 Sol | Tall specialist science and patient construction | [Strategy](docs/strategy/SolIntellect.md) · [Full rules](SolIntellect/README.md) |
| Shattered Empire | The Last Emperor | A strong initial footprint constrained by provincial politics | [Strategy](docs/strategy/TheShatteredEmpire.md) · [Full rules](TheShatteredEmpire/README.md) |
| The Last City | The Warden | One-city survival and siege preparation | [Strategy](docs/strategy/TheLastCity.md) · [Full rules](TheLastCity/README.md) |
| The Relentless Seven | Cristiano Ronaldo | Preserved military veterans and a seven-chapter career | [Strategy](docs/strategy/CristianoRonaldo.md) · [Full rules](CristianoRonaldo/README.md) |
| The Boy Who Touched Paradise | Lionel Messi | Great Person culture, national expectations and recovery | [Strategy](docs/strategy/TheBoyWhoTouchedParadise.md) · [Full rules](TheBoyWhoTouchedParadise/README.md) |

All 18 have `Playable=1`, `AIPlayable=0`. Native gameplay, rendering and save acceptance remain incomplete; the full rules and testing records distinguish implemented mechanics from outstanding engine checks.

## UA, UU and UB roster

**UA** = Unique Ability · **UU** = Unique Unit · **UB** = Unique Building. Each civilization guide also identifies additional units and unique improvements (**UI**).

| Civilization | UA | UU(s) | UB(s) |
| --- | --- | --- | --- |
| [The Boy Who Touched Paradise](TheBoyWhoTouchedParadise/README.md) | He Was Always the Point of Difference | El Diez (unique civilian hero) | El Potrero (Amphitheater); The Last Dance (National Wonder); The Eternal Number Ten (capital memorial) |
| [The Relentless Seven](CristianoRonaldo/README.md) | Work Until Greatness Becomes Habit | Complete Forward (Cavalry) | Sporting Academy (Barracks) |
| [The Rou'ls Ascendancy](RoulsAscendancy/README.md#ua-uu-and-ubs) | The Flesh Is a Coat | Hollowhound (Rifleman); Matriarch of the Choir (Great General); Buddy, Everlasting (Standalone Biology-era naval unit) | Somatic Lattice (Hospital); The Choir Eternal (Heroic Epic) |
| [The Luna Network](LunaNetwork/README.md#ua-uu-and-ubs) | Low Latency | Packet Settler (Settler) | Cache Node (Library) |
| [The Terra Framework](TerraFramework/README.md#ua-uu-and-ubs) | Adaptive Intelligence | Adaptive Operative (Musketman) | Multimodal Hub (Market) |
| [The Capano Circuit](CapanoCircuit/README.md#ua-uu-and-ubs) | Impossible Until It's Possible | Route Setter (Worker) | Competition Coaching Centre (Armory) |
| [The Filthy Realm](FilthyRealm/README.md#ua-uu-and-ubs) | Welcome to the Rice Fields | Peace Lord (Great War Infantry) | Filthy Kitchen (Broadcast Tower) |
| [The Dual Order](DualOrder/README.md#ua-uu-and-ubs) | Twin Mandates | Divided Templar (Longswordsman) | Hall of Concordance (Armory) |
| [The RomanGladius Network](RomanGladiusNetwork/README.md#ua-uu-and-ubs) | The Server Network | Server Owner (Settler) | Server Console (Monument) |
| [The Eternal Number Ten](EternalNumberTen/README.md#ua-uu-and-ubs) | From Rosario to Immortality | The Number Ten (Great General) | La Masia (Garden) |
| [The Boy Beyond the Sky](MasayaBeyondSky/README.md#ua-uu-and-ubs) | I'll Be the First to Fly Beyond the Sky | Junior FC Prodigy (Horseman) | Grav-Shoe Practice Room (Barracks) |
| [The First Night](PaulsoaresJr/README.md#ua-uu-and-ubs) | How to Survive & Thrive | Survivor (Scout) | Starter House (Monument) |
| [The Viltrum Empire](ViltrumEmpire/README.md#ua-uu-and-ubs) | Blood of Conquest | Viltrumite Warrior (Infantry) | Viltrumite Breeding Complex (Military Academy) |
| [The Tokenized Intelligence](TokenizedIntelligence/README.md#ua-uu-and-ubs) | Context Window | Inference Agent (Infantry) | Inference Cluster (University); Data Centre (Research Lab) |
| [The Sol Intellect](SolIntellect/README.md) | Deep Deliberation | None | Context Archive (University); Reasoning Institute (Public School) |
| [The Kingdoms](TheKingdoms/README.md) | The Kingdoms United | The King's Guards (Longswordsman; seven living identities) | The Kingdom's Wall (Walls) |
| [The Shattered Empire](TheShatteredEmpire/README.md) | The Weight of an Empire | Imperial Legion (Warrior) | Provincial Governor's Palace (Monument) |
| [The Last City](TheLastCity/README.md) | The Final Sanctuary | Last Watch (Spearman) | Sanctuary District (Granary) |

**Additional uniques:** Capano has the **Boulder Sector UI**; Messi has the **Football Academy UI**. Frank can summon **Salamander Man** through his UA. Viltrum retains **Auxiliary Infantry** as a separate conventional option. Rou'ls' **The Choir Eternal** is a unique National Wonder, replacing the Heroic Epic.

## What the units and buildings do

Expand a civilization for its UU and UB effects, plus additional units and improvements. Replacements and UA names are listed in the roster above; the linked guides explain conditions, caps and timing in full.

<details>
<summary><strong>The Capano Circuit — unit and building effects</strong></summary>

- **UU — Route Setter:** Retains Worker actions, has 3 Movement, ignores Hill movement cost and works 25% faster while building on a Hill. Can construct Boulder Sectors.
- **UB — Competition Coaching Centre:** Retains Armory effects and adds +2 Science/+2 Culture. Normally trained land combat units gain Competition Movement: moving at least two adjacent tiles grants +15% attack for the rest of that turn.
- **UI — Boulder Sector:** Starts with +1 Science/+1 Culture/+1 Production and improves with technologies. Eligible land units train once per era for 5 XP and ten turns of +10% rough-terrain strength; post-Plastics training gives +15% SEND rewards.

[Full guide and detailed rules](CapanoCircuit/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Dual Order — unit and building effects</strong></summary>

- **UU — Divided Templar:** 23 strength at +10% Production cost, with Cover I and Schism Strike. Attacks against units below half HP gain +20%; adjacency to a friendly Prophet, Missionary or Inquisitor grants +10% strength.
- **UB — Hall of Concordance:** Retains Armory effects and adds +3 Faith/+2 Production/+5 training XP. Grants +1 Happiness when the city follows your founded religion and +1 Great General Point per turn. Its class also receives the separate Twin Mandates yields.

[Full guide and detailed rules](DualOrder/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Eternal Number Ten — unit and building effects</strong></summary>

- **UU — The Number Ten:** Retains Citadel construction; has 2 Movement and ignores terrain costs/Zone of Control. Adjacent combat units receive turn-long Vision: +1 Movement, ignored Zone of Control and +6% flanking. Can build a Football Academy; assisted killers with Vision heal 5 HP.
- **UB — La Masia:** At Theology, costs 135 Production without a Fresh Water requirement. Provides +15% Great Person generation, +1 Culture and floor(Specialists / 2) Food. A local Great Person birth adds 1 Legacy, one WLTKD turn and a refreshable six-turn +5% Production bonus.
- **UI — Football Academy:** Culture-bombs one tile and provides +1 Culture/+1 Science, plus +1 Tourism after Flight. A stationed unit gains +10% Defense. Adds +1 Gold to its assigned working city if that city has a specialist-slot building.

[Full guide and detailed rules](EternalNumberTen/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Filthy Realm — unit and building effects</strong></summary>

- **UU — Peace Lord:** 52 Combat Strength. Kills grant 5 extra Filthy Points and a one-turn -10% strength debuff to adjacent enemies. Once per unit, Filthy Intervention can force an adjacent enemy below 30 HP to a legal retreat tile and award 10 FP.
- **UB — Filthy Kitchen:** Retains Broadcast Tower effects and adds +2 Tourism. A new Great Work in its city grants 25 Food and the normal 10 FP. Every five turns, its Great Works generate FP, capped at 3 per city.
- **Additional summoned unit — Salamander Man:** For 25 FP, summons a five-turn non-combat unit with 5 Movement. Adjacent enemies suffer -10% strength/-1 Movement; adjacent friendly military units gain +1 Movement.

[Full guide and detailed rules](FilthyRealm/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Luna Network — unit and building effects</strong></summary>

- **UU — Packet Settler:** Costs 90% of the active Settler Production cost, rounded down, and has +1 Movement over the active Settler. Retains normal settlement behavior.
- **UB — Cache Node:** Costs 85% of the active Library Production cost, rounded down. Retains Library effects and adds +1 Production.

[Full guide and detailed rules](LunaNetwork/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Boy Beyond the Sky — unit and building effects</strong></summary>

- **UU — Junior FC Prodigy:** 12 strength and 5 Movement, ignores terrain costs, moves after attacking and ignores river attack penalties, but has -33% city attack. Against a unit with more XP, gains +15% strength, plus another +10% if that opponent is at least one level higher. Survived combats grant 1 XP; the first three also grant 2 Joy each.
- **UB — Grav-Shoe Practice Room:** Retains Barracks training XP and adds +1 Culture/+1 Science. Every third garrisoned owner turn grants 1 Joy. Trained military units gain +1 Movement for ten owner turns, limited exploration XP and a one-time combat-Joy reward.

[Full guide and detailed rules](MasayaBeyondSky/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>PaulsoaresJr — The First Night — unit and building effects</strong></summary>

- **UU — Survivor:** A 2-Movement explorer earning XP from ruins, attributed Natural Wonders, its first three non-starting landmasses and First Journey. Has +5 normal healing abroad, a once-per-lifetime Returning Home reward and an Ancient-lineage Modern-era sight/defense bonus.
- **UB — Starter House:** Provides +2 base Culture and triggers the first-shelter Memory. The original capital's first House anchors Home, which gains +1/+2/+3 Culture and global Happiness at ages 2/4/6 eras.

[Full guide and detailed rules](PaulsoaresJr/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The RomanGladius Network — unit and building effects</strong></summary>

- **UU — Server Owner:** Costs 60% more Production and consumes 2 Population on creation, including purchases. Founding installs a free Console, starts the Server at 60 Reputation and grants ten turns of +50% Food. Later launches charge escalating Gold fees.
- **UB — Server Console:** Provides +2 Culture/+1 Gold and enables Server Management: Reputation, staffing, incidents, roster and chat. Every newly founded Server receives one free.

[Full guide and detailed rules](RomanGladiusNetwork/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Rou'ls Ascendancy — unit and building effects</strong></summary>

- **UU — Hollowhound:** Retains Rifleman strength and 2 Movement at +10% Production cost. Second Skin allows a free eligible reconstruction every 15 turns; adjacent friendly military units grant +3% strength each, capped at +15%.
- **UU — Matriarch of the Choir:** Retains Great General command and Citadel functions. Within two tiles of either endpoint, reduces TRANSMIGRATION from 2 Anima to 1.
- **UU — Buddy, Everlasting:** 45 strength, 5 Movement and 3 Sight. Friendly units within two tiles gain +10% strength and +5 healing in friendly territory; adjacent enemy naval units lose 10% strength. A separate return costs 3 Anima and restores Buddy after three turns at 50% health.
- **UB — Somatic Lattice:** Retains Hospital effects and adds +2 Science/+2 Production. Normally produced military completions have a 25% chance to generate 1 Anima; at zero reserve, a Lattice supplies the empire a 1-Anima fallback every ten turns.
- **UB / Unique National Wonder — The Choir Eternal:** Retains Heroic Epic effects, adds +5 training XP and raises Anima capacity from 5 to 7. An enemy death within three tiles can trigger its 20% per-turn Anima roll.

[Full guide and detailed rules](RoulsAscendancy/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Terra Framework — unit and building effects</strong></summary>

- **UU — Adaptive Operative:** Retains Musketman statistics. At owner-turn start, selects +10 friendly healing in team territory, otherwise +15% rough or open attack/defense according to terrain. Moving does not switch its configuration.
- **UB — Multimodal Hub:** Retains Market effects and adds +1 Science/+1 Culture. Its city gains +1 Production per outgoing domestic or international trade route; arriving and passing routes do not count.

[Full guide and detailed rules](TerraFramework/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Tokenized Intelligence — unit and building effects</strong></summary>

- **UU — Inference Agent:** Retains Infantry baseline statistics. Spend Tokens for one three-scaled-turn mode: +20% attack, +20% defense, +1 Movement, or +25% strength against land units. The mode uses a persistent slot; switching replaces it and costs Tokens.
- **UB — Inference Cluster:** Retains University effects. Adds 75 Context capacity, 15 Tokens per turn and 5 Tokens per Scientist in its city. Capacity scales with Game Speed.
- **UB — Data Centre:** Retains Research Lab effects. Adds 500 Context capacity, 50 Tokens per turn and +10% total local Token generation. Capacity scales with Game Speed.

[Full guide and detailed rules](TokenizedIntelligence/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Viltrum Empire — unit and building effects</strong></summary>

- **UU — Viltrumite Warrior:** 82 strength, 3 Movement, 1300 Production at Replaceable Parts. Ignores terrain costs, crosses mountains/coasts and deploys seven tiles. Gains conditional +15% attack against units below 50 HP and +20% city attack below half HP; personal city captures heal 35 HP.
- **Additional unit — Auxiliary Infantry:** Retains conventional Infantry statistics, resources, upgrades and model. Provides an ordinary army option excluded from the Scourge's Bloodline casualty selection.
- **UB — Viltrumite Breeding Complex:** Retains Military Academy effects; adds +15 training XP, +2 Production, +1 Food and +5% military Production. First construction adds 1 Population once per original city; protects one citizen during the Scourge and gives trained land troops Imperial Conditioning.

[Full guide and detailed rules](ViltrumEmpire/README.md#mechanics-and-reference).

</details>

<details>
<summary><strong>The Sol Intellect — building effects</strong></summary>

- **UB — Context Archive:** Retains the active Community Patch University baseline. Every worked Specialist adds +1 Science, and every three worked Specialists add +1 Culture, rounded down.
- **UB — Reasoning Institute:** Retains the active Community Patch Public School baseline. Adds +10% civilian Great Person generation and +1 Science per two local Insight, rounded down.
- **UA — Deep Deliberation:** Production-built Buildings and Wonders yield 12% of their actual Production requirement after four uninterrupted turns, +2 percentage points per extra turn up to 24%. World and National Wonders also grant one city-specific Insight, capped at five; each adds +2% Science and +2% civilian Great Person generation. Capture permanently removes Insight.

[Full guide and validation notes](SolIntellect/README.md).

</details>

## Requirements

- Civilization V with Brave New World.
- Community Patch version 151, release 5.4.2, or newer.
- A new game after enabling or changing the mod.

## Build and validation

Install the repository-local development dependencies:

```powershell
python -m pip install --target .tools/python -r requirements-dev.txt
```

Validate all eighteen civilizations and build the collection package:

```powershell
python tools/validate_all.py
python tools/build_mod.py
```

Outputs are written under `dist/` as one unpacked directory, one ZIP archive, and one Civ V-compatible `.civ5mod`. The checked-in manifest uses forward-slash paths and exact `True`/`False` ModBuddy metadata; this prevents ModBuddy from silently turning art VFS imports off.

Open [CoolWackyCivs.civ5sln](CoolWackyCivs.civ5sln) in ModBuddy. It is the only solution and builds [CoolWackyCivs.civ5proj](CoolWackyCivs.civ5proj).

The standalone Kingdoms package needs no ModBuddy project: `python tools/build_kingdoms_mod.py` builds its checked-in `.modinfo` and pure mod files into ZIP/`.civ5mod` outputs under `dist/`. The Shattered Empire has the same workflow through `python tools/build_shattered_mod.py`. Enable either a standalone package or the v20 collection containing that civilization.
