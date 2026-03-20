extends Control

@onready var btn_new_game: Button = $HBox/MenuPanel/MarginContainer/VBox/BtnNewGame
@onready var btn_load: Button = $HBox/MenuPanel/MarginContainer/VBox/BtnLoad
@onready var btn_settings: Button = $HBox/MenuPanel/MarginContainer/VBox/BtnSettings
@onready var btn_about: Button = $HBox/MenuPanel/MarginContainer/VBox/BtnAbout
@onready var btn_exit: Button = $HBox/MenuPanel/MarginContainer/VBox/BtnExit


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


func _on_new_game() -> void:
	GameManager.reset_relationships()
	get_tree().change_scene_to_file("res://scenes/fmv/ScenePlayer.tscn")


func _on_load() -> void:
	pass


func _on_settings() -> void:
	pass


func _on_about() -> void:
	pass


func _on_exit() -> void:
	get_tree().quit()
