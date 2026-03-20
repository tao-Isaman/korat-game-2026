extends CanvasLayer

signal choice_selected(next_scene_id: String)

@onready var panel: ColorRect = $Panel
@onready var button_container: HBoxContainer = $Panel/HBoxContainer


func _ready() -> void:
	visible = false


func show_choices(choices: Array) -> void:
	_clear_buttons()

	for choice in choices:
		var btn := Button.new()
		var icon: String = choice.get("icon", "")
		var label: String = choice.get("label", "")
		if label != "":
			btn.text = "%s %s" % [icon, label]
		else:
			btn.text = icon
		btn.custom_minimum_size = Vector2(140, 50)
		btn.add_theme_font_size_override("font_size", 20)

		var next_id: String = choice.get("next", "")
		btn.pressed.connect(_on_button_pressed.bind(next_id))
		button_container.add_child(btn)

	visible = true


func hide_choices() -> void:
	_clear_buttons()
	visible = false


func _clear_buttons() -> void:
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()


func _on_button_pressed(next_scene_id: String) -> void:
	hide_choices()
	choice_selected.emit(next_scene_id)
