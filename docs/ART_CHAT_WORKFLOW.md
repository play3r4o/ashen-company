# Ashen Company dedicated art-chat workflow

This workflow extends the existing Ashen Studio pipeline with a separate local
art chat. It does not replace the existing PixelLab recipes, touch the Godot
runtime, or create a second runtime manifest. Current generated assets are
eligible when explicitly approved in `REFERENCE_MANIFEST.yaml`; generated and
rejected are not synonyms.

## 1. Open the dedicated chat

Open a new local Work/Codex chat on this repository and paste the exact contents
of `art/art_chat/ART_CHAT_STARTER_PROMPT.md` once. The chat should remain
focused on art requests and should not be used for gameplay or scene edits.

The repository is the shared memory. The chat rereads the style lock, manifest,
prompt library, category guide, and request before each generation.

The chat also starts in operator mode. It reads
`art/art_chat/CURRENT_JOB.yaml` and `art/art_chat/ASSET_LINEAGE.yaml` at the
start of every task and writes the job state after every state change. The
user-facing commands are intentionally short:

```text
Create [asset] [optional tier]
Baseline retry: [defects]
Style pass: [requested visual changes]
Approve current candidate
Reject current candidate
Create next tier
Continue the current job
Prepare approved asset for Godot
Show current job
Cancel current job
```

The full command contract and state behavior are documented in
`art/art_chat/OPERATOR_MODE.md` and `art/art_chat/COMMAND_REFERENCE.md`. The
operator hides prompt-building and validation details unless they are
requested; each response shows the action, candidate path/preview when
present, baseline status, current stage, and two or three valid next commands.

The initial state is idle. A command such as `Create Company Hall Tier 1`
resolves the existing request/specification files and does not require the
user to write YAML manually unless a real design decision is missing.

## 2. Create or resolve a request

Start with a stable YAML request under `art/art_chat/requests/`. Use
`REQUEST_TEMPLATE.md` and `REQUEST_SCHEMA.yaml`. A request records asset ID,
category, purpose, inheritance/anchor, exact final and source dimensions,
orientation, view, transparency mode, category-relevant manifest IDs, prompt
blocks, forbidden traits, candidate count, status, and staging/review/approval
paths. Constructed assets (`buildings` and constructed `props`) also record
`physical_coherence_required: true`, `perspective_coherence_required: true`,
`structural_review_required: true`, `proportion_profile`,
`architectural_function`, `allowed_vertical_emphasis`, and
`ground_plane_required: true`. Normal camp buildings default to
`compact_grounded`; vertical profiles require deliberate function.

Simple messages such as “Create the Blacksmith” should resolve to these fields
from the files. Ask for clarification only if the repository cannot safely
resolve a materially different choice.

The operator records the resolved request path, compiled prompt path, selected
references, current candidate, pending review type, iteration counts, last user
instruction, and next valid commands in `CURRENT_JOB.yaml`.

Validate the request before generation:

```powershell
python tools/art_chat/validate_request.py --request art/art_chat/requests/building_blacksmith_v01.yaml
```

Player requests require the current approved player/hero family and may never
substitute the enemy family. If no approved player anchor exists, report:

> No approved current player-character reference is available.

### Tiered assets are sequential

For any tiered building, prop, equipment set, environment feature, or UI
component, set `progression_asset: true` and record the progression family,
single tier number, immediately preceding `previous_approved_tier`, preserved
core elements, one-major/two-minor change budget, growth limits, roof/floor
limits, and `archetype_change_allowed: false`. Tier 1 uses a null previous tier.
Tier 2 and above cannot compile until the immediately preceding tier has an
actual approved asset and approval record. A request containing a tier range or
multiple independent tier indices is invalid.

Progression continuity is mandatory: the previous approved tier supplies the
primary visual anchor, and each new tier must remain recognizably the same
asset and function. Do not use Tier 1 as the sole anchor for later tiers or
generate Tier 3/Tier 4 from prose alone.

