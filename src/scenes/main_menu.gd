extends Control
## M0 placeholder main menu — confirms the project boots with portrait stretch + autoloads
## active. Built in code to keep the .tscn trivial. Replaced by a real menu in a later milestone.

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "余烬深渊\nAshsworn: The Cinder Deep"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "MVP scaffold · Godot %s" % Engine.get_version_info().get("string", "")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.modulate = Color(1, 1, 1, 0.6)
	vbox.add_child(subtitle)

	var start := Button.new()
	start.text = "进入深渊  Descend"
	start.custom_minimum_size = Vector2(440, 120)
	start.pressed.connect(_on_start_pressed)
	vbox.add_child(start)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/battle.tscn")
