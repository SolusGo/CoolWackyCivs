# Validation and engine smoke tests

Automated tests run against read-only in-memory clones of the real BNW/Community Patch gameplay database, the retained CP v151 schema, and strict Lua 5.1 API doubles. They do not launch Civ V or certify the native renderer.

Run `python tools/validate_kingdoms_mod.py` for Kingdoms SQL/inheritance/art, all four speed lifecycles, serialized state recovery, UI decisions/visibility, optional-hook fallback and a 500-turn two-player AI/reload simulation. Run `python tools/validate_all.py` for the complete thirteen-civilization collection. Build with `python tools/build_mod.py` or `python tools/build_kingdoms_mod.py`.

The lifecycle suite covers gradual House formation and schisms, names/IDs/traits, real demand completion/expiry/refusal/invalidity, action costs, Wall Stability, peaceful and disputed succession, factions/support/penalty cleanup, pending and seven-Guard saves, upgrades/deaths/oaths, AI appointments, foreign capture/recapture, razing/refounding and damaged snapshot fallback. UI tests execute actual callbacks and hide the panel in city/diplomacy/popup/foreign/AI contexts.

## Live engine checklist (not yet run)

Enable Brave New World and Community Patch with logging, select The Kingdoms, and start a fresh single-player game. First confirm Database.log, xml.log and Lua.log have no Kingdoms errors. Use ordinary play for the fresh-game path; debug-console staging is useful for later-era, war and reload scenarios.

- [ ] 1. Civ loads without SQL/XML errors.
- [ ] 2. Capital is Kings Throne.
- [ ] 3. New city becomes Kingdom.
- [ ] 4. Starting Kingdom creates Houses.
- [ ] 5. Population thresholds create new Houses gradually.
- [ ] 6. House split works.
- [ ] 7. House traits persist.
- [ ] 8. Loyalty persists after reload.
- [ ] 9. Prestige persists.
- [ ] 10. Influence calculations work.
- [ ] 11. Demands are generated.
- [ ] 12. Invalid demands are avoided.
- [ ] 13. Completed demands resolve.
- [ ] 14. Failed demands resolve.
- [ ] 15. House appeasement actions work.
- [ ] 16. Kingdom Stability updates.
- [ ] 17. Realm Stability updates.
- [ ] 18. Ruler generated.
- [ ] 19. Ruler death works.
- [ ] 20. Peaceful succession works.
- [ ] 21. Claims update.
- [ ] 22. Civil War triggers.
- [ ] 23. Factions form.
- [ ] 24. House alliances influence factions.
- [ ] 25. Civil War penalties apply.
- [ ] 26. Civil War penalties are removed afterward.
- [ ] 27. Civil War events work.
- [ ] 28. Rebel units spawn safely.
- [ ] 29. Player can support faction.
- [ ] 30. Winner becomes ruler.
- [ ] 31. Chronicle records events.
- [ ] 32. Chronicle persists after save/reload.
- [ ] 33. King's Guard unlocks Medieval.
- [ ] 34. King's Guard remains constructible later.
- [ ] 35. Cap of seven works.
- [ ] 36. Candidate selection works.
- [ ] 37. Candidate House effects apply.
- [ ] 38. Guard receives correct trait promotion.
- [ ] 39. King's Guard upgrade retains identity.
- [ ] 40. King's Guard death frees slot.
- [ ] 41. King's Guard Civil War loyalty event works.
- [ ] 42. Kingdom's Wall gives +1 Happiness/+2 Production.
- [ ] 43. Kingdom's Wall Stability bonus works.
- [ ] 44. UI opens and closes correctly.
- [ ] 45. UI does not show during inappropriate screens if that would obstruct Civ V interfaces.
- [ ] 46. No constant polling/FPS degradation.
- [ ] 47. AI can use the civilization.
- [ ] 48. Save during Civil War and reload.
- [ ] 49. Save with seven King's Guards and reload.
- [ ] 50. City capture/recapture does not corrupt Kingdom data.

Also test two cities finishing queued Guards on the same turn, Gold/faith purchases, the cap after upgrading every Guard, distant gifting, repeated load screen events, opening before the first city, capital loss with an active civil war, screenshots at 1366×768, and a long Chronicle with each filter. Native queue auto-upgrades, AI city orders and unit animation/art require engine inspection.
