# Patch Notes

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
