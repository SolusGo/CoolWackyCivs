# Patch Notes

## Cool Wacky Civs version 8 — The RomanGladius Network — 2026-09-18

- Added Lachlan “RomanGladius” and The RomanGladius Network as the collection's seventh civilization, with tall Growth, Gold, Science, Culture, and Diplomacy priorities.
- Implemented per-Server population yields, persistent 0–100 Reputation bands, activity, under/overmoderation, Moderator Culture, Administrator upkeep, and the Capital's Owner Online bonuses.
- Added the Network Dashboard with every Server's roster, staff, status, chat, logs, timed bonuses, and active event choices.
- Added eight interactive incidents plus automatic Viral Server, Veteran Returns, and Player Record events, with AI staff management and resolution support.
- Added four persistent total-Player milestones at 10, 25, 50, and 100 Population.
- Added the Server Owner with +60% Production cost, two-Population training cost, escalating launch fees, free Server Console, 60 starting Reputation, and ten-turn Grand Opening.
- Added the Server Console Monument replacement with exact +2 Culture and +1 Gold yields and full Community Patch inheritance.
- Preserved the supplied leader, map, Dawn of Man, and heraldry art; generated a standalone Server Console closely matching the concept sheet; compiled complete Civ V DXT5 atlas families.
- Extended combined validation and added a deterministic RomanGladius runtime mock covering yield thresholds, staff transactions, Reputation, events, founding, milestones, and save identity.

## Cool Wacky Civs version 6 — The Dual Order — 2026-09-18

- Added Grandmaster Severin and The Dual Order as the collection's sixth civilization, with a Hills start bias and religion/military/production-focused AI.
- Implemented Twin Mandates yields for Barracks, Armories, Temples, and their replacements; Zeal training from combined military and religious infrastructure; friendly-territory strength; kill healing; and upgrade persistence.
- Implemented faith-gated Balance Pressure at +2% Combat Strength and +1% Production per active major-civilization war, capped at five, with an in-game status indicator.
- Added Golden Age military Production and trained-unit XP, including purchase exclusion and immediate state refreshes.
- Added the 23-Strength Divided Templar with +10% cost, Cover I, below-half-health Schism Strike, and religious-unit adjacency strength.
- Added the Hall of Concordance with complete Armory inheritance, +3 Faith, +2 Production, five additional XP, founded-religion Happiness, and the specified +1 Great General Point per-turn fallback.
- Preserved the supplied heraldry directly from the concept sheet and generated separate leader, unit, building, Dawn of Man, and map source art before compiling complete Civ V DXT5 atlas families.
- Extended combined validation and added a deterministic Dual Order runtime mock covering mandates, faith gating, war tiers, Golden Ages, Hall effects, Zeal, and Schism Strike.

## Cool Wacky Civs version 5 — The Filthy Realm — 2026-09-18

- Added Filthy Frank and The Filthy Realm as the collection's fifth civilization, with Culture/Domination AI flavors and a Rice Fields capital list.
- Implemented five-level foreign-city Filth through mutually exclusive dummy buildings, exact yield penalties, non-stacking nearby combat bonuses, trade/tourism/warfare spread, and connectivity-based decay.
- Added persistent Filthy Points from kills, pillaging, Filth, routes, Great Works, captures, denunciations, declarations of war, and targeted World Congress embargoes.
- Added the in-game Filthy Realm panel with Salamander Man, Realm Distortion, deterministic Ravioli yield theft, It's Time to Stop, cooldowns, target selection, and AI ability use.
- Added the 52-Strength Peace Lord, Know Your Place kill rewards, temporary adjacent humiliation, and once-per-unit Filthy Intervention retreat action.
- Added the Filthy Kitchen with Broadcast Tower inheritance, +2 Tourism, Great Work food/point rewards, capped passive points, and faster trade-route contamination.
- Remade the leader, Dawn of Man, map, and Salamander art from the supplied concept direction; extracted and reframed the face, leader, Peace Lord, and Kitchen; compiled exact Civ V DXT5 atlas sizes.
- Extended combined SQL/DDS/UI validation and added a deterministic Filthy runtime mock covering Filth, spending, cooldowns, summons, Stop, Intervention, and pillaging.

## Cool Wacky Civs version 4 — icon and runtime hardening — 2026-09-13

- Refined the Rou'ls, Luna, and Terra civilization emblems from new transparent high-resolution sources, with supersampled rendering and thumbnail sharpening.
- Corrected every non-Capano atlas family to Civ V's native slot sets: color 256/128/80/64/45/32, alpha 128/64/48/32/24/16, leader 256/128/64, unit 256/128/80/64/45, and building 256/128/64/45.
- Added dedicated Rou'ls and Luna leader portrait atlases instead of incorrectly reusing their civilization emblems.
- Re-encoded every rebuilt texture as legacy DXT5 where block dimensions permit and uncompressed legacy RGBA for 45px slots.
- Fixed Great Migration rollback so a failed replacement move restores the defeated target at its original health without spending Anima.
- Added post-conversion Terra promotion cleanup so configuration bonuses cannot leak through upgrades or ownership conversion.
- Added exact atlas, full DDS decode, required-event registration, migration rollback, and Terra post-conversion regression checks.

## Cool Wacky Civs version 3 — Capano runtime repair — 2026-09-13

- Corrected every Capano `OpenSaveData` call to use the Community Patch's function-style API, fixing the live initialization crash recorded in `Lua.log`.
- Registered the existing `UnitSetXY` handler so Boulder Sector movement effects and Competition Movement activation now run in game.
- Made the Capano save-data mock enforce the real API signature and added assertions for every required event registration, preventing either regression from passing the test suite again.
- Rebuilt the combined collection as version 3 so Civ V imports a clean runtime package without reintroducing standalone Capano mods.

