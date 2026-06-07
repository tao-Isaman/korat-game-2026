extends CanvasLayer

# ---------------------------------------------------------------------------
# Realistic smartphone UI overlay.
# Shows a phone-shaped panel with a status bar, dynamic island, contacts-style
# relationship list, a history feed and a bottom tab bar. Everything is built
# in code; all small icons are custom-drawn so it reads like a real phone.
# ---------------------------------------------------------------------------

# --- Palette (dark "app" look) ---
const COL_BODY := Color("0a0a0c")
const COL_BODY_BORDER := Color("2c2c34")
const COL_SCREEN := Color("0e0e13")
const COL_CARD := Color("1b1b22")
const COL_TEXT := Color("f6f6f8")
const COL_SUBTEXT := Color("9a9aa2")
const COL_ACCENT := Color("ff3b78")
const COL_SEP := Color("2a2a31")
const COL_TRACK := Color("303039")

const CHAR_COLORS := {
	"paeng": Color("d11e6b"),    # แป้ง — dark pink
	"baitoey": Color("ff8a33"),  # ใบเตย — orange
	"beam": Color("ffb3c7"),     # บีม — pastel pink
	"ploy": Color("8b5cf6"),     # พลอย — violet
}

# --- Dimensions ---
const BODY_SIZE := Vector2(460, 940)
const BEZEL := 13.0
const PAD := 26.0
const STATUS_H := 58.0
const TABBAR_H := 80.0
const BODY_RADIUS := 56
const SCREEN_RADIUS := 44

var phone_open: bool = false
var current_tab: String = "relationship"

var phone_btn: Button
var overlay: ColorRect
var phone_root: Control
var content_container: VBoxContainer
var header_title: Label
var header_subtitle: Label
var time_label: Label
var tabs: Array = []

var font_regular: Font
var font_medium: Font
var font_bold: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font_regular = load("res://assets/fonts/Kanit-Regular.ttf")
	font_medium = load("res://assets/fonts/Kanit-Medium.ttf")
	font_bold = load("res://assets/fonts/Kanit-Bold.ttf")
	_build_ui()
	_close_immediate()
	hide_phone_button()


# --- Public API (called by ScenePlayer) ---
func show_phone_button() -> void:
	phone_btn.visible = true


func hide_phone_button() -> void:
	phone_btn.visible = false
	if phone_open:
		_close_immediate()


