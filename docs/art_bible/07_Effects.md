# Ashen Company Art Bible — Effects

Effects support gameplay readability. They should clarify an attack, hit, fire, status, or supernatural presence without turning the small portrait viewport into a bright, noisy screen.

## Effect families

- Mundane impacts use earth, iron, parchment, and a small amber spark.
- Fire uses warm amber and a compact shadowed core; the campfire is a source of warmth, not a floodlight.
- Supernatural effects use pale blue-green sparingly and may lightly tint nearby pixels.
- Dread, poison, and curse effects need distinct motion or shape in addition to their color.
- UI feedback effects are separate from world effects and never contain baked text.

## Layering

Prefer reusable layers: source flash, traveling projectile, contact burst, lingering ground mark, and dissipating particles. Keep the character base sprite reusable and let the effect own the attack silhouette when possible.

## Pixel constraints

- Hard pixel clusters only; no blurred glows or soft particle sprites.
- Effects must state their frame size, origin anchor, draw layer, and whether they loop.
- Do not let a one-pixel accent become a large screen wash at runtime.
- Keep transparent padding intentional so the effect can be centered without cropping.

## Review questions

Can the effect be identified at 1x? Does it leave the actor and terrain readable? Is the light direction and color family consistent with the art bible? If not, return it to staging.
