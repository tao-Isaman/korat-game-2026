extends Control

@onready var btn_new_game: Button = $MenuPanel/VBox/BtnNewGame
@onready var btn_load: Button = $MenuPanel/VBox/BtnLoad
@onready var btn_settings: Button = $MenuPanel/VBox/BtnSettings
@onready var btn_about: Button = $MenuPanel/VBox/BtnAbout
@onready var btn_exit: Button = $MenuPanel/VBox/BtnExit
@onready var logo: TextureRect = $Logo


func _ready() -> void:
	btn_new_game.pressed.connect(_on_new_game)
	btn_load.pressed.connect(_on_load)
	btn_settings.pressed.connect(_on_settings)
	btn_about.pressed.connect(_on_about)
	btn_exit.pressed.connect(_on_exit)

	# Disable unimplemented buttons
	btn_load.disabled = true
	btn_settings.disabled = true
	btn_about.disabled = true

	# Slowly fade in logo
	if logo:
		logo.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(logo, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Setup hover bounce animation for all buttons
	var all_buttons: Array = [btn_new_game, btn_load, btn_settings, btn_about, btn_exit]
	for btn in all_buttons:
		btn.pivot_offset = btn.custom_minimum_size / 2.0
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))


func _on_btn_hover(btn: Button) -> void:
	# Bounce scale up with elastic feel
	var tween := btn.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.3)


func _on_btn_unhover(btn: Button) -> void:
	# Return to normal scale smoothly
	var tween := btn.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SPRING)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.25)


func _on_new_game() -> void:
	GameManager.play_click_sound()
	GameManager.reset_relationships()
	get_tree().change_scene_to_file("res://scenes/fmv/ScenePlayer.tscn")


func _on_load() -> void:
	pass


func _on_settings() -> void:
	pass


func _on_about() -> void:
	pass


func _on_exit() -> void:
	GameManager.play_click_sound()
	# Wait a short moment for the click sound to play before quitting
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
