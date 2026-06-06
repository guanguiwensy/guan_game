class_name ResultPanel
extends CanvasLayer
## Victory / Defeat overlay (M1 PASS surface). Shown when a battle ends.
## Continue advances a layer on victory; Retry re-runs the layer on defeat.

signal again(layer: int)
signal to_menu()
signal inventory_requested()
signal talents_requested()

var _title: Label
var _primary: Button
var _is_win := false
var _layer := 1


func _ready() -> void:
	layer = 10   # CanvasLayer index: render above the HUD
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 30)
	center.add_child(vb)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 72)
	vb.add_child(_title)

	_primary = Button.new()
	_primary.custom_minimum_size = Vector2(380, 104)
	_primary.pressed.connect(_on_primary)
	vb.add_child(_primary)

	var bag := Button.new()
	bag.text = "查看背包  Inventory"
	bag.custom_minimum_size = Vector2(380, 84)
	bag.pressed.connect(func() -> void: inventory_requested.emit())
	vb.add_child(bag)

	var tal := Button.new()
	tal.text = "天赋  Talents"
	tal.custom_minimum_size = Vector2(380, 84)
	tal.pressed.connect(func() -> void: talents_requested.emit())
	vb.add_child(tal)

	var menu := Button.new()
	menu.text = "返回主菜单  Menu"
	menu.custom_minimum_size = Vector2(380, 84)
	menu.pressed.connect(func() -> void: to_menu.emit())
	vb.add_child(menu)


func show_result(is_win: bool, layer_num: int) -> void:
	_is_win = is_win
	_layer = layer_num
	if is_win:
		_title.text = "胜利!\nVICTORY"
		_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		_primary.text = ("通关 10 层! 再来一轮" if layer_num >= 10 else "继续下一层  Continue")
	else:
		_title.text = "失败\nDEFEAT"
		_title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		_primary.text = "重试本层  Retry"
	visible = true


func hide_panel() -> void:
	visible = false


func _on_primary() -> void:
	var nxt := _layer
	if _is_win:
		nxt = (_layer + 1) if _layer < 10 else 1
	again.emit(nxt)
