# Ashen Company Art Bible — Environment

The refuge and Blackthorn Moor share one continuous 32px-era world language. The player should understand the route from safe camp to dangerous moor without a style reset.

## Scale and anchors

- Terrain is authored as 32x32 cells.
- Roads, gates, foundations, and major prop clusters align to the same grid or to an explicit half-cell rule recorded in the recipe.
- Structure tiers preserve the exact ground anchor, collision footprint, and interaction contour.
- Roofs, cloth, banners, smoke, and foliage may overlap actors visually but never redefine their collision footprint.

## The refuge

The northern safe area keeps the Hall-fire-gate lane open. Six restoration plots are deliberate and readable: Veterans' Hall north-center, Armory northwest, Quartermaster northeast, Blacksmith southwest, Training Yard southeast, and Campfire lower-center. Perimeter props add life without blocking the player or obscuring the plot anchors.

The physical palisade is a modular runtime boundary. Background terrain must not secretly reintroduce a second fence, gate, or collision wall.

## Blackthorn Moor

The moor is muddy, open, and threatening. Use dead grass, puddles, blackthorn, broken stakes, ancient stones, low ruins, and clear combat spaces. Edges may be dense and dark; the traversable center must remain readable. Pale blue-green supernatural traces are sparse and meaningful.

## Environment recipes

Every environment recipe should state:

- tile or sprite dimensions;
- whether the output tiles, repeats, or is a fixed background;
- the ground anchor and collision assumptions;
- neighboring terrain categories and edge behavior;
- the permitted amount of detail in the traversable area;
- whether the result is a reference, staging candidate, or production-ready runtime sprite.

Do not use a full-screen screenshot as an interactive scene asset. Live structures, characters, and controls remain separate Godot nodes.
