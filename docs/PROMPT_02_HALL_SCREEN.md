# Luna Max Prompt 02 — Veterans' Hall Screen

Assume the shared Ashen UI foundation and Settings screen already exist.

Work only on the Veterans' Hall presentation.

## Goal

Replace the current text-heavy Hall popup with a clear settlement expansion
screen matching `docs/references/hall_reference.png`, while keeping all Hall
logic, resource costs, capacity rules, and saves unchanged.

## Create

- `res://ui/screens/hall/hall_screen.tscn`
- `res://ui/screens/hall/hall_screen.gd`
- optional reusable:
  - `res://ui/components/building_slot_row.tscn`
  - `res://ui/components/resource_cost_row.tscn`
  - `res://ui/components/camp_expansion_preview.tscn`

## Screen hierarchy

- Ashen modal
- Ashen header: `VETERANS' HALL`
- current Hall tier
- current building capacity
- Current vs Next Expansion preview row
- Current Settlement section
- dynamic building-slot list
- status message if all slots are occupied
- Next Expansion section
- description of next expansion
- reward line such as `+1 BUILDING SLOT`
- dynamic resource cost row
- primary action: `EXPAND THE REFUGE`
- secondary row:
  - `MANAGE COMPANY`
  - `OFFLINE WORK`
- neutral action: `RETURN TO TOWN`

## Data rules

1. Find the existing Hall state and upgrade methods.
2. The UI must receive a view-data dictionary or equivalent.
3. The screen must not calculate authoritative upgrade prices.
4. The screen must not change capacity directly.
5. The Expand button emits a request.
6. Existing game code/service validates cost and performs the upgrade.
7. After success, refresh the screen from authoritative state.
8. Disable the button when requirements are not met.
9. Show missing resource values clearly.
10. Perform exactly one expansion per click.

## Preview rules

Do not build a second world simulator.

First implementation may use:

- current Hall/camp sprite preview
- simple dashed slot markers
- next preview with one additional slot marker

Use existing camp/building sprites where possible.

Do not render the entire active world inside the menu unless the project
already has a safe lightweight preview method.

## Layout

- Keep the top HUD visible.
- Use a ScrollContainer if content exceeds the safe area.
- Dynamic building rows must be created from current state.
- Use the supplied card frame.
- Use green/olive only for positive status such as `OCCUPIED` or affordable.
- Use red/danger only when an action is blocked or destructive.
- Keep one clear primary action.

## Preserve

- Hall tier
- resource names
- resource values
- exact costs
- building capacity
- occupied building list
- expansion effects
- offline-work behavior
- company-management behavior
- saves

## Finish criteria

- Existing Hall functionality remains identical.
- Current and next states are visually understandable.
- No hard-coded test resource values unless those are the actual current data.
- Existing tests pass.
- Stop after Hall. Do not begin Arsenal.
