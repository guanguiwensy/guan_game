class_name BattleHud
extends CanvasLayer
## Portrait battle HUD (GDD §0): layer/wave/enemies up top, hero HP + power + skill bar
## at the bottom. Built in code (placeholder styling; visual polish is M5). Read-only —
## it reads BattleEngine state each frame, it does not drive logic.

signal debug_jump(layer: int)

var _layer_label: Label
var _wave_label: Label
var _enemies_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _power_label: Label
var _chips: Array = []   # [{name: Label, cd: Label, panel: PanelContainer}]


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- top bar ---
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 40
	top.offset_left = 30
	top.offset_right = -30
	top.add_theme_constant_override("separation", 28)
	root.add_child(top)
	_layer_label = _mk_label("第 1 层", 34)
	_wave_label = _mk_label("波 0/0", 26)
	_enemies_label = _mk_label("敌 0", 26)
	top.add_child(_layer_label)
	top.add_child(_wave_label)
	top.add_child(_enemies_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var dbg := Button.new()
	dbg.text = "→ L10"
	dbg.pressed.connect(func() -> void: debug_jump.emit(10))
	top.add_child(dbg)

	# --- bottom box ---
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -270
	bottom.offset_bottom = -40
	bottom.offset_left = 30
	bottom.offset_right = -30
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)

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
	_power_label = _mk_label("战力 0", 24)
	row.add_child(_power_label)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 16)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(chips)
	for i in 3:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(150, 92)
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vb)
		var nm := _mk_label("—", 22)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var cd := _mk_label("", 26)
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(nm)
		vb.add_child(cd)
		chips.add_child(panel)
		_chips.append({"name": nm, "cd": cd, "panel": panel})


func set_layer_number(layer_num: int) -> void:
	_layer_label.text = "第 %d 层" % layer_num


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
		var chip: Dictionary = _chips[i]
		if i < status.size():
			var st: Dictionary = status[i]
			chip["name"].text = String(st["name"]).split(" ")[0]
			var rem: float = st["remaining"]
			if rem > 0.0:
				chip["cd"].text = "%.1f" % rem
				chip["panel"].modulate = Color(0.6, 0.6, 0.6)
			else:
				chip["cd"].text = "就绪"
				chip["panel"].modulate = Color(1, 1, 1)
		else:
			chip["name"].text = "—"
			chip["cd"].text = ""


func _mk_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