# --- UI construction ---
func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size

	# Floating launcher button (top-right), circular with a drawn phone icon.
	phone_btn = Button.new()
	phone_btn.focus_mode = Control.FOCUS_NONE
	phone_btn.custom_minimum_size = Vector2(66, 66)
	phone_btn.position = Vector2(vp.x - 66 - 28, 28)
	var fab := StyleBoxFlat.new()
	fab.bg_color = COL_ACCENT
	fab.set_corner_radius_all(33)
	fab.shadow_color = Color(0, 0, 0, 0.45)
	fab.shadow_size = 12
	fab.shadow_offset = Vector2(0, 4)
	var fab_hover := fab.duplicate()
	fab_hover.bg_color = COL_ACCENT.lightened(0.12)
	phone_btn.add_theme_stylebox_override("normal", fab)
	phone_btn.add_theme_stylebox_override("hover", fab_hover)
	phone_btn.add_theme_stylebox_override("pressed", fab_hover)
	phone_btn.add_theme_stylebox_override("focus", fab)
	var glyph := Control.new()
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.draw.connect(_paint_phone_icon.bind(glyph))
	phone_btn.add_child(glyph)
	phone_btn.pressed.connect(_toggle_phone)
	add_child(phone_btn)

	# Dim backdrop.
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_overlay_input)
	add_child(overlay)

	# Phone root (animated container).
	phone_root = Control.new()
	phone_root.size = BODY_SIZE
	phone_root.pivot_offset = BODY_SIZE * 0.5
	add_child(phone_root)

	# Phone body + theme so Kanit (Thai) renders everywhere inside.
	var theme := Theme.new()
	theme.default_font = font_regular
	theme.default_font_size = 18
	phone_root.theme = theme

	var body := PanelContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	var body_sb := StyleBoxFlat.new()
	body_sb.bg_color = COL_BODY
	body_sb.set_corner_radius_all(BODY_RADIUS)
	body_sb.set_border_width_all(2)
	body_sb.border_color = COL_BODY_BORDER
	body_sb.shadow_color = Color(0, 0, 0, 0.5)
	body_sb.shadow_size = 28
	body_sb.shadow_offset = Vector2(0, 10)
	body.add_theme_stylebox_override("panel", body_sb)
	phone_root.add_child(body)

	var bezel := MarginContainer.new()
	bezel.add_theme_constant_override("margin_left", int(BEZEL))
	bezel.add_theme_constant_override("margin_right", int(BEZEL))
	bezel.add_theme_constant_override("margin_top", int(BEZEL))
	bezel.add_theme_constant_override("margin_bottom", int(BEZEL))
	body.add_child(bezel)

	# Screen (rounded, clips content).
	var screen := Panel.new()
	var screen_sb := StyleBoxFlat.new()
	screen_sb.bg_color = COL_SCREEN
	screen_sb.set_corner_radius_all(SCREEN_RADIUS)
	screen.add_theme_stylebox_override("panel", screen_sb)
	screen.clip_contents = true
	bezel.add_child(screen)

	_build_status_bar(screen)
	_build_content(screen)
	_build_tab_bar(screen)
	_build_overlays(screen)


func _build_status_bar(screen: Panel) -> void:
	var bar := HBoxContainer.new()
	bar.anchor_right = 1.0
	bar.offset_left = PAD
	bar.offset_right = -PAD
	bar.offset_top = 16
	bar.offset_bottom = 42
	screen.add_child(bar)

	time_label = Label.new()
	time_label.text = "9:41"
	time_label.add_theme_font_override("font", font_bold)
	time_label.add_theme_font_size_override("font_size", 18)
	time_label.add_theme_color_override("font_color", COL_TEXT)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(time_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	var icons := HBoxContainer.new()
	icons.add_theme_constant_override("separation", 7)
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(icons)
	icons.add_child(_status_icon(Vector2(18, 14), _paint_signal))
	icons.add_child(_status_icon(Vector2(20, 15), _paint_wifi))
	icons.add_child(_status_icon(Vector2(27, 14), _paint_battery))


func _build_content(screen: Panel) -> void:
	var content := VBoxContainer.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.offset_left = PAD
	content.offset_right = -PAD
	content.offset_top = STATUS_H + 8
	content.offset_bottom = -TABBAR_H
	content.add_theme_constant_override("separation", 14)
	screen.add_child(content)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	content.add_child(header)

	header_title = Label.new()
	header_title.add_theme_font_override("font", font_bold)
	header_title.add_theme_font_size_override("font_size", 30)
	header_title.add_theme_color_override("font_color", COL_TEXT)
	header.add_child(header_title)

	header_subtitle = Label.new()
	header_subtitle.add_theme_font_override("font", font_regular)
	header_subtitle.add_theme_font_size_override("font_size", 15)
	header_subtitle.add_theme_color_override("font_color", COL_SUBTEXT)
	header.add_child(header_subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 12)
	scroll.add_child(content_container)


func _build_tab_bar(screen: Panel) -> void:
	var bar := Control.new()
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.anchor_right = 1.0
	bar.offset_top = -TABBAR_H
	screen.add_child(bar)

	# Hairline divider on top of the tab bar.
	var divider := ColorRect.new()
	divider.color = COL_SEP
	divider.anchor_right = 1.0
	divider.offset_bottom = 1.0
	bar.add_child(divider)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_bottom = -14  # leave room for the home indicator
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(row)

	row.add_child(_make_tab("relationship", "เพื่อน", _paint_people))
	row.add_child(_make_tab("history", "ประวัติ", _paint_clock))


func _build_overlays(screen: Panel) -> void:
	# Dynamic island (centered black pill on top of the status bar).
	var island := Panel.new()
	var island_sb := StyleBoxFlat.new()
	island_sb.bg_color = Color.BLACK
	island_sb.set_corner_radius_all(17)
	island.add_theme_stylebox_override("panel", island_sb)
	island.anchor_left = 0.5
	island.anchor_right = 0.5
	island.offset_left = -59
	island.offset_right = 59
	island.offset_top = 13
	island.offset_bottom = 46
	island.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(island)

	# Home indicator bar at the bottom.
	var home := Panel.new()
	var home_sb := StyleBoxFlat.new()
	home_sb.bg_color = Color(1, 1, 1, 0.32)
	home_sb.set_corner_radius_all(3)
	home.add_theme_stylebox_override("panel", home_sb)
	home.anchor_left = 0.5
	home.anchor_right = 0.5
	home.anchor_top = 1.0
	home.anchor_bottom = 1.0
	home.offset_left = -67
	home.offset_right = 67
	home.offset_top = -14
	home.offset_bottom = -9
	home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(home)


func _make_tab(id: String, label_text: String, paint: Callable) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.pressed.connect(_show_tab.bind(id))

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 4)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)

	var icon := Control.new()
	icon.custom_minimum_size = Vector2(26, 26)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(paint.bind(icon))
	content.add_child(icon)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_medium)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(lbl)

	tabs.append({"id": id, "content": content})
	return btn


