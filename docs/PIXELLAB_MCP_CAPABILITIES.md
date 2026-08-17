# Ashen Studio v1 — PixelLab MCP Capabilities

Audit date: 2026-08-03

This document records only capabilities exposed by the connected `mcp__pixellab__` tools during the audit. It is an audit of tool descriptors plus one read-only `get_balance` call. No generation, edit, inpaint, deletion, selection, or upload tool was invoked.

## Backend and authentication

- PixelLab MCP is the current primary backend in `tools/pixellab/backend_config.yaml`.
- The connected tools are callable through the host-managed MCP integration.
- No direct API connection is created by the repository.
- `PIXELLAB_API_TOKEN` is not required for normal MCP operation.
- MCP bearer credentials are not exposed as tool parameters and are not copied, printed, logged, inspected, or stored here.
- `tools/pixellab/backend_stub.py` remains only as a future offline or batch fallback.

## Relevant tools

### Standalone UI element

`create_ui_asset` is the dedicated UI-panel generator. The exposed inputs are:

- `description` (required);
- optional `color_palette`, `elements`, `pieces`, `name`, `width`, `height`, `no_background`, and `seed`;
- named elements include `button`, `icon_button`, `toolbar`, `tab`, `panel`, `window`, `health_bar`, `avatar`, `triangle`, `pentagon`, `hexagon`, and `octagon`;
- custom pieces support `rounded_rect`, `circle`, and `polygon` shapes.

It queues a job and returns a `ui_asset_id`. `get_ui_asset` reports processing or completion and, when completed, exposes the image URL and download information. `list_ui_assets` lists UI panels with status.

The exposed UI canvas limits are 192–688px per axis with aspect gating: square up to 512x512, 16:9 up to 688x384, 9:16 up to 384x688, 4:3 up to 600x448, and 3:4 up to 448x600. The tool exposes `no_background` for background removal and `seed` for reproducible output.

### Freeform standalone pixel art

- `create_image_pixen` accepts a description, optional detail/direction/outline/view, `width`, `height`, `no_background`, and `seed`. Its descriptor states 16–768px per side, multiples of four, with a total-area rule.
- `create_image_pixflux` accepts a description, `width`, `height`, `no_background`, and `seed`; it also accepts an init image and a forced-palette image through base64 or URL parameters. Its descriptor states 16–400px per side and a total-area range of 32x32 to 400x400.
- `create_image_pro` accepts a description, `width`, `height`, `no_background`, and `seed`. It accepts up to four labelled reference images through a JSON string and a separate style image; each can be supplied as a URL or base64. It returns a set of options, with the count dependent on canvas size.

### Editing and interaction states

- `edit_image` edits one or more existing PNG inputs from base64 or URL. It accepts a text `description` or a reference image, optional output `width`/`height`, `no_background`, and `seed`. Several input frames receive the same edit consistently. Inputs are limited to 512x512, and the tool is explicitly described as preserving pose, composition, and pixel style while applying the requested change.
- `inpaint_image` regenerates only a masked rectangle or custom mask, leaving the area outside the mask pixel-identical. It accepts an image URL/base64, a description, mask coordinates or a mask image, `crop_to_mask`, `no_background`, and `seed`. The image must be 32x32–512x512.
- `create_object_state` creates a named variant of an existing PixelLab object from `object_id`, `edit_description`, optional `state_name`, and `seed`. This is the correct state tool when the approved source is already a PixelLab-managed object.
- `create_character_state` creates a named variant of an existing PixelLab character across its rotations, with `edit_description`, `state_name`, optional palette reuse, and `seed`. It is for characters, not UI controls.

The MCP surface does not expose a dedicated `button_state` or `ui_interaction_state` tool. For a local approved PNG, use `edit_image`; for a PixelLab object, use `create_object_state`. State filenames and Ashen approval metadata remain the repository pipeline's responsibility.

## Reference-image support

Reference images are supported, but not by every tool:

| Tool | Reference support exposed |
|---|---|
| `create_ui_asset` | No image-reference parameter; it exposes a text `color_palette` hint. |
| `create_image_pro` | Up to four labelled reference images plus one style image, using URL or base64 parameters. `style_copy` can select palette, outline, detail, or shading. |
| `edit_image` | One reference image URL or base64, applied to one or more input images. |
| `create_image_pixflux` | Init image and forced-palette image, each via URL or base64. |
| `create_1_direction_object` | Style-reference images as base64 objects. |
| `create_map_object` | Optional background image as base64 for style matching/inpainting. |

