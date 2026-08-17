# Ashen Company Art Bible — Palette

The palette is a controlled family, not a color picker. A recipe may use a small subset of these colors, but it should not introduce arbitrary saturated colors without a documented reason.

## UI tokens

These values mirror `assets/ui/ashen/asset_manifest.json` and are the canonical UI starting point.

| Token | Hex | Use |
|---|---|---|
| `ink` | `#0D0B09` | Deep outlines and the darkest readable edge |
| `void` | `#120F0C` | Modal voids and deep background |
| `panel` | `#1E1914` | Primary panel fill |
| `panel2` | `#261F18` | Raised panel fill |
| `panel3` | `#2E241B` | Card and hover separation |
| `wood_dark` | `#241810` | Dark oak and frame recesses |
| `wood` | `#432A18` | Oak midtone |
| `wood_light` | `#603D1F` | Lit wood edge |
| `iron_dark` | `#1C1C1B` | Blackened iron outline |
| `iron` | `#3A3833` | Iron body |
| `iron_light` | `#60594C` | Worn iron highlight |
| `brass_dark` | `#5B3A12` | Recessed brass |
| `brass` | `#AF7322` | Heading and focus accent |
| `gold` | `#DC9D40` | Strong highlight |
| `gold_light` | `#F4C469` | Sparse brightest warm accent |
| `red_dark` | `#4B140F` | Danger recess |
| `red` | `#872519` | Company red and destructive action |
| `red_light` | `#BE4027` | Danger highlight |
| `green_dark` | `#2F3C18` | Positive-state recess |
| `green` | `#697C31` | Positive state and affordable status |
| `cream` | `#E5D7B9` | Primary UI text and parchment |
| `muted` | `#978970` | Secondary text |
| `disabled` | `#47433D` | Disabled control |

## World tokens

- Earth: `#493A2D`, `#65513A`, `#847055`.
- Moss: `#394737`, `#53604A`.
- Iron: `#454B4D`, `#6F7473`, `#A49D8D`.
- Company red: `#6D343A`, `#8C4A4F`.
- Parchment and fire: `#C9B789`, `#D19547`, `#EDB85D`.
- Supernatural light: `#73AAA1`, `#A6D4C9` only when the light is visibly unnatural.

## Usage rules

- Use value contrast before hue contrast so sprites remain readable in grayscale.
- Reserve `red` and `red_light` for company identity, danger, wounds, or a destructive action. Do not turn every selected state red.
- Use `green` only for positive state; it is not a general decoration color.
- Use pale blue-green as a rare signal. If a mundane asset needs it for readability, choose a world neutral instead.
- Keep outlines close to the local material's dark value. Avoid one universal black outline on every object.
- Transparent pixels must remain truly transparent; do not replace them with a chroma color in production output.
