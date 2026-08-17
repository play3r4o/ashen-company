# Luna Max Prompt 01 — UI Foundation and Settings

Work only on the shared UI foundation and the Settings screen.

Do not implement Hall or Arsenal in this task.

## Goal

Replace the current Settings presentation with a reusable, pixel-native modal
that matches `docs/references/settings_reference.png`, while preserving every
existing setting and save behavior.

## Required screen structure

Create:

- `res://ui/screens/settings/settings_screen.tscn`
- `res://ui/screens/settings/settings_screen.gd`

Suggested node structure:

- `SettingsScreen` (`Control`)
  - instance of `AshenModal`
    - content:
      - `AshenHeader`, title `SETTINGS`
      - `ScrollContainer`
        - `VBoxContainer`
          - `AshenSectionHeader`, title `AUDIO`
          - Music slider row
          - Sound slider row
          - Effect Density segmented selector
          - `AshenSectionHeader`, title `GAMEPLAY`
          - Screen Shake toggle
          - Left-Handed Action Button toggle
          - Show Collision / Interaction Shapes toggle
          - Confirm Entering / Leaving Camp toggle
          - `AshenSectionHeader`, title `SAVE & MAINTENANCE`
          - backup text area
          - Export and Import horizontal button row
          - Reload App / Check for Update button
          - Reset Game Progress danger button
          - Back to Camp neutral button

## Exact behavior rules

1. Find the current settings variables and current save/load methods.
2. Reuse those exact values.
3. When the screen opens, read current values into controls.
4. When a control changes, call the existing setting-update path.
5. Do not create a second settings data model.
6. Preserve backup export/import behavior.
7. Preserve reload/check-update behavior.
8. Preserve reset behavior and its confirmation if one already exists.
9. If reset has no confirmation, add a confirmation dialog, but do not change
   the underlying reset action.
10. Back and close must use the same safe close path.

## Layout targets at 390x844

- Modal side margin: 18.
- Content padding: 14.
- Standard row minimum height: 44.
- Buttons: 48-52 high.
- Section gap: 18.
- Labels left; controls right.
- Allow vertical scrolling when safe-area height is smaller.
- Do not leave large unused empty areas between sections.
- Do not cover the whole screen with the decorative frame if content is short.

## Effect density selector

Use three adjacent Button controls:

- LOW
- MED
- HIGH

Selected state should use the selected card or primary styling.
Unselected states use neutral styling.

Do not convert an existing continuous effect-density setting into discrete
values unless the current game already uses discrete values. If it is
continuous, keep the existing control instead of changing semantics.

## Finish criteria

- All current settings still work.
- Settings persist after restart.
- Export/import work.
- Reset is visibly dangerous.
- Screen uses supplied assets.
- No baked text.
- No gameplay changes.
- Existing tests pass.

Provide a concise report and stop. Do not begin Hall.
