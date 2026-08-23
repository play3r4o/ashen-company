# Acceptance and Scoring

## Hard gates

Any one of these fails the asset regardless of score:

- wrong dimensions, grid, projection, pivot or frame layout;
- obvious copying, tracing, recolor or near-identical silhouette;
- unknown or incompatible license;
- baked text where live text is required;
- accidental blur, antialiasing or nontransparent background;
- inconsistent light direction;
- runtime scale compensation required to fit;
- missing required transition, direction, frame or state;
- unreadable at native phone scale;
- collision/anchor assumptions not documented;
- physically impossible construction: floating/sinking parts, unsupported weight,
  contradictory depth planes, unreachable entrances, or visual/collision/
  interaction anchors that disagree.

## Scoring

Score each item 0 (fail), 1 (revise), or 2 (pass):

1. Ashen identity markers are visible.
2. Silhouette and function read at 1×.
3. Value grouping survives grayscale.
4. Palette/materials match approved Ashen neighbors.
5. Construction and grounding are believable on the shared 64×64 world grid.
6. Pixel clusters and outlines meet the Tiny Swords craft bar at 1× without
   copying its silhouettes or pixel arrangements.
7. Projection, anchor and scale are consistent.
8. Animation/state coverage is complete.
9. Gameplay context remains clear.
10. Originality delta is convincing.

Approval requires no hard-gate failure, no zero scores and at least 17/20. A 1 in originality, projection/anchor or native-scale readability still requires revision even when the total passes.

## Category checks

### Terrain/environment

Tileable fill, all required transitions, no black reveal, coherent shadow, traversable lane clarity, visible blockers only and scene-context test.

### Structures/props

Ground anchor, support/joins, contact shadow, collision footprint, interaction
footprint, Y-sort behavior, reachable openings, upgrade continuity and material
wear logic.

### Characters

Silhouette, four-direction consistency, stable feet, uncropped equipment, readable class/behavior and light/dark terrain tests.

### UI

Nine-slice/state completeness, live text, 44px touch target, safe-area variants, editor/runtime parity and color-independent states.

### Effects

Mechanic clarity, stable pivot/canvas, telegraph-contact-decay, density fallback and no opaque screen wash.

## Approval record

Record asset ID, version, recipe, candidate hash, reviewer, date, score, hard-gate result, identity markers, provenance, context captures and remaining limitations.
