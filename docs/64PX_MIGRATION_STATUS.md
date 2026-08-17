# Native 64px world migration status

This file is the acceptance ledger for the native terrain migration. A phase is
only marked complete when its focused Godot test passes. Visual categories that
do not have an approved/licensed native replacement remain gated; they must not
be hidden with a legacy sprite or a generated placeholder.

## Completed foundation phases

| Phase | Result | Evidence |
| --- | --- | --- |
| 0 — Freeze and audit | Complete | Numeric audit and asset coverage matrix are in `docs/`; dirty worktree preserved. |
| 1 — `WorldMetrics` | Complete | `src/world_metrics.gd`; terrain 64px, navigation/blocker 32px, spatial hash 48px. |
| 2 — Save v4 boundary | Complete | `src/save_service.gd`; settings-only pre-v4 migration, one-time backup/reset/notice. |
| 3 — Native TileSets | Complete | Native 64px Meadow, water, shadow and Blackthorn TileSets; authored transforms are scale 1. |
| 4 — Meadow source scene | Complete | `blackthorn_moor_preview.tscn` owns WaterFill, BaseTiles, MeadowShadows and MeadowComposition. |
| 5 — Region conversion | Complete | `RegionGenerator` returns grid 64, size 18×39, footprint 1152×2496; roads use two terrain cells. |
| 6 — Camp tiers | Complete | Camp tiers 0–4 own native 64px ground TileMaps and authored bounds, gate and safe/no-spawn shapes. |
| 10 — Legacy terrain branch | Complete in code | Old production switch and 32px Blackthorn TileSet references are removed; archive is retained for history. |

## Remaining approval gates

The following categories still need an explicitly approved/licensed 64px-compatible
asset set before they can be promoted and their legacy art archived:

- Ruined-city buildings, walls, roads and prison.
- Meadow/world vegetation.
- Player classes, enemies, elites and boss.
- Projectiles, attack/technique effects, pickups, hazards and damage feedback.

The existing scene contracts and collision ownership are retained while these
art approvals are pending. No unrelated sprite is substituted.

## Verification record

The current local verification passes:

- `tests/run_all.gd`: 90 passed, 0 failed.
- `tests/world_scene_tests.gd`: 0 failures.
- `tests/smoke_game.gd`: 0 failures.
- `tests/settings_ui_smoke.gd`: 0 failures.
- `tests/architecture_guard_tests.gd`: 0 failures.
- `tests/asset_manifest_tests.gd`: 0 failures.
- `tests/combat_scene_tests.gd`: 0 failures.
- `tests/editor_runtime_parity_tests.gd`: 0 failures.
- `tests/ui_scene_tests.gd`: 0 failures.
- Godot headless editor initialization: exit code 0.

Phone QA, PWA packaging, and visual approval of the remaining categories are
still required before the migration can be called fully complete.