## Dimensions and transparency

The tools expose explicit width/height or input-size behavior, but their limits differ. `no_background` is the exposed transparent-background control where listed below.

| Tool | Exposed dimension behavior | Transparency behavior |
|---|---|---|
| `create_ui_asset` | Explicit width/height, 192–688px per axis, aspect-gated as documented above. | `no_background` is exposed. |
| `create_image_pixen` | Explicit width/height; multiples of four; 16–768px per side; total-area rule. | `no_background` is exposed. |
| `create_image_pixflux` | Explicit width/height; 16–400px per side; total-area rule. | `no_background` is exposed. |
| `create_image_pro` | Explicit width/height; maximum depends on aspect ratio. | `no_background` is exposed and defaults to true according to the descriptor. |
| `edit_image` | Defaults to the first input size or accepts output width/height; inputs max 512x512. | Follows input by default; `no_background: false` flattens a transparent input onto white. |
| `inpaint_image` | Input must be 32x32–512x512; mask dimensions are explicit when using a rectangle. | Follows input by default; `no_background: false` flattens onto white. |

The current `ui/settings_frame.yaml` requests exactly 354x724. That is outside `create_ui_asset`'s exposed height maximum of 688, and it is outside `create_image_pixflux`'s 400px per-side limit. `create_image_pixen` also requires each side to be a multiple of four, so 354 is not valid there. No generation should be attempted for that recipe until the size contract is reconciled with an exposed tool.

## Reproducibility

The following relevant tools expose an optional numeric `seed`: `create_ui_asset`, `create_image_pixen`, `create_image_pixflux`, `create_image_pro`, `edit_image`, `inpaint_image`, `create_object_state`, `create_character_state`, and `animate_image`. The tool descriptors do not promise bit-for-bit determinism; Ashen recipes should still record the seed, tool name, prompt, references, and output hashes.

## Usage and remaining generations

`get_balance` is a read-only, no-argument tool. Its exposed capability is to return remaining USD credits and subscription generations, plus generations used and total.

The audit call returned:

```text
credits: $0.00
generations_remaining: 40
generations_used: 0
generations_total: 40
subscription: trial
```

## Complete connected tool inventory

The following PixelLab MCP tools were available in the connected namespace:

### Agent and service support

`agent_feedback`, `agent_help`, `agent_inspect`, `agent_list`, `agent_talk`

### Generation and animation

`animate_character`, `animate_image`, `animate_object`, `create_1_direction_object`, `create_8_direction_object`, `create_building_kit`, `create_character`, `create_character_state`, `create_font`, `create_image_pixen`, `create_image_pixflux`, `create_image_pro`, `create_isometric_tile`, `create_map_object`, `create_object_state`, `create_path_tiles`, `create_portrait_character`, `create_sidescroller_tileset`, `create_talking_gif`, `create_tiles_pro`, `create_topdown_tileset`, `create_ui_asset`, `create_vocal_animation`

### Editing and repair

`edit_image`, `inpaint_image`

### Status, retrieval, and lists

`get_balance`, `get_character`, `get_font`, `get_image`, `get_isometric_tile`, `get_lip_sync`, `get_map_object`, `get_object`, `get_portrait_character`, `get_sidescroller_tileset`, `get_tiles_pro`, `get_topdown_tileset`, `get_ui_asset`, `get_vocal_animation`, `list_characters`, `list_isometric_tiles`, `list_objects`, `list_projects`, `list_sidescroller_tilesets`, `list_tiles_pro`, `list_topdown_tilesets`, `list_ui_assets`

### Lifecycle and organization

`delete_animation`, `delete_character`, `delete_isometric_tile`, `delete_object`, `delete_sidescroller_tileset`, `delete_tiles_pro`, `delete_topdown_tileset`, `delete_ui_asset`, `dismiss_review`, `select_object_frames`, `set_character_portrait`, `update_character_tags`, `update_object_tags`

## Audit conclusion

The first semantically appropriate tool for a standalone Settings UI element is `create_ui_asset`, but the current 354x724 Settings frame recipe does not fit that tool's exposed canvas limits. Resolve that dimension mismatch before any generation. No generation occurred and no credits were consumed during this audit.
