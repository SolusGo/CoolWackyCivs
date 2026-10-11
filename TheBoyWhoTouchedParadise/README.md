# Argentina — The Boy Who Touched Paradise

Lionel Messi leads a separate, human-only civilization for Civilization V: Brave New World and Community Patch v151 (audited against installed 5.4.6). Its story has three acts: brilliance, heartbreak and redemption. Messi is extraordinary from the beginning; The Final Peak completes a dream without creating his talent.

This is collection civilization eighteen, added in **Cool Wacky Civs v24**. **The Eternal Number Ten remains a separate selectable civilization, with its existing mechanics and saves unchanged.** This civilization uses only `PARADISE` database identifiers, Lua contexts, artwork and save keys.

**v25 stability patch:** [technical audit](docs/Audit.md), reliable popup/modal returns, explicit gifting-hook dependency and early duplicate GP-birth protection. Mechanics, narrative, artwork and numerical balance remain the same. Existing v24 `PARADISE_v1` data needs no migration; automated historical-save compatibility passes, with actual engine save loading still awaiting the live checklist.

## Uniques and starting strength

| Unique | Actual effects |
| --- | --- |
| UA — He Was Always the Point of Difference | Permanent +5% Great Person generation throughout the empire, +1 Culture in the current capital, Dreams, Moments of Magic and the three-act Journey. Starting bonuses remain installed during pressure and after fulfillment. |
| UU — El Diez | One noncombat civilian hero, 2 Movement, no maintenance or expend actions. Created when a friendly city can host him after your first capital is established. Cannot be trained, purchased or gifted to a City-State. Uses the compatible Great Merchant map model. |
| Inspirational Presence | In exactly one owned hosting city: +2 Culture, +2 Golden Age Points and +10% Great Person generation, through native CP building yields/modifiers. Moving immediately transfers these effects. |
| UB — El Potrero | Replaces the active Amphitheater. Preserves its scalar and companion-table effects, including costs, prerequisites and Great Work slots. Adds +1 Culture and +10% local Great Person generation. |
| National Wonder — The Last Dance | An actual city construction costing 450 base Production, at Radio in the Modern Era, once per player. Additional Journey eligibility is checked by `CityCanConstruct`. |
| Memorial — The Eternal Number Ten | Granted to the current capital at fulfillment: +2 Culture and +4 Tourism. Follows legitimate capital relocation, with only one active copy. This memorial belongs exclusively to Paradise. |

El Diez obeys ordinary civilian movement and access rules. Destruction, deletion or capture schedules a return after five scaled **owner turns**. The capital is preferred; another friendly city is used if its civilian slot is free. If every eligible slot is occupied, recovery waits. Eliminated players cannot respawn him. Duplicate units are removed safely. Voluntary deletion gives no Dreams, Memories or pressure reduction.

## Dreams

Dreams start at zero. Spending reduces the current balance only; lifetime earnings never fall. All earning and spending changes create a notification and update The Journey. Significant achievements also create bounded, permanent Memories.

| Genuine achievement | Dreams | Pressure relief |
| --- | --- | --- |
| Great Person birth | 2 per birth | 8 for the first birth each era |
| Production-completed World Wonder | 4 per distinct Wonder | 10 for the first each era |
| First Golden Age start each era | 3 | 12 |
| First new City-State alliance each era | 2 | 10 |
| First Production-completed El Potrero each era | 1 | — |
| Successful national recovery | 5 once | 30 |

Great Person purchases, direct Lua spawns, conversions and truly free grants do not count as generated births. Native post-creation thresholds/counters distinguish generation. The Admiral path uses a conservative threshold check because CP does not expose an Admiral creation counter. See [Implementation.md](docs/Implementation.md) for its limits.

Golden Age extensions never count as starts. Each City-State's first alliance in the entire journey is recorded, so losing/regaining it—even in another era—cannot generate Dreams. Free, purchased and dummy buildings do not earn construction Dreams. Completed World Wonders and buildings have stable, persisted callback claims.

## Moments of Magic

Open **THE JOURNEY** at the top center of the normal map, then choose **Moments of Magic**. Each ability costs **6 Dreams** and requires El Diez in an owned city. Use **one choice per civilization per era**, in any act and after the finale. Disabled buttons explain the reason. The gameplay runtime validates the request before spending.

| Choice | Effects |
| --- | --- |
| A Pass Nobody Saw | Science and Culture equal to 1.5 turns of the hosting city's respective current output, rounded down. Minimum 10 each; maximum `250 + 100 × era index` each. Requires an active research target. Outputs are captured before granting yields. Culture reaches both the national policy pool and the hosting city's border pool. |
| When All Hope Was Lost | +20% local Production and +15% **defense from buildings** for eight scaled owner turns. Native CP applies the modifiers. City transfer removes the temporary effect; it does not stack with itself. |
| The Beautiful Game | `20 + 10 × zero-based era index` Golden Age Points, scaled by GoldenAgePercent; +10 Influence to up to two met, living, peaceful City-States with nonnegative relations. Lowest relations first, ties by player ID. Permanently hostile targets are excluded. Golden Age Points are awarded even with no eligible City-State. |

The defense effect is a documented CP approximation: its supported modifier strengthens the building contribution rather than multiplying total city strength.

## The three acts

**Act I — He Was Beautiful: Ancient through Medieval.** Develop cities, Great People and Culture, earn Dreams and use magic freely. There are no national pressure penalties.

**Act II — The Weight of Expectation: Renaissance through Industrial.** An illustrated event sets Pressure to 25. Pressure increases by one every three scaled owner turns. Achievements reduce it; major losses may increase it. El Diez and the baseline UA remain active.

