# Production Pipeline

## 1. Brief

Create one recipe with stable ID, category, purpose, runtime owner, dimensions, grid, projection, layer, anchor, collision intent, animation contract, palette subset and variants.

## 2. References and identity delta

Attach the Ashen identity board, functional/context board and the Tiny Swords
craft comparator. Study its 1× readability, stepped contour discipline,
material separation, modular completeness, stable anchors and animation
economy. State what is learned, what is excluded and at least three Ashen
markers. The comparator may influence finish quality, never the asset's
silhouette, architecture, proportions, palette relationships or pixels.

## 3. Family master

For a new family, approve one master before variants. Lock construction, material ramps, outline weight, anchor and scale. Variants inherit the master; they are not generated independently from scratch.

## 4. Silhouette and construction

Review solid silhouette, 64×64-grid footprint and large value groups before
texture. Run the physical-world preflight: ground plane, support/gravity,
contact shadow, front-to-back occlusion, scale against the player, reachable
openings and authored visual/collision/interaction anchor. Buildings require
structural logic; characters require stable anatomy/gear; tiles require full
transition coverage. A physical contradiction is a baseline failure, not a
style iteration.

## 5. Pixel and palette pass

Work at native resolution. Clean clusters manually. Remove accidental antialiasing, isolated noise, color drift, uneven outlines and alpha contamination.

## 6. Animation

Build on identical canvases with documented pivots, frame map, FPS and event timing. Test loops and direction changes before export.

## 7. Staging and validation

Generated or edited candidates remain under `art/generated/` with metadata. Validate dimensions, alpha, frame divisibility, palette limits, import assumptions and duplicate hashes.

## 8. Review

Review isolated at 1×, in a 390×844 context capture, in grayscale, beside approved neighbors and against the originality checklist. One candidate is preferred; use two only to compare a meaningful design decision.

## 9. Approval and promotion

Record reviewer, date, source hash, recipe hash, provenance and known limitations. Promote to `art/approved/`, then prepare the flattened production file. Generated output is never automatically approved.

## 10. Godot adoption

Runtime adoption is a separate code task. Copy approved art to the canonical runtime location, set nearest/no-mipmap/lossless imports, assign it in an editable scene, verify editor/runtime parity and remove obsolete runtime references only after tests pass.

## Directory states

- `art/generated/`: candidates and metadata.
- `art/approved/`: reviewed masters.
- `art/production/`: source-ready production exports.
- `art/archive/`: retired history, never a runtime fallback.
- `assets/runtime/`: only assets intentionally adopted by the game.

## AI-assisted work

AI generation is useful for concepts and controlled source material, but results require native-resolution cleanup, structural correction, palette normalization, originality review and manual approval. Never accept text, fake transparency, inconsistent pixels or style drift because the overall image is attractive.

## Batch consistency

Do not ask for a whole category as unrelated prompts. Approve a master, create a construction sheet and palette, then derive named variants while keeping anchors, outline rules and material ramps fixed.
