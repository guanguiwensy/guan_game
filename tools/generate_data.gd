extends SceneTree
## One-shot data generator (dev tool). Builds the M1 config resources (.tres) for skills,
## enemies, and the 10 stages from the GDD starter values, so config stays the source of
## truth (ADR-001). Re-run after editing values here:
##   godot --headless --path . --script tools/generate_data.gd
## Numbers mirror design/gdd/mvp-gdd.md. Affixes & talents are generated in M2/M3.

func _initialize() -> void:
	_ensure_dir("res://src/data/skills")
	_ensure_dir("res://src/data/enemies")
	_ensure_dir("res://src/data/stages")
	_ensure_dir("res://src/data/affixes")
	_ensure_dir("res://src/data/talents")
	var n := 0
	n += _gen_skills()
	n += _gen_enemies()
	n += _gen_stages()
	n += _gen_affixes()
	n += _gen_talents()
	print("[generate_data] wrote %d resources" % n)
	quit(0)


func _ensure_dir(p: String) -> void:
	DirAccess.make_dir_recursive_absolute(p)


func _save(res: Resource, path: String) -> int:
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("[generate_data] save failed %s (err %d)" % [path, err])
		return 0
	return 1


# --- Skills ----------------------------------------------------------------

func _gen_skills() -> int:
	var c := 0
	c += _save(_skill(&"ember_swing", "余烬挥斩 Ember Swing", "physical", 1.0, 0.0, "single", 0.0, &"", 0.0, true, 0), "res://src/data/skills/ember_swing.tres")
	c += _save(_skill(&"cleaving_blow", "裂石斩 Cleaving Blow", "physical", 2.4, 4.0, "single", 0.0, &"", 0.0, false, 1), "res://src/data/skills/cleaving_blow.tres")
	c += _save(_skill(&"riftwind", "裂地回旋 Riftwind", "physical", 1.3, 7.0, "aoe_around_hero", 180.0, &"", 0.0, false, 2), "res://src/data/skills/riftwind.tres")
	c += _save(_skill(&"frostmaw_surge", "霜噬冲击 Frostmaw Surge", "ice", 1.6, 9.0, "aoe_at_target", 140.0, &"freeze", 0.6, false, 3), "res://src/data/skills/frostmaw_surge.tres")
	return c


func _skill(id: StringName, disp: String, tag: String, mult: float, cd: float, mode: String, radius: float, status: StringName, chance: float, is_auto: bool, prio: int) -> SkillData:
	var s := SkillData.new()
	s.id = id
	s.display_name = disp
	s.tag = tag
	s.skill_multiplier = mult
	s.cooldown = cd
	s.target_mode = mode
	s.aoe_radius = radius
	s.status = status
	s.status_chance = chance
	s.is_auto_attack = is_auto
	s.auto_cast_priority = prio
	return s


# --- Enemies ---------------------------------------------------------------

func _gen_enemies() -> int:
	var c := 0
	c += _save(_enemy(&"cinder_wisp", "余烬游魂 Cinder Wisp", 60.0, 8.0, 0.0, 140.0, 1.0, 5, 3, false), "res://src/data/enemies/cinder_wisp.tres")
	c += _save(_enemy(&"slagbound_husk", "碎甲傀儡 Slagbound Husk", 220.0, 12.0, 40.0, 50.0, 1.4, 12, 8, false), "res://src/data/enemies/slagbound_husk.tres")
	c += _save(_enemy(&"bonegnaw_crawler", "噬骨爬虫 Bonegnaw Crawler", 120.0, 16.0, 12.0, 90.0, 1.1, 8, 5, false), "res://src/data/enemies/bonegnaw_crawler.tres")
	c += _save(_enemy(&"lord_of_cinders", "焚誓领主 Lord of Cinders", 1400.0, 30.0, 30.0, 45.0, 1.5, 100, 80, true), "res://src/data/enemies/lord_of_cinders.tres")
	return c


func _enemy(id: StringName, disp: String, hp: float, atk: float, armor: float, move: float, interval: float, xp: int, gold: int, boss: bool) -> EnemyData:
	var e := EnemyData.new()
	e.id = id
	e.display_name = disp
	e.base_hp = hp
	e.base_attack = atk
	e.base_armor = armor
	e.move_speed = move
	e.attack_interval = interval
	e.xp_reward = xp
	e.gold_reward = gold
	e.is_boss = boss
	return e


# --- Stages ----------------------------------------------------------------

func _gen_stages() -> int:
	var c := 0
	for L in range(1, 11):
		c += _save(_stage(L), "res://src/data/stages/layer_%02d.tres" % L)
	return c


