# Generated asset prompts

The two production backgrounds were generated with the built-in image generation tool and copied into `assets/backgrounds`.

## Camp

> Original detailed pixel-art medieval mercenary war camp called Ashen Company, grim but hopeful, top-down three-quarter view with a repaired command tent, timber palisade, armorer workbench, training dummies, supplies, central campfire, muddy paths, blackthorn and cold moor beyond. Authentic crisp 16-bit pixels; portrait 9:16; earth brown, moss green, iron gray, muted burgundy, parchment and amber, with pale blue-green reserved for distant supernatural mist. Environment only; no UI, text, watermark, modern objects or high-fantasy crystals.

## Interactive camp layers

The restoration town uses a clean foundation plus transparent structure sprites. Source sheets are kept under `assets/camp_layers/sources` and are excluded from Godot imports; the runtime sprites are under `assets/camp_layers/buildings`.

> Edit the original camp into a permanent background-and-fence layer. Preserve the portrait framing, top-down three-quarter camera, distant Blackthorn Moor, palisade, gate, watchtower, palette and pixel scale. Remove all interior buildings, tents, stalls, dummies, campfire, benches, crates, barrels, tables, banners, carts, racks and loose props. Replace them with empty packed-earth plots, subtle paths, mud, sparse grass and flat foundation stones. No characters, buildings, fire, UI, labels, text or watermark.

> Create consistent isolated upgrade stages on a perfectly flat magenta chroma-key background, matching the camp's detailed grounded pixel art and three-quarter camera. Armory: ruined forge foundation, open working forge, roofed timber-and-stone armory, fortified master smithy. Quartermaster: torn supply cache, open timber stall, roofed storehouse, fortified company warehouse. Training Yard: rough practice patch, fenced dummy yard, equipped drill yard, archery and sparring yard, disciplined training compound, fortified master training yard. Keep the footprint and ground contact consistent within each set; no characters, labels, numbers, cell borders, UI or watermark.

> Create two isolated camp landmarks on a perfectly flat magenta chroma-key background: a sturdy cream-and-burgundy veterans' command tent with timber steps and warm lantern, and a separate stone-ring campfire with cookpot, benches and company standard. Match the camp's scale, camera and crisp pixel-art style. No people, labels, UI or watermark.

### Six-plot restoration layout and Armory separation

> Edit the empty camp foundation into six deliberate, clearly separated plots connected by walking paths: Veterans' Hall north-center, Armory west-middle, Quartermaster east-middle, Blacksmith southwest, Training Yard southeast, and a circular Campfire muster point lower-center. Preserve the exact portrait framing, three-quarter camera, moor, palisade, gate, watchtower, palette, lighting and pixel scale. Keep the foundation reusable: no buildings, active fire, people, labels, UI, text or watermark.

> Create four Armory/arsenal upgrade stages in one horizontal row on a perfectly flat #ff00ff chroma-key background: ruined covered weapon cache, open timber weapons shelter, roofed secure arsenal, fortified master armory. Match the existing grounded detailed pixel art, three-quarter camera, footprint and burgundy company accents. Show organized bows, spears, axes and shields. No forge, fire, hearth, anvil, chimney, smithing tools, people, labels, numbers, UI or watermark. The former forge-style Armory sheet becomes the Blacksmith progression.

## Blackthorn Moor

> Original detailed pixel-art battlefield on Blackthorn Moor, an open muddy moor viewed top-down in three-quarter perspective with dead grass, puddles, blackthorn, broken stakes and small ancient stones around the perimeter. Clear traversable center, dark edges, cold overcast light, crisp 16-bit pixels, earth brown, moss green, iron gray and extremely subtle pale blue-green mist near stones. Environment only; no UI, characters, text, watermark or large obstacles.

## Continuous world map

The earlier combined map is retained as `assets/backgrounds/world_map_v1.png`, generated with the built-in image generation tool using the earlier camp foundation and moor as style references.

