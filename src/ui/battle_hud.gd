class_name BattleHud
extends CanvasLayer
## Portrait battle HUD (GDD §0): layer/wave/enemies up top; hero HP + power + auto-cast
## toggle + tappable skill chips at the bottom; transient loot toasts. Read-only on combat
## state — it reads BattleEngine each frame and emits intent signals; it never drives logic.

signal debug_jump(layer: int)
signal inventory_pressed()
signal talents_pressed()
signal skill_tapped(index: int)
signal auto_toggled(on: bool)

var _root: Control
var _inv_button: Button
var _layer_label: Label
var _wave_label: Label
var _enemies_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _power_label: Label
var _chips: Array = []   # Array[Button]


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# --- top bar ---
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 40
	top.offset_left = 30
	top.offset_right = -30
	top.add_theme_constant_override("separation", 22)
	_root.add_child(top)
	_layer_label = _mk_label("第 1 层", 34)
	_wave_label = _mk_label("波 0/0", 26)
	_enemies_label = _mk_label("敌 0", 26)
	top.add_child(_layer_label)
	top.add_child(_wave_label)
	top.add_child(_enemies_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_inv_button = Button.new()
	_inv_button.text = "背包 (0)"
	_inv_button.pressed.connect(func() -> void: inventory_pressed.emit())
	top.add_child(_inv_button)
	var tal_button := Button.new()
	tal_button.text = "天赋"
	tal_button.pressed.connect(func() -> void: talents_pressed.emit())
	top.add_child(tal_button)
	var dbg := Button.new()
	dbg.text = "→ L10"
	dbg.pressed.connect(func() -> void: debug_jump.emit(10))
	top.add_child(dbg)

	# --- bottom box ---
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -280
	bottom.offset_bottom = -40
	bottom.offset_left = 30
	bottom.offset_right = -30
	bottom.add_theme_constant_override("separation", 12)
	_root.add_child(bottom)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(0, 30)
	_hp_bar.show_percentage = false
	bottom.add_child(_hp_bar)

	var row := HBoxContainer.new()
	bottom.add_child(row)
	_hp_label = _mk_label("HP 0/0", 24)
	row.add_child(_hp_label)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp2)
	var auto_btn := CheckButton.new()
	auto_btn.text = "自动"
	auto_btn.button_pressed = true
	auto_btn.toggled.connect(func(on: bool) -> void: auto_toggled.emit(on))
	row.add_child(auto_btn)
	_power_label = _mk_label("战力 0", 24)
	row.add_child(_power_label)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 16)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(chips)
	for i in 3:
		var chip := Button.new()
		chip.custom_minimum_size = Vector2(170, 96)
		chip.text = "—"
		chip.pressed.connect(func() -> void: skill_tapped.emit(i))
		chips.add_child(chip)
		_chips.append(chip)


func set_layer_number(layer_num: int) -> void:
	_layer_label.text = "第 %d 层" % layer_num


func set_inventory_count(n: int) -> void:
	if _inv_button != null:
		_inv_button.text = "背包 (%d)" % n


## Transient "loot dropped" toast (M5).
func notify_loot(text: String) -> void:
	toast("掉落：" + text, Color(1.0, 0.85, 0.3))


## Generic transient toast near the top of the screen.
func toast(text: String, color: Color = Color.WHITE) -> void:
	if _root == null:
		return
	var t := Label.new()
	t.text = text
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", color)
	t.position = Vector2(320, 170)
	_root.add_child(t)
	var tw := t.create_tween()
	tw.tween_property(t, "position:y", 120.0, 0.7)
	tw.parallel().tween_property(t, "modulate:a", 0.0, 1.2)
	tw.tween_callback(t.queue_free)


func update_live(engine: Variant) -> void:
	var hero: CombatActor = engine.hero
	_hp_bar.max_value = hero.max_hp
	_hp_bar.value = maxf(hero.hp, 0.0)
	_hp_label.text = "HP %d/%d" % [maxi(int(hero.hp), 0), int(hero.max_hp)]
	_power_label.text = "战力 %d" % int(hero.power())
	_wave_label.text = "波 %d/%d" % [engine.current_wave_index() + 1, engine.total_waves()]
	_enemies_label.text = "敌 %d" % engine.enemies_alive_count()

	var status: Array = engine.skill_status()
	for i in _chips.size():
		var chip: Button = _chips[i]
		if i < status.size():
			var st: Dictionary = status[i]
			var nm: String = String(st["name"]).split(" ")[0]
			var rem: float = st["remaining"]
			if rem > 0.0:
				chip.text = "%s\n%.1f" % [nm, rem]
				chip.disabled = true
				chip.modulate = Color(0.6, 0.6, 0.6)
			else:
				chip.text = "%s\n就绪" % nm
				chip.disabled = false
				chip.modulate = Color(1, 1, 1)
		else:
			chip.text = "—"
			chip.disabled = true


func _mk_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
