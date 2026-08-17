# Ashen Company Art Bible — Materials

Ashen Company is built from familiar working materials. Every asset should communicate its material through a few deliberate pixel clusters, not through noise or a generic fantasy-metal treatment.

## Dark oak and timber

- Use long, irregular grain clusters aligned with the beam direction.
- Keep the darkest value in joints, under overhangs, and around iron hardware.
- Use burgundy cloth or paint as an accent, never as the dominant wood color.
- Palisade stakes, building posts, and frames need distinct silhouettes at 1x.

## Blackened iron

- Iron is a charcoal body with restrained cool-gray wear on exposed edges.
- Braces, rivets, hinges, and spearheads may use a few brighter pixels to establish construction.
- Avoid chrome-like mirror bands and polished silver gradients.

## Leather, cloth, and parchment

- Leather is dark and warm with broad, low-contrast folds.
- Company cloth uses muted burgundy and should remain recognizable when desaturated.
- Parchment is warm and readable, with a darker edge and limited stain clusters.
- Live text is always rendered by Godot over a quiet material surface; it is never painted into the asset.

## Ground and stone

- Packed earth, mud, cobble, moss, and stone should be separable by value and cluster direction.
- Terrain tiles must tile or meet their neighboring categories cleanly. Do not hide seams with blur.
- A structure's ground footprint is part of the asset contract: preserve the bottom anchor and keep roofs and foliage non-colliding.

## Texture density

Use three scales of detail:

1. A large value block for the silhouette and material family.
2. Medium clusters for construction and form.
3. A few small accents for wear, rivets, sparks, or cloth edges.

Do not fill empty space with random pixels. Quiet areas are important for UI readability and for separating actors from the environment.
