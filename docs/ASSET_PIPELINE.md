# Ashen Studio v1 — Asset Pipeline

This pipeline turns a written asset decision into reviewable, reproducible art without touching the Godot runtime. PixelLab MCP is now the primary generation backend. Local Python tools validate, review, and promote results; they do not create a second provider connection.

## Folder responsibilities

| Folder | Meaning |
|---|---|
| `art/references/` | Global, UI, environment, building, character, enemy, weapon, item, and effect references |
| `art/recipes/` | Provider-agnostic YAML recipes and the schema |
| `art/generated/` | PixelLab MCP results and other unreviewed candidates; disposable staging |
| `art/reviews/` | Generated contact sheets and metadata used for a human decision |
| `art/approved/` | The selected candidate, versioned and hash-recorded after manual approval |
| `art/production/` | An approved asset ready for a separate Godot adoption step |
| `art/archive/` | Retired versions kept for recovery and comparison |

## Backend configuration

`tools/pixellab/backend_config.yaml` records PixelLab MCP as primary, the exact audited tool mapping, the two-candidate cap, staging roots, and the future local-stub fallback. It contains no credentials.

Normal MCP operation does not require `PIXELLAB_API_TOKEN`. Authentication is managed by the connected MCP integration. The local stub remains available only for a future offline or batch workflow.

## State flow

```text
provider-agnostic recipe
  -> local recipe validation
  -> PixelLab MCP generation, only after explicit user request
  -> art/generated/<category>/<asset_name>/
  -> local asset validation
  -> review sheet
  -> human approval
  -> art/approved/<category>/<asset_name>/vNNN/
  -> separate Godot adoption task
  -> art/production/<category>/<asset_name>/vNNN/
```

No MCP result is promoted automatically. The promotion tool preserves the source candidate, refuses to overwrite an existing version, and writes approval evidence.

## Identity and reference contract

`docs/art_bible.md` and `docs/art_bible/style_tokens.yaml` are the identity authority. Tiny Swords is the project's strong craft comparator: it should raise the bar for immediate native-scale readability, crisp stepped contours, broad value grouping, material separation, modular completeness, stable anchors and animation economy. It never supplies Ashen pixels, silhouettes, proportions, costumes, structures, UI geometry, palette relationships, poses or animation frames.

Every substantial recipe must include three reference roles:

1. an Ashen identity board and approved Ashen production neighbors;
2. a functional/context board showing projection, role and runtime fit;
3. a strong craft comparator such as Tiny Swords, used for finish discipline rather than identity.

The recipe also includes an identity-delta statement naming the studied quality, excluded comparator traits and at least three Ashen fingerprint markers. “The comparator, but darker/recolored” is invalid. Review includes physical-construction preflight, silhouette-only, grayscale, native 1×, 390×844 context and side-by-side originality checks. For world assets, physical construction must pass before style polish: the object needs a clear 64×64-grid ground anchor, visible footprint, believable support/gravity, contact shadow, coherent front-to-back occlusion, reachable openings, and authored visual/collision/interaction alignment.

For a new asset family, approve one family master before generating variants. Lock construction, palette ramps, outline weight, anchor and scale, then derive variants from that master. Independently generated family members are not considered consistent merely because their prompts share adjectives.

## Local commands

From the repository root, install the local validator and review-sheet dependencies:

```powershell
python -m pip install -r tools/pixellab/requirements.txt
```

Validate every recipe:

```powershell
python tools/pixellab/validate_recipe.py --all
```

Validate a staged candidate against a recipe:

```powershell
python tools/pixellab/validate_asset.py `
  --recipe art/recipes/ui/button_neutral.yaml `
  --asset art/generated/ui/button_neutral/button_neutral_normal__candidate-01.png
```

Build a review sheet after MCP candidates exist:

```powershell
python tools/pixellab/generate_review_sheet.py `
  --recipe art/recipes/ui/button_neutral.yaml
```

Stage a manually selected candidate in `art/approved/`:

```powershell
python tools/pixellab/promote_asset.py `
  --recipe art/recipes/ui/button_neutral.yaml `
  --asset art/generated/ui/button_neutral `
  --target approved `
  --approve
```

Move an approved version into `art/production/` for the later Godot adoption step:

```powershell
python tools/pixellab/promote_asset.py `
  --recipe art/recipes/ui/button_neutral.yaml `
  --asset art/approved/ui/button_neutral/v001 `
  --target production `
  --approve
```

The local backend stub is not part of the MCP-primary path. It remains available only as a future fallback:

```powershell
python tools/pixellab/backend_stub.py `
  --recipe art/recipes/ui/button_neutral.yaml
```

This command does not call PixelLab. It is not required for normal operation and should not be used to create a second API connection.

## Validation gates

Recipe validation checks category, naming, required sections, exact state sizes, alpha policy, nearest filtering, deterministic seed, candidate limit, staging destinations, identity-delta evidence, provenance, and mandatory manual approval. Asset validation checks file existence, PNG dimensions, required alpha, safe location, and candidate naming. These checks do not prove visual quality or originality; the review sheet and human approval remain required before `approved` or `production`.

## Safe Godot adoption rules

When a separate task adopts a production asset into Godot:

- copy only the approved file and its documented metadata;
- keep PNG import filtering nearest-neighbor;
- keep mipmaps disabled;
- use lossless compression for pixel art;
- enable repeat only for an explicitly tiled texture;
- place textures at integer coordinates and keep scale factors integer where possible;
- use the recipe's nine-slice margins, frame anchor, and state naming;
- run the existing project checks after the adoption, without changing gameplay semantics.

Godot should generate its own `.import` metadata. This pipeline does not hand-author or modify runtime import files.

## Current v1 boundary

The five starter UI recipes remain provider-agnostic: settings frame, neutral button, danger button, toggle, and slider. This capability audit does not generate art or consume generation credits.
