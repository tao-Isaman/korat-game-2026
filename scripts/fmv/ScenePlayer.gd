extends Control

const FADE_DURATION := 0.3

var _is_transitioning: bool = false
var _pending_choices: Array = []

@onready var background: ColorRect = $Background
@onready var title_label: Label = $TitleLabel
@onready var video_container: Control = $VideoContainer
@onready var choice_overlay: CanvasLayer = $ChoiceOverlay
@onready var fade_rect: ColorRect = $FadeRect
@onready var auto_advance_timer: Timer = $AutoAdvanceTimer


func _ready() -> void:
	GameManager.scene_player = self
	auto_advance_timer.timeout.connect(_on_auto_advance_timeout)
	choice_overlay.choice_selected.connect(_on_choice_selected)
	fade_rect.color = Color(0, 0, 0, 1)
	GameManager.go_to_scene(GameManager.FIRST_SCENE)


func load_scene(scene_id: String) -> void:
	if _is_transitioning:
		return

	# Return to main menu screen
	if scene_id == "scene_main_menu":
		get_tree().change_scene_to_file("res://scenes/fmv/Main.tscn")
		return

	var data: Dictionary = GameManager.get_scene(scene_id)
	if data.is_empty():
		push_warning("Scene not found: " + scene_id)
		return

	_is_transitioning = true
	auto_advance_timer.stop()
	_pending_choices = []

	# Fade to black
	await _fade_in()

	# Update content while black
	_set_scene_content(data)

	# Fade out to reveal
	await _fade_out()

	_is_transitioning = false

	# Start scene logic
	_start_scene_logic(data)


func _set_scene_content(data: Dictionary) -> void:
	choice_overlay.hide_choices()
	title_label.text = data.get("title", "")

	# Clear previous video immediately
	for child in video_container.get_children():
		video_container.remove_child(child)
		child.queue_free()

	var video_path: String = data.get("video", "")
	if video_path != "":
		title_label.visible = false
		var stream = load(video_path)
		if stream:
			var player := VideoStreamPlayer.new()
			player.stream = stream
			player.loop = true
			video_container.add_child(player)
			# Set full rect explicitly after adding to tree
			player.anchor_left = 0.0
			player.anchor_top = 0.0
			player.anchor_right = 1.0
			player.anchor_bottom = 1.0
			player.offset_left = 0
			player.offset_top = 0
			player.offset_right = 0
			player.offset_bottom = 0
			player.play()
		else:
			push_warning("Failed to load video: " + video_path)
			title_label.visible = true
	else:
		title_label.visible = true


func _start_scene_logic(data: Dictionary) -> void:
	var choices: Array = data.get("choices", [])
	var duration: float = data.get("duration", 0.0)

	if choices.size() > 0 and duration > 0.0:
		# Show choices after duration
		_pending_choices = choices
		auto_advance_timer.wait_time = duration
		auto_advance_timer.start()
	elif choices.size() > 0:
		# Show choices immediately
		choice_overlay.show_choices(choices)
	elif duration > 0.0:
		# Auto-advance after duration
		_pending_choices = []
		auto_advance_timer.wait_time = duration
		auto_advance_timer.start()


func _on_auto_advance_timeout() -> void:
	if _pending_choices.size() > 0:
		choice_overlay.show_choices(_pending_choices)
		_pending_choices = []
	else:
		var data: Dictionary = GameManager.get_scene(GameManager.current_scene_id)
		var next_id: String = data.get("next", "")
		if next_id != "":
			GameManager.go_to_scene(next_id)


func _on_choice_selected(next_scene_id: String) -> void:
	GameManager.go_to_scene(next_scene_id)


func _fade_in() -> void:
	if fade_rect.color.a >= 1.0:
		return
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished


func _fade_out() -> void:
	if fade_rect.color.a <= 0.0:
		return
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, FADE_DURATION)
	await tween.finished
