@tool
extends ProgressBar

## Keeps the gameplay-facing HealthBar Range while exposing the red fill as an
## independently editable child control. The HUD still writes only to this
## root's value, and the child mirrors that value for rendering.

@onready var fill_visual := AshenSceneBindings.optional(self, &"FillVisual") as Range


func _ready() -> void:
	if not value_changed.is_connected(_sync_fill_visual):
		value_changed.connect(_sync_fill_visual)
	_sync_fill_visual(value)


func _sync_fill_visual(next_value: float) -> void:
	if is_instance_valid(fill_visual):
		# Keep the authored child fill on the same range as the gameplay-facing
		# ProgressBar.  This prevents high-health heroes from appearing full even
		# when the parent value is below its maximum.
		fill_visual.max_value = max_value
		fill_visual.value = next_value
