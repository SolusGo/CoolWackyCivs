# Implementation notes and edge cases

## Persistent state

Anima, the two-rebirth turn limit, TRANSMIGRATION cooldown, Great Migration usage, Second Skin timers, action locks, and Buddy's pending return are stored with `Modding.OpenSaveData`. A short namespaced marker is appended to unit `ScriptData`; data written by other mods is preserved. A serial number identifies each consciousness independently of Civ V unit IDs, which can be reused.

Second Skin's 15-turn timer follows the consciousness through reconstruction and upgrades. Reconstructed units retain their name, level, exact experience in hundredths where the DLL exposes it, valid promotions, and non-Rou'ls script data.

## Death handling

`UnitPrekill` only records a snapshot. Unit creation happens after combat finishes or during the safe dirty-data fallback, avoiding Civ V's delayed-death and in-combat assertions. Administrative `Kill()` calls used by upgrades, gifts, capture conversion, scrapping, and Great Person consumption do not resurrect healthy units.

Battle membership identifies the military unit responsible for a kill. City bombardment does not generate Anima. Reentrant deaths caused by reconstruction, swapping, Great Migration, rollback, or Buddy's return are suppressed. If no city tile can legally hold a reconstruction, no Anima is spent and the unit stays dead. Among simultaneous AI losses, higher-level, siege, ranged, Hollowhound, and costly modern units are considered first.

The per-turn resurrection cap is per Rou'ls player. A free Hollowhound resurrection still occupies one of its two slots. A paid resurrection remains possible while Second Skin is cooling down.

## TRANSMIGRATION

Eligibility and destination legality are checked again at activation, after UI selection. The transaction rejects aircraft, embarked units, cargo and carriers, missiles, nuclear weapons, combat participants, enemy territory, mixed domains, blocked tiles, and units still settling from another ability.

Both original unit objects move, so XP, promotions, names, religion data, and modded state stay intact. Anima and the eight-turn cooldown are committed only after both positions match. If a movement hook changes the result, the code attempts to restore both positions and spends no Anima. A Matriarch within two tiles of either endpoint lowers the cost from two to one.

After a successful swap, both units have all movement and attack counters exhausted. A temporary promotion removes melee and ranged attack capability until the owner's next turn; it also survives an immediate upgrade.

## Great Migration

The target must be visible, at war, military, unembarked, not carrying cargo, and within three tiles of a Rou'ls military unit. Aircraft, missiles, nuclear weapons, Great People, civilians, one-per-player/team/world classes, and classes without a legal Rou'ls equivalent are rejected.

Creating a Civ V unit at `(-1,-1)` can dereference a null plot in the DLL. The implementation therefore creates the equivalent on the nearest visible, legal, owned staging tile. The actual unit then validates the target through the DLL's destination rules. Only after this succeeds is the victim removed. If another mod prevents the kill or the final move is displaced, the operation rolls back and spends no Anima. The completed vessel has 75 HP, half the victim's XP capped at 60, no inherited enemy promotions, no movement or attacks, and sets the once-per-game flag.

## Buddy and spatial effects

Buddy's pending consciousness counts toward his one-per-player limit. At the third owner turn the code first tries a legal capital berth, then owned water beside coastal cities in distance order. If every berth is blocked or the capital is inland, Buddy waits without duplicating or losing his snapshot and retries each turn. With fewer than three Anima, Buddy dies normally and can be rebuilt.

Hollowhound adjacency, Buddy's friendly strength aura, and Buddy's enemy naval penalty refresh around unit creation, movement, death, combat completion, war, peace, and turn boundaries. Transient aura promotions are excluded from resurrection snapshots. Buddy healing runs once per receiving unit owner's turn and only on territory owned by that unit's team.

## In-game smoke test

Static and mocked-runtime tests cannot reproduce the executable's animation queue. Before a public balance release, use FireTuner or a late-era test save to check:

1. A Rou'ls military attacker kills a unit; a city kill does not add Anima.
2. Three land units die in one turn; only two return, and failed placement spends nothing.
3. A Hollowhound dies twice inside 15 turns and again after its timer; free, paid, then free behavior is observed.
4. A promoted unit returns with its name, level, XP, valid promotions, 50 HP, and no actions; upgrade it during a cooldown.
5. A discounted and full-price swap work across long distances; embarked, carrier, mixed-domain, enemy-territory, and newly locked selections fail.
6. The Somatic Lattice's 25% training roll only applies to normally produced military units, and its zero-Anima fallback fires once per empire every ten turns.
7. The Choir Eternal raises and clamps the cap, adds inherited Heroic Epic effects plus 5 XP, and gains at most one local death Anima per turn.
8. Great Migration rejects hidden, special, cargo, aircraft, nuclear, and illegal-terrain targets; a valid target creates the correct civilization override with 75 HP and capped XP.
9. Buddy returns after three turns at a capital berth, falls back to another coastal city when needed, waits through total blockage, and retains XP and promotions.
10. Save and reload during Second Skin cooldown, TRANSMIGRATION cooldown, an action lock, and Buddy's pending return.