The current Company Hall review disposition is recorded in the tier review
JSON files: Tier 1 direction acceptable pending normal structural review; Tier
2 strongest current direction but requires revision and sequential-anchor
approval; Tier 3 not approved and requires simplification; Tier 4 hard rejected
for uncontrolled escalation and permanently ineligible as an anchor. Do not
generate a replacement Tier 4 until a corrected Tier 3 is approved.

## 3. Compile the prompt bundle

The compiler combines the request, style lock, machine-readable lock, category
guide, selected prompt blocks, and manifest-approved references into a single
provider-neutral Markdown bundle:

```powershell
python tools/art_chat/build_prompt_bundle.py `
  --request art/art_chat/requests/building_blacksmith_v01.yaml
```

The default output is under `art/art_chat/requests/compiled/`. The bundle lists
the exact repository paths that should be attached to the art chat. It is not an
API call and does not select a provider. Every building bundle automatically
injects `PHYSICAL_COHERENCE_BLOCK`, `BUILDING_MASSING_BLOCK`,
`STRUCTURAL_NEGATIVE_BLOCK`, and `STRUCTURAL_PREFLIGHT_BLOCK`, even when the
request author omits them. The compiler resolves the request's proportion
profile and architectural function inside `BUILDING_MASSING_BLOCK`.
Tiered bundles also inject `PROGRESSION_CONTINUITY_BLOCK`,
`PROGRESSION_NEGATIVE_BLOCK`, and `PROGRESSION_PREFLIGHT_BLOCK`; the immediate
previous approved tier is listed as a mandatory attachment. Rejected tiers
cannot be compiled or used as anchors.

## 4. Attach only relevant canonical references

Automatic selection requires `approval_status: approved`,
`approved_as_reference: true`, and a matching `reference_scope`. Current v3
town/forest references are the primary world-art authorities. Current camp
images supply composition, scale, and atmosphere. Provisional terrain supplies
tile/layout context only and may be attached only to terrain-specific requests.

Never attach excluded, rejected, legacy, temporary/work, debug, mockup,
outline-mask, or unrelated category references simply because they are visually
convenient. Do not mix enemy references into player requests or UI references
into world-art requests.

## 5. Generate into staging

If the user explicitly authorizes generation in the dedicated art chat, create
one candidate by default and stage it under:

```text
art/art_chat/generated/<asset_id>/
```

The chat must not write directly to `approved/`, `rejected/`, `assets/`, `ui/`,
or any production folder. The candidate stays at the requested source or final
contract; no silent crop, pad, or resize is allowed during staging.

The default operator command creates exactly one candidate, performs
transparency processing and baseline preflight, writes candidate metadata and a
review sheet, updates `CURRENT_JOB.yaml`, and stops for review. A baseline retry
creates one corrected candidate without increasing the visual-style iteration
count. A style pass is allowed only after baseline review passes and increments
the visual-style count once.

Beside every candidate, write metadata containing the prompt/bundle path,
provider/model, canonical references, final and source dimensions, seed when
available, timestamp, transparency mode, and output metadata. Never record
credentials or bearer tokens.

Prefer native RGBA. If that is unavailable, use a flat exact `#FF00FF` key with
no edge, glow, shadow, bloom, or semi-transparent fringe touching it, then
remove the key deterministically before review.

## 6. Review before approval

Create a review sheet with native and suitable nearest-neighbor enlarged views:

```powershell
python tools/art_chat/make_review_sheet.py `
  --request art/art_chat/requests/building_blacksmith_v01.yaml `
  --asset art/art_chat/generated/building_blacksmith_v01/blacksmith.png
```

Review at 1x first, then use `OUTPUT_REVIEW_CHECKLIST.md`. Check silhouette,
orientation, anchor, scale bucket, materials, light direction, transparency,
actual-scale readability, category scope, provisional warnings, and prohibited
drift. Reusable UI must remain text-free. For buildings and constructed props,
complete the named `STRUCTURAL_SANITY_REVIEW` before the candidate can be
ready_for_approval:

- ground plane, facade planes, supports, roof/wall/foundation, doors/stairs,
  openings, and massing must each be explicitly recorded as consistent or
  plausible;
