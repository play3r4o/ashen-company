# ImageGen v2 source manifest

These are the approved high-resolution source images for the reference-quality
visual pass. Godot ignores this source directory; `tools/process_imagegen_v2.py`
turns the approved sources into native runtime assets under
`assets/generated/reference_v2`.

Generation mode: built-in ImageGen tool.

## Shared direction

- Use the supplied Refuge reference as the authority for pixel density,
  three-quarter perspective, palette, warm upper-left lighting, compact shadows,
  material detail, atmosphere, and mobile readability.
- Produce original artwork only; do not copy reference pixels, logos, or text.
- Keep believable medieval materials and restrained folk-horror accents.
- Crisp native-resolution pixel art, no antialiasing, blur, painterly gradients,
  photorealism, 3D rendering, UI mockup perspective, or modern objects.

## `refuge_master.png`

Use case: authoritative portrait mobile game environment master. Create a
fortified refuge surrounded by dense dark-green forest, with a warm cobbled
interior, continuous timber palisade, centered rear Hall, central campfire and
benches, a central lower gate and traveled road, and supplies grouped around the
perimeter. Keep the central walking lane clear. No UI, text, characters, enemies,
or detached asset-sheet objects.

## Hero chroma sheets

Files: `warrior_sheet_chroma.png`, `hunter_sheet_chroma.png`,
`mage_sheet_chroma.png`, and `rogue_sheet_chroma.png`.

Create one exact 4x4 sprite grid on flat `#ff00ff`. Rows are down, left, right,
and up. Columns are idle A, idle B, walk A, and walk B. Every cell uses the same
scale, ground anchor, lighting, outline weight, and complete silhouette. Preserve
the class equipment: spear and shield, longbow, staff with restrained barrow
light, or paired knives. No shadows, text, grid lines, effects, or scenery.

## `enemy_atlas_chroma.png`

Create an exact 3x3 grid on flat `#ff00ff`: wolf, raider, archer; shielded
reaver, blighted corpse, carrion crow; houndmaster, grave guard, Barrow Knight.
Match the hero scale and environment lighting, with immediately readable combat
silhouettes and pale blue-green reserved for supernatural details. No text,
lines, scenery, shadows, or overlapping cells.

## UI chroma sheets

- `hud_rail_chroma.png`: a straight-on timber-and-iron HUD rail with a hanging
  level tab, long health recess, compact resource cells, and a square settings
  socket; no icons, values, labels, perspective, or shadow.
- `controls_chroma.png`: one wide ornate dark action-button frame and one round
  iron settings cog, vertically separated; no text or symbols besides the cog.
- `hud_icons_chroma.png`: exact 3x2 grid containing a level pennant, heart,
  silver coins, provisions, iron key, and Dread eye; no text or grid lines.

All chroma sheets were converted with the ImageGen skill's
`remove_chroma_key.py` helper using border auto-keying, soft matte, despill, a
transparent threshold of 12, and an opaque threshold of 220.