func _stage(L: int) -> StageData:
	var s := StageData.new()
	s.layer = L
	s.wave_gap = 1.5
	s.gold_reward = 20 * L
	s.xp_reward = 30 * L
	s.drop_level = L
	s.is_boss_layer = (L == 10)
	var t := float(L - 1) / 9.0
	s.drop_quality_weights = {
		&"common": lerpf(60.0, 20.0, t),
		&"magic": lerpf(28.0, 30.0, t),
		&"rare": lerpf(9.0, 30.0, t),
		&"epic": lerpf(2.5, 16.0, t),
		&"legendary": lerpf(0.5, 4.0, t),
	}
	var waves: Array[Dictionary] = []
	if L < 10:
		waves.append({&"cinder_wisp": 3 + L})
		waves.append({&"bonegnaw_crawler": 1 + int(L / 2.0)})
		if L >= 3:
			waves.append({&"slagbound_husk": 1 + int(L / 3.0)})
	else:
		waves.append({&"cinder_wisp": 6})
		waves.append({&"bonegnaw_crawler": 3, &"slagbound_husk": 2})
		waves.append({&"lord_of_cinders": 1})
	s.waves = waves
	return s


# --- Affixes ---------------------------------------------------------------

func _gen_affixes() -> int:
	var c := 0
	c += _save(_affix(&"aff_hp", &"hp", 20.0, 60.0), "res://src/data/affixes/aff_hp.tres")
	c += _save(_affix(&"aff_attack", &"attack", 4.0, 12.0), "res://src/data/affixes/aff_attack.tres")
	c += _save(_affix(&"aff_armor", &"armor", 3.0, 10.0), "res://src/data/affixes/aff_armor.tres")
	c += _save(_affix(&"aff_crit_rate", &"crit_rate", 0.02, 0.06), "res://src/data/affixes/aff_crit_rate.tres")
	c += _save(_affix(&"aff_crit_damage", &"crit_damage", 0.06, 0.18), "res://src/data/affixes/aff_crit_damage.tres")
	c += _save(_affix(&"aff_attack_speed", &"attack_speed", 0.03, 0.10), "res://src/data/affixes/aff_attack_speed.tres")
	c += _save(_affix(&"aff_elemental", &"elemental_damage", 5.0, 15.0), "res://src/data/affixes/aff_elemental.tres")
	return c


func _affix(id: StringName, stat: StringName, lo: float, hi: float, pct: bool = false) -> AffixData:
	var a := AffixData.new()
	a.id = id
	a.stat = stat
	a.min_value = lo
	a.max_value = hi
	a.is_percent = pct
	a.allowed_slots = []
	return a


# --- Talents (Path of Cinders) ---------------------------------------------

func _gen_talents() -> int:
	# id, name, category, stat, value, is_percent, max_rank, cost, requires, gx, gy
	var defs := [
		[&"ember_might", "余烬之力 Ember Might", "attack", &"attack", 8.0, false, 3, 1, [], 0, 0],
		[&"ember_vigor", "余烬活力 Ember Vigor", "hp", &"hp", 60.0, false, 3, 1, [], 2, 0],
		[&"keen_edge", "锋锐 Keen Edge", "crit", &"crit_rate", 0.03, false, 2, 1, [&"ember_might"], 0, 1],
		[&"swift_hands", "迅捷 Swift Hands", "attack", &"attack_speed", 0.06, false, 2, 1, [&"ember_might"], 1, 1],
		[&"thick_hide", "厚皮 Thick Hide", "hp", &"armor", 6.0, false, 2, 1, [&"ember_vigor"], 2, 1],
		[&"searing_brand", "灼印 Searing Brand", "elemental", &"elemental_damage", 8.0, false, 2, 1, [&"ember_might"], 0, 2],
		[&"frost_focus", "冰霜专注 Frost Focus", "elemental", &"elemental_damage", 12.0, false, 1, 2, [&"searing_brand"], 1, 2],
		[&"cruel_strikes", "残酷打击 Cruel Strikes", "crit", &"crit_damage", 0.10, false, 2, 1, [&"keen_edge"], 0, 3],
		[&"precision", "精准 Precision", "crit", &"crit_rate", 0.04, false, 1, 2, [&"keen_edge"], 1, 3],
		[&"bonfire_heart", "篝火之心 Bonfire Heart", "hp", &"hp", 0.10, true, 1, 2, [&"thick_hide"], 2, 2],
		[&"battle_fury", "战怒 Battle Fury", "attack", &"attack_speed", 0.05, false, 1, 2, [&"swift_hands"], 1, 4],
		[&"executioner", "处决 Executioner", "crit", &"crit_damage", 0.15, false, 1, 2, [&"cruel_strikes"], 0, 4],
		[&"unbroken", "不屈 Unbroken", "hp", &"hp", 200.0, false, 1, 3, [&"bonfire_heart"], 2, 3],
		[&"cinderlord", "余烬领主 Cinderlord", "attack", &"attack", 25.0, false, 1, 3, [&"searing_brand", &"executioner"], 0, 5],
	]
	var c := 0
	for d in defs:
		var n := TalentNode.new()
		n.id = d[0]
		n.display_name = d[1]
		n.category = d[2]
		n.stat = d[3]
		n.value_per_rank = d[4]
		n.is_percent = d[5]
		n.max_rank = d[6]
		n.cost_per_rank = d[7]
		var reqs: Array[StringName] = []
		for r in d[8]:
			reqs.append(r)
		n.requires = reqs
		n.grid_pos = Vector2i(d[9], d[10])
		c += _save(n, "res://src/data/talents/%s.tres" % String(d[0]))
	return c
