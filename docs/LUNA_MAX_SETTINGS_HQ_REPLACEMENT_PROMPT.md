# Luna Max — Replace Settings Art With High-Quality Approved Assets

The Settings screen already works. This task is a visual replacement and
layout-refinement pass only.

## Do not change behavior

Do not change:

- setting names or values
- save/load paths or save schema
- signals or callbacks
- export/import
- reload/update behavior
- reset behavior
- menu open/close behavior
- camp input locking
- unrelated code
- Hall or Arsenal

Do not rebuild the Settings screen from scratch.

## New asset location

The new high-quality assets are under:

`res://assets/ui/ashen_hq/settings/`

Read:

`res://assets/ui/ashen_hq/settings/asset_manifest.json`

before editing.

## Core visual change

Replace the current simplified modal-frame construction with:

`res://assets/ui/ashen_hq/settings/frames/ashen_settings_modal_fixed_354x724.png`

Use it as a `TextureRect`, not as a nine-slice texture.

Required logical size:

- width: 354
- height: 724

Required horizontal placement at 390x844:

- left: 18
- right: 18

Place it below the existing top HUD. Use approximately `y = 102`, but inspect
the project and adjust only enough to avoid overlapping the HUD.

Keep nearest-neighbor filtering.

The image already includes:

- high-quality outer wood-and-iron frame
- side rails
- lanterns
- bottom construction
- empty title plaque
- painted close-button art

Do not place another visible modal frame, title plaque, lantern, or close icon
over it.

Place a transparent `TextureButton` hit target over the painted close button.
The hit target must be at least 44x44 logical pixels and must use the existing
safe Settings close action.

## Content coordinates

Treat the modal frame as the coordinate basis.

Recommended content area relative to the modal:

- left padding: 28
- right padding: 28
- top content start: 112
- bottom padding: 24

Title label:

- centered within the empty plaque
- text: `SETTINGS`
- approximate y: 31 within the modal
- size: 26-30
- color: `#E6D8BC`

The title is real Godot text. Do not bake it into the texture.

## Section headings

Use:

- `ornaments/ashen_divider_left_96x20.png`
- `ornaments/ashen_divider_right_96x20.png`

For each section:

- left divider
- centered heading
- right divider

Do not use repeated vertical diamond decorations.
Do not use a single stretched divider behind the text.

Headings:

- AUDIO
- GAMEPLAY
- SAVE & MAINTENANCE

Heading color: `#D7A04A`
Heading font size: 16-18

Recommended section spacing:

- 18 pixels before a section heading
- 10 pixels after it

## Sliders

Use:

- `controls/ashen_slider_track_190x18.png`
- `controls/ashen_slider_fill_190x18.png`
- `controls/ashen_slider_knob_24x24.png`

Target visible size:

- track width: 190
- knob: 24x24
- row height: at least 46

Labels left, sliders right.
Music, Sound, and Effect Density must align exactly.

Preserve the real Effect Density semantics. If it is continuous, keep it as a
slider. Do not convert it to Low/Med/High.

## Toggles

Use:

- `controls/ashen_toggle_on_54x30.png`
- `controls/ashen_toggle_off_54x30.png`

Target visible size: 54x30.

Keep labels left and toggles right.
Minimum row touch height: 48.
The entire row may be clickable if that does not change behavior.

## Backup field

Use:

`frames/ashen_text_field_286x82.png`

Exact visible size: 286x82.

Keep placeholder text as a real Godot control.
Use 10-12 pixels internal padding.
Do not display debug handles or accidental editor markers.

## Buttons

Use the exact-size textures rather than the older simplified theme buttons.

Full-width neutral:

- `buttons/ashen_button_neutral_normal_300x50.png`
- hover / pressed / disabled variants with the same naming

Half-width neutral:

- `buttons/ashen_button_neutral_half_normal_146x50.png`
- hover / pressed / disabled variants

Red action:

- `buttons/ashen_button_red_normal_300x50.png`
- hover / pressed / disabled variants

Map them to Button theme overrides using `StyleBoxTexture` with no stretch
margins required, because these are fixed-size button textures.

Use:

- half neutral for Export and Import
- full neutral for Reload / Check for Update
- red for Reset Game Progress
- full neutral for Back to Camp

Do not add a second border around these textures.
Do not use plain ColorRect buttons.

Button label color: `#E6D8BC`
Button label size: 15-17

## Scrollbar

Use:

- `controls/ashen_scroll_track_12x128.png`
- `controls/ashen_scroll_grabber_normal_14x42.png`
- hover and pressed variants

Keep the scrollbar inset from the outer frame.
It must not cover labels or toggles.

## Background

Keep the camp visible behind the menu.

Use a simple dark overlay around `#000000A5`.
Do not blur.
Do not make the camp almost completely black.

## Remove old duplicated art

Hide or remove from the Settings scene only:

- old simplified modal frame
- duplicate header plaque
- visible old close icon
- old side ornaments
- old lanterns
- old procedural diamond divider clutter
- old simplified button textures

Do not delete shared old assets if Hall or Arsenal currently use them.
Only stop the Settings screen from referencing them.

## Layout quality checks

At 390x844 verify:

1. The fixed frame is 354x724 and centered.
2. The top HUD is not covered.
3. The title is centered in the plaque.
4. The close hit target matches the painted close icon.
5. The camp is visible around the frame.
6. Sliders are 190 pixels wide and aligned.
7. Toggles are 54x30 and aligned.
8. Long labels do not collide with toggles.
9. Export and Import are equal size.
10. Reset is visually red and distinct.
11. Back to Camp has at least 18 pixels separation above it.
12. All content remains reachable through scrolling.
13. Nearest-neighbor filtering is preserved.
14. No behavior changed.

## Finish

Run existing tests and manually verify every setting.
Provide:

- changed files
- screenshot at 390x844
- confirmation that behavior and persistence remain unchanged
- any remaining alignment issue

Stop after the Settings visual replacement.
