# Ronaldo technical audit — 2026-10-11

Scope: existing BNW civilization under Community Patch v151 / 5.4.6. **Player-only selection remains `Playable=1, AIPlayable=0`**, following the user's latest clarification. No mod was installed or enabled in the game's MODS directory. No numerical balance, chapter, SQL definition, civilization/promotion/policy type, or other civilization's gameplay was changed.

## Confirmed flaws and fixes

| Flaw | Correction and evidence |
|---|---|
| Kill healing ran before incoming attacker damage. At full HP, 8 healing disappeared before 20 incoming damage. | Queue healing and comparable-kill Ambition until BattleFinished, with survivor/lineage checks. The new source-ordered regression fails against the original runtime: expected 12 damage, got 20; it passes after the fix. Native movement costs finish before the refund, and attack counts are untouched. |
| A free/spawned Forward lacked its recorded origin and lost veteran Finisher on upgrading. | Actual Forward creation records the origin. Loading and upgrade hooks repair old live Forwards, including foreign ones. Reduced Finisher is explicitly retained through later conversions/upgrades. |
| Eliminating Ronaldo stopped the runtime on reload, leaving foreign veterans without innate Lua healing or upgrade behavior. | Runtime presence checks the assigned civilization even after elimination; career rewards still require a living Ronaldo player. A foreign veteran's upgrade and 5 HP healing pass after an eliminated-origin reload. |
| General threshold edits could impersonate a birth. | Use the native own-player General-created counter. Native GP purchases use CityTrained and a shared saved birth entitlement. Admiral inference rejects irregular and ordinary team-only increases. Duplicate births, immediate expenditure, conversion, transfer and reload are covered. |
| Flight did not immediately refresh existing overseas Tourism when no chapter unlocked. | Refresh city representations on TeamTechResearched. The existing three-city allocation and all yields remain unchanged. |
| A freshly created/transferred General could leave nearby units without the aura until movement/turn refresh. | Refresh nearby military representations at General creation/transfer; existing movement/death hooks still remove them. Multiple Generals do not stack. |
| Nested combat cleanup removed a shared unit's still-active parent General-point modifier. | Restore the parent frame's temporary modifier after finishing the nested frame, then remove it at final completion. |
| Dawn and leader textures were identical. | New original seven-stage Dawn panorama, 1600×900 DXT5. All existing leader/portrait DDS bytes match the previous commit. VFS paths are unchanged. |
| Standalone packaging described a BNW requirement but did not declare that DLC dependency. | Declare BNW explicitly, alongside CP v151. Validate both packages' dependencies, ordered SQL, VFS, checksums, single gameplay/UI entry points and collection exclusion. |

Additional hardening: a saved immutable creation serial prevents replaying both upgrade callbacks from granting another Reinvention tier or another upgrade heal. Fresh creation clears orphaned upgrade entitlements, and the upgrade hook requires both units to exist. A reused unit ID cannot receive a queued combat reward or claim an old upgrade. Dead units cannot complete development milestones. Career UI reads only the active human player's state; other players' events and forced AI control cannot replace it. All seven narratives and legacy progress remain event-driven; no polling was added.

## Source verification and purchase review

