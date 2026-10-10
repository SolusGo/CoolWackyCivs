# Changelog

## 1.0 Legalism correction — 2026-10-10

- Fixed inheritance SQL aborting on CP's already-renamed theming migration table. The Governor's Palace now receives the Monument's flat Culture and its additional Gold, so native Legalism can select the civilization's Monument replacement.
- Corrected the shared CP test schema to complete the official theming migration, and removed the same invalid companion copies from other collection civs. Generators now see only the final runtime tables.
- Added Palace policy-eligibility assertions and optional SQL replay against a read-only live game-cache clone. No policy entitlements or political mechanics change.

## 1.0 founding and civil-war corrections — 2026-10-10

- Fixed normal limited sight blocking otherwise legal starting provinces. Ranked connected local candidates now use a guarded terrain-only reveal around native founding; failed probes restore fog and pending grants recover interrupted revelation. Wonders cannot be discovered by probing, and hidden resources do not improve site ranking.
- Separated military, negotiated, exhausted, lost and undocumented war outcomes. Retained 5/7 suppression rewards and the military-only +10; clean mixed victories earn a rounded-down military share of +10, while negotiated/exhausted/failed wars earn no completion bonus. Peaceful reunification retains Restoration eligibility.
- Added persistent outcome-specific faction Chronicle prose and war/UI breakdowns. Older active wars reconstruct provable outcomes once; completed records/rewards, Governors, Oaths, version-1 keys and package IDs/versions remain intact.
- Marked factions resolved before native unit cleanup to prevent callback reentrancy; stale or lost Governor/city identities cannot award military credit. Synchronized editable localization with the previous hardening text.
- Replaced fully revealed mock starts with limited team sight; added native rejection/rollback/wonder/interruption cases and four-speed war reward, migration, AI and idempotence regressions. Real Civ V playtesting remains outstanding.

## 1.0 hardening — 2026-10-10

- Separated peacetime charters (50% Gold +5 Authority) from wartime autonomy (200% Gold +10 Authority), with lasting hereditary Ambition pressure, shared AI checks and explicit UI costs/consequences.
- Separated recruitment from persistent two-per-faction defection allowances; preserved six active defections and 24 live rebels. Added veteran/upgrade, safe spawn, repetition and reload checks.
- Excluded redundant autonomy petitions, validated technology/resource/farm/plot feasibility and withdrew impossible petitions without penalties. Retained deadlines and prevented duplicate completion/generation.
- Required explicit revealed, connected starting land with bounded terrain traversal and wrapping checks. Added pending grant recovery for interrupted city/Settler creation and stricter established-save exclusions.
- Cached city/unit effects, refreshed only dirty objects or changed global conditions, coalesced nested callback saves and reduced closed-screen refreshes. Retained immediate saving after actions.
- Fixed immediate upgrade/ownership promotion refresh, rebel Legion imperial bonuses, privileges lost on Governor replacement, stale battle Governor identities, duplicate loss penalties, captured Governor reactivation and missing optional civil-war joiner defection totals.
- Added four-speed hardening/defection tests, twelve map profiles, interrupted/failed-grant tests, 100+ province/650+ unit endurance coverage and a reproducible before/after benchmark. Save keys and package versions remain compatible; in-game CP v151 verification remains outstanding.

## 1.0 — 2026-10-10

- Added The Last Emperor, Aeternum, Imperial Legion, Governor's Palace, original artwork and full English text.
- Added founding entitlements, named persistent Governors, Authority, Loyalty, Prestige, petitions and decisions.
- Added staged unrest, finite tracked rebel factions, geographic claimant wars, military Oaths and upgrade-safe lineages.
- Added mutually exclusive reforms, era succession, dynasty records, reversible restoration effects and a bounded Chronicle.
- Added event-driven seven-tab UI, shared-rule AI, dual-bank saves, all-speed automated simulation and standalone/collection packaging.
- Engine playtesting remains outstanding; documented safe simulations replace independent rebel civilization creation.
