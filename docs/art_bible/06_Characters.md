# Characters and Creatures

Characters are practical mercenaries and unsettling moor inhabitants. They read from silhouette, posture and equipment before palette accents.

## Proportion direction

Use compact but grounded anatomy: slightly taller and less round/chibi than the Tiny Swords baseline, with readable shoulders, hands, feet and equipment. Heads must not dominate the body. Clothing layers reflect weather and occupation.

Suggested visible envelopes at native scale:

- ordinary actor: roughly 44–64px wide and 64–88px tall;
- elite: roughly 64–96px wide and 80–112px tall;
- boss: recipe-specific, deliberately larger.

Frame canvases may be larger to prevent cropping. Each recipe records the exact frame size and feet anchor. Runtime root scale remains 1.0.

## Hero silhouettes

- Warrior: shield/guard weight, broad stance, practical armor.
- Hunter: bow/quiver or sling kit, layered moor cloak, mobile stance.
- Mage: staff, satchel, charms and controlled verdigris magic—not a copied monk silhouette.
- Rogue: low center of gravity, compact blades, hood/scarf used as practical weather gear.

Class recognition must survive grayscale and silhouette-only review.

## Enemy families

Differentiate by mass and behavior: wolves are long/low; raiders lean forward; archers preserve a readable bow arm; shielded reavers are front-heavy; blighted corpses are bound/stiff; supernatural elites use altered posture and folk-horror construction, not glow alone.

## Direction and anchor

- Four directions share identical canvas dimensions.
- Feet occupy the same baseline in every frame.
- Side views keep body volume and apparent height.
- Weapons, spear tips, capes and effects never crop.
- Sprite offsets, collision and sort anchor are authored once and remain stable at runtime.

## Originality rules

Do not trace, recolor or proportion-match a comparator. Change body ratio, costume construction, equipment shapes, pose rhythm and palette relationships. A silhouette overlay that closely matches the baseline fails even if internal pixels differ.

## Production sheet

Every character family includes a neutral turnaround, anchor diagram, palette, silhouette strip, runtime frame map, animation list, equipment-layer rules and a 1× test against light/dark terrain.
