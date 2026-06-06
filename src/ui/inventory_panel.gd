class_name InventoryPanel
extends CanvasLayer
## Inventory + equip/compare panel (GDD §4). Lists equipped items and the bag; selecting a
## bag item previews the per-stat + power delta vs the currently-equipped piece (the
## compare-on-swap requirement), and Equip applies it. Renders above the result panel.

signal closed()

const QUALITY_COLOR := {
	&"common": Color(0.80, 0.80, 0.80), &"magic": Color(0.40, 0.62, 1.0),
	&"rare": Color(1.0, 0.85, 0.30), &"epic": Color(0.72, 0.42, 1.0), &"legendary": Color(1.0, 0.55, 0.20),
}
const QUALITY_CN := {&"common": "锈蚀", &"magic": "灼印", &"rare": "淬火", &"epic": "焚誓", &"legendary": "渊心"}
const SLOT_CN := {&"weapon": "武器", &"helm": "头盔", &"chest": "胸甲", &"gloves": "手套", &"boots": "战靴", &"amulet": "项链"}
const STAT_CN := {&"attack": "攻击", &"hp": "生命", &"armor": "护甲", &"crit_rate": "暴击", &"crit_damage": "暴伤", &"attack_speed": "攻速", &"elemental_damage": "元素"}
const STAT_ORDER: Array[StringName] = [&"attack", &"hp", &"armor", &"crit_rate", &"crit_damage", &"attack_speed", &"elemental_damage"]
const SLOT_ORDER: Array[StringName] = [&"weapon", &"helm", &"chest", &"gloves", &"boots", &"amulet"]

var _equipment: EquipmentSystem
var _base: HeroStats
var _equipped_box: VBoxContainer
var _inv_box: VBoxContainer
var _detail_box: VBoxContainer
var _selected: Item


func _ready() -> void:
	layer = 12
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.97)
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
	title_row.add_child(_label("背包 Inventory", 40))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(sp)
	var close := Button.new()
	close.text = "关闭 ✕"
	close.pressed.connect(_on_close)
	title_row.add_child(close)

	root.add_child(_label("已装备 Equipped", 26))
	_equipped_box = VBoxContainer.new()
	root.add_child(_equipped_box)

	root.add_child(_label("背包物品 Items", 26))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 460)
	root.add_child(scroll)
	_inv_box = VBoxContainer.new()
	_inv_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_inv_box)

	_detail_box = VBoxContainer.new()
	_detail_box.add_theme_constant_override("separation", 6)
	root.add_child(_detail_box)


func open(equipment: EquipmentSystem, base: HeroStats) -> void:
	_equipment = equipment
	_base = base
	_selected = null
	_refresh()
	visible = true


func _refresh() -> void:
	for c in _equipped_box.get_children():
		c.queue_free()
	for slot in SLOT_ORDER:
		var it: Item = _equipment.equipped.get(slot)
		var lbl := _label("%s: %s" % [SLOT_CN[slot], (_item_short(it) if it != null else "— 空 —")], 22)
		if it != null:
			lbl.add_theme_color_override("font_color", QUALITY_COLOR.get(it.quality, Color.WHITE))
		_equipped_box.add_child(lbl)

	for c in _inv_box.get_children():
		c.queue_free()
	if _equipment.inventory.is_empty():
		_inv_box.add_child(_label("（暂无物品 — 去打怪掉落）", 22))
	else:
		for it in _equipment.inventory:
			var b := Button.new()
			b.text = _item_short(it)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_color_override("font_color", QUALITY_COLOR.get(it.quality, Color.WHITE))
			b.pressed.connect(_on_select.bind(it))
			_inv_box.add_child(b)

	_render_detail()


func _on_select(it: Item) -> void:
	_selected = it
	_render_detail()


func _render_detail() -> void:
	for c in _detail_box.get_children():
		c.queue_free()
	if _selected == null:
		_detail_box.add_child(_label("选择一件物品查看对比", 22))
		return
	_detail_box.add_child(_label("对比：" + _item_short(_selected), 24))
	var cmp := _equipment.compare(_selected, _base)
	var before: HeroStats = cmp["before"]
	var after: HeroStats = cmp["after"]
	for stat in STAT_ORDER:
		var d := _stat_of(after, stat) - _stat_of(before, stat)
		if absf(d) < 0.0001:
			continue
		var line := _label("%s  %+.2f" % [STAT_CN[stat], d], 22)
		line.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4) if d > 0.0 else Color(1.0, 0.5, 0.5))
		_detail_box.add_child(line)
	var pd := after.power() - before.power()
	var pl := _label("战力  %+d" % int(round(pd)), 26)
	pl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_detail_box.add_child(pl)
	var eq := Button.new()
	eq.text = "装备 Equip"
	eq.custom_minimum_size = Vector2(300, 84)
	eq.pressed.connect(_on_equip)
	_detail_box.add_child(eq)


func _on_equip() -> void:
	if _selected != null:
		_equipment.equip(_selected)
		_selected = null
		_refresh()


func _on_close() -> void:
	visible = false
	closed.emit()


func _item_short(it: Item) -> String:
	if it == null:
		return "—"
	var main: String = STAT_CN.get(it.main_stat, String(it.main_stat))
	return "%s·%s  %s+%d  (%d词缀)" % [QUALITY_CN.get(it.quality, "?"), SLOT_CN.get(it.slot, "?"), main, int(round(it.main_value)), it.affixes.size()]


func _stat_of(s: HeroStats, stat: StringName) -> float:
	match stat:
		&"attack": return s.attack
		&"hp": return s.hp
		&"armor": return s.armor
		&"crit_rate": return s.crit_rate
		&"crit_damage": return s.crit_damage
		&"attack_speed": return s.attack_speed
		&"elemental_damage": return s.elemental_damage
	return 0.0


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