# --- Open / close ---
func _toggle_phone() -> void:
	if phone_open:
		_hide_phone()
	else:
		_show_phone()


func _show_phone() -> void:
	phone_open = true

	var vp := get_viewport().get_visible_rect().size
	phone_root.size = BODY_SIZE
	phone_root.position = (vp - BODY_SIZE) * 0.5
	phone_root.pivot_offset = BODY_SIZE * 0.5

	var t := Time.get_time_dict_from_system()
	time_label.text = "%d:%02d" % [t.hour, t.minute]

	overlay.visible = true
	phone_root.visible = true
	get_tree().paused = true
	_show_tab(current_tab)

	overlay.modulate.a = 0.0
	phone_root.modulate.a = 0.0
	phone_root.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.18)
	tween.tween_property(phone_root, "modulate:a", 1.0, 0.18)
	tween.tween_property(phone_root, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_phone() -> void:
	if not phone_open:
		return
	phone_open = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.15)
	tween.tween_property(phone_root, "modulate:a", 0.0, 0.15)
	tween.tween_property(phone_root, "scale", Vector2(0.9, 0.9), 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_finish_hide)


func _finish_hide() -> void:
	overlay.visible = false
	phone_root.visible = false
	if is_inside_tree() and get_tree():
		get_tree().paused = false


func _close_immediate() -> void:
	phone_open = false
	overlay.visible = false
	phone_root.visible = false
	overlay.modulate.a = 1.0
	phone_root.modulate.a = 1.0
	phone_root.scale = Vector2.ONE
	if is_inside_tree() and get_tree():
		get_tree().paused = false


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_phone()


