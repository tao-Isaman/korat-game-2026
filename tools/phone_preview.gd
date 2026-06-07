extends Control

# Dev-only harness to preview PhoneUI.tscn without needing gameplay videos.
# Run: godot --path . --scene res://tools/phone_preview.tscn

@onready var phone: CanvasLayer = $PhoneUI


func _ready() -> void:
	# Seed sample data so both tabs have content to show.
	GameManager.reset_relationships()
	GameManager.add_relationship("paeng", 72)
	GameManager.add_relationship("baitoey", 48)
	GameManager.add_relationship("beam", 25)
	GameManager.add_relationship("ploy", 11)
	GameManager.choice_history = [
		{"scene_title": "ฉาก 1 — หน้าอาคาร", "choice_label": "ไปเรียนกับใบเตย"},
		{"scene_title": "ฉาก 2 — โรงอาหาร", "choice_label": "ชวนบีมไปถ่ายรูปเล่น"},
		{"scene_title": "ฉาก 3 — ห้องสมุด", "choice_label": "นั่งเงียบ ๆ ข้างพลอย"},
	]

	var hint := Label.new()
	hint.text = "Phone UI preview — tap the button (top-right) or tap outside to toggle."
	hint.position = Vector2(40, 36)
	hint.add_theme_font_size_override("font_size", 24)
	add_child(hint)

	phone.show_phone_button()
	phone.call_deferred("_show_phone")
