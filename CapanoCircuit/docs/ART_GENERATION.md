# Capano art generation and extraction

## Sources and tool

- `art-source/Capano/CapanoConcept.png`: user-supplied civilization concept sheet. It supplies the geometric hold emblem and crops for the Route Setter, Competition Coaching Centre, Boulder Sector, Beta, Circuit, and technique icons.
- `art-source/Capano/CapanoLeaderReference.png`: user-supplied appearance reference for Enrico.
- `art-source/Capano/CapanoLeader.png`: final leader source generated with OpenAI's built-in ImageGen tool using both supplied images as references.
- `art-source/Capano/CapanoArtPreview.png`: reproducible contact sheet of the generated leader scene and extracted atlas subjects.

`python tools/make_capano_assets.py` crops and resizes these sources into the legacy uncompressed RGBA DDS textures under `CapanoCircuit/Art`. The script draws a clean alpha-only version of the supplied climbing-hold emblem for the map and unit flag, while the colored civilization icon is extracted from the original concept sheet.

## Final ImageGen prompt

> Use case: stylized-concept. Asset type: Civilization V custom leader scene / diplomatic background illustration, polished production concept art. Primary request: create a premium painterly leader portrait for “Enrico Capano, leader of The Capano Circuit,” using Input Image 1 for the overall Civilization climbing visual language and Input Image 2 only as appearance inspiration for the leader. Scene: a dramatic modern competition bouldering gym with black and muted-purple geometric climbing volumes, opening visually toward rugged Australian sandstone mountains at sunset; subtle chalk dust in the air and route-setting tools nearby. Subject: an original young adult male climber/routesetter inspired by the person in Input Image 2—dark wavy medium-length hair, short dark beard and moustache, warm focused expression, lean athletic build—wearing a simple black climbing T-shirt and deep red climbing pants, chalking his hands as if studying a difficult sequence. Do not copy the thumbnail layout, pose, text, or YouTube graphics; make a fresh dignified leader composition. Style: premium Civilization V leader-screen key art, realistic painterly finish, historical-strategy-game gravitas, detailed skin/fabric/rock, restrained cinematic atmosphere, not photoreal and not cartoony. Composition: landscape 16:9, leader from thighs/waist up placed center-left, face and both hands readable, generous negative space on the right for game UI, strong silhouette, no important details touching edges. Lighting: warm sunset rim light from the mountain opening, cool soft gym fill, subtle volumetric haze. Palette: charcoal black, chalk white, muted BlocHaus purple, sandstone orange, small deep-red accent. Constraints: no words, lettering, logos, watermarks, UI frames, flags, emblems, tattoos copied from the reference, extra fingers, distorted hands, duplicate people, or modern brand marks.

The generated leader is deliberately an original game-art interpretation inspired by the supplied reference, not a traced or photographic copy.
