# Codex / Luna Max Master Prompt — Ashen Company Unified UI

You are working in the existing Godot 4.7 project **Ashen Company**.

This task is intentionally written for a low-reasoning coding model. Follow
the steps literally. Do not improvise a new visual style. Do not rewrite the
game. Do not replace working gameplay systems.

## Non-negotiable constraints

1. Preserve all gameplay behavior.
2. Preserve save compatibility.
3. Preserve existing setting names and values.
4. Preserve existing Hall costs, capacity rules, and expansion logic.
5. Preserve existing Arsenal preparation rules and limits.
6. Keep the project at its existing 390x844 portrait reference resolution.
7. Keep the GL Compatibility renderer and nearest-neighbor pixel rendering.
8. Do not migrate the world to TileMap or TileMapLayer.
9. Do not place invisible buttons over full-screen mockup screenshots.
10. Do not bake text, resource values, or dynamic state into PNGs.
11. Do not add blur shaders.
12. Do not modify unrelated combat, generation, inventory, or save code.
13. Reuse one shared Theme and one set of UI components.
14. Make small commits after each phase.
15. Run existing tests after every phase.

## Read before editing

Read these files first:

- `res://assets/ui/ashen/asset_manifest.json`
- `res://docs/UI_STYLE_GUIDE.md`
- `res://docs/ASHEN_UI_ASSET_MANIFEST.md`

Also inspect the reference images in:

- `res://docs/references/settings_reference.png`
- `res://docs/references/hall_reference.png`
- `res://docs/references/arsenal_reference.png`

If the archive was extracted with `docs/` at the project root, Godot paths
will begin with `res://docs/`.

## Asset path

All reusable UI art is already supplied under:

`res://assets/ui/ashen/`

Do not move or rename it.

## Required implementation order

Complete the phases in this exact order:

1. Shared UI foundation.
2. Settings screen.
3. Veterans' Hall screen.
4. Expedition Arsenal screen.
5. Cleanup and regression verification.

Do not begin a later phase while the current phase is broken.

---

# PHASE 1 — Shared UI foundation

## Create directories

Create these directories if absent:

- `res://ui/theme/`
- `res://ui/components/`
- `res://ui/screens/settings/`
- `res://ui/screens/hall/`
- `res://ui/screens/arsenal/`

## Create the Theme

Create:

`res://ui/theme/ashen_ui_theme.tres`

Use `StyleBoxTexture` resources that point to the supplied nine-slice PNGs.

Set texture margins exactly from:

`res://assets/ui/ashen/asset_manifest.json`

At minimum configure:

### Button

- `normal`: neutral normal texture
- `hover`: neutral hover texture
- `pressed`: neutral pressed texture
- `disabled`: neutral disabled texture
- font color: cream
- hover font color: gold-light
- disabled font color: muted gray
- minimum height: 48 logical pixels

### PanelContainer

Use the standard panel frame for ordinary panels.

### LineEdit / TextEdit

Use `ashen_text_field_9slice.png`.

### HSlider

Use supplied slider track, fill, and knob textures.

### VScrollBar

Use supplied track and grabber textures.

Do not include a new font file. Reuse the project's existing UI font.

## Create reusable components

Create the following scenes:

### `res://ui/components/ashen_modal.tscn`

Node structure:

- `AshenModal` (`Control`, full rect)
  - `DimOverlay` (`ColorRect`, full rect, color `#000000B0`)
  - `SafeMargin` (`MarginContainer`, full rect)
    - `Frame` (`PanelContainer`)
      - `ContentMargin` (`MarginContainer`)
        - `Content` (`VBoxContainer`)
  - `CloseButton` (`TextureButton`)

Rules:

- `SafeMargin` side margins: 18.
- `Frame` must not overlap the top HUD.
- Content padding: 14.
- Close button visible only when requested by the screen.
- Expose a method or exported node reference that lets a screen add its
  content to the `Content` container.
- Closing must emit a signal. It must not directly alter gameplay state.

### `res://ui/components/ashen_header.tscn`

- `PanelContainer`
  - optional centered crest
  - title label

Use the header nine-slice texture. Do not hard-code a screen title.

### `res://ui/components/ashen_section_header.tscn`

- Horizontal row with:
  - left divider segment
  - section label
  - right divider segment

The title is dynamic.

### `res://ui/components/ashen_toggle_row.tscn`

- Left-aligned label.
- Right-aligned `TextureButton` or custom toggle control.
- OFF texture: `ashen_toggle_off.png`.
- ON texture: `ashen_toggle_on.png`.
- Entire row must have a minimum touch height of 44.
- Emit `value_changed(bool)`.
- Do not store settings internally.

### `res://ui/components/ashen_slider_row.tscn`

- Left label.
- Right HSlider.
- Minimum row height: 44.
- Emit `value_changed(float)`.
- Do not store settings internally.

### `res://ui/components/ashen_primary_button.tscn`

Use the primary red button textures.

### `res://ui/components/ashen_danger_button.tscn`

Use the danger button textures.

### `res://ui/components/ashen_card.tscn`

Reusable selectable panel with:

- icon slot
- title
- optional description
- optional stats
- optional selected check icon
- selected and disabled visual states

Do not include weapon-specific logic.

## Menu layer

Use or create one `CanvasLayer` above the existing world and HUD.

Recommended structure:

- `MenuLayer` (`CanvasLayer`)
  - one currently active screen

Do not create multiple overlapping menu layers.

When a menu is open:

- Disable camp movement and world interaction input.
- Keep the camp visible.
- The dim overlay may cover the world, but do not obscure the top HUD unless
  the existing game intentionally does so.
- Keep only cheap ambient animation if already available.
- Restore input correctly when the menu closes.

Commit after Phase 1.

---

# PHASE 2 — Settings screen

Follow the dedicated prompt:

`res://docs/PROMPT_01_UI_FOUNDATION_AND_SETTINGS.md`

Do not redesign setting behavior.

Commit after Phase 2.

---

# PHASE 3 — Veterans' Hall screen

Follow:

`res://docs/PROMPT_02_HALL_SCREEN.md`

The Hall screen displays state. Existing Hall logic remains the source of truth.

Commit after Phase 3.

---

# PHASE 4 — Expedition Arsenal screen

Follow:

`res://docs/PROMPT_03_ARSENAL_SCREEN.md`

The Arsenal screen displays and edits preparation state through existing
services or main-game methods. Do not duplicate combat data.

Commit after Phase 4.

---

# PHASE 5 — Verification

Run all existing automated tests.

Manually verify at 390x844:

1. Open and close every screen ten times.
2. No screen leaves camp input disabled after closing.
3. Buttons are at least 44 logical pixels high.
4. Text remains readable.
5. No title overlaps the close button.
6. Settings persist after app reload.
7. Hall costs and capacity match the old screen.
8. Hall expansion performs exactly one upgrade.
9. Arsenal selection limits match existing rules.
10. Only prepared Arsenal content appears in run level-ups.
11. Back and close actions return to camp.
12. No save migration occurs.
13. No texture uses blurry filtering.
14. No full-screen reference mockup is included in a shipping scene.

At the end, provide:

- changed file list
- preserved behaviors
- screenshots of the three screens
- test output
- any remaining temporary placeholders
