# Validation and outstanding live checks

The new focused suite uses the same Python/Lua 5.1, disposable CP database clone and DirectXTex tools as the collection. It checks:

- Human-only registration, unique IDs, every Amphitheater scalar/companion inheritance, native dummy effects and localized SQL references.
- Thirty-nine decoded DDS textures with full mip chains, all atlas dimensions, packaged files and independent runtime/UI add-ins.
- Nonzero human player initialization, one maintenance-free hero, transferred presence and no effects on the existing Messi civilization.
- Genuine specialist/Writer/General/Admiral/Prophet event sequences; exclusion of free, scripted and purchased GPs; duplicate creation/construction callbacks.
- Per-era GA/ground rewards, first-ever alliance identities, unchanged lifetime earnings when spending, invalid research/turn/action rejection and all three magic effects.
- Deterministic City-State recipients, expired Production effect, city capture cleanup, capped pressure, once-only phase/crisis transitions, post-activation recovery and failed-deadline retry.
- Hero capture/prekill deduplication, deletion without reward, duplicate cleanup, occupied-capital fallback, persisted recovery, elimination and all four game speeds.
- A peaceful no-loss/no-City-State/no-Wonder route, lifetime/alternative objective eligibility, real Wonder completion, once-only final rewards, memorial relocation, persisted cinematic acknowledgement and post-final Dreams/magic.
- Optional UI load without gameplay, functioning tabs/buttons, modal push/pop, story presentation and hiding for City View, diplomacy and nested game popup signals, with no polling callback.

Run:

```powershell
python tools/build_mod.py --manifest-only
python tools/validate_paradise_mod.py
python tools/validate_all.py
python tools/build_mod.py
```

These automated checks are required before delivery. They are **not live Civ V gameplay tests**. Run this smoke checklist in BNW + Community Patch v151:

Delivery run: `tools/validate_all.py` passed every eighteen-civilization suite. The combined package checked 689 registered files, 74 ordered SQL actions, 67 Lua scripts, 517 decoded DDS textures and 22 native Firaxis ModBuddy entry points. The Paradise focused suite passed all database, gameplay, adversarial and optional-UI scenarios described above. No live Civ V game was run.

1. Select both Messi civilizations separately from the setup screen. Start Paradise as a nonzero human slot if practical. Confirm leader/Dawn/map portraits, capital Buenos Aires, second city Rosario, El Potrero replacement and visible El Diez map model/flag.
2. Confirm native +5% national GP generation, +1 capital Culture and hosting-city +2 Culture/+2 GAP/+10% GP generation. Move El Diez between cities, onto ordinary lawful tiles and across embarkable water. Check no Build, Citadel, Great Work, founding or religious expend button appears.
3. Naturally generate a specialist GP, a combat-earned General/Admiral and a Prophet. Check 2 Dreams exactly once. Purchase/free-grant a GP and extend a Golden Age; verify no generated reward. Build and purchase El Potrero; only production completion earns its era reward.
4. Open all Journey tabs at 1024×768 and a widescreen resolution. Verify icons, scrollbars, burst snapshots and actual actionable buttons. Open City View, diplomacy, Culture Overview, policy/technology/fullscreen popups and close them. Check the launcher never overlays those screens and closing the Journey does not stop the runtime.
5. Use each magic in different eras. Observe actual Science/Culture pools, normal additive Production, building-defense contribution, deterministic Influence and expiry after the shown owner-turn duration. Capture a Hope city and check its effect disappears immediately.
6. Capture/destroy/delete El Diez; save/reload during his absence. Count five owner turns and verify exactly one return in an eligible city. Occupy the capital civilian slot and verify another city is used. Eliminate the civilization and verify no respawn.
7. Enter Renaissance and Industrial naturally or with FireTuner. Check story modal persistence, pressure thresholds 50/75, native yield penalties and reduction when relief crosses a threshold. Complete recovery with a genuine post-start achievement; separately fail it and finish the later Potrero alternative. No reward may arise from deliberate repeatable losses.
8. Play a peaceful game without City-States or available World Wonders. Reach 40 lifetime Dreams through GP/GA development and finish three alternatives, including recovery. Confirm The Last Dance enters a real city's production queue only when eligible and retains eligibility through save/reload and interruptions.
9. Finish The Last Dance; inspect full-screen celebration art, original narration, Memories and gold transition. Confirm +15 scaled GA turns, +2 global Happiness, +10% global Culture/GP, one +2 Culture/+4 Tourism memorial and city WLTKD celebrations. Reload before and after acknowledgement; no reward repeats. Relocate/lose the capital and verify one memorial and one fulfillment effect. Check normal victory is still required and magic still works.

Balance over complete games, map-specific movement, native GP attribution edge cases and engine screen layout remain live-verification items. The documented Admiral inference and defense substitute are the known engine limitations.
