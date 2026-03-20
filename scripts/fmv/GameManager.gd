extends Node

const SCENES_PATH := "res://data/scenes.json"
const FIRST_SCENE := "scene_01"

var scenes_data: Dictionary = {}
var current_scene_id: String = ""
var scene_player: Node = null


func _ready() -> void:
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

	# Convert array to dictionary keyed by "id"
	if json.data is Array:
		for scene in json.data:
			if scene is Dictionary and scene.has("id"):
				scenes_data[scene["id"]] = scene
	else:
		push_error("scenes.json root must be an Array")


func get_scene(id: String) -> Dictionary:
	return scenes_data.get(id, {})


func go_to_scene(id: String) -> void:
	current_scene_id = id
	if scene_player and scene_player.has_method("load_scene"):
		scene_player.load_scene(id)
	else:
		push_warning("GameManager: scene_player not set")
