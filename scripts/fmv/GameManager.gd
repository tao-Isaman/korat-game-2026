extends Node

const SCENES_PATH := "res://data/scenes.json"
const FIRST_SCENE := "scene_01"

const CHARACTERS := ["paeng", "baitoey", "beam", "ploy"]
const CHARACTER_NAMES := {
	"paeng": "แป้ง",
	"baitoey": "ใบเตย",
	"beam": "บีม",
	"ploy": "พลอย"
}
const CHARACTER_BIOS := {
	"paeng": "แฟนของกิต วิญญาณ ปากร้ายใจดี พูดตรง ไม่กลัวใคร มาเพราะกิตยังปล่อยไม่ได้",
	"baitoey": "เพื่อนสนิทของกิตและแป้ง ห้าวๆ พูดตรง แอบชอบกิตมานาน ดูแลโดยไม่บอกว่าดูแล",
	"beam": "รุ่นน้องนิเทศ ปี 2 สดใส พลังงานสูง ชอบถ่ายรูป จำกิตได้ตั้งแต่รับน้อง",
	"ploy": "ทันตะ ปี 3 เงียบ สังเกตมากกว่าพูด สนใจเรื่องจิตใจและความตาย"
}

var scenes_data: Dictionary = {}
var current_scene_id: String = ""
var scene_player: Node = null

# Relationship points per character (0-100)
var relationships: Dictionary = {}
var choice_history: Array = []

signal relationship_changed(character: String, value: int)


func _ready() -> void:
	_load_scenes()
	reset_relationships()


func _load_scenes() -> void:
	var file := FileAccess.open(SCENES_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open scenes.json: " + str(FileAccess.get_open_error()))
		return

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("Failed to parse scenes.json at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return

	if json.data is Array:
		for scene in json.data:
			if scene is Dictionary and scene.has("id"):
				scenes_data[scene["id"]] = scene
	else:
		push_error("scenes.json root must be an Array")


func reset_relationships() -> void:
	for c in CHARACTERS:
		relationships[c] = 0
	choice_history = []


func get_relationship(character: String) -> int:
	return relationships.get(character, 0)


func get_character_name(character: String) -> String:
	return CHARACTER_NAMES.get(character, character)


func add_relationship(character: String, amount: int) -> void:
	if not relationships.has(character):
		return
	relationships[character] = clampi(relationships[character] + amount, 0, 100)
	relationship_changed.emit(character, relationships[character])


func apply_choice_relationships(choice: Dictionary) -> Array:
	var changes: Array = []
	var rel: Dictionary = choice.get("relationship", {})
	for character in rel:
		var amount: int = int(rel[character])
		add_relationship(character, amount)
		changes.append(amount)

	# Track choice history
	var scene_data: Dictionary = get_scene(current_scene_id)
	choice_history.append({
		"scene_title": scene_data.get("title", current_scene_id),
		"choice_label": choice.get("label", ""),
	})

	return changes


func get_scene(id: String) -> Dictionary:
	return scenes_data.get(id, {})


func go_to_scene(id: String) -> void:
	current_scene_id = id
	if scene_player and scene_player.has_method("load_scene"):
		scene_player.load_scene(id)
	else:
		push_warning("GameManager: scene_player not set")