## Cool Wacky Civs version 2 — Capano icon overhaul — 2026-09-13

- Replaced all fourteen Capano gameplay-icon sources with dedicated high-resolution illustrations instead of small crops from the civilization concept sheet.
- Added a new Route Setter portrait centered on the setter, drill, hold, chalk, and tool pack for a much clearer unit panel image.
- Rebuilt the Competition Coaching Centre, Boulder Sector, Beta, Awkward Sequence, technique, Circuit, and Grampians icon slots in one coherent charcoal, purple, and sandstone visual language.
- Added contrast, color, and sharpening treatment before atlas downsampling so the artwork survives Civ V's 16–45px UI sizes and DXT5 compression.
- Kept the Boulder Sector's Construction prerequisite unchanged and bumped the combined package version to force a clean texture refresh.

## Cool Wacky Civs version 1 — Combined collection — 2026-09-12

- Consolidated Rou'ls, Luna, Terra, and Capano into one mod ID, manifest, ModBuddy project, solution, and deployable package.
- Removed the four standalone projects, manifests, solutions, and redundant builders, including the accidental second Capano solution created inside its source folder.
- Corrected ModBuddy VFS metadata to exact `True`/`False` values; lowercase values caused ModBuddy's generated Capano manifest to set every file to `import="0"`.
- Standardized generated manifest paths to forward slashes and MD5 values to ModBuddy's uppercase form.
- Added a collection validator covering all 128 content files, sixteen ordered SQL actions, four runtime entry points, VFS basename uniqueness, and the official ModBuddy-generated manifest.

## Capano Circuit version 3 — VFS deployment fix — 2026-09-12

- Corrected the installed package state that had disabled VFS importing for every Capano art and runtime file, which made valid DDS textures appear missing to Civ V.
- Audited all 28 DDS files with Microsoft's DirectXTex parser and full pixel decoder in addition to the existing Pillow and legacy-header checks.
- Added strict atlas-to-file geometry validation and an installed-copy audit for file hashes, source parity, and required VFS import flags.
- Bumped the mod version so Civ V imports the corrected manifest as a clean package.

## Capano Circuit version 2 — Consolidated icon atlas — 2026-09-11

- Moved Enrico's portrait into the civilization's already-working color atlas and removed the separate leader atlas from the database, avoiding Civ V's stale per-filename VFS texture state.
- Bumped the mod version so Civ V performs a clean file import instead of reusing version 1 cache metadata.
- Matched the proven Civ V encoding rule used by installed working mods: DXT5 for block-aligned textures and uncompressed 32-bit DDS for 45px rows.

## Capano Circuit version 1 — Civ V texture-loader fix — 2026-09-11

- Re-encoded every Capano DDS texture as legacy FourCC DXT5 so Civ V can load the civilization and icon atlases.
- Extended validation to require DXT5 headers and fully decode every DDS payload, preventing a superficially valid but engine-incompatible texture from shipping again.

## Capano Circuit version 1 — Initial implementation — 2026-09-11

- Added Enrico Capano and The Capano Circuit as a standalone, AI-playable Community Patch civilization.
- Implemented target-specific Beta across four failed attacks, maximum-Beta SEND rewards, five-step technique progression, and the once-per-player Ammagamma challenge.
- Added the 3-Movement Route Setter with Worker inheritance, Hill movement/work bonuses, and exclusive Boulder Sector construction.
- Added the non-adjacent Boulder Sector, its Science/Culture/Production Circuit progression, asymmetric movement, hostile Awkward Sequence, once-per-era training, Yellow status, and BlocHaus cosmetic messages.
- Added the Competition Coaching Centre with Armory inheritance, +2 Science, +2 Culture, and two-tile Competition Movement for normally trained land units.
- Added save-backed identity/progression and Community Patch battle, construction, movement, upgrade/conversion, war, and diplomacy integrations.
- Added generated Enrico-inspired leader art plus extracted civilization, unit, building, improvement, promotion, map, and flag textures from the supplied concept art.
- Added full English localization, fictional leader dialogue, Civilopedia text, city and spy names, ModBuddy packaging, build tooling, and schema/behavior validation.

## Luna Network version 1 — Correct standalone implementation — 2026-09-06

- Added GPT-5.6 Luna and The Luna Network as a separate Community Patch civilization mod.
- Implemented Low Latency for normally produced military units and non-Wonder buildings using game-speed-adjusted Production requirements.
- Added save-backed pending Production, Process/empty-queue handling, and capture/destruction cleanup.
- Added two-turn Rapid Response for trained land and naval combat units, including save/load and upgrade continuity.
- Added the Packet Settler with dynamically inherited Settler behavior, 10% lower Production cost, and +1 Movement.
- Added the Cache Node with dynamically inherited Community Patch Library effects, 15% lower Production cost, and +1 Production.
- Added dedicated Luna leader and civilization artwork, localization, city names, spy names, diplomacy, and metadata.
- Set Luna to `Playable = 1` and `AIPlayable = 0` so it remains human-selectable but cannot be chosen by AI.
- Added Luna-specific build and validation tooling.
- Split civilization documentation into separate Rou'ls and Luna READMEs and made the repository README collection-wide.

## Rou'ls Ascendancy version 1 — Player-only civilization selection — 2026-09-06

- Set The Rou'ls Ascendancy to remain human-playable while preventing AI selection.
