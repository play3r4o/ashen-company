class_name AshenProjectileState
extends RefCounted

var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var damage: float = 1.0
var radius: float = 4.0
var life: float = 1.0
var pierce: int = 1
var faction: int = 0
var color: Color = Color.WHITE
var kind: String = "line"
var splash_radius: float = 0.0
var homing: bool = false
var target_uid: int = -1
var status: String = ""
var hit_ids: Dictionary = {}
var source_tags: Array[String] = []
var returning: bool = false
var return_delay: float = 0.0
var orbiting: bool = false
var orbit_angle: float = 0.0
var orbit_radius: float = 0.0
var orbit_speed: float = 0.0
var ricochets: int = 0
