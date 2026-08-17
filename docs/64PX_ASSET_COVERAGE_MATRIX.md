# Native 64px World Asset Coverage Matrix

This matrix is the migration gate for world-space presentation. `MIGRATED` means
the runtime scene/resource is on the native 64px path and has passed the current
scene tests. `NEEDS_APPROVAL` means the old visual is intentionally not promoted
to the native set; a replacement must be approved before that category is marked
complete. Runtime scenes must never load directly from a source-pack download
folder.

| Stable asset ID | Current owner | Current runtime source | Desired replacement | Source/licence | Native dimensions | Anchor/collision | Status |
|---|---|---|---|---|---|---|---|
| `meadow_base_64` | `blackthorn_moor_preview.tscn` / `BaseTiles` | `meadow_tileset_64.tres` | Native meadow terrain TileSet | Approved project runtime asset | 64×64 tiles | Terrain semantics unchanged | `MIGRATED` |
| `meadow_water_64` | `WaterFill` | `meadow_water_tileset_64.tres` | Opaque water underlay for transparent terrain pixels | Approved project runtime asset | 64×64 tiles | Non-blocking fill | `MIGRATED` |
| `meadow_shadow_64` | `MeadowShadows` | `meadow_shadow_tileset.tres` | Full-resolution shadow layer with 4px authored offset | Approved project runtime asset | 64×64 tile region | Non-blocking overlay | `MIGRATED` |
| `meadow_composition_64` | `MeadowComposition` | Authored preview TileMapLayer | Roads, transitions, wear, edges, flowers and cracks | Approved project runtime asset | 64×64 tiles | Non-blocking overlay | `MIGRATED` |
| `blackthorn_generated_64` | `AshenTerrainLayer` | `blackthorn_terrain.tscn` + `meadow_tileset_64.tres` | Deterministic 64px generated terrain | Approved project runtime asset | 64×64 tiles | Region semantics unchanged | `MIGRATED` |
| `camp_ground_tier_0..4` | `camp_tier_0..4.tscn` | Authored tier Ground TileMapLayers | Native 64px camp floors | Existing approved camp art | 64×64 tiles | Tier-owned collision | `MIGRATED` |
| `camp_structures` | Camp tier scenes | Reusable structure scenes | Hall, fire, gate, palisade, slots and buildings | Existing approved project art | Scene-specific | Scene-owned footprints | `MIGRATED` |
| `camp_props` | Camp tier scenes | Reusable prop scenes | Barrels, crates, racks, firewood and banners | Existing approved project art | Scene-specific | Scene-owned footprints | `MIGRATED` |
| `ruined_city_structures` | `ruined_city_site.tscn` | Authored landmark scene | Native-compatible city buildings and interiors | Requires explicit source/licence approval | 64px-compatible | Scene-owned collision | `NEEDS_APPROVAL` |
| `ruined_city_walls` | `ruined_city_walls.tscn` | Authored landmark scene | Matching horizontal/vertical broken wall kit | Requires explicit source/licence approval | 64px-compatible | Scene-owned gaps | `NEEDS_APPROVAL` |
| `ruined_city_roads` | `ruined_city_roads*.tscn` | Authored landmark scenes | Destroyed road transitions | Requires explicit source/licence approval | 64px-compatible | Non-blocking visual | `NEEDS_APPROVAL` |
| `prison` | `ruined_city_site.tscn` | Authored prison content | Complete ruined prison with one usable cell | Requires explicit source/licence approval | 64px-compatible | Scene-owned collision | `NEEDS_APPROVAL` |
| `vegetation` | Meadow/world presentation | Existing tree and foliage scenes | Native-compatible trees, roots and shrubs | Requires explicit source/licence approval | 64px-compatible | Only large roots block | `NEEDS_APPROVAL` |
| `player_classes` | Player visual scenes | Existing SpriteFrames | Four-direction idle/walk sheets with stable feet | Requires explicit source/licence approval | Stable frame canvas | Authored body collider | `NEEDS_APPROVAL` |
| `enemies_and_elites` | Enemy scenes | Existing SpriteFrames | Four-direction enemy/elite sheets | Requires explicit source/licence approval | Stable frame canvas | Authored body collider | `NEEDS_APPROVAL` |
| `boss` | Boss scene | Existing boss SpriteFrames | Native-compatible boss animation set | Requires explicit source/licence approval | Stable frame canvas | Authored body collider | `NEEDS_APPROVAL` |
| `projectiles` | Combat projectile scenes | Existing projectile prefabs | Approved projectile sprites/trails | Requires explicit source/licence approval | Scene-specific | Scene-owned collision | `NEEDS_APPROVAL` |
| `combat_effects` | Combat effect scenes | Existing effect prefabs | Approved melee, technique and hit effects | Requires explicit source/licence approval | Scene-specific | Effect-only | `NEEDS_APPROVAL` |
| `pickups_and_feedback` | Pickup/floating-text scenes | Existing prefabs | Approved pickups, hazards and damage feedback | Requires explicit source/licence approval | Scene-specific | Scene-owned collision where needed | `NEEDS_APPROVAL` |

## Promotion rules

1. Copy an approved asset into `assets/runtime/` and record its source and licence
   before referencing it from a shipped scene.
2. Record frame dimensions, alpha bounds, feet/ground anchor and collision status.
3. Run the scene-contract, asset-manifest and editor/runtime parity tests.
4. Only after zero runtime references remain may the superseded file move to
   `art/archive/runtime_legacy/`.

The native terrain/camp foundation is intentionally complete while actor, combat,
ruined-city and prison art remain explicit approval gates. No fallback sprite or
code-drawn substitute is permitted for those rows.
