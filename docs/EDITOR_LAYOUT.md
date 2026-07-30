# Editable world layout

The Refuge has one authoring scene per Hall level:
`camp_layout.tscn` (Refuge), `camp_layout_tier1.tscn` (Outpost), through
`camp_layout_tier4.tscn` (Ashen Town). Open the level you want in Godot's 2D
view and save it after making changes. The game selects the matching scene at
runtime; there is no second set of positions to keep in sync.

The scene instances share the common authoring vocabulary, but each keeps its
own Hall-level bounds and preview slot count. Use `building_catalog.tscn` to
edit the reusable Armory, Quartermaster, Blacksmith, and Training artwork and
their default collision/interaction shapes.

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

The player’s building decision is saved as a stable slot assignment, for
example `plot_1 = armory`. When a level scene loads, the game shows only the
services assigned to those slots and leaves the other revealed slots empty.
The game keeps precise world coordinates and only applies the portrait map
scale at render time, so the authored shapes remain aligned with the art on
the phone. After saving the scene, run the game again to see the exact same
placement, collision, interaction, and wall repetition.
