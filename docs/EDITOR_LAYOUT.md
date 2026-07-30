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

## Menus and HUD

Screen-space authoring scenes are in `src/ui/`:

- `hud_layout.tscn` controls the resource rail, arrival crest, action buttons,
  and run status regions.
- `visual_layout.tscn` contains editable rectangles for the major camp, run,
  results, settings, and modal panels. The inherited
  `camp_menu_layout.tscn`, `run_menu_layout.tscn`,
  `results_menu_layout.tscn`, and `settings_menu_layout.tscn` scenes make each
  menu context easy to open by itself.

Move or resize the named Control nodes in the 390×844 reference viewport. The
runtime creates real buttons and labels inside those rectangles, so the scene
stays visual-only and does not replace live state or input handling. Rectangles
are scaled to other portrait widths and the safe-area band remains reserved.

## World depth

Camp artwork is partitioned by its ground anchor. The retained back layer is
drawn before the actor and the retained front layer after it. An actor north of
a prop is therefore behind it, while an actor south of that prop is in front.
Move a building, tree, or decoration's visible anchor in its camp layout scene;
the depth split follows that edited position automatically.
