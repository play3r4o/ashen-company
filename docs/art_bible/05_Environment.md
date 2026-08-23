# Environment and Terrain

The refuge and Meadow/Blackthorn Moor share one continuous native-64 world language. Safety changes density, warmth and maintenance—not projection or pixel scale.

## Native terrain contract

- Terrain cell: 64×64 at scale 1.0.
- Projection: orthographic top-down; no isometric diamond grid.
- Canonical layer order: WaterFill → WaterAnimation → BaseTerrain → MeadowShadows → MeadowComposition → Y-sorted props/actors.
- Shadow layer offset: 4 world pixels down unless a reviewed terrain family requires another documented value.
- Transparent banks reveal the layer below, never black.
- Terrain, navigation and combat measurements are separate systems; do not resize art to alter gameplay.

## Tile-family completeness

A terrain family is incomplete until it supports:

- center/fill variants;
- cardinal edges;
- inner and outer corners;
- transitions to every neighboring material it must touch;
- damaged/worn alternatives;
- repeat-safe large areas;
- representative shadow and composition overlays.

Roads in ruins are never pristine. They transition from damaged stone through broken edge, debris and weeds into surrounding earth.

## Projection and depth

- Buildings are roof-dominant with visible front/side wall thickness appropriate to their facing.
- Horizontal and vertical walls must share thickness and construction vocabulary.
- Prop roots use a ground anchor. Y-sort makes actors north of a prop appear behind it and actors south appear in front.
- Foreground canopy/roof parts may sit above both.
- Collision follows visible ground footprint, not the full alpha bounds.

## Physical-world accuracy gate

Environment art must be composed as a believable place, not as unrelated
transparent cut-outs placed beside one another. Use this gate before judging
palette or decoration:

- Every building, wall, gate, tree, rock, prop and landmark has one clear
  contact point with the 64×64 world grid and a stable bottom/ground anchor.
- Ground, foundation, wall base and shadow agree on the same plane. No object
  floats, sinks, or casts a detached shadow.
- The same orthographic camera, light direction and scale language are used for
  every asset in a scene. Do not mix front-facing illustrations with top-down
  world pieces.
- Back, main and foreground layers are separated wherever the player or an
  enemy must pass behind or in front of the object. The layer order must be
  obvious from the art, not guessed from alpha bounds.
- Doors, roads, gates and broken wall gaps are physically reachable. Decorative
  foliage may be non-blocking, but it must not visually imply an invisible wall.
- The authored footprint is the source for collision and interaction. Do not
  derive blocking rectangles from the full texture or from transparent padding.
- A person, door, crate and building must share a believable relative scale at
  native 1×. If the scale is ambiguous, compare it against the approved player
  reference before adding detail.

Physical mistakes are baseline failures. Regenerate or correct the construction
before spending a style iteration.

## Strong Tiny Swords craft target

Use the Tiny Swords family as a stronger craft benchmark for environment
readability while keeping Ashen's own materials and silhouettes:

- Build each tile or prop from a bold outer silhouette and a small number of
  deliberate interior clusters.
- Use crisp dark navy contour pixels, clean stepped edges and 3–5 readable
  value steps per major material instead of soft gradients or noisy texture.
- Make material changes obvious at 1×: grass, earth, wet stone, timber, iron,
  water and shadow should separate immediately.
- Prefer saturated-but-controlled greens, teal water, warm timber and amber
  accents over grey mud; Ashen wear comes from repairs, moss, peat and damage.
- Design families as modular, repeat-safe pieces with stable anchors and
  compatible transitions. A beautiful isolated tile that cannot join its
  neighbors is incomplete.
- Keep highlights sparse and purposeful. Use compact warm light for human
  spaces and pale verdigris only for supernatural traces.

This is a craft target, not permission to copy Tiny Swords shapes, palettes,
buildings, vegetation, props or pixel arrangements.

## Refuge

The refuge uses maintained cobble/earth, compact roads and an open Hall–fire–gate lane. Props cluster near walls and structures. Expansion adds authored building slots and believable construction, not empty acreage.

## Moor and ruined city

The moor uses peat, wet grass, thorn, water, stumps and stones while preserving combat readability. The ruined city must read as a former whole settlement: streets, civic anchors, ordinary houses, broken walls, a prison complex, open interiors/gaps and coherent collapse. Ruin blockers come from visible authored structures only.

## Density rules

- Keep player routes, attack warnings, pickups and interaction silhouettes clear.
- Large vegetation uses sparse clusters and intentional negative space.
- Decorative variation cannot create fake blockers or visual walls.
- Enemies never spawn inside authored blockers or the visible camera area.

## Environment recipe requirements

Record dimensions, grid, tileability, layer, neighbors, anchor, collision intent, sort behavior, variants, provenance and a 1× context capture. A beautiful isolated tile that cannot transition cleanly is not production-ready.
