# Ashen Company Art Bible — Animation

Animation is authored as discrete pixel poses. Motion should feel deliberate and slightly mechanical, like hand-built sprite art, rather than smooth vector interpolation.

## Timing and movement

- Keep all runtime placement on whole pixels.
- Use two-pixel gait, bob, and squash phases where a motion needs more life.
- Avoid fractional scale, subpixel translation, and blur between frames.
- Record frame order and per-frame duration in the recipe when a sheet is generated.
- Loop idle and ambient cycles cleanly; avoid a visible jump at the seam.

## Current envelopes

- Character idle: two frames per direction.
- Character walk: four frames per direction, using the same 56x64 frame envelope when applicable.
- Campfire: six frames.
- Embers: eight frames.
- Smoke: four wisps or phases.
- Cloth and lantern movement: three restrained phases.
- Foliage: one-pixel movement only unless a recipe explicitly justifies more.

These are starting contracts, not permission to add animation where a static asset is clearer.

## Effects and attacks

Attack motion belongs in separate weapon/effect layers when that keeps the base character reusable. Impact timing should have a readable anticipation, contact, and recovery pose. Effects must not hide a gameplay event behind an indistinguishable burst of particles.

## Sheet rules

- State the exact row/column order, frame size, anchor, and transparent padding.
- Keep every frame in a set on the same baseline and logical canvas.
- Do not bake timing labels, arrows, or frame numbers into the sheet.
- Review the assembled loop at nearest-neighbor scale before promotion.
