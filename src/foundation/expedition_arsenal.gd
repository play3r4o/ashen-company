class_name ExpeditionArsenal
extends Resource

@export var id: String = "arsenal_company_standard"
@export var display_name: String = "Company Standard"
@export var class_id: String = "warrior"
@export var starting_weapon: String = "sword"
@export var weapon_ids: PackedStringArray = PackedStringArray(["sword"])
@export var technique_ids: PackedStringArray = PackedStringArray()
@export var doctrine_ids: PackedStringArray = PackedStringArray()

func to_dictionary() -> Dictionary:
	return {"id": id, "name": display_name, "class_id": class_id, "starting_weapon": starting_weapon, "weapon_ids": Array(weapon_ids), "technique_ids": Array(technique_ids), "doctrine_ids": Array(doctrine_ids)}

static func from_dictionary(data: Dictionary) -> ExpeditionArsenal:
	var result := ExpeditionArsenal.new()
	result.id = String(data.get("id", result.id))
	result.display_name = String(data.get("name", result.display_name))
	result.class_id = String(data.get("class_id", result.class_id))
	result.starting_weapon = String(data.get("starting_weapon", result.starting_weapon))
	result.weapon_ids = PackedStringArray(data.get("weapon_ids", [result.starting_weapon]))
	result.technique_ids = PackedStringArray(data.get("technique_ids", []))
	result.doctrine_ids = PackedStringArray(data.get("doctrine_ids", []))
	return result
