# Ashen Studio v1 — File Naming

Names are lowercase ASCII `snake_case`. Use stable names that describe the asset rather than the provider or the current prompt wording. Do not use spaces, dates, `final`, `new`, or `latest` as versioning.

## Recipe IDs

Recipe files use:

`art/recipes/<category>/<asset_name>.yaml`

The `recipe_id` is the forward-slash form, for example `ui/button_neutral`. It must match the file category and asset name.

Allowed categories are:

`ui`, `environment`, `buildings`, `characters`, `enemies`, `weapons`, `items`, and `effects`.

## Storage paths

| State | Path pattern | Purpose |
|---|---|---|
| Reference | `art/references/<category>/...` | Human or project references; never a production import |
| Generated | `art/generated/<category>/<asset_name>/...` | Provider or local candidate output |
| Review | `art/reviews/<category>__<asset_name>__review.png` | Contact sheet and review evidence |
| Approved | `art/approved/<category>/<asset_name>/<version>/...` | Human-selected candidate |
| Production | `art/production/<category>/<asset_name>/<version>/...` | Ready for a separate Godot adoption task |
| Archive | `art/archive/<category>/<asset_name>/<version>/...` | Retired approved material kept for recovery |

Versions are zero-padded `v001`, `v002`, and so on. A promotion must never overwrite an existing version by default.

## Asset filenames

Use the asset name, state, and optional direction or frame marker:

- `button_neutral_normal.png`
- `button_neutral_hover.png`
- `hero_warrior_down_f02.png`
- `campfire_f03.png`
- `terrain_mud_edge_north.png`

Candidate suffixes are appended before the extension:

`<asset_filename>__candidate-01.png`

The maximum candidate number is `02`.

## UI state names

Use `normal`, `hover`, `pressed`, `disabled`, `focused`, `on`, and `off` only where the control uses that state. Do not embed state words inside the pixels.

## Metadata

Sidecar JSON may use the same basename with `.json`. It records recipe ID, dimensions, hashes, references, and approval evidence. It must not contain provider secrets or prompt text that exposes a secret.