> Create one very large, extremely tall continuous medieval folk-horror world-map background in strict top-down three-quarter perspective. The northern quarter contains a safe mercenary town enclosed by an irregular shield-shaped wooden palisade that closely wraps six empty building plots: Veterans' Hall north-center, Armory northwest, Quartermaster northeast, Blacksmith southwest, Training Yard southeast and Campfire south-center. Use a single open southern gate and broad connected roads. Continue the road through three quarters of unique explorable moor with a ruined cart, waystone, raider clearing, barrow stones, muddy ponds, dead woods, low ruins and open combat clearings. Highly detailed hand-painted pixel art; earth brown, moss green, iron gray, muted burgundy, warm town amber and restrained pale blue-green supernatural traces. Terrain and palisade only: no main buildings, campfire object, characters, enemies, UI, labels, text, repeated tiles or visible seams.

## Unified terrain and physical palisade — current

The current terrain is `assets/backgrounds/world_map_v2.png`. It replaces the softer mixed-style map with crisp terrain-only art; the fence has been removed from the background entirely.

> Recreate the previous very tall world map as a crisp terrain-only map. Preserve its north-town-to-south-moor route, central road, branching paths, six empty northern building plots and exploration landmarks. Match the sharp high-detail pixel clusters and isometric edges of the production building sprites. Use defined cobbles, mud, moss, stones and dead grass. No painterly blur or antialiased haze. Remove every palisade, gate, tower, fence, building, tent, character, fire, label and UI element.

The current physical fence is `assets/camp_layers/palisade/camp_palisade_v2.png`, generated on a flat chroma background and converted to alpha locally.

> Create a wide landscape sprite of one continuous outer medieval timber palisade around a completely open town yard. Use pointed dark wood stakes, braced rails, iron-banded posts, two small watch platforms at the upper corners and one wide open gate at exact bottom center. Match the production building sprites' hard-edged, detailed isometric pixel art. Outer wall only: no internal fences, spokes, dividers or partitions. Render on a perfectly uniform flat #ff00ff chroma-key background with no ground, shadows, buildings, props, characters, text, UI or watermark.

## Mercenary player

> One original grounded medieval mercenary spearman, full body in a readable top-down three-quarter view, wearing a dark iron kettle helmet, short mail shirt, burgundy padded gambeson, brown boots and a small round buckler, with an ashwood boar spear. Detailed hand-painted pixel art matching Blackthorn Moor, historically plausible equipment and practical proportions. Isolated on a flat magenta chroma-key background with no scenery, shadow, text, watermark, modern equipment or high-fantasy ornament.

## Enemy company

> A consistent 3-by-3 atlas of nine original grounded medieval folk-horror enemies: gaunt wolf, desperate raider, moor archer, shielded reaver, blighted corpse, carrion crow, houndmaster elite, grave guard and Barrow Knight. Detailed hand-painted pixel art matching Blackthorn Moor, readable silhouettes, practical historical equipment and an earthy low-saturation palette. Pale blue-green appears only on supernatural enemies. Each figure is isolated in its cell on a flat magenta chroma-key background with no scenery, shadows, labels, gore, watermark, modern equipment or exaggerated fantasy weapons.

## Company ledger UI frame

> Use case: ui-mockup. Asset type: reusable portrait game-menu background for a Godot mobile pixel-art UI. Create a polished medieval folk-horror ledger and war-camp interface surface with a large empty central area for live UI controls. Dark weathered parchment mounted inside blackened oak and riveted iron, subtle leather straps and small wax-seal details only around the perimeter. Detailed hand-crafted pixel art with crisp nearest-neighbor edges, grounded medieval materials and restrained ornament. Portrait 2:3 composition, front-facing, with at least 82 percent of the center visually quiet for readable text and buttons. Warm amber edge light; earth brown, iron gray, moss green, muted burgundy and parchment tan. No words, letters, numbers, button-like icons, characters, weapons, logos or watermark. Avoid photorealism, 3D rendering, ornate fantasy gold, cathedral motifs, bright saturated colors and low-contrast gradients.
