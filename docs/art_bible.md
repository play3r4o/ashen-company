# Ashen Company — Visual Identity and Asset Creation Bible

This is the entry point for all new Ashen Company artwork. Detailed rules live in `docs/art_bible/`; machine-readable constants live in `docs/art_bible/style_tokens.yaml`.

## Core direction

Ashen Company is a grounded late-medieval mercenary world with restrained folk horror. It is practical, weathered, readable on a phone, and hopeful around the refuge fire. The world is built from wet stone, dark oak, reused iron, patched cloth, peat earth, lichen, thorn, parchment and muted burgundy.

Tiny Swords is a **strong craft baseline**. Use it to set the bar for clean
native-scale readability, chunky silhouettes, crisp contour rhythm, clear
material separation, modular construction, stable animation anchors, compact
value groups and efficient pixel animation. It is not Ashen Company's identity
and it is never a source of shapes. Never copy or closely reproduce its
silhouettes, anatomy, costumes, faction colors, buildings, roofs, props, UI
frames, palette relationships, poses, animation frames, or pixel clusters.

The target is: **Tiny Swords-level craft discipline with Ashen Company content,
materials and construction**. A candidate should feel as immediately legible
and polished as that comparator at 1×, while remaining visibly different in
what it depicts and how its forms are designed.

> Equivalent craft discipline, unmistakably different design.

## Ashen visual fingerprint

Every important asset should carry at least three relevant markers:

1. **Mercenary repair** — patched cloth, braces, replacement boards, reused iron and visible maintenance.
2. **Moorland material** — peat, wet stone, lichen, thorn and desaturated olive vegetation.
3. **Restrained burgundy** — a company accent, never a full-surface faction color.
4. **Warm refuge / cold horror** — amber human light versus pale verdigris supernatural light.
5. **Grounded asymmetry** — wear and repairs are uneven but structurally believable.
6. **Late-medieval utility** — broad, low, functional silhouettes rather than storybook towers.
7. **Folk-horror intrusion** — barrows, bindings, weathered circles and hooked thorn used sparingly.

## Technical contract

- Portrait reference viewport: `390×844`.
- World terrain grid: native `64×64` cells at scale `1.0`.
- Projection: orthographic top-down with roof-dominant structures and visible front walls; no isometric diamond grid.
- Filtering: nearest-neighbor; no mipmaps; lossless compression.
- Placement: whole pixels; stable ground/feet anchors.
- Live text: Godot controls only. Never bake reusable labels into images.
- Normal sprite alpha: binary wherever possible. Partial alpha is reserved for documented glow, smoke and translucent effects.
- Runtime art must be original or properly licensed and recorded in provenance.

## Physical-world accuracy

Every world asset must be believable inside the shared game world, even when it
is stylised. Pixel simplification may remove detail; it may not contradict
gravity, support, scale or depth.

- Use one orthographic top-down camera and one consistent 64×64 world grid.
- Give every constructed object a clear ground plane, footprint and bottom
  anchor. Nothing may float, sink into the ground, or stop at an unexplained
  height.
- Roofs, walls, foundations, posts, beams, doors, stairs and attached props
  must connect in a plausible front-to-back order.
- Use contact shadows and visible joins to show where weight meets the ground;
  do not use a detached dark blob as a substitute for grounding.
- Separate back, main and foreground/roof layers whenever an actor must be able
  to pass behind or in front of the object.
- The artwork, collision footprint, interaction area and touch area must share
  the same authored ground anchor. Runtime code must not infer them from the
  texture bounds.
- Doors and paths must remain reachable at the scale of the player. Props may
  be asymmetrical and weathered, but their placement must still make physical
  sense.

Before a candidate receives a style review, verify: ground plane, support,
occlusion order, footprint, scale against a player, entrance reachability and
absence of floating or impossible joins. A failure is a construction failure,
not a visual-style iteration.

## Source hierarchy

1. This bible and `style_tokens.yaml` define identity.
2. Approved Ashen production assets define continuity.
3. Category boards define function and context.
4. Tiny Swords is the strong craft comparator, never the identity source.
5. Generated images and mockups are concepts until reviewed and promoted.

Existing runtime art is not automatically an identity reference merely because it is already in the game.

## Required workflow

Brief → references → identity-delta statement → physical/construction
preflight → Tiny Swords craft pass → palette and pixel pass → animation →
automated validation → 1× phone review → originality review → approval →
production promotion → separate Godot adoption.

No generated result enters production automatically. Missing art is a blocked art task, not permission to use an unrelated fallback.

## Detailed sections

- [Project and identity](art_bible/00_Project.md)
- [Palette](art_bible/01_Palette.md)
- [Lighting](art_bible/02_Lighting.md)
- [Materials](art_bible/03_Materials.md)
- [UI](art_bible/04_UI.md)
- [Environment](art_bible/05_Environment.md)
- [Characters](art_bible/06_Characters.md)
- [Effects](art_bible/07_Effects.md)
- [Animation](art_bible/08_Animation.md)
- [Originality](art_bible/09_Originality.md)
- [Production pipeline](art_bible/10_Production_Pipeline.md)
- [Acceptance and scoring](art_bible/11_Acceptance.md)
- [Asset brief template](art_bible/ASSET_BRIEF_TEMPLATE.md)
