extends CanvasLayer

var phone_open: bool = false
var current_tab: String = "relationship"

var phone_panel: PanelContainer
var phone_btn: Button
var close_btn: Button
var tab_relationship: Button
var tab_history: Button
var content_container: VBoxContainer
var overlay: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_hide_phone()
	hide_phone_button()


func show_phone_button() -> void:
	phone_btn.visible = true


func hide_phone_button() -> void:
	phone_btn.visible = false
	if phone_open:
		_hide_phone()


func _build_ui() -> void:
	# Phone button (top-right corner)
	phone_btn = Button.new()
	phone_btn.text = "PHONE"
	phone_btn.custom_minimum_size = Vector2(120, 50)
	phone_btn.add_theme_font_size_override("font_size", 22)
	phone_btn.position = Vector2(get_viewport().get_visible_rect().size.x - 140, 15)
	phone_btn.pressed.connect(_toggle_phone)
	add_child(phone_btn)

	# Dark overlay behind phone
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	overlay.gui_input.connect(_on_overlay_input)
	add_child(overlay)

	# Phone panel (centered, looks like a phone screen)
	phone_panel = PanelContainer.new()
	phone_panel.custom_minimum_size = Vector2(500, 700)
	phone_panel.visible = false
	add_child(phone_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	phone_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "PHONE"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(50, 40)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(_hide_phone)
	header.add_child(close_btn)

	# Tab buttons
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 5)
	vbox.add_child(tabs)

	tab_relationship = Button.new()
	tab_relationship.text = "Relationship"
	tab_relationship.custom_minimum_size = Vector2(0, 45)
	tab_relationship.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_relationship.add_theme_font_size_override("font_size", 20)
	tab_relationship.pressed.connect(_show_tab.bind("relationship"))
	tabs.add_child(tab_relationship)

	tab_history = Button.new()
	tab_history.text = "History"
	tab_history.custom_minimum_size = Vector2(0, 45)
	tab_history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_history.add_theme_font_size_override("font_size", 20)
	tab_history.pressed.connect(_show_tab.bind("history"))
	tabs.add_child(tab_history)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Scrollable content area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 8)
	scroll.add_child(content_container)


func _toggle_phone() -> void:
	if phone_open:
		_hide_phone()
	else:
		_show_phone()


func _show_phone() -> void:
	phone_open = true
	overlay.visible = true
	phone_panel.visible = true

	# Center the phone panel
	var vp := get_viewport().get_visible_rect().size
	phone_panel.position = (vp - phone_panel.custom_minimum_size) / 2.0

	get_tree().paused = true
	_show_tab(current_tab)


func _hide_phone() -> void:
	phone_open = false
	overlay.visible = false
	phone_panel.visible = false
	get_tree().paused = false


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_phone()


func _show_tab(tab: String) -> void:
	current_tab = tab

	# Update tab button style
	tab_relationship.disabled = (tab == "relationship")
	tab_history.disabled = (tab == "history")

	# Clear content
	for child in content_container.get_children():
		content_container.remove_child(child)
		child.queue_free()

	match tab:
		"relationship":
			_build_relationship_tab()
		"history":
			_build_history_tab()


func _build_relationship_tab() -> void:
	for character_id in GameManager.CHARACTERS:
		var name_th: String = GameManager.get_character_name(character_id)
		var bio: String = GameManager.CHARACTER_BIOS.get(character_id, "")
		var points: int = GameManager.get_relationship(character_id)

		var card := PanelContainer.new()
		content_container.add_child(card)

		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 12)
		card_margin.add_theme_constant_override("margin_right", 12)
		card_margin.add_theme_constant_override("margin_top", 10)
		card_margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(card_margin)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card_margin.add_child(vbox)

		# Name + points
		var header := HBoxContainer.new()
		vbox.add_child(header)

		var name_label := Label.new()
		name_label.text = name_th
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(name_label)

		var points_label := Label.new()
		points_label.text = "%d" % points
		points_label.add_theme_font_size_override("font_size", 26)
		if points > 0:
			points_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.7, 1))
		header.add_child(points_label)

		# Relationship bar
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value = points
		bar.custom_minimum_size = Vector2(0, 14)
		bar.show_percentage = false
		vbox.add_child(bar)

		# Bio
		var bio_label := Label.new()
		bio_label.text = bio
		bio_label.add_theme_font_size_override("font_size", 16)
		bio_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(bio_label)


func _build_history_tab() -> void:
	var history: Array = GameManager.choice_history
	if history.is_empty():
		var empty_label := Label.new()
		empty_label.text = "ยังไม่มีประวัติการเลือก"
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_container.add_child(empty_label)
		return

	for entry: Dictionary in history:
		var card := PanelContainer.new()
		content_container.add_child(card)

		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 12)
		card_margin.add_theme_constant_override("margin_right", 12)
		card_margin.add_theme_constant_override("margin_top", 8)
		card_margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(card_margin)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card_margin.add_child(vbox)

		var scene_label := Label.new()
		scene_label.text = entry.get("scene_title", "")
		scene_label.add_theme_font_size_override("font_size", 18)
		scene_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		vbox.add_child(scene_label)

		var choice_label := Label.new()
		choice_label.text = entry.get("choice_label", "")
		choice_label.add_theme_font_size_override("font_size", 22)
		vbox.add_child(choice_label)
