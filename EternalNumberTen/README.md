# The Eternal Number Ten

The Eternal Number Ten is a Civilization V: Brave New World civilization led by Lionel Messi. It starts without an immediate numerical trait bonus and earns strength through a persistent Legacy career. The implementation requires the Community Patch and is shipped inside the combined Cool Wacky Civs package.

## Unique ability — From Rosario to Immortality

Legacy is stored per player through `Modding.OpenSaveData`. Great People grant 2, World Wonders grant 4, and the first City-State alliance and Golden Age in each Era grant 3. A qualifying Assist grants 1 Legacy, 15% of the defeated unit's base strength as Culture, and the same amount of Golden Age Points, with a 2–12 yield clamp and a two-reward player-turn cap.

At the beginning of a turn, an eligible land combat unit beside at least two friendly combat units receives One-Two Football for that turn: +1 Movement, +5% Combat Strength, and +10% Flanking Bonus. Chapter III raises the strength bonus to +8% total.

## Career Chapters

| Chapter | Requirement | Permanent result |
| --- | --- | --- |
| A Ball and a Dream | 25 Legacy | Capital +1 Food/+1 Production; new cities +10 Food; Capital-trained Scouts and civilians +1 Sight |
| The Napkin Contract | 55 Legacy, Classical | +6% Great Person generation; free Capital La Masia after Theology; Capital Specialists +1 Science |
| The Golden Years | 90 Legacy, Renaissance | +10% Golden Age duration; Assist yields +15%; stronger One-Two Football; Wonders +1 Culture |
| Heavy Is the Shirt | 130 Legacy, Industrial | unlocks four-turn Resilience after specified setbacks, with a 22-turn civilization cooldown |
| The Long-Awaited Crown | 180 Legacy, Modern | allied City-State Culture/Happiness, +10% quest Influence, +17% Great General aura, quest Legacy |
| The Third Star | 240 Legacy, Atomic | one-time Golden Age/WLTKD/policy/healing/XP and permanent Golden Age Science/Tourism plus Great Work Culture |

Legacy can accumulate before an Era gate. The runtime checks every unmet chapter after Legacy or Era changes and never grants a chapter twice.

After Chapter VI, every 55 additional Legacy grants a two-turn Golden Age and `15 × current Era number` Culture. The first six repeat rewards also grant +1% permanent Tourism each. Later repeats retain the Golden Age and Culture without exceeding +6% Tourism.

## Uniques

- **The Number Ten** replaces the Great General. It has 2 Movement, ignores terrain movement costs and enemy Zones of Control, retains Citadel construction, and can build a Football Academy. Adjacent combat units receive Vision Beyond the Defence for the turn: +1 Movement, ignored enemy Zones of Control, and +6% Flanking Bonus. An assisted killer with Vision heals 5 HP.
- **La Masia** replaces the Garden at Theology. It costs 135 Production, requires no Fresh Water, supplies +15% Great Person generation and +1 Culture, and adds exactly `floor(Specialists / 2)` Food. A Great Person born there grants one WLTKD turn, one additional Legacy, and a refreshable six-turn +5% Production bonus.
- **Football Academy** is an alternative Great General improvement. It culture-bombs one tile, supplies +1 Culture and +1 Science, adds +1 Tourism after Flight, gives a stationed unit +10% Defense, and deals no adjacent damage. Its contextual Gold is applied to the working city for distinct worked tiles adjacent to an Academy when that city has at least one specialist-slot building.

## Legacy panel

The optional in-game panel shows current Legacy, the next threshold and Era gate, all six chapters, chapter story/effects, the Third Star, and Epilogue history. Gameplay remains in `MessiRuntime.lua`; closing or failing to load the panel does not disable any mechanic.

## Community Patch dependencies

- `UnitPrekill` plus battle membership hooks provide reliable victim position and killer attribution for Assists and military-death Resilience.
- `PlayerGoldenAge(iPlayer, bStart, iTurns)` detects Golden Age starts and ends.
- `SetAlly(iMinor, iOldAlly, iNewAlly)` detects alliance gains and losses immediately; turn snapshots provide a save/load fallback.
- `CityConstructed`, `UnitCreated`, `PlayerCityFounded`, `TeamTechResearched`, unit conversion, and unit upgrade hooks keep rewards and states event-driven.
- Hidden CP policies implement exact Great Person rate, Golden Age duration, quest Influence, Great General aura, Golden Age yield, Great Work yield, and permanent Tourism effects.

The Community Patch does not expose a dedicated quest-completed Lua hook. Chapter V therefore compares each City-State's displayed quest count and Influence at the Messi turn boundary. A decreased quest count accompanied by increased Influence counts as completion; its per-Era Legacy cap is persisted. The +10% Influence reward itself is an exact CP policy effect.

The promotion API cannot remove ignored Zone of Control after only the first movement action, so Vision grants it for the whole receiving turn. This is the closest stable event-driven equivalent and does not change the specified Movement or Flanking values.

## Debugging

Set `DEBUG = true` near the top of `Lua/MessiRuntime.lua`, enable Civ V logging, and inspect `Lua.log` for chapter, La Masia, and Resilience messages. Persistent keys are namespaced as `Messi|<playerID>|...`; no state uses a global player assumption.

Run the deterministic and package validators from the repository root:

```powershell
python tools/validate_messi_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

## In-game smoke checklist

1. Start as The Eternal Number Ten and confirm Rosario is the Capital and the Legacy launcher appears.
2. Use FireTuner or normal play to cross every threshold before and after its Era gate; confirm each chapter unlocks once.
3. Form and break a three-unit triangle across turns; verify temporary promotions clear and Vision stacks with One-Two Football.
4. Kill beside another friendly unit; verify two rewards per turn, Culture/GAP rounding, Legacy, and Vision healing.
5. Trigger every Resilience source; verify four active turns, no magnitude stacking, and the 22-turn cooldown.
6. Research Theology before and after Chapter II; confirm exactly one free Capital La Masia.
7. Change specialist counts and produce Great People in La Masia; verify floor division and Production-duration refresh.
8. Gain, lose, and regain City-State alliances within one Era; confirm the first-alliance reward cannot be farmed.
9. Complete at least three quests in one Era; confirm only two grant Legacy and quest Influence is 10% higher.
10. Unlock Chapter VI, then trigger at least seven Epilogue rewards; confirm Tourism stops at +6% while Culture and Golden Ages continue.
11. Save and reload during Resilience and La Masia Production; confirm remaining durations and chapter state survive.

## Art

The leader, Dawn of Man, and Football Academy source PNGs were produced with the built-in image generator and compiled into Civ V DDS families by `tools/make_messi_assets.py`. The generator's public-figure safeguard rejected a direct Messi portrait, so the final leader scene intentionally uses an original, non-identifiable symbolic Number Ten figure. No team crests, sponsor marks, federation marks, or tournament branding are used.
