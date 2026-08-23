# Animation

Animation is restrained, readable and mechanically timed. Tiny Swords is a benchmark for polish and anchor discipline, not a frame source or motion template.

## Default timing ranges

| Motion | Typical frames | Typical FPS |
|---|---:|---:|
| Character idle | 4–6 | 6–8 |
| Walk/run | 6–8 | 10–12 |
| Attack | 6–10 | event-driven or 10–14 |
| Ambient prop | 3–6 | 4–8 |
| Fire/effect | 5–8 | 8–12 |

These are starting ranges. Gameplay events determine attack timing.

## Anchor discipline

- All frames in an animation share canvas dimensions.
- Feet/ground anchor stays fixed unless root movement is intentional and gameplay-owned.
- Apparent body scale remains stable.
- Held equipment preserves grip point and volume.
- Empty alpha padding is deliberate and documented.
- Crop checks cover every direction and frame.

## Motion design

- Idle uses breathing, weight shift or cloth response; no whole-body blinking or scaling.
- Walk cycles visibly move legs and transfer weight.
- Attacks show anticipation, contact and recovery.
- Heavy attacks spend more frames on anticipation/contact; fast attacks shorten recovery without removing readability.
- Cloth, smoke, lanterns and foliage use small independent phase offsets.

## Loop desynchronization

Ambient loops receive deterministic phase offsets so repeated fires, water foam, lanterns or foliage do not pulse together. Randomization changes start phase only; it does not change size, pivot, layer or collision.

## Direction strategy

Four-direction assets need authored directional art unless a recipe explicitly approves mirroring. Mirroring must not reverse heraldry, handed weapons, readable symbols or asymmetric gear. Never silently reuse one direction as all four.

## Animation review

Review at 1× and slow motion. Confirm stable anchor, no crop, no size change, readable contact frame, seamless loop, correct event timing and no accidental source pixels from neighboring atlas cells.
