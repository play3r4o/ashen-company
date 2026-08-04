# ImageGen v3 modular Refuge kit

These built-in ImageGen sources replace the single composited Refuge backdrop.
Every runtime object is exported separately by `tools/process_imagegen_v3.py`.

Style references: the approved `imagegen_v2/refuge_master.png` and the supplied
reference screenshot. Shared direction: crisp high-detail medieval pixel art,
top-down three-quarter view, dark forest palette, warm upper-left lantern light,
hard pixel clusters, consistent scale, and original pixels only.

- `hall_chroma.png`: isolated tier-zero Veterans' Hall.
- `palisade_gate_chroma.png`: repeatable single pole and independent gate.
- `props_chroma.png`: six independent perimeter prop clusters.
- `campfire_chroma.png`: six campfire-and-benches animation frames.
- `forest_chroma.png`: three trees, shrub, stump, and rock/root cluster.
- `plot_chroma.png`: independent empty construction footprint.
- `cobble.png`, `forest_floor.png`, `road.png`: seamless terrain sources.

Chroma sources use a flat magenta key. The ImageGen skill's key-removal helper
creates the alpha intermediates in `tmp/imagegen_v3`; those intermediates are
not runtime assets.
