class_name AshenPickupState
extends RefCounted

var position: Vector2 = Vector2.ZERO
var value: int = 1
var velocity: Vector2 = Vector2.ZERO
# The default experience kind keeps the existing pickup contract intact while
# allowing rare drops to use their own authored visual and collection rule.
var kind: String = "experience"
