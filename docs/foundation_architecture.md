# Foundation architecture

The rebuild keeps the town and Blackthorn Moor in one continuous world. The safe boundary is a physical modular palisade; crossing its southern gate starts an expedition and walking back through the same opening extracts.

Permanent data is schema v2: four hero records, individual class trees and equipment, company unlocks, town tiers, biome keys, frontier restoration and idle assignments. Active-run data stores the seed, selected hero, Dread state, build, health, unsecured loot and discovered landmarks. The procedural region is reconstructed from the seed.

Core ownership is split between:

- `SaveService`: schema validation, browser-backed persistence and Base64 backup.
- `RosterService`: active hero, hero XP and offline assignments.
- `RegionGenerator`: deterministic tiles, chunks, landmarks and physical barriers.
- `ExpeditionService`: unbounded Dread, boss cycles and scaling.
- `StructureDefinition`: art tiers, ground footprint, interaction/touch contour and sort anchor.

The current playable controller composes these services while further combat-node extraction continues behind stable service contracts.
