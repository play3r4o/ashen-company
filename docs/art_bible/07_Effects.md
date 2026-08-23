# Effects

Effects communicate mechanics first and spectacle second. They remain crisp, bounded and readable under heavy waves.

## Shape language

- Mundane impact: short wedges, chips, dust, sparks and broken material.
- Bleed: narrow burgundy cuts/drops, restrained in volume.
- Poison: irregular olive pools and low vapor.
- Fire: amber core, orange body, dark ember edge.
- Frost: angular pale planes and fractured rims.
- Shock: branching narrow strokes with clear origin/target.
- Supernatural/arcane: verdigris rings, bindings and barrow-like marks—never generic blue magic or soft neon blobs.

Color supplements shape, timing and motion. Danger cannot be communicated by color alone.

## Pixel and alpha rules

- Hard clusters define the effect body.
- Partial alpha is limited to glow, smoke and fading edges and must be documented.
- Avoid blur, airbrush particles and smooth vector-looking curves.
- Every frame has a stable canvas and pivot.
- Effects do not contain base weapon, terrain or actor pixels unless explicitly designed as a combined one-shot scene.

## Timing

Use readable phases: anticipation/telegraph → contact → decay. Contact is usually the brightest/largest single phase. Loops cannot change apparent world position or collision.

## Density and performance

- Design small, medium and high cosmetic-density variants where necessary.
- Important telegraphs and hit confirmation survive every quality mode.
- Decorative embers, smoke and debris reduce before gameplay entities.
- Heavy-wave review must verify that overlapping effects do not form an opaque screen wash.

## Deliverables

Each effect recipe records frame size/count, FPS, loop mode, pivot, blend/modulate behavior, gameplay duration, quality-mode rules, owning scene and a dark/light terrain test.