# --- Tabs / content ---
func _show_tab(tab: String) -> void:
	current_tab = tab

	for t in tabs:
		var active: bool = t["id"] == tab
		t["content"].modulate = COL_ACCENT if active else COL_SUBTEXT

	if tab == "relationship":
		header_title.text = "ความสัมพันธ์"
		header_subtitle.text = "คนรอบตัวของกิต"
	else:
		header_title.text = "ประวัติ"
		header_subtitle.text = "สิ่งที่กิตเลือกผ่านมา"

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
		var char_col: Color = CHAR_COLORS.get(character_id, COL_ACCENT)

		var card := _card(20)
		content_container.add_child(card)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 18)
		margin.add_theme_constant_override("margin_right", 18)
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_bottom", 16)
		card.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 12)
		margin.add_child(vbox)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		vbox.add_child(row)

		row.add_child(_make_avatar(58, char_col, name_th.substr(0, 1)))

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)

		var name_label := Label.new()
		name_label.text = name_th
		name_label.add_theme_font_override("font", font_bold)
		name_label.add_theme_font_size_override("font_size", 23)
		name_label.add_theme_color_override("font_color", COL_TEXT)
		info.add_child(name_label)

		var bio_label := Label.new()
		bio_label.text = bio
		bio_label.add_theme_font_override("font", font_regular)
		bio_label.add_theme_font_size_override("font_size", 14)
		bio_label.add_theme_color_override("font_color", COL_SUBTEXT)
		bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(bio_label)

		var score := HBoxContainer.new()
		score.add_theme_constant_override("separation", 5)
		score.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(score)

		var heart := Control.new()
		heart.custom_minimum_size = Vector2(22, 20)
		heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart.draw.connect(_paint_heart.bind(heart, char_col))
		score.add_child(heart)

		var points_label := Label.new()
		points_label.text = "%d" % points
		points_label.add_theme_font_override("font", font_bold)
		points_label.add_theme_font_size_override("font_size", 24)
		points_label.add_theme_color_override("font_color", char_col)
		points_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		score.add_child(points_label)

		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value = points
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		var track := StyleBoxFlat.new()
		track.bg_color = COL_TRACK
		track.set_corner_radius_all(4)
		var fill := StyleBoxFlat.new()
		fill.bg_color = char_col
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		vbox.add_child(bar)


func _build_history_tab() -> void:
	var history: Array = GameManager.choice_history
	if history.is_empty():
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 40)
		content_container.add_child(spacer)

		var empty_label := Label.new()
		empty_label.text = "ยังไม่มีประวัติการเลือก"
		empty_label.add_theme_font_override("font", font_regular)
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", COL_SUBTEXT)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_container.add_child(empty_label)
		return

	for entry: Dictionary in history:
		var card := _card(16)
		content_container.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		card.add_child(row)

		# Accent stripe down the left edge.
		var stripe := Panel.new()
		stripe.custom_minimum_size = Vector2(4, 0)
		stripe.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var stripe_sb := StyleBoxFlat.new()
		stripe_sb.bg_color = COL_ACCENT
		stripe_sb.set_corner_radius_all(2)
		stripe.add_theme_stylebox_override("panel", stripe_sb)
		row.add_child(stripe)

		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		row.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		margin.add_child(vbox)

		var scene_label := Label.new()
		scene_label.text = entry.get("scene_title", "")
		scene_label.add_theme_font_override("font", font_regular)
		scene_label.add_theme_font_size_override("font_size", 13)
		scene_label.add_theme_color_override("font_color", COL_SUBTEXT)
		scene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(scene_label)

		var choice_label := Label.new()
		choice_label.text = entry.get("choice_label", "")
		choice_label.add_theme_font_override("font", font_medium)
		choice_label.add_theme_font_size_override("font_size", 18)
		choice_label.add_theme_color_override("font_color", COL_TEXT)
		choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(choice_label)


# --- Builders / helpers ---
func _card(radius: int) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_CARD
	sb.set_corner_radius_all(radius)
	card.add_theme_stylebox_override("panel", sb)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card


func _make_avatar(d: float, color: Color, initial: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(d, d)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		c.draw_circle(c.size * 0.5, d * 0.5, color)
	)
	var lbl := Label.new()
	lbl.text = initial
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font_bold)
	lbl.add_theme_font_size_override("font_size", int(d * 0.42))
	# Dark text on light (pastel) avatars, white on dark ones, for readability.
	var initial_col: Color = Color("221018") if color.get_luminance() > 0.6 else Color.WHITE
	lbl.add_theme_color_override("font_color", initial_col)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)
	return c


