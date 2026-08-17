# Ashen Company Art Bible — Project

## Identity

Ashen Company is a dark medieval-fantasy mercenary game with a folk-horror edge. The player restores a battered company refuge, prepares a small roster, and enters Blackthorn Moor for dangerous expeditions. Art should feel practical, weathered, and readable before it feels ornate.

The visual target is crisp pixel art with grounded late-medieval materials:

- dark oak, blackened iron, worn leather, muddy earth, moss, parchment, and muted burgundy company cloth;
- restrained amber light for camp warmth and brass UI accents;
- pale blue-green reserved for supernatural traces, mist, and other unnatural light;
- silhouettes and value grouping that remain readable on a small mobile screen.

## Canonical runtime target

| Concern | Canonical rule |
|---|---|
| Device composition | Portrait mobile |
| Design viewport | 390 x 844 logical pixels |
| World grid | 32 x 32 native-pixel terrain cells |
| UI sizing | Exact sizes from the recipe or existing Ashen UI manifest |
| Texture filtering | Nearest-neighbor |
| Texture compression | Lossless for pixel art |
| Text in art | Forbidden for UI and reusable assets |
| Candidate count | One preferred candidate, two maximum |
| Production gate | Manual review and approval are mandatory |

## Existing project anchors

The current repository already contains the visual language this pipeline extends:

- `docs/art_bible.md` is the earlier 32px world-art baseline.
- `docs/UI_STYLE_GUIDE.md` and `assets/ui/ashen/asset_manifest.json` define the current UI kit, margins, palette, and touch targets.
- `assets/backgrounds/world_map_v2.png`, `assets/camp_layers/`, and `assets/foundation/` are style references for the world and settlement.
- `assets/generated/reference_v2/` contains current generated reference material; it is not a substitute for an approved production asset.

## Non-negotiables

1. Preserve the hard pixel edge at every stage. Never blur, antialias, or add a painterly pass to hide a mismatch.
2. Author at the exact requested dimensions. Do not crop, pad, or resize a candidate during promotion.
3. Keep words, letters, numbers, logos, and UI labels out of reusable art. Godot controls own all live text.
4. Treat the recipe as the source of truth for intent, dimensions, references, palette, and reproducibility.
5. Stage every generated candidate under `art/generated/`, review it, and promote only an approved candidate.
6. Stop at two candidates. More variation makes comparison less useful and is not part of this studio workflow.

## How to use this bible

Read this file and the relevant category file before writing a recipe. If a new asset would require a rule that conflicts with this bible, update the bible first and record the decision in the recipe rather than silently creating an exception.
