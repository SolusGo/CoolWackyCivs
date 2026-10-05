# Original Token Network artwork

Created with the built-in imagegen tool. No company marks or borrowed logos.
The source images are `Axiom.png`, `Dawn.png`, and `Map.png` in this directory.
`tools/make_token_assets.py` compiles crops/fits, original geometric icon artwork,
alpha masks and atlases. No generated illustration is repainted by that script.

## Axiom

Use case: stylized-concept. Asset type: Civilization V static diplomacy leader portrait,
wide landscape 16:9. Original AI sovereign Axiom, Keeper of Context: bronze-and-obsidian
faceless oracle automaton with floating luminous teal concentric inference rings as
its head, antique patterned robes, seated within a colossal ancient stone computational
temple, gold engraved neural lattices, dramatic painterly strategy-game art, rich
oil-painting textures. Central upper body and atmospheric architecture. Ancient and
futuristic, dignified and contemplative. No company logos, text or watermark.

## Dawn of Man

Use case: historical-scene. Wide Civilization V Dawn of Man illustration. Sweeping
ancient computational metropolis of sandstone and bronze, terraced oracle-temples
linked by luminous teal inference threads, citizens in antique robes assembling
golden geometric token glyphs around a huge concentric-ring monument. Blue dusk,
mountains, warm atmospheric light and textured painterly detail. No text, logos or
watermark; ancient architecture fused with mysterious technology.

## Map

Use case: historical-scene. Portrait civilization selection map panel. Ancient
parchment map of the Token Network: mountains, central circular bronze citadel,
oracle-temple nodes connected by thin teal luminous filaments in a neural lattice,
rivers, engraved terrain hachures, gold compass and classical border, aged warm
ivory paper and hand-drawn cartography. No words, labels, logos or watermark.

## Atlas indices

Civilization atlas: 0 Network emblem, 1 Axiom portrait.
Object atlas (4×4): 0 Token, 1 Context/UA, 2 Inference Cluster, 3 Data Centre,
4 Inference Agent, 5 Tactical, 6 Simulation/Grand Strategy, 7 Forecast,
8 Offensive, 9 Defensive, 10 Mobility/Route, 11 Target, 12 Clear Context,
13 Culture, 14 Cached Response, 15 Saturation.

All civilization, alpha and object atlases include 256, 128, 80, 64, 48, 45, 32,
24 and 16 pixel cells. Unit flag is 32 pixels. DDS uses DXT5/BC3 with alpha when
both dimensions are divisible by four; 45-pixel textures use uncompressed RGBA
as required by the collection's Civ V compiler. Leader is 1600×900, Dawn 1024×768,
map 360×412. Corners outside circular icons and alpha marks remain transparent.
