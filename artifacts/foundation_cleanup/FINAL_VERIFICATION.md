# Foundation cleanup final verification

Date: 2026-08-04

## Automated suites

- `tests/run_all.gd`: 82 passed, 0 failed.
- `tests/settings_ui_smoke.gd`: passed.
- `tests/architecture_guard_tests.gd`: 0 failures.
- `tests/asset_manifest_tests.gd`: 0 failures.
- `tests/editor_runtime_parity_tests.gd`: 0 failures.
- `tests/world_scene_tests.gd`: 0 failures.
- `tests/combat_scene_tests.gd`: 0 failures.
- `tests/ui_scene_tests.gd`: 0 failures.
- `tests/smoke_game.gd`: 0 failures; two simulated heavy-combat seconds completed in 3337 ms.

## Presentation evidence

- Re-captured the complete 390x844 evidence set in
  `artifacts/foundation_cleanup/screenshots/final/` using the OpenGL Compatibility renderer.
- Captured safe-area variants at 0, 34, 47, and 59 pixels.
- The Training Grounds runtime now uses the same editable 156-node canvas that is visible in Godot.
- Each stable projectile and combat-effect ID has a dedicated scene and canonical production texture.

## Web export

- `Web` release export completed successfully.
- `index.html`, `index.manifest.json`, and `index.service.worker.js` returned HTTP 200 from a local server.
- The manifest declares portrait orientation.
- The service worker includes the exported PCK in its cache list.
- Binary package scan found no references to `art`, `preview`, `docs`, `artifacts`, old generated/UI roots, camp ambience, or the retired effect multiplexer.

## Manual device check still required

The user must perform the final installed-PWA and iPhone 13-class frame-rate check. This environment can verify the package and desktop simulation but cannot measure Safari's on-device sustained frame rate or home-screen installation behavior.
