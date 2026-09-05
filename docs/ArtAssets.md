# Art assets

The bitmap assets were created with the built-in image-generation tool. Generated PNG sources are retained under `art-source/`; the DDS files consumed by Civ V are under `RoulsAscendancy/Art/`.

Leader prompt:

> Use case: stylized-concept. Asset type: Civilization V mod static diplomacy background, widescreen 16:9. Subject: Trent Rou'ls, the Unbodied, a shifting dark humanoid silhouette surrounded by faint overlapping translucent humanoid bodies representing previous hosts. Scene: an ancient advanced biological consciousness archive on Trentaal, tall ribbed architecture, empty vessel chambers hinted in the distance. Style: polished painterly science fantasy concept art suitable for a strategy game leader diplomacy screen. Composition: central regal silhouette from knees upward, face mysterious luminous void, several ghostly prior silhouettes slightly offset behind him, atmospheric architecture wide to both sides. Mood: dignified, eerie, quietly welcoming, restrained teal and pale gold light, subtle mist, dark deep blue background. Constraints: no text, no letters, no UI, no logos, no watermark; no gore, no weapons, not a recognizable historical leader. This is a single wide leader scene.

Emblem prompt:

> Use case: logo-brand. Asset type: Civilization V civilization emblem and unit flag symbol. Primary request: a single iconic symbol for the Rou'ls Ascendancy, expressing consciousness passing between biological vessels. Subject: three nested abstract humanoid silhouettes forming one continuous circular loop around a small luminous core, like consciousness moving from body to body. Style: bold clean heraldic game emblem, vector-friendly flat silhouette, elegant science-fantasy, readable at 32 pixels. Composition: perfectly centered, symmetrical, fills a square safely with generous margin. Color: solid white emblem only. Background: genuinely transparent alpha. Constraints: no text, no letters, no border frame, no gradients, no shadows, no glow outside the white silhouette, no watermark; one connected simple emblem.

`tools/make_leader_asset.py` creates the required 1600×900 static leader DDS. `tools/make_icon_assets.py` creates color and alpha 1×1 icon atlases at 256, 128, 80, 64, 45, and 32 pixels.
