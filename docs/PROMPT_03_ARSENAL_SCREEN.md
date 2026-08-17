# Luna Max Prompt 03 — Expedition Arsenal Screen

Assume the shared Ashen UI foundation, Settings screen, and Hall screen exist.

Work only on Expedition Arsenal / campfire preparation.

## Goal

Replace the current form-like Arsenal with data-driven weapon cards,
technique slots, and doctrine preparation matching
`docs/references/arsenal_reference.png`.

Do not change combat behavior or level-up probabilities in this task.

## Create

- `res://ui/screens/arsenal/arsenal_screen.tscn`
- `res://ui/screens/arsenal/arsenal_screen.gd`
- reusable:
  - `res://ui/components/weapon_candidate_card.tscn`
  - `res://ui/components/technique_candidate_slot.tscn`
  - `res://ui/components/doctrine_candidate_card.tscn`

## Screen hierarchy

- Ashen modal
- Ashen header: `EXPEDITION ARSENAL`
- subtitle: `Prepare what may appear during level-ups`
- computed or existing Company Style summary
- summary row:
  - starting weapon
  - prepared weapon count / limit
  - prepared technique count / limit
  - prepared doctrine count / limit
- Weapon Candidates section
- two-column weapon card grid
- Technique Candidates section
- technique-slot grid
- Doctrine section
- informational line explaining that only prepared content appears
- primary action: `CROSS THE GATE`
- neutral action: `BACK TO CAMP`

## Weapon card required data

Each card must be configured from existing weapon data and display:

- weapon icon
- display name
- power
- attack interval
- selected/prepared state
- disabled/locked state if relevant

Optional if data already exists:

- one-line behavior description
- tags

Do not invent permanent weapon stats inside the UI.

## Selection rules

1. Find the existing Arsenal preparation state and limits.
2. Reuse the exact limit values.
3. Clicking an unprepared card requests preparation.
4. Clicking a prepared card requests removal only if existing rules allow it.
5. Starting weapon must remain valid.
6. Never allow more prepared entries than the real limit.
7. Update selected borders and check icons after every change.
8. Do not create a second preparation list.
9. The authoritative state remains in existing game/service code.
10. Cross the Gate must call the existing expedition-start path.

## Techniques and doctrines

If the current project has no implemented techniques/doctrines yet:

- Show empty disabled slots.
- Do not fake gameplay content.
- Keep the UI structure ready for later data.
- Hide or disable interactions that have no backend.

If they exist:

- populate dynamically
- obey exact limits
- preserve save behavior

## Company style

Do not keep Warrior/Hunter/Mage/Rogue tabs unless they are real gameplay
choices.

Preferred order:

1. If the game already has a real role/class selection, preserve it.
2. Otherwise derive a read-only style label from prepared content.
3. If no reliable derivation exists, omit the style label rather than adding
   fake mechanics.

## Layout

- Weapon grid: two columns.
- Card minimum height: 92.
- Card gap: 8.
- Weapon icon should be visually dominant.
- Prepared cards use selected frame and check icon.
- Empty technique slots use supplied empty-slot frame and plus icon.
- Keep buttons at least 48 high.
- Use ScrollContainer for smaller safe areas.

## Finish criteria

- Existing preparation behavior is unchanged.
- Existing weapon values are displayed correctly.
- Selection limits cannot be exceeded.
- Cross the Gate still starts the same expedition.
- Only prepared content appears in level-ups according to existing logic.
- Existing tests pass.
- Provide screenshots and stop.
