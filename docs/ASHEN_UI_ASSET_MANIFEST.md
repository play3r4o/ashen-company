# Ashen UI Asset Placement and Naming

Extract the archive into the root of the Godot project.

After extraction, the main art path must be:

`res://assets/ui/ashen/`

Do not rename the files unless every prompt and resource path is updated.

## Nine-slice margins

| Asset group | Left | Top | Right | Bottom |
|---|---:|---:|---:|---:|
| Modal frame | 16 | 16 | 16 | 16 |
| Header frame | 16 | 12 | 16 | 12 |
| Standard panels/cards/slots | 8 | 8 | 8 | 8 |
| Text field | 10 | 10 | 10 | 10 |
| Buttons | 12 | 10 | 12 | 10 |

The full machine-readable list is in:

`res://assets/ui/ashen/asset_manifest.json`

## Folder ownership

### `frames/`

Use with `StyleBoxTexture`, `PanelContainer`, or `NinePatchRect`.

- `ashen_modal_frame_9slice.png`: outer screen panel.
- `ashen_header_frame_9slice.png`: screen-title plaque.
- `ashen_panel_frame_9slice.png`: ordinary sections.
- `ashen_card_frame_9slice.png`: selectable cards.
- `ashen_card_selected_9slice.png`: selected/prepared cards.
- `ashen_card_disabled_9slice.png`: unavailable cards.
- `ashen_slot_empty_9slice.png`: empty Arsenal/skill slot.
- `ashen_slot_selected_9slice.png`: occupied or highlighted slot.
- `ashen_warning_frame_9slice.png`: warnings and dangerous information.
- `ashen_focus_ring_9slice.png`: keyboard/controller focus overlay.
- `ashen_text_field_9slice.png`: backup text field and input areas.

### `buttons/`

Map the four states to Godot Button theme overrides:

- `normal`
- `hover`
- `pressed`
- `disabled`

Use neutral buttons for normal navigation, primary red buttons for the main
screen action, and danger buttons for destructive actions.

### `controls/`

- Complete ON and OFF toggle textures.
- Slider track, fill, and knob.
- Scrollbar track and three grabber states.

### `icons/`

General interface icons only. Keep existing weapon and building artwork where
it is already better and more specific.

### `ornaments/`

Use sparingly. The header crest may be centered above the title plaque.
Lanterns may be placed on long modal side rails but should not appear on every
small card.

### `tiles/`

- `ashen_panel_fill_tile.png`: optional subtle panel texture.
- `ashen_world_dim_dither.png`: optional pixel-dither overlay. A plain
  `ColorRect` with `#000000B0` is also acceptable and simpler.

## Import rules

- Lossless PNG import.
- Nearest-neighbor texture filtering.
- No mipmaps.
- Do not enable repeat except where a node explicitly tiles a texture.
- Preserve the project's existing pixel-perfect viewport behavior.
