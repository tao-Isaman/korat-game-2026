extends Control

const FADE_DURATION := 0.3
const VIDEO_FADE_EARLY := 0.3

var _is_transitioning: bool = false
var _pending_choices: Array = []
var _video_queue: Array = []
var _video_index: int = 0
var _loop_video_path: String = ""
var _current_player: VideoStreamPlayer = null
var _fade_started_early: bool = false
var _cheat_buffer: String = ""
var _cheat_timer: float = 0.0
var _wait_sound_player: AudioStreamPlayer = null

@onready var background: ColorRect = $Background
@onready var title_label: Label = $TitleLabel
@onready var video_container: Control = $VideoContainer
@onready var choice_overlay: CanvasLayer = $ChoiceOverlay
@onready var fade_rect: ColorRect = $FadeRect
@onready var auto_advance_timer: Timer = $AutoAdvanceTimer
@onready var phone_ui: CanvasLayer = $PhoneUI


func _ready() -> void:
	GameManager.scene_player = self
	auto_advance_timer.timeout.connect(_on_auto_advance_timeout)
	choice_overlay.choice_selected.connect(_on_choice_selected)
	fade_rect.color = Color(0, 0, 0, 1)
	GameManager.go_to_scene(GameManager.FIRST_SCENE)


func load_scene(scene_id: String) -> void:
	if _is_transitioning:
		return

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
	_stop_wait_sound()

	await _fade_in()
	_set_scene_content(data)
	await _fade_out()

	_is_transitioning = false
	_start_scene_logic(data)


func _set_scene_content(data: Dictionary) -> void:
	choice_overlay.hide_choices()
	phone_ui.hide_phone_button()
	title_label.text = data.get("title", "")

	_clear_video()

	# Parse video fields
	_video_queue = data.get("videos", [])
	_loop_video_path = data.get("loop_video", "")
	_video_index = 0

	# Backward compat: old "video" field
	if _video_queue.is_empty() and data.get("video", "") != "":
		_video_queue = [data.get("video")]

	if _video_queue.size() > 0 or _loop_video_path != "":
		title_label.visible = false
	else:
		title_label.visible = true


func _start_scene_logic(data: Dictionary) -> void:
	var choices: Array = data.get("choices", [])
	var duration: float = data.get("duration", 0.0)

	if _video_queue.size() > 0:
		# Play sequential videos, then loop + choices
		_pending_choices = choices
		_play_next_video()
	elif _loop_video_path != "":
		# Only loop video, show choices immediately
		_play_loop_video()
		if choices.size() > 0:
			choice_overlay.show_choices(choices)
			phone_ui.show_phone_button()
	else:
		# No videos — use duration timer
		if choices.size() > 0 and duration > 0.0:
			_pending_choices = choices
			auto_advance_timer.wait_time = duration
			auto_advance_timer.start()
		elif choices.size() > 0:
			choice_overlay.show_choices(choices)
			phone_ui.show_phone_button()
		elif duration > 0.0:
			_pending_choices = []
			auto_advance_timer.wait_time = duration
			auto_advance_timer.start()


# --- Video playback ---

func _play_next_video() -> void:
	if _video_index >= _video_queue.size():
		_on_all_videos_finished()
		return

	var path: String = _video_queue[_video_index]
	var stream = load(path)
	if stream == null:
		push_warning("Failed to load video: " + path)
		_video_index += 1
		_play_next_video()
		return

	_clear_video()
	_fade_started_early = false
	_current_player = _create_video_player(stream, false)
	_current_player.finished.connect(_on_video_finished, CONNECT_ONE_SHOT)
	_current_player.play()


func _on_video_finished() -> void:
	_video_index += 1
	if _video_index < _video_queue.size():
		_transition_to_next_video()
	else:
		_transition_to_next_video()


func _transition_to_next_video() -> void:
	# If early fade didn't trigger, do it now
	if not _fade_started_early:
		await _fade_in()
	else:
		# Wait for the early fade to finish
		while fade_rect.color.a < 1.0:
			await get_tree().process_frame
	_play_next_video()
	await _fade_out()


func _check_early_fade() -> void:
	# Start fade before video ends so transition feels smooth
	if _current_player == null or not is_instance_valid(_current_player):
		return
	if _fade_started_early:
		return
	if not _current_player.is_playing():
		return

	var length := _current_player.get_stream_length()
	var pos := _current_player.stream_position
	var remaining := length - pos

	if length > 0.0 and remaining <= VIDEO_FADE_EARLY + FADE_DURATION and remaining > 0.0:
		_fade_started_early = true
		_fade_in()