- no impossible depth merging and no floating or unsupported elements may be
  recorded;
- all nine flags must be `true` in the review JSON beside the review sheet.

This is a human visual gate. Automated validation and image metadata do not
prove structural correctness. Baseline construction corrections happen before
visual-style iterations; do not spend a style iteration correcting physical
impossibility, perspective, grounding, proportions, dimensions, or category
defects.

For tiered assets, complete `PROGRESSION_CONTINUITY_REVIEW` as a separate
manual section. Confirm the previous tier is recognizable, the core footprint,
entrance, primary silhouette, function, and human scale are inherited, the
delta budget is respected, additions are subordinate, roof/height growth is
controlled, no archetype drift occurred, and the result remains one coherent
structure. All required progression flags must be true before
`ready_for_approval` or promotion.

## 7. Approve explicitly

After the human reviewer selects the exact candidate, promote it with the
explicit manual flag:

```powershell
python tools/art_chat/approve_asset.py `
  --request art/art_chat/requests/building_blacksmith_v01.yaml `
  --asset art/art_chat/generated/building_blacksmith_v01/blacksmith.png `
  --approve `
  --reviewer <name>
```

The tool creates a new version under the request's approved destination, writes
an approval record, preserves the source candidate, and refuses to overwrite an
existing version. For buildings and constructed props it also refuses
promotion unless the exact reviewed candidate is recorded in the review JSON
and every `STRUCTURAL_SANITY_REVIEW` flag is explicitly `true`. Without
`--approve`, it must not promote anything. The operator resolves the request
and candidate from `CURRENT_JOB.yaml`; the approval tool records the resulting
hash and metadata in `ASSET_LINEAGE.yaml` and moves the job to `approved`.
Approval never integrates the asset into Godot.

## 8. Reject or clean up

A failed candidate stays visible in staging or is moved manually into the
request's `rejected/` record area with a reason. It must not enter the canonical
reference library. Do not delete old PixelLab, Settings, generated, or legacy
reference work merely because it is excluded from canonical style; preserve it
for history and runtime compatibility. The rejected HQ Settings frame and the
previously excluded generated v4 UI family remain explicitly excluded.

## 9. Later Godot integration

Godot adoption is a separate task. It may copy an explicitly approved asset to
the runtime only after checking the production contract, import behavior,
nearest filtering, mipmaps, and existing gameplay references. This art-chat
workspace never edits runtime files or import metadata and never replaces a
current production reference automatically.

The operator command `Prepare approved asset for Godot` is proposal-only until
the user explicitly confirms. It validates dimensions, alpha, filenames,
import expectations, and destination, then shows the exact proposed runtime
file operations. A separate confirmed task is required for any runtime write.

## Operator state and lineage

`CURRENT_JOB.yaml` records one active candidate/job at a time. Its state is
repository-owned, so `Continue the current job` works even after the chat is
reopened or its history is unavailable. `ASSET_LINEAGE.yaml` records only
explicitly approved family/tier entries: approved candidate path, request,
parent tier, approval timestamp, hash, inherited elements, and progression
status. Rejected or merely generated candidates are never lineage anchors.

## Validation sequence

```powershell
python tools/art_chat/validate_references.py --write-overview
python tools/art_chat/validate_request.py --all
python tools/art_chat/validate_operator_state.py
python tools/art_chat/build_prompt_bundle.py --request art/art_chat/requests/building_company_hall_v01.yaml
python tools/art_chat/build_prompt_bundle.py --request art/art_chat/requests/building_blacksmith_v01.yaml
python tools/art_chat/build_prompt_bundle.py --request art/art_chat/requests/character_ranger_v01.yaml
python tools/art_chat/build_prompt_bundle.py --request art/art_chat/requests/environment_terrain_rework_v01.yaml
```

The reference validator writes the canonical overview, candidate inventory,
native-dimension metadata, terrain warning, and nearest-neighbor inspection
views where appropriate. The complete generated-source audit is recorded in
`art/art_chat/reviews/generated_asset_inventory.json` and
`art/art_chat/reviews/generated_asset_inventory.png`.