Reviewed the tagged [CP 5.4.6 source](https://github.com/LoneGazebo/Community-Patch-DLL/tree/Release-5.4.6/CvGameCoreDLL_Expansion2), available locally under `.references/psj-cp-5.4.6/`, alongside the installed v151 manifest/schema.

- [CvUnit.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.6/CvGameCoreDLL_Expansion2/CvUnit.cpp): DoUpgradeTo emits UnitUpgraded before conversion; convert emits UnitConverted after copying XP/promotions and before killing the old unit. setDamage can invoke UnitPrekill immediately.
- [CvUnitCombat.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.6/CvGameCoreDLL_Expansion2/CvUnitCombat.cpp): ordinary melee resolves defender damage before attacker damage; BattleFinished follows movement spending. CombatResult supplies primary unit identities before resolution.
- [CustomMods.h](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.6/CvGameCoreDLL_Expansion2/CustomMods.h): UnitUpgraded `(player, oldUnit, newUnit, goody)`; UnitConverted `(oldPlayer, newPlayer, oldUnit, newUnit, isUpgrade)`. No authoritative GP-birth hook is defined. GreatPersonExpended is an expenditure event.
- [CvPlayer.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.6/CvGameCoreDLL_Expansion2/CvPlayer.cpp) and [CvLuaPlayer.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.6/CvGameCoreDLL_Expansion2/Lua/CvLuaPlayer.cpp): General-created count is exposed; Admiral-created count is not. Native birth helpers update thresholds after UnitCreated. The owner also receives the team threshold increment.
- [CvCity.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/Release-5.4.6/CvGameCoreDLL_Expansion2/CvCity.cpp): GetPurchaseCost uses the same player UnitPurchaseCostModifier for military/civilian units. The combat-specific war-weariness adjustment accepts positive surcharges, not a supported military-only discount. Neither the purchase-cost function nor its Lua getter exposes a military price override hook. IsCanPurchase and the purchase debit use this native price. Gold/faith purchases emit CityTrained.

The **5% military-only rebate is retained**. Applying the general native discount would affect civilians; editing global unit rows or replacing purchase UI would not safely change both human and AI affordability. Displayed price and up-front funds remain the full native cost. The actual effective Gold cost is reduced by the rounded rebate. Faith/civilian purchases are excluded. No substitute bonus was introduced.

## Files changed

- Gameplay: `Lua/CR7Runtime.lua`; human display guard: `UI/CR7Career.lua`.
- Dawn: `Art/CR7Dawn.dds`, new `art-source/CristianoRonaldo/DawnJourney.png` and prompt record, `tools/make_ronaldo_assets.py`.
- Packaging: `tools/build_ronaldo_mod.py`, standalone v2/collection v23 manifests, and only the collection project version.
- Tests: `tools/validate_ronaldo_mod.py`, `ronaldo_mock.lua`, existing assertion files, new `ronaldo_audit_assertions.lua` and `ronaldo_ai_assertions.lua` under `tools/tests/`.
- Documentation: civilization README/Validation/Audit, art-source README, collection README and PATCHNOTES.

All five Ronaldo SQL files and their generator remain unchanged, including AIPlayable=0 and every approved balance number. Other civilizations' source files are unchanged. Pre-existing project editor metadata remains local and is excluded from this commit.

## Validation

- `python tools/validate_ronaldo_mod.py`: installed-schema inheritance/native modifiers, duplicate type rows, localization, all 34 DDS files through Pillow/DirectXTex, separate Dawn pixels/dimensions/compression, Lua 5.1 syntax, package registration and checksums.
- Existing chapter/cap/upgrade/Academy/capture/war/aura/overseas/legacy/lifecycle/UI and four-speed tests remain enabled.
- New regressions: source-ordered melee/ranged/defender kills, multiple kills, combined/clamped healing, mutual deaths, post-cost movement, no extra attacks, stale IDs, replaying both upgrade hooks, free/foreign Forwards, eliminated-origin reload, nested combat, GP counter/threshold edits, native GP purchases, transfer/conversion, immediate expenditure, legacy pending-GP migration, mid-turn reload, Flight and razed/refounded Academy origins.
- Forced-AI simulation: two independently controlled AI Ronaldo players over 60 modeled turns earn all seven chapters and legacy from production/promotion/combat handlers, retain ordinary policies, suppress human popups and reload without duplicating rewards. This does **not** enable AIPlayable or certify native tactical AI.
- `python tools/validate_all.py`: complete seventeen-civilization regression suite, including actual Firaxis ModBuddy manifest validation for all 20 entry points and combined database/asset/Lua checks.
- Builders verify LZMA `.civ5mod` integrity. Source/manifest hashes are also checked against staged Git bytes, preserving checkout consistency.

## Save compatibility and remaining limits

Collection v23 / standalone v2 retain both mod GUIDs and minimum compatible save version 1. `CR7|v1|`, existing type IDs, Ambition, chapter flags, origin records, cooldowns, per-turn caps and one-time entitlements are preserved. New creation/completion keys prevent future duplicate upgrades; live Forward origin repair grants no tier or XP. Old pending General records without counter metadata use the guarded threshold fallback once. Deterministic reload tests cover mixed old/new metadata and accrued progress.

Previously lost veteran promotions cannot be reconstructed when an old advanced unit has no reliable Forward-origin metadata; the fix protects live Forwards and future upgrades. Admiral threshold changes that exactly imitate a full native birth increment remain ambiguous, including sufficiently large teammate changes. External mods deliberately calling native GP-birth helpers are indistinguishable from engine births. Captain ranged resistance remains +5% native ranged defensive strength, and anonymous city bombardment cannot supply a Decisive Night participant identity.

No native Civ V game was launched. Real save files, DDS loading in game, selection, popup rendering, combat outcomes, game logs, FPS and turn times remain unverified. The Lua combat frame is transient; tests reload between resolved battles/mid-turn, not within a native resolution callback. Network/hotseat modes remain disabled.

For manual verification, use the README's eleven-step checklist. Prioritize: new Dawn versus unchanged leader; full-price military purchases with 5% refund and no civilian refund; healing after incoming damage with one post-cost movement refund; free/foreign Forward upgrades after reload/elimination; genuine/faith GP births and external threshold edits; immediate Flight Tourism and ownership removal; v22/v1 saves retaining all chapters/tiers/caps; queued Career popups, hidden screens, and FPS with the panel open/closed. Test with CP and exactly one package, then inspect Database.log and Lua.log.
