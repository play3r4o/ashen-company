# Lighting

## Global light

- Default world light arrives from upper-left.
- Cast shadows fall down-right.
- Contact shadows are compact and darkest at feet/foundations.
- Every material keeps the same light direction within an asset family.
- Normal pixel sprites use clusters, not gradients or blur, to describe volume.

## Human and supernatural hierarchy

Human light is warm amber: fire, lanterns, occupied windows and worked brass. Supernatural light is pale verdigris: barrows, awakened runes, corrupted corpses and unnatural mist. They are never interchangeable.

The environment remains readable without glow. Glow supports a visible source; it never replaces the source sprite.

## Value grouping

Build an asset in three broad groups before adding detail:

1. shadow/outline mass;
2. readable local material mass;
3. restrained highlight and focal accents.

These groups must survive grayscale review at phone scale.

## Local lights

- Align the light origin with the painted lantern, flame or rune.
- Warm spill is short and strongest on nearby upward/left-facing surfaces.
- Dynamic lights are optional; base art must work when low-quality mode disables them.
- Avoid stacking baked glow, additive sprite and PointLight2D until values clip.
- Flicker changes intensity subtly, never object scale or position.

## UI lighting

UI is physically lit from upper-left like the world. Metal corners, timber strips, parchment and wax follow that rule. Buttons communicate state through depth, rim and offset—not arbitrary glow.

## Reject

Reject inconsistent light direction, airbrushed bloom, white outlines, detached black drop shadows, oversized radial glows or shadows baked into reusable sprites when placement would make them incorrect.
