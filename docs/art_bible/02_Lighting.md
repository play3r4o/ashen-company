# Ashen Company Art Bible — Lighting

Lighting is a continuity system. The viewer should be able to move from the camp to Blackthorn Moor and still understand which edges are lit, which surfaces are recessed, and where an actor is standing.

## Default light

- The key light comes from the upper left.
- Lit upper-left planes use a restrained warm or neutral highlight.
- Shadow planes fall down-right and remain compact.
- Contact shadows are neutral-black or a dark local material color, never a soft gray halo.
- Feet, building foundations, and prop bases need a readable ground contact even when the background is dark.

## Materials and light response

- Parchment and fire can carry the brightest warm pixels.
- Iron gets small, hard highlight clusters rather than long gradients.
- Wet mud may use a few cool or warm glints, but it must not become a reflective surface.
- Cloth receives broad, quiet value blocks; do not outline every fold.
- Supernatural light may use `#73AAA1` or `#A6D4C9`, but it should affect nearby surfaces subtly rather than creating a neon aura.

## UI lighting

UI frames share the world light direction even when they are front-facing. Place brass highlights on upper-left edges and keep lower-right recesses dark. A modal may have a warm edge or lantern accent, but the center must stay quiet for live Godot text and controls.

## Disallowed shortcuts

- No blur, bloom, drop-shadow filter, or soft airbrush used as a substitute for pixel clusters.
- No inconsistent light direction between button states.
- No full-screen color wash that makes a candidate look finished while hiding wrong dimensions or poor silhouette.
