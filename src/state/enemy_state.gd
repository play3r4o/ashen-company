class_name AshenEnemyState
extends RefCounted

var uid: int = 0
var id: String = ""
var position: Vector2 = Vector2.ZERO
var health: float = 1.0
var max_health: float = 1.0
var speed: float = 1.0
var damage: float = 1.0
var xp: int = 1
var radius: float = 10.0
var color: Color = Color.WHITE
var kind: String = "raider"
var touch_cooldown: float = 0.0
var attack_cooldown: float = 0.0
var stagger: float = 0.0
var special: bool = false
var bleed_timer: float = 0.0
var bleed_damage: float = 0.0
var bleed_ticks: int = 0
var scorch_timer: float = 0.0
var scorch_damage: float = 0.0
var scorch_ticks: int = 0
var poison_timer: float = 0.0
var poison_damage: float = 0.0
var poison_ticks: int = 0
var mark_timer: float = 0.0
var pin_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var dispersing: bool = false
var path_check_timer: float = 0.0
var has_direct_path: bool = true
var last_hit_critical: bool = false
