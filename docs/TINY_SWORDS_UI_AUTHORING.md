# Tiny Swords UI authoring

The UI uses the Tiny Swords 64px atlas as an editable art layer, with real
Godot controls on top for all text and interaction.

## Paintable layer

Open:

`res://scenes/ui/components/tiny_swords_ui_art_canvas.tscn`

Select `BackdropTiles` or `PanelFrameTiles` in the Scene dock. The TileMap
dock appears at the bottom of the editor. Choose any individual 64px square
from the atlas and paint, erase, move, or replace it exactly as with the
Meadow TileMap.

Every square in a source sheet is a separate tile. For example, the 3x3
`wood_table_slots.png` sheet is nine independently paintable cells: corners,
edges, and center fill are not merged into one component. The same applies to
the 5x5 paper panels, 7x7 wood table, buttons, and bars. Assemble a frame by
placing the appropriate slices next to one another.

The runtime paintable scenes use this canonical slice atlas:

`res://scenes/ui/theme/tiny_swords_ui_tileset.tres`

Its atlas sources are the canonical Tiny Swords sheets under:

`res://assets/runtime/ui/tiny_swords/`

The repository includes the complete UI Elements set: banners, bars, buttons
(including round and square variants), cursors, 25 human-avatar sheets, all
12 icon sheets, papers, ribbons, swords, wood-table sheets, and the authored
32px control sprites. The 64px-compatible sheets are all atlas sources in the
TileSet, so they are available in the TileMap dock as individual 64px cells.

The scene stores all art cells in the `.tscn`; runtime code does not
reconstruct their positions.

## Screen usage

The authored canvas is instanced by the live Arsenal, Camp Service, Results,
Training Grounds, Settings, level-up, and relic screens. Confirmation dialogs
use `res://scenes/ui/components/tiny_swords_ui_modal_art.tscn`, and the run
pause plate uses `res://scenes/ui/components/tiny_swords_ui_pause_art.tscn`.
The HUD rail is authored in
`res://scenes/ui/components/tiny_swords_ui_hud_art.tscn` and instanced by
`res://scenes/ui/hud/hud.tscn`.

Moving or repainting the cells in those scenes therefore changes the runtime
art. Use **Editable Children** on an instance if you want a screen-specific
composition instead of changing the shared canvas.

## Interactive controls

Labels, buttons, sliders, toggles, text fields, and scrollbars remain real
`Control` nodes. They cannot be painted as TileMap cells without losing input,
focus, dynamic text, and safe-area behavior. Edit their scenes directly:

- `res://scenes/ui/components/` for reusable controls.
- `res://scenes/ui/screens/` for screen-specific placement.
- `res://scenes/ui/hud/hud.tscn` for the HUD.

Keep control positions and sizes on the 8px sub-grid. Keep art cells at native
64px and do not scale the TileMap layer.
