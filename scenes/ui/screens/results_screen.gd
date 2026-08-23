class_name AshenResultsScreen
extends Control

signal march_again_requested
signal return_to_camp_requested

@onready var heading: Label = AshenSceneBindings.optional(self, &"ResultHeading") as Label
@onready var stats: Label = AshenSceneBindings.optional(self, &"ResultStats") as Label
@onready var objective: Label = AshenSceneBindings.optional(self, &"ObjectiveResult") as Label
@onready var doctrine: Label = AshenSceneBindings.optional(self, &"DoctrineResult") as Label
@onready var loot: Label = AshenSceneBindings.optional(self, &"LootResult") as Label
@onready var rewards: Label = AshenSceneBindings.optional(self, &"RewardResult") as Label


func _ready() -> void:
	var march_again := AshenSceneBindings.required(self, &"MarchAgainButton", "ResultsScreen") as Button
	var return_to_camp := AshenSceneBindings.required(self, &"ReturnToCampButton", "ResultsScreen") as Button
	AshenSceneBindings.connect_pressed(march_again, func() -> void: march_again_requested.emit())
	AshenSceneBindings.connect_pressed(return_to_camp, func() -> void: return_to_camp_requested.emit())


func bind_result(values: Dictionary) -> void:
	if heading != null:
		heading.text = String(values.get("heading", "THE COMPANY RETURNS"))
	if stats != null:
		stats.text = String(values.get("stats", ""))
	if objective != null:
		objective.text = String(values.get("objective", ""))
	if doctrine != null:
		doctrine.text = String(values.get("doctrine", ""))
	if loot != null:
		loot.text = String(values.get("loot", ""))
	if rewards != null:
		rewards.text = String(values.get("rewards", ""))
