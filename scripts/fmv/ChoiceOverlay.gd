extends CanvasLayer

signal choice_selected(next_scene_id: String)

@onready var panel: ColorRect = $Panel
@onready var button_container: HBoxContainer = $Panel/HBoxContainer


func _ready() -> void:
	panel.visible = false


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
		btn.custom_minimum_size = Vector2(250, 80)
		btn.add_theme_font_size_override("font_size", 32)

		btn.pressed.connect(_on_button_pressed.bind(choice))
		button_container.add_child(btn)

	panel.visible = true


func hide_choices() -> void:
	_clear_buttons()
	panel.visible = false


func _clear_buttons() -> void:
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()


func _on_button_pressed(choice: Dictionary) -> void:
	var changes: Array = GameManager.apply_choice_relationships(choice)
	hide_choices()
	_show_point_notifications(changes)
	choice_selected.emit(choice.get("next", ""))


func _show_point_notifications(changes: Array) -> void:
	if changes.is_empty():
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var y_offset: float = 0.0

	for amount in changes:
		if amount == 0:
			continue

		var label := Label.new()
		if amount > 0:
			label.text = "+%d" % amount
			label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.7, 1))
		else:
			label.text = "%d" % amount
			label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))

		label.add_theme_font_size_override("font_size", 72)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.position = Vector2(viewport_size.x - 250, 40 + y_offset)
		add_child(label)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - 80.0, 2.0)
		tween.tween_property(label, "modulate:a", 0.0, 2.0)
		tween.chain().tween_callback(label.queue_free)

		y_offset += 80.0
