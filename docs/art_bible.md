# Ashen Company 32px Art Bible

All world assets use one native-pixel standard. The camera is top-down three-quarter, textures use nearest-neighbour filtering, and artwork must never be blurred to hide resolution differences.

## Grid and scale

- Terrain is authored as 32×32 tiles.
- Ordinary actors fit a 32×48 visual envelope; elites may use 48×64 and bosses 64×80.
- Town structures use grid-aligned ground anchors. Upgrade tiers preserve the exact anchor and collision footprint.
- Foundations and posts define collision. Roofs, cloth, banners, smoke and foliage may overlap actors without collision.
- Pixel clusters remain hard-edged at every scale; no subpixel sprite placement, texture smoothing or painterly overlays.

## Palette and light

- Earth: `#493a2d`, `#65513a`, `#847055`.
- Moss: `#394737`, `#53604a`.
- Iron: `#454b4d`, `#6f7473`, `#a49d8d`.
- Company red: `#6d343a`, `#8c4a4f`.
- Parchment and fire: `#c9b789`, `#d19547`, `#edb85d`.
- Supernatural light only: `#73aaa1`, `#a6d4c9`.
- Light falls from upper left. Ground shadows fall down-right and stay compact.

## Silhouettes and animation

- Heroes must read by equipment first: shielded Warrior, longbow Hunter, pale-fire Mage and low-profile Rogue.
- Enemies use distinct mass and posture; supernatural enemies cannot be identified by color alone.
- Movement uses two-pixel gait, bob and squash phases. Attacks use separate weapon/effect layers so the base sprite remains reusable.
- Danger uses shape, timing and motion as well as color.

## UI

- Body copy uses the readable UI font; ornamental pixel lettering is reserved for short headings.
- Numerical statistics use a smaller amber line separated from description text.
- Locked states use lower luminance and contrast, not the word “locked” alone.
- Panels, icons and buttons use the same iron, timber, parchment and company-red materials as the world.