func _on_all_videos_finished() -> void:
	# Play loop video if exists
	if _loop_video_path != "":
		_play_loop_video()

	# Show choices or auto-advance
	var data: Dictionary = GameManager.get_scene(GameManager.current_scene_id)
	var choices: Array = _pending_choices if _pending_choices.size() > 0 else data.get("choices", [])
	_pending_choices = []

	if choices.size() > 0:
		choice_overlay.show_choices(choices)
		phone_ui.show_phone_button()
		_play_wait_sound()
	else:
		var next_id: String = data.get("next", "")
		if next_id != "":
			GameManager.go_to_scene(next_id)


func _play_loop_video() -> void:
	_clear_video()
	var stream = load(_loop_video_path)
	if stream:
		_current_player = _create_video_player(stream, true)
		_current_player.play()


var _cover_rect: TextureRect = null

func _create_video_player(stream: Resource, loop: bool) -> VideoStreamPlayer:
	var player := VideoStreamPlayer.new()
	player.stream = stream
	player.loop = loop
	# Hide the player visually — we use TextureRect to display the video
	player.visible = false
	video_container.add_child(player)

	# TextureRect with STRETCH_COVER to fill screen without black bars
	_cover_rect = TextureRect.new()
	_cover_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cover_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	video_container.add_child(_cover_rect)
	_cover_rect.anchor_left = 0.0
	_cover_rect.anchor_top = 0.0
	_cover_rect.anchor_right = 1.0
	_cover_rect.anchor_bottom = 1.0
	_cover_rect.offset_left = 0
	_cover_rect.offset_top = 0
	_cover_rect.offset_right = 0
	_cover_rect.offset_bottom = 0

	return player


func _process(delta: float) -> void:
	# Update TextureRect with video texture each frame
	if _current_player and is_instance_valid(_current_player) and _current_player.is_playing():
		var tex = _current_player.get_video_texture()
		if tex and _cover_rect and is_instance_valid(_cover_rect):
			_cover_rect.texture = tex

	# Start fade before video ends for smooth transition
	_check_early_fade()

	# Cheat code — execute after 0.5s of no new input
	if _cheat_buffer.length() > 1:
		_cheat_timer += delta
		if _cheat_timer > 0.5:
			_execute_cheat()


func _execute_cheat() -> void:
	var num: String = _cheat_buffer.substr(1)
	_cheat_buffer = ""
	var scene_id: String = "scene_%s" % num.pad_zeros(2)
	if GameManager.get_scene(scene_id).size() > 0:
		_is_transitioning = false
		GameManager.go_to_scene(scene_id)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var key_event: InputEventKey = event as InputEventKey
	var c: String = char(key_event.unicode)

	if c == "":
		return

	# Reset timer on each keystroke
	_cheat_timer = 0.0

	if _cheat_buffer == "" and c == "s":
		_cheat_buffer = "s"
		return

	if _cheat_buffer.begins_with("s") and c.is_valid_int():
		_cheat_buffer += c
		return

	# Invalid key — reset
	_cheat_buffer = ""


func _clear_video() -> void:
	if _current_player and is_instance_valid(_current_player):
		_current_player.stop()
		if _current_player.finished.is_connected(_on_video_finished):
			_current_player.finished.disconnect(_on_video_finished)
	_cover_rect = null
	for child in video_container.get_children():
		video_container.remove_child(child)
		child.queue_free()
	_current_player = null


# --- Timer & choices ---

func _on_auto_advance_timeout() -> void:
	if _pending_choices.size() > 0:
		choice_overlay.show_choices(_pending_choices)
		phone_ui.show_phone_button()
		_pending_choices = []
	else:
		var data: Dictionary = GameManager.get_scene(GameManager.current_scene_id)
		var next_id: String = data.get("next", "")
		if next_id != "":
			GameManager.go_to_scene(next_id)


func _on_choice_selected(next_scene_id: String) -> void:
	_stop_wait_sound()
	GameManager.go_to_scene(next_scene_id)


func _play_wait_sound() -> void:
	_stop_wait_sound()
	var stream: AudioStream = load("res://assets/sound/wait_sound.mp3")
	if stream == null:
		return
	_wait_sound_player = AudioStreamPlayer.new()
	_wait_sound_player.stream = stream
	_wait_sound_player.bus = "Master"
	_wait_sound_player.autoplay = true
	add_child(_wait_sound_player)
	# Loop: restart when finished
	_wait_sound_player.finished.connect(_on_wait_sound_finished)


func _on_wait_sound_finished() -> void:
	if _wait_sound_player and is_instance_valid(_wait_sound_player):
		_wait_sound_player.play()


func _stop_wait_sound() -> void:
	if _wait_sound_player and is_instance_valid(_wait_sound_player):
		_wait_sound_player.stop()
		_wait_sound_player.queue_free()
		_wait_sound_player = null


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
