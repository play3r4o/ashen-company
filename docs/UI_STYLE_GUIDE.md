# Ashen Company Unified UI Style Guide

## Purpose

This pack converts the approved Settings, Veterans' Hall, and Expedition
Arsenal mockups into reusable production assets. It is not a collection of
full-screen screenshots. All labels, numbers, buttons, cards, and state
changes must remain real Godot controls.

## Visual language

- Native-looking pixel art.
- Dark wood and blackened iron construction.
- Small brass/gold accents used for focus, headings, and selection.
- Deep red reserved for primary actions and danger.
- Warm cream text.
- The camp stays visible behind modal screens through a dark translucent overlay.
- Borders are decorative but narrow enough for a 390-pixel-wide portrait screen.

## Shared component hierarchy

All major screens should reuse:

1. Modal frame
2. Header frame
3. Section divider
4. Neutral button
5. Primary button
6. Danger button
7. Panel/card frame
8. Selected card frame
9. Empty slot frame
10. Toggle and slider assets
11. Shared icon family

The screen layouts may differ. The visual components must not.

## Typography

No font files are included. Use the project's existing readable font.

Recommended hierarchy:

- Screen title: 24-30 px at the 390x844 design resolution.
- Section heading: 15-18 px.
- Standard label: 13-16 px.
- Secondary description/stat: 11-13 px.
- Button label: 15-18 px.

Avoid all-caps paragraphs. Use all caps only for titles, short section labels,
and major actions.

## Rendering

- Keep nearest-neighbor filtering.
- Do not add blur shaders.
- Do not use mipmaps for these UI textures.
- Do not scale individual icons by non-integer factors when it can be avoided.
- Use nine-slice margins from `asset_manifest.json`.
- Preserve at least a 44x44 logical touch target even when the visible icon is smaller.

## Asset ownership

- Training Grounds: combat progression and expedition options.
- Hall: settlement expansion and permanent building capacity.
- Arsenal: prepared weapons, techniques, and doctrine.
- Settings: utility controls.
- Blacksmith and Inventory should reuse this kit but use their own layouts.

## Reference images

The `/docs/references/` directory contains the approved visual targets.
Treat them as composition references only. Do not ship them as interactive
background screenshots.
