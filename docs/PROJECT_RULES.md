# Ashen Studio v1 — Project Rules

## Scope

This folder is the art-production layer for Ashen Company. It defines recipes, references, generated candidates, review evidence, and approved art without changing the game's behavior.

The current task's hard boundary is:

- do not modify gameplay logic;
- do not modify Godot scenes or scene resources;
- do not modify existing runtime scripts, services, project settings, or import files;
- do not replace or rename existing assets as part of art-pipeline setup.

Adopting an approved asset into `assets/` or wiring it into `ui/` is a separate, explicitly authorized task.

## Worktree safety

- Inspect `git status` before starting and preserve unrelated user changes.
- Add pipeline files only in the requested `docs/`, `.codex/`, `art/`, and `tools/pixellab/` areas unless the user expands scope.
- Never run a cleanup that deletes, resets, or reformats unrelated files.
- Do not create a second settings model, runtime manifest, or Godot import configuration in this art layer.

## Production gates

1. A recipe exists and passes `validate_recipe.py`.
2. Candidate files are staged in `art/generated/` and pass `validate_asset.py`.
3. A review sheet records the recipe, dimensions, references, and candidate hashes.
4. A human selects one candidate. At most two candidates may be compared.
5. The selected candidate is promoted to `art/approved/` and only then to `art/production/`.

No file in `art/production/` is considered approved merely because it exists there. The promotion record is the evidence of approval.

## Art standards

- Use the relevant file in `docs/art_bible/` and the current UI manifest as the source of truth.
- Preserve exact dimensions and alpha behavior from the recipe.
- Use nearest-neighbor rendering, no mipmaps, and lossless PNG for pixel art.
- Never bake labels, numbers, text, logos, or button captions into reusable UI art.
- Keep light upper-left, contact shadows down-right, and supernatural blue-green restrained.
- Keep transparent production pixels transparent; chroma-key backgrounds belong only in explicitly marked staging sources.

## Secrets and providers

PixelLab MCP is the current primary generation backend. The connected MCP integration owns authentication; normal MCP operation does not require `PIXELLAB_API_TOKEN`, and this repository must not create another API connection or inspect authentication headers.

The local `tools/pixellab/backend_stub.py` remains available only as a future offline or batch fallback. It must not make a network request during local validation or review. Direct API authentication is optional future infrastructure for that fallback, never a normal MCP setup step.

Never copy, print, log, inspect, commit, or store MCP bearer credentials. Never put credentials in a recipe, prompt, review sheet, metadata file, or source file.

## Completion report

Every pipeline change should report the files added or modified, the commands run, validation results, and the one remaining manual action, if any. If no art was generated, say so explicitly.
