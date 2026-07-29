class_name IdleAssignment
extends Resource

enum Kind { IDLE, ACTIVE, PATROL, FORAGING, TRAINING }

@export var hero_id: String = ""
@export var kind: Kind = Kind.IDLE
@export var started_at_utc: float = 0.0
@export var last_seen_utc: float = 0.0
@export var pending_silver: int = 0
@export var pending_provisions: int = 0
@export var pending_xp: int = 0
