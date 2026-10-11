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

v24 delivery run: `tools/validate_all.py` passed every eighteen-civilization suite. The combined package checked 689 registered files, 74 ordered SQL actions, 67 Lua scripts, 517 decoded DDS textures and 22 native Firaxis ModBuddy entry points. The Paradise focused suite passed all database, gameplay, adversarial and optional-UI scenarios described above. No live Civ V game was run.

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

## v25 stability smoke checks (still require a real game)

v25 delivery validation: the required manifest-only build, focused Paradise suite and complete eighteen-civilization suite passed. The combined checks again covered 689 package files, 74 ordered SQL actions, 67 Lua 5.1 scripts, all 517 DDS textures and 22 native Firaxis ModBuddy entry points. New nine-class birth/exclusion, v24 save, event-registration and popup/modal/cinematic cases passed. The final folder, ZIP and native `.civ5mod` built successfully, including the native archive integrity check. No live Civ V test was performed.

- Replace the enabled collection package with v25 while preserving a copy of a v24 Paradise save. Load it with CP v151/5.4.6. Compare current/lifetime Dreams, used-era magic, Pressure, act, crisis/practice/deadline, hero recovery, Memories, objectives and fulfillment. Load saves from before/after final acknowledgement; neither rewards nor acknowledgements may repeat.
- Open/close Journey repeatedly; enter/exit City View and diplomacy with Journey open. Verify input is restored and the launcher returns. Repeat while a story is pending; it must reappear and still require **Continue the Journey**.
- Open/close TechTree, the compact tech chooser, Policies and Culture Overview. Toggle the TechTree twice from its opening control. Test Culture Overview's completion-before-dequeue path. Open a nested confirmation, close its parent/child in each allowed order and verify Journey neither overlays a visible fullscreen screen nor stays hidden on the map.
- With FireTuner or a disposable UI test add-in, omit a popup's Processed event or send an ignored popup request. On selecting a unit, returning to selection mode, exiting City View/diplomacy or beginning the next owner turn, stale blockers must clear if no native fullscreen context remains visible. Observe no recurring visibility timer/FPS degradation.
- Save/reload while Final Peak presentation is pending and while another fullscreen UI obstructs it. Close that screen; verify the cinematic resumes, Escape does not acknowledge it, and Continue works. After acknowledgement, reload again and verify ordinary gameplay/magic access. Test active-player transitions with FireTuner where practical; hotseat remains disabled.
- Naturally generate all nine GP types, including GWAM and a Prophet in a non-capital holy city, and a combat-earned Admiral. Compare the exact 2 Dreams/lifetime increment and objective/era-relief/recovery effects. Purchase/free-grant/script-InitUnit/convert each feasible GP: none should earn. Check a second close-in-time birth and save/reload before settlement. Native non-free creation helpers from arbitrary mods and changes to Prophet cost modifiers remain documented attribution limits.
- Try direct and distance gifting of El Diez: both must be denied with only Paradise enabling its own interaction hook. Ordinary units and non-Paradise civilizations must retain normal gifting, including maps with no living City-States. Recheck capture/deletion/recovery and foreign hero cleanup.

The automated test list and matching source references are recorded in [Audit.md](Audit.md). Live save loading, UI event dispatch order in the running game, nested modal input and Admiral/Prophet attribution are not claimed as engine-tested.
