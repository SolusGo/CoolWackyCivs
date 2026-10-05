# The Boy Beyond the Sky

This civilization is human-only (`Playable = 1`, `AIPlayable = 0`): humans can select it, but AI players cannot.

Masaya Hinata leads a Civilization V: Brave New World + Community Patch v151 civilization about the uncomplicated joy of childhood Flying Circus. The design turns exploration, participation, experimentation, and experience into a renewable `Joy of Flight` meter rather than rewarding conquest.

## Unique ability — I'll Be the First to Fly Beyond the Sky

Joy of Flight ranges from 0 to 100 and is shown in an event-driven top panel for the active Masaya player. It is gained from:

- +1 per revealed tile first recorded around a moving Masaya unit, capped at 5 per player turn.
- +2 the first time each military unit earns combat XP in a player turn.
- +5 for each legitimately selected/earned promotion.
- +3 per Masaya participant when an enemy military unit's effective combat strength is at least as high.
- +10 the first time a unit reaches Level 4.
- the two unique promotion/building sources described below.

At 50 Joy, **Can't Stop Flying** gives all land military units +10% combat XP, Recon and Mounted units +1 Movement, and newly trained military units +5 XP. At 100 Joy, **Beyond the Sky** begins immediately for six player turns: land military units gain +1 Movement, ignore terrain costs, receive +15% attack strength and +50% combat XP, and ignore river-crossing attack penalties. A legitimate promotion during the state heals 25 HP. Joy is locked at its 100 cap until the state ends, then becomes exactly 25.

## Unique unit — Junior FC Prodigy

The Junior FC Prodigy replaces the Horseman, dynamically inherits the installed ruleset's Horseman requirements/companion rows, has 12 Combat Strength and 5 Movement, and rounds 110% of the current Horseman Production cost to the nearest 5 (85 in CP 5.4.2). It:

- ignores terrain movement costs;
- may move after attacking;
- ignores river-crossing attack penalties;
- suffers -33% attack strength against Cities;
- ignores enemy Zone of Control while more than one full Movement point remains.

**Just One More Flight** grants +1 XP after every survived combat, including combat with a city. Its first three lifetime combats also grant +2 Joy each.

**Natural Prodigy** grants +15% Combat Strength during combat against a unit with more XP, plus another +10% if that opponent is at least one level higher. The temporary combat promotions are installed before resolution, removed after resolution, and scrubbed on save load.

## Unique building — Grav-Shoe Practice Room

The Grav-Shoe Practice Room replaces and dynamically inherits the current Barracks. It provides the inherited +15 XP to trained units, +1 Culture, and +1 Science. Each room keeps an independent counter; every third owner turn with a garrison grants +1 Joy. The counter **pauses** while ungarrisoned.

Military units trained there gain **Can't Put Them Down**. For their first ten owner turns they gain +1 Movement; while that timed movement state is active, newly revealed tiles grant +1 XP up to five lifetime exploration XP. Their first legitimate combat-XP gain grants +2 Joy once. The visible tracking promotion remains after the movement effect expires.

## Persistence and Community Patch hooks

Player Joy, the Beyond end turn, exploration cap, and per-city Practice Room counters use `Modding.OpenSaveData` under `MASAYA_KID_V1_*` keys. A namespaced `[MASAYAKID1:...]` block in each tracked Masaya unit's script data stores a generated serial, Level 4 reward, Prodigy combat count, Practice Room creation turn, exploration XP, one-time combat Joy, and the last turn combat participation paid out. Other mods' script data is preserved.

The runtime uses `BattleStarted`, `BattleJoined`, `BattleFinished`, `UnitSetXY`, `UnitPromoted`, `UnitCreated`, `UnitConverted`, `CityTrained`, and `PlayerDoTurn`. `UnitConverted` is the sole upgrade-state path because CP emits it after `UnitUpgraded` while the old unit still exists. Gameplay has no frame update or rapid timer. The separately loaded UI reads `MapModData` and refreshes only on state/data/active-player events.

## Technical approximations and limits

- Conditional Zone-of-Control immunity is refreshed after each move and at turn/state refresh. It is active only while the Prodigy has more than Civ V's one-move denominator remaining, which is the stable CP approximation of the requested condition.
- “Strong opponent” uses CP's current attack/defense strength wrappers, falling back to base melee/ranged strength if a wrapper is unavailable.
- Exploration remains event-driven: Civ V exposes movement after visibility updates but no tile-revealed hook, so a tile revealed by another source can be credited if its first cache observation occurs around a later Masaya move. The runtime deliberately avoids global-map polling.
- The Prodigy intentionally uses the stock Horseman 3D model and strategic-view silhouette. Its custom 32px wing/star unit flag is separate from its illustrated portrait and remains readable at flag scale.
- The static leader scene has no animation or custom voice/music. Multiplayer and hotseat remain disabled for the combined collection pending synchronization testing; AI gameplay is fully automatic and does not depend on the UI.

## Art

`art-source/MasayaBeyondSky/MasayaConcept.png` is the supplied visual reference. `tools/make_masaya_assets.py` non-destructively crops its authored scenes/icons, creates the required Civ V atlas sizes, and draws only the simplified alpha/flag silhouette. All shipped DDS files, the leader-scene XML, database atlas rows, VFS imports, and package entries are validated.

## Build and validation

From the repository root:

```powershell
python tools/make_masaya_assets.py
python tools/validate_masaya_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

The focused suite checks SQL against the installed CP database, exact inheritance, yields, promotions, localization, art geometry/decoding, project packaging, Lua 5.1 syntax, persistence, thresholds, duration, per-unit caps, combat rewards, training, garrison cadence, and UI visibility.
