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

	var newgame := Button.new()
	newgame.text = "新游戏 New Game"
	newgame.custom_minimum_size = Vector2(440, 90)
	newgame.pressed.connect(_on_new_game)
	vbox.add_child(newgame)

	if SaveSystem.has_save():
		var prog := Label.new()
		prog.text = "存档：Lv %d · 最深第 %d 层" % [Player.level, Player.max_layer_cleared]
		prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prog.add_theme_font_size_override("font_size", 24)
		prog.modulate = Color(1, 1, 1, 0.7)
		vbox.add_child(prog)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/battle.tscn")


func _on_new_game() -> void:
	SaveSystem.clear_save()
	Player.reset()
	get_tree().change_scene_to_file("res://src/scenes/battle.tscn")
