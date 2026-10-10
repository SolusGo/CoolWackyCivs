# Original Dawn of Man illustration

`Art/LastLight.png` was generated with the built-in imagegen tool, following [the imagegen skill](C:/Users/ThatOneYi/.codex/skills/.system/imagegen/SKILL.md). It depicts the hooded Warden overlooking humanity's final lit sanctuary amid the ruined world. The selected image was visually inspected. Stock leader diplomacy and icon/unit assets remain inherited.

Final prompt:

> Use case: stylized-concept. Asset type: Civilization V Dawn of Man background illustration for a custom one-city survival civilization, The Last City. Generate a single wide landscape image, dark fantasy post-apocalyptic aesthetic. Humanity's final walled sanctuary, Last Light, illuminated by warm lanterns beneath a cold ash-gray sky, battered monumental stone walls, ruined world beyond, a lone anonymous hooded Warden overlooking the refuge. Painterly strategy-game loading screen quality, atmospheric readable silhouette, restrained charcoal and slate colors with amber sanctuary lights. No text, no typography, no logos, no game UI, no real persons. Wide landscape 16:9 composition suitable for conversion into a 1024x512 DDS game texture.

`python tools/build_lastcity_art.py` resamples the source and compiles a 1024×512 DXT5 DDS with Pillow. Only `Art/LastLight.dds` is needed by the game; it is registered in both manifests/VFS and referenced by `Civilizations.DawnOfManImage`. The PNG remains in Git for reproducible conversion. Automated tests decode the DDS and verify its dimensions. Actual Dawn of Man rendering has not been tested in Civ V.
