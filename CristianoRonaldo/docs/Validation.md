# Validation record — 2026-10-11

## Performed

- Read the installed CP v151 manifest, which identifies release 5.4.6, and inspected locally available matching DLL source wrappers/events before choosing database fields and callback signatures.
- Executed all Ronaldo SQL on a disposable, read-only gameplay-cache clone with the installed CP schema applied. Verified player-only selection, Cavalry/Barracks inheritance, exact native modifiers, companion-table inheritance, unique overrides and localization.
- Parsed UI and leader XML, checked control references and compiled every Ronaldo Lua file using Lua 5.1 through Lupa.
- Decoded all 34 Ronaldo DDS textures with Pillow and DirectXTex `info`/`analyze`; verified every registered atlas size/grid and slot. Visually inspected the original art preview. The leader scene uses the repository's native `FallbackImage` attribute convention.
- Ran production Lua handlers unchanged against a deterministic CP-shaped model: caps, genuine/free promotions, training/purchases, origin/era rewards, upgrades and tier exclusivity, full XP retention, low-health upgrades, seven chapter/era gates, Golden Ages, General auras, war cooldowns, population/wonder milestones, city capture, overseas allocation, Flight, legacy rewards after both percentage caps, unit ID reuse, foreign ownership/upgrades and save-state reloads.
- Combat tests use `CombatResult` for identities, matching this CP source. Tests cover duplicate pre-kill callbacks, queued and nested combat, genuine melee captures, and conquest-flagged peace cessions. Movement refund executes after `BattleFinished`, without changing attack counts.
- Tested Career UI callbacks using control/event mocks: launcher, close, Escape, chapter selections, queued unlocks, city/diplomacy/culture screen blockers, and safe behavior when the gameplay context is absent. No polling callback exists.
- Tested Quick/Standard/Epic/Marathon threshold/reward scaling and saved mid-turn promotion limits. These are deterministic model tests, not runtime certification.
- Generated manifests with the Python builders and the actual installed Firaxis ModBuddy manifest task. Confirmed the combined entry points agree, resolve to real files and use the required field order. Package builds verify LZMA `.civ5mod` integrity.

The focused executable check is `python tools/validate_ronaldo_mod.py`; the collection suite is `python tools/validate_all.py`. Builders produce the standalone v1 and collection v22 packages under `dist/`.

## Not performed

No native Civilization V game was launched or played for this implementation. Actual civilization selection, icons on native screens, popup layout, direct DLL combat outcomes, save-file reloads, AI random exclusion, gameplay database/Lua logs, FPS and turn times remain unverified. No network multiplayer/hotseat tests were performed. The manifests disable those modes.

## Implementation differences requiring particular attention

1. Military Gold purchase discounts are immediate 5% rebates because CP's native unit-cost policy also discounts civilians. Up-front affordability and displayed prices remain full cost.
2. Captain's ranged resistance uses the native +5% ranged defensive-strength field; CP does not expose a flat damage multiplier for this specific aura.
3. General/Admiral births are inferred from a new GP plus a corresponding CP threshold increase. Death/expenditure and subsequent GP creation flush pending births, but unrelated external/teammate threshold changes can interfere.
4. Decisive Night participants are surviving military combatants with identifiable opposing teams since that war's declaration; anonymous city-bombardment callbacks are excluded.
5. The leader is static art and the Forward uses the standard Cavalry world model with custom portrait/flag. The route map is illustrative.

See the README's eleven-step in-game checklist before claiming native runtime validation.
