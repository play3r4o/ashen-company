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

Recipe validation checks category, naming, required sections, exact state sizes, alpha policy, nearest filtering, deterministic seed, candidate limit, staging destinations, and mandatory manual approval. Asset validation checks file existence, PNG dimensions, required alpha, safe location, and candidate naming. These checks do not prove visual quality; the review sheet and human approval remain required before `approved` or `production`.

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
