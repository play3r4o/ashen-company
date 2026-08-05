class_name AshenResultsScreen
extends Control

signal march_again_requested
signal return_to_camp_requested

@onready var heading: Label = %ResultHeading
@onready var stats: Label = %ResultStats
@onready var objective: Label = %ObjectiveResult
@onready var doctrine: Label = %DoctrineResult
@onready var loot: Label = %LootResult
@onready var rewards: Label = %RewardResult


func _ready() -> void:
	%MarchAgainButton.pressed.connect(func() -> void: march_again_requested.emit())
	%ReturnToCampButton.pressed.connect(func() -> void: return_to_camp_requested.emit())


func bind_result(values: Dictionary) -> void:
	heading.text = String(values.get("heading", "THE COMPANY RETURNS"))
	stats.text = String(values.get("stats", ""))
	objective.text = String(values.get("objective", ""))
	doctrine.text = String(values.get("doctrine", ""))
	loot.text = String(values.get("loot", ""))
	rewards.text = String(values.get("rewards", ""))
