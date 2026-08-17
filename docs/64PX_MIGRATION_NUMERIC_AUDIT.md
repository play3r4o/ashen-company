# Native 64px migration numeric audit

This audit is the guardrail for the phased world-grid conversion. It is not a
request to replace every occurrence of `32` with `64`.

## Target constants

| Measurement | Target | Reason |
| --- | ---: | --- |
| Terrain cell width/height | 64px | Native Meadow/Tiny Swords terrain grid |
| Terrain cell center offset | 32px | Center of a 64px cell |
| Generated Meadow cells | 18×39 | Preserves the existing 1152×2496px region footprint |
| Navigation cell | 32px | Preserves enemy routing and narrow blocker precision |
| Blocker sample cell | 32px | Preserves projectile and line-of-sight collision sampling |
| Spatial hash cell | 48px | Existing targeting/performance bucket; not terrain |
| Reference viewport | 390×844 | Existing portrait layout |

## Code classifications

### Convert to the shared 64px terrain constant

- `scenes/world/terrain/terrain_layer.gd`: terrain cell iteration, terrain
  neighbors, authored tile lookup, terrain coverage, and terrain chunk sizing.
- `src/services/region_generator.gd`: generated region cell dimensions and
  terrain-cell coordinates.
- `scenes/world/world_controller.gd`: terrain-kind lookup and terrain-cell
  hashing.
- `src/foundation/biome_definition.gd`: default biome tile size.
- Meadow TileSets and authored Meadow TileMapLayers.

### Keep at 32px, but route through a named metric

- `scenes/actors/enemies/enemy_controller.gd`: flow-field cells, blocker
  rasterization, neighbor searches, and path-cell centers.
- `scenes/combat/combat_runtime_controller.gd`: blocker sampling cells.
- Player/world collision sampling that is explicitly grid-based.

### Keep unchanged as gameplay measurements

- Player movement speed and Guard Step distances.
- Weapon and technique ranges/radii.
- Projectile spawn offsets, speeds, lifetimes, and radii.
- Pickup and interaction radii.
- Enemy contact ranges and spawn margins.
- UI dimensions, spacing, and safe-area values.

## Required review rule

Every remaining numeric `32` must be either:

1. Replaced with `WorldMetrics.TERRAIN_TILE_SIZE` or
   `WorldMetrics.TERRAIN_HALF_TILE` when it is terrain geometry;
2. Replaced with `WorldMetrics.NAVIGATION_CELL_SIZE` or
   `WorldMetrics.BLOCKER_SAMPLE_SIZE` when it is a gameplay grid; or
3. Documented as a gameplay/UI value that must not change.

No repository-wide numeric replacement is allowed.