func _status_icon(size: Vector2, paint: Callable) -> Control:
	var c := Control.new()
	c.custom_minimum_size = size
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(paint.bind(c))
	return c


# --- Custom icon painters ---
func _paint_phone_icon(c: Control) -> void:
	var s := c.size
	var w := s.x * 0.42
	var h := s.y * 0.56
	var x := (s.x - w) * 0.5
	var y := (s.y - h) * 0.5
	var ci := c.get_canvas_item()
	var body := StyleBoxFlat.new()
	body.bg_color = Color.WHITE
	body.set_corner_radius_all(int(min(w, h) * 0.26))
	body.draw(ci, Rect2(x, y, w, h))
	var ins := 2.5
	var scr := StyleBoxFlat.new()
	scr.bg_color = COL_ACCENT
	scr.set_corner_radius_all(int(min(w, h) * 0.16))
	scr.draw(ci, Rect2(x + ins, y + ins * 2.2, w - ins * 2.0, h - ins * 4.4))
	c.draw_circle(Vector2(s.x * 0.5, y + h - ins * 1.4), 1.6, COL_ACCENT)


func _paint_signal(c: Control) -> void:
	var s := c.size
	var bw := 3.0
	var gap := 2.0
	for i in 4:
		var hh: float = s.y * (0.4 + 0.2 * i)
		var x: float = i * (bw + gap)
		c.draw_rect(Rect2(x, s.y - hh, bw, hh), Color.WHITE)


func _paint_wifi(c: Control) -> void:
	var s := c.size
	var ctr := Vector2(s.x * 0.5, s.y * 0.92)
	for i in 3:
		var r: float = s.x * 0.5 - i * (s.x * 0.18)
		c.draw_arc(ctr, r, deg_to_rad(-145), deg_to_rad(-35), 24, Color.WHITE, 2.0)
	c.draw_circle(ctr, 1.6, Color.WHITE)


func _paint_battery(c: Control) -> void:
	var s := c.size
	var bw := s.x - 3.0
	var bh := s.y
	c.draw_rect(Rect2(0, 0, bw, bh), Color(1, 1, 1, 0.5), false, 1.5)
	c.draw_rect(Rect2(bw + 1.0, bh * 0.3, 2.0, bh * 0.4), Color.WHITE)
	var pad := 2.0
	c.draw_rect(Rect2(pad, pad, (bw - 2.0 * pad) * 0.82, bh - 2.0 * pad), Color.WHITE)


func _paint_people(c: Control) -> void:
	var s := c.size
	c.draw_circle(Vector2(s.x * 0.5, s.y * 0.32), s.x * 0.17, Color.WHITE)
	c.draw_arc(Vector2(s.x * 0.5, s.y * 1.02), s.x * 0.3, deg_to_rad(202), deg_to_rad(338), 24, Color.WHITE, max(2.0, s.x * 0.12))


func _paint_clock(c: Control) -> void:
	var s := c.size
	var ctr := s * 0.5
	var r: float = min(s.x, s.y) * 0.42
	c.draw_arc(ctr, r, 0, TAU, 32, Color.WHITE, 2.0)
	c.draw_line(ctr, ctr + Vector2(0, -r * 0.55), Color.WHITE, 2.0)
	c.draw_line(ctr, ctr + Vector2(r * 0.4, r * 0.12), Color.WHITE, 2.0)


func _paint_heart(c: Control, color: Color) -> void:
	var w := c.size.x
	var h := c.size.y
	var r := w * 0.26
	var cy := h * 0.34
	c.draw_circle(Vector2(w * 0.32, cy), r, color)
	c.draw_circle(Vector2(w * 0.68, cy), r, color)
	var pts := PackedVector2Array([
		Vector2(w * 0.085, cy + r * 0.15),
		Vector2(w * 0.915, cy + r * 0.15),
		Vector2(w * 0.5, h * 0.93),
	])
	c.draw_colored_polygon(pts, color)