| National Pressure | City effects |
| --- | --- |
| 0–49 | No national yield penalty |
| 50–74 | −5% Culture and Production |
| 75–100 | −10% Culture and Production |

Pressure stays between 0 and 100. Losing a city to conquest adds 15; losing the original/current capital adds 25. Losing an alliance held for ten scaled owner turns adds 12. An enemy-caused hero loss can add 8. Stable loss identities and per-era category caps prevent repeating an incident from multiplying its effects. These losses provide **no Dreams or positive rewards**. There is no forced city destruction, unhappiness spiral or military defeat.

On entering Industrial, **A Dream Denied** adds 40 Pressure and opens a 25-scaled-owner-turn challenge. Complete any one objective after activation: generate a Great Person, start a Golden Age, construct a World Wonder or obtain a first-ever alliance with another City-State. Existing achievements cannot satisfy it retroactively.

An attainable alternative is always offered: **station El Diez in a city with El Potrero for eight scaled owner turns during the challenge**. The turns need not be consecutive or in the same city. Completion reduces Pressure by 30, adds 5 Dreams and creates **We Rise Again**. Failure adds 15 Pressure and opens another opportunity after eight scaled owner turns. Retries give only one eventual recovery reward. Failure never locks redemption.

**Act III — The Last Dance: Modern onward.** Passive pressure growth stops. Existing Pressure and any unfinished recovery remain relevant until reduced or fulfilled. The player can pursue the finale. No-loss games can finish through peaceful development and the reliable recovery alternative.

## The Final Peak

Build The Last Dance after reaching the Modern Era and Radio, earning **40 lifetime Dreams**, and completing **three distinct objectives**:

- Generate four genuine Great People.
- Begin two genuine Golden Ages.
- Construct World Wonders in two different eras.
- Obtain first alliances with two different City-States.
- Complete the national recovery challenge.
- Production-complete El Potrero in two different cities and develop two Great Works. The highest observed owned Great Work count is retained.

Progress accumulates throughout the game. Current Dreams are not consumed by eligibility or construction. No specific map, loss, war, City-State availability or Wonder monopoly is required. Eligibility is monotonic, avoiding an invalidation that would waste an in-progress Wonder. Normal engine construction limits prevent duplicate instances.

Completion opens an illustrated full-screen modal with original narration, the accumulated Memories, a transition to gold and an explicit reward summary. **Continue the Journey** acknowledges it; pending presentation survives reload. Gameplay rewards are committed by the runtime once, so closing or failing to load the UI cannot erase them.

- Add 15 Standard-speed Golden Age turns (extend an existing Golden Age if already active).
- Set Pressure to zero permanently and remove its penalties.
- Grant +2 global Happiness, +10% global Culture and +10% global Great Person generation through a single native capital effect.
- Give every currently owned city three scaled turns of We Love the King Day and a celebration notification.
- Install the capital memorial with +2 Culture and +4 Tourism.
- Preserve Dreams, magic, baseline bonuses and all Memories.

The epilogue records **The Dream Is Complete. The Beauty Remains.** No automatic victory is awarded. Culture and Diplomacy are favored, while Science and military play remain available.

## Interface and speed

The Journey has Overview, Memories, Moments of Magic and Final Peak tabs. The scrapbook lists chronological titles, era/turn, locations, original text and category icons. Long content scrolls. Gameplay and UI are separate add-ins. Refreshes happen on gameplay changes, panel opening and turn/screen events; there is no update timer or per-frame map scan. The launcher hides for City View, diplomacy, game popups and non-selection modes. The main panel and illustrated events use modal handling.

Turn durations use the active CP **TrainPercent**, rounded to the nearest turn, minimum one: pressure interval, hero recovery, magic duration, recovery practice/deadlines and comeback cooldown. Golden Age duration, celebration duration and Beautiful Game's one-time points use **GoldenAgePercent**. Dream rewards, the 6-Dream cost, 40 lifetime requirement and percentage bonuses remain fixed. Production uses the engine's normal building/game-speed rules. The Pass grants 1.5 actual city-output turns at every speed, with the same numerical minimum/cap.

## Installation, development and verification

Build the combined package from the repository root:

```powershell
python tools/build_mod.py --manifest-only
python tools/validate_all.py
python tools/build_mod.py
```

The unpacked folder, ZIP and native `.civ5mod` are in `dist/Cool Wacky Civs (v 25)*`. Install the unpacked folder or native package under the Civ V user MODS directory, enable Community Patch and the collection, then start a **new game** and select **Argentina — The Boy Who Touched Paradise / Lionel Messi**. Do not enable duplicate collection versions together. Installation requires no generation script or development dependency. Updating an existing v24 Paradise journey preserves its save namespace, data format, Mod ID and minimum compatible save version; follow the stability audit's live save-load checklist.

The mod keeps the collection's original Mod ID and supports single player. Multiplayer/hotseat remain disabled. Adding a civilization requires a new game; this is not advertised as an upgrade that inserts a new playable civilization into an existing save. Existing Eternal Number Ten source files were not modified.

Focused validation: `python tools/validate_paradise_mod.py`. Dependencies are the repository's `requirements-dev.txt` packages in `.tools/python`; DDS rebuilding additionally needs DirectXTex. Art generation prompts and the original paintings are in [art-source](../art-source/TheBoyWhoTouchedParadise/PROMPTS.md). Only rebuilding uses the optional generator tools; all finished textures ship in the mod.

Automated results and the outstanding live checklist are in [Validation.md](docs/Validation.md). Engine UI layout, native civilian capture/model behavior and native yield attribution still need actual Civ V smoke testing; automated tests do not claim that was performed. Direct portrait generation was restricted, so the coherent paintings use a fictional Argentine Number Ten figure, as allowed by the specification. The leader identity and narrative remain Lionel Messi.
