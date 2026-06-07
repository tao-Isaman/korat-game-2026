extends CanvasLayer

signal choice_selected(next_scene_id: String)

@onready var panel: ColorRect = $Panel
@onready var button_container: HBoxContainer = $Panel/HBoxContainer

var _choice_theme: Theme


func _ready() -> void:
	panel.visible = false
	_choice_theme = load("res://assets/theme/choice_theme.tres")


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
		btn.custom_minimum_size = Vector2(0, 58)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 36)

		# Apply pill theme
		if _choice_theme:
			btn.theme = _choice_theme

		# Bounce animation on mouse enter
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))

		btn.pressed.connect(_on_button_pressed.bind(choice))
		button_container.add_child(btn)
		
		# Set pivot to center dynamically when layout updates the size
		btn.pivot_offset = btn.size / 2.0
		btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)

	panel.visible = true


func hide_choices() -> void:
	_clear_buttons()
	panel.visible = false


func _clear_buttons() -> void:
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()


func _on_button_hover(btn: Button) -> void:
	# Bounce (jiggle) scale animation on hover
	var tween := btn.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.25)


func _on_button_unhover(btn: Button) -> void:
	var tween := btn.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SPRING)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)


func _on_button_pressed(choice: Dictionary) -> void:
	GameManager.play_click_sound()
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
