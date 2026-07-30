# Editable world layout

`src/foundation/camp_layout.tscn` is the source of truth for the tier-zero
Refuge. Open it in Godot's 2D view and save the scene after making changes.
The same scene is loaded by the game at runtime; there is no second set of
positions to keep in sync.

Each authored object uses the same small vocabulary:

- Move the parent `Node2D` to move the object's ground anchor.
- Edit `Sprite` position, scale, offset, and flips to change its artwork.
- Edit `Footprint` to define the physical ground area that blocks the hero.
- Edit `Interaction` to define the area that can be approached/selected.

The `Boundary` polygon is the walkable interior of the camp. The `Walls`
polygons are the physical wall strips; their repeated pole artwork is rebuilt
from those same polygons, including the gate opening. `Plots` use the same
controls for empty construction sites. `Decor` footprints are physical but
remain non-interactable unless an interaction node is added later.

The red guide is the walkable boundary, red outlines are footprints, amber
outlines are interaction areas, and blue outlines are wall/decor footprints.
Toggle `show_hitboxes` or `show_interaction_areas` on the root `CampLayout`
node to simplify the editor view.

The game keeps precise world coordinates and only applies the portrait map
scale at render time, so the authored shapes remain aligned with the art on
the phone. After saving the scene, run the game again to see the exact same
placement, collision, interaction, and wall repetition.
