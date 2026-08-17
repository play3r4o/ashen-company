# Ashen Studio v1 — PixelLab Rules

PixelLab MCP is the current primary generation backend for Ashen Studio v1. Recipes remain provider-agnostic YAML so the art contract does not depend on one provider or one MCP tool.

The connected MCP server is used through Codex. The repository does not create another API connection and does not read authentication headers.

## Backend selection

- Use the connected `mcp__pixellab__*` tools for an explicitly requested generation.
- Use `create_ui_asset` for a standalone PixelLab UI panel when its exposed size limits fit the recipe.
- Use `create_image_pro` when labelled reference images or a style image are required.
- Use `edit_image` for a local or URL-backed approved image that needs an edited interaction state.
- Use `create_object_state` for a named variant of an existing PixelLab object.
- Use `get_balance` for the read-only account usage check.
- Use `tools/pixellab/backend_stub.py` only as a future offline or batch fallback. It is not used for normal MCP operation.

The audited tool details and exact exposed parameters are recorded in `docs/PIXELLAB_MCP_CAPABILITIES.md`. Do not infer unsupported parameters from another provider or from a recipe field.

## Authentication and credentials

Normal MCP operation does not require `PIXELLAB_API_TOKEN`. MCP authentication is host-managed outside this repository.

Direct API authentication is optional future infrastructure for the local stub or a deliberately added batch adapter. It is not part of the current workflow and must not be installed, configured, or requested for ordinary MCP generation.

Never copy, print, log, inspect, serialize, or commit MCP bearer credentials. Never put credentials in recipes, prompts, review sheets, metadata, environment snapshots, or source files.

## Before any MCP generation

- The recipe must pass local validation.
- The user must explicitly request generation for the specific recipe.
- The target dimensions, alpha behavior, references, and negative constraints must be clear.
- The selected MCP tool must expose the required dimensions and background behavior; if it does not, stop and reconcile the recipe before generating.
- The Ashen pipeline admits no more than two candidates. If a PixelLab mode returns more options, do not stage more than two for review.
- Results must be written to `art/generated/<category>/<asset_name>/` before review or promotion.
- No asset may enter `art/approved/` or `art/production/` without human approval.

## Candidate and approval discipline

- Generate one candidate when the recipe is already well constrained.
- Generate a second candidate only when comparison would resolve a real ambiguity.
- Never promote the first output automatically.
- Review at 1x nearest-neighbor scale, on the intended background, and beside the closest existing runtime reference.
- Automated validation checks dimensions, alpha, names, and recipe constraints; it does not replace visual approval.

## Prompt and reference discipline

Keep the positive prompt concrete: material, silhouette, camera, pixel density, light direction, and intended use. Keep negative constraints explicit: no text, no labels, no watermark, no blur, no gradients, no extra canvas, and no unrelated props.

Use existing Ashen Company references in preference to generic style words. Record which reference establishes palette, scale, and composition. Do not assume that every MCP tool accepts image references; use only the parameters exposed by the selected tool.

## Stop conditions

Stop and return the candidate to staging if it has wrong dimensions, baked text, an opaque background where alpha is required, an inconsistent light direction, a changed anchor, a mismatched pixel density, too many candidates, or a silhouette that is not readable at the target scale.
