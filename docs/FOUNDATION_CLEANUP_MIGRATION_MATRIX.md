# Foundation Cleanup Migration Matrix

This matrix is the live record of presentation ownership. `MIGRATED` means the
runtime directly instances the authored scene and the old active path is gone.
`IN PROGRESS` means the canonical scene is active but controller or legacy-file
cleanup is not complete. `BLOCKED: ART` means no approved dedicated production
asset exists; the cleanup must not hide that gap with unrelated artwork.

| Visual system | Former owner/path | Canonical runtime owner | Behavior owner | Status | Remaining removal or blocker |
|---|---|---|---|---|---|
| Application composition | one-node `main.tscn` | `scenes/app/game_root.tscn` | `GameCoordinator` and typed controllers | MIGRATED | root coordinator is under 50 lines; compatibility `src/main.gd` is 4 lines |
| HUD | `src/ui/hud_layout.*` | `scenes/ui/hud/hud.tscn` | `AshenHudLayout` | MIGRATED | none |
| Settings | duplicate settings layouts | `scenes/ui/screens/settings_screen.tscn` | `AshenSettingsScreen` | MIGRATED | none |
| Training Grounds | `src/ui/training_tree_screen.*` | `scenes/ui/screens/training_tree_screen.tscn` | screen + Training service | MIGRATED | none |
| Expedition Arsenal | `src/ui/arsenal_screen.*` | `scenes/ui/screens/arsenal_screen.tscn` | screen + Arsenal service | MIGRATED | none |
| Results | rectangle library/code binding | `scenes/ui/screens/results_screen.tscn` | `AshenResultsScreen` | MIGRATED | none |
| Level-up | code-built cards | `scenes/ui/overlays/level_up_overlay.tscn` + card scene | overlay + offer service | MIGRATED | none |
| Relic/contract choices | code-built panels | authored overlay scenes | overlay scripts | MIGRATED | none |
| Gate/reset/dismantle confirmations | code-built panels | authored confirmation overlay scenes | overlay scripts | MIGRATED | mounted through `UIController.ModalLayer` |
| Hall/construction/building/class/offline | visual guides and builders | complete scenes and screen-specific card scenes under `scenes/ui/` | `AshenCampListScreen` | MIGRATED | none |
| Inventory | code-built inventory panel | `scenes/ui/screens/inventory_screen.tscn` + `inventory_item_card.tscn` | inventory screen binding | MIGRATED | none |
| Camp tiers 0-4 | `src/foundation/camp_layout*` + camp draw layer | `scenes/world/camp/camp_tier_*.tscn` | `AshenCampRuntime` | MIGRATED | none |
| Camp touch selection | moving screen-space hotspot buttons | structure/plot `TouchArea` polygons | `AshenCampRuntime` signals | MIGRATED | obsolete hotspot scenes removed |
| Camp walls/gate/zones | constants and guessed rectangles | authored wall/gate scenes and polygons | `AshenCampRuntime` | MIGRATED | none |
| Campfire | combined and duplicated draw assets | `scenes/world/structures/campfire.tscn` | `AshenCampfire` | MIGRATED | none: one base, one flame, one smoke |
| Structures and props | draw dictionaries and texture bounds | reusable scenes under `scenes/world/structures` and `props` | scene scripts | MIGRATED | none |
| Actors | actor draw path | scenes under `scenes/actors/` | actor presentation controller | MIGRATED | none |
| Projectiles | circles/lines in the main draw path | one scene per stable projectile under `scenes/combat/projectiles/` | combat presentation controller | MIGRATED | each projectile owns collision and hit-effect reference |
| Pickups/effects/hazards | production draw primitives | one scene per stable effect under `scenes/combat/` | combat presentation controller | MIGRATED | dedicated canonical combat atlas is active; old multiplexer is archived |
| Procedural terrain | retained `_draw()` chunks | TileSet + TileMapLayer in `scenes/world/terrain/` | terrain scene + region service | MIGRATED | preview includes terrain, barrier, landmark, gate and vegetation coverage |
| Audio | players and lookup in `main.gd` | `scenes/app/audio_controller.gd` | Audio controller | MIGRATED | none |
| Debug collision | production drawing | `scenes/world/debug/collision_debug.tscn` | debug scene | MIGRATED | none |

## Removed fallback paths

- Runtime references to `res://assets/generated/`, `res://art/`,
  `res://preview/`, `res://docs/`, and `res://artifacts/` are forbidden by tests.
- Old `src/render/camp_layer.gd`, retained terrain draw scripts, rectangle-only UI
  layouts, and duplicate `src/ui` runtime scenes have been removed from active
  ownership.
- The screen-space camp hotspot proxy layer has been removed; authored
  `TouchArea` polygons now own taps and hover highlights.
- Inline actor/projectile/effect state classes have moved to `src/state/`.
- Retired runtime files were moved, not deleted, to
  `art/archive/runtime_legacy/` after reference validation.
- Runtime camp ambience placement was removed. The authored Gate scene now owns
  its prompt, pulse, position, and visibility presentation.

## Evidence

- Asset audit: `artifacts/foundation_cleanup/asset_audit.csv`
- Runtime manifest: `assets/runtime/asset_manifest.json`
- 390x844 captures: `artifacts/foundation_cleanup/screenshots/`
- Architecture guards: `tests/architecture_guard_tests.gd`
- Asset validation: `tests/asset_manifest_tests.gd`
- Editor/runtime parity: `tests/editor_runtime_parity_tests.gd`
- World/combat/UI contracts: `tests/*_scene_tests.gd`
