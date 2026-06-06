class_name TalentTreePanel
extends CanvasLayer
## Path of Cinders panel (GDD §5). Lists nodes by tier with rank/max, lets the player spend
## points (respecting prerequisites/caps) and reset. Renders above the result panel.

signal closed()

const STAT_CN := {&"attack": "攻击", &"hp": "生命", &"armor": "护甲", &"crit_rate": "暴击", &"crit_damage": "暴伤", &"attack_speed": "攻速", &"elemental_damage": "元素"}

var _talents: TalentSystem
var _list: VBoxContainer
var _points_label: Label


func _ready() -> void:
	layer = 12
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.05, 0.97)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 36)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title_row := HBoxContainer.new()
	root.add_child(title_row)
	title_row.add_child(_label("天赋 · 余烬之路", 38))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(sp)
	var close := Button.new()
	close.text = "关闭 ✕"
	close.pressed.connect(_on_close)
	title_row.add_child(close)

	var bar := HBoxContainer.new()
	root.add_child(bar)
	_points_label = _label("可用天赋点: 0", 28)
	bar.add_child(_points_label)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(sp2)
	var reset_btn := Button.new()
	reset_btn.text = "重置 Reset"
	reset_btn.pressed.connect(_on_reset)
	bar.add_child(reset_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)


func open(talents: TalentSystem) -> void:
	_talents = talents
	_refresh()
	visible = true


func _refresh() -> void:
	_points_label.text = "可用天赋点: %d" % _talents.available_points
	for c in _list.get_children():
		c.queue_free()
	var nodes: Array = _talents.defs.values()
	nodes.sort_custom(func(a: TalentNode, b: TalentNode) -> bool:
		return (a.grid_pos.y * 100 + a.grid_pos.x) < (b.grid_pos.y * 100 + b.grid_pos.x))
	for node: TalentNode in nodes:
		var row := HBoxContainer.new()
		var r := _talents.rank(node.id)
		var v: float = node.value_per_rank * (100.0 if node.is_percent else 1.0)
		var unit := "%" if node.is_percent else ""
		var lbl := _label("%s  [%d/%d]   %s +%g%s" % [node.display_name, r, node.max_rank, STAT_CN.get(node.stat, String(node.stat)), v, unit], 22)
		if r >= node.max_rank:
			lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		elif not _talents.can_spend(node.id):
			lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		row.add_child(lbl)
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)
		var btn := Button.new()
		btn.text = "+ (%d点)" % node.cost_per_rank
		btn.disabled = not _talents.can_spend(node.id)
		btn.pressed.connect(_on_spend.bind(node.id))
		row.add_child(btn)
		_list.add_child(row)


func _on_spend(id: StringName) -> void:
	_talents.spend(id)
	_refresh()


func _on_reset() -> void:
	_talents.reset()
	_refresh()


func _on_close() -> void:
	visible = false
	closed.emit()


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
