# The Sol Intellect

**Leader:** GPT-5.6 Sol · **Adjective:** Solar · **Capital:** Sol Prime

The collection's fourteenth civilization is a patient, tall science civilization with two unique buildings and no unique unit. Sol is human-only (`Playable = 1`, `AIPlayable = 0`): humans can select it, but AI players cannot. Requires Brave New World and Community Patch v151 (5.4.2 or newer); start a new game after enabling version 19.

## Ability and buildings

**Deep Deliberation:** Complete a positive-cost Building or World/National Wonder through Production after four uninterrupted city production turns to gain Science equal to 12% of its actual Production requirement. Each further turn adds two percentage points, capped at 24% from turn ten onward. Round down, with a minimum reward of one Science. Costs use the city's native requirement for the current game speed, rather than Production invested or overflow.

| Continuous production turns | Science reward |
| --- | --- |
| 1–3 | None |
| 4 | 12% |
| 5 | 14% |
| 6 | 16% |
| 7 | 18% |
| 8 | 20% |
| 9 | 22% |
| 10+ | 24% |

Switching the active order to any other Building, Unit, Project, Process or empty queue resets the counter. Returning to the old item starts a new streak. Queue changes behind the active head do not interrupt it. Gold/faith purchases, free grants, captures, dummy buildings and Units/Projects/Processes never award research. Science goes to the current technology; when none is selected, a saved research bank holds the full reward until one is selected.

**Insight:** Every Production-built World or National Wonder grants its city one Insight, including Wonders finished in fewer than four turns. Each city can have five. Each point adds +2% Science and +2% civilian Great Person generation, for +10% of each at the cap. Further Wonders can still award Deep Deliberation research. Capture permanently removes all Insight; recapture starts at zero.

**Context Archive — University replacement:** Retains the active CP University's scalar effects, costs, specialist slots and companion-table properties. Each worked specialist adds +1 Science. Every three worked specialists add +1 Culture, rounded down. Scientist, Engineer, Merchant, Writer, Artist, Musician, CP Civil Servant and other installed specialist types are included. Unemployed Citizens are excluded.

**Reasoning Institute — Public School replacement:** Retains the active CP Public School baseline. Adds +10% civilian Great Person generation and +1 Science per two local Insight, rounded down. Its GP bonus stacks with Insight, for an additional +20% GP generation in a five-Insight city.

Sol has no direct military, movement, expansion, Happiness or Gold bonus and no start bias. Its AI favors Science, Growth, Great People, Wonders and defense over early aggression.

## Implementation and artwork

`SQL/00_Sol_Core.sql` clones the active CP scalar rows at mod activation. `01_Sol_Inheritance.sql` clones all installed CP Building property relations identified by the generator. `02_Sol_Effects.sql` adds the exact unique bonuses, hidden dummies, AI flavors, city/spy names, diplomacy and atlases. `10_Sol_Text.sql` supplies help and Civilopedia text. The baseline University and Public School are never modified.

`Lua/SolRuntime.lua` persists per-player city coordinates, exact production order/item, completed construction turns, the next-turn production snapshot, completion identity, Insight and unallocated research. It uses CP's `PlayerDoneTurn` before the next native city turn and `PlayerDoTurn` after city production. Native `CityConstructed` settles the finishing turn before the queue head is removed. The completion counter, matching queue head, purchase flags and an armed native-turn snapshot distinguish actual production from free grants and duplicate hooks.

Insight uses 0–5 copies of `BUILDING_SOL_INSIGHT`, each providing the native +2% Science/+2% GP modifier. Context specialist Science uses native `Building_SpecialistYieldChangesLocal`; culture and Institute Insight Science use hidden flat-yield building counts. Specific-city and city-data dirty events update specialist assignments and order switches without a timer, frame callback or polling loop. Turn/load/capture/construction/sale events repair derived counts; coordinates and destruction events prevent city ID reuse from inheriting data.

Original art includes a contemplative ceramic-and-gold intellect in a layered solar observatory, distinct Archive/Institute paintings, a concentric neural-sun glyph, small white alpha glyphs, a geographic setup illustration and Dawn artwork. The packaged art consists of 26 legacy DDS textures and one static leader scene. Full-resolution masters, the art preview and exact image generation prompts are in [`art-source/SolIntellect`](../art-source/SolIntellect). The scene uses Civ V's supported static fallback rather than a new animated 3D leader. Sol retains the inherited base-game soundtrack; no custom music or voice recording is bundled.

## Build and verification

From the repository root:

```powershell
python tools/create_sol.py
python tools/make_sol_assets.py
python tools/build_mod.py --manifest-only
python tools/validate_sol_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

The SQL generator reads the installed CP schema and a read-only game cache. Regenerate companion SQL if a future CP release introduces additional building-property tables; existing or newly added scalar columns are automatically retained at activation. The collection's single-player configuration remains unchanged.

[Validation coverage and live-engine checklist](docs/Validation.md) distinguish automated results from Civ V engine acceptance. [The original supplied design](docs/OriginalDesign.md) is preserved in full.
