extends Node2D
## BattleScene — drives + renders a BattleEngine run for the current layer (M1) and handles
## loot drops + the inventory/equip loop (M2). Hero stats come from Player.current_stats()
## (= base + equipment), so equipping changes the fight's numbers. Combat is the verified
## logic core; this scene visualizes it, rolls loot on kills, and feeds win/lose to the UI.

var _engine: BattleEngine
var _world: Node2D
var _hud: BattleHud
var _result: ResultPanel
var _inv: InventoryPanel
var _talents: TalentTreePanel
var _hero_view: HeroView
var _views: Dictionary = {}        # CombatActor -> EnemyView
var _actor_by_id: Dictionary = {}  # int -> CombatActor (enemies; hero is id 0)

var _loot: LootSystem
var _stage: StageData
var _affix_pool: Array = []
var _paused := false
var _run_counter := 0
var _shake := 0.0
var current_layer: int = 1

const QUALITY_CN := {&"common": "锈蚀", &"magic": "灼印", &"rare": "淬火", &"epic": "焚誓", &"legendary": "渊心"}


func _ready() -> void:
	_make_background()
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	_hud = BattleHud.new()
	add_child(_hud)
	_hud.debug_jump.connect(start_layer)
	_hud.inventory_pressed.connect(_open_inventory)
	_hud.talents_pressed.connect(_open_talents)
	_hud.skill_tapped.connect(_on_skill_tapped)
	_hud.auto_toggled.connect(_on_auto_toggled)

	_result = ResultPanel.new()
	add_child(_result)
	_result.again.connect(start_layer)
	_result.to_menu.connect(_go_menu)
	_result.inventory_requested.connect(_open_inventory)
	_result.talents_requested.connect(_open_talents)

	_inv = InventoryPanel.new()
	add_child(_inv)
	_inv.closed.connect(_on_panel_closed)

	_talents = TalentTreePanel.new()
	add_child(_talents)
	_talents.closed.connect(_on_panel_closed)

	start_layer(current_layer)


func start_layer(layer: int) -> void:
	current_layer = clampi(layer, 1, 10)
	_run_counter += 1
	_clear_views()
	_result.hide_panel()
	_paused = false
	_shake = 0.0
	if _world != null:
		_world.position = Vector2.ZERO

	_stage = GameData.get_stage(current_layer)
	if _stage == null:
		push_error("BattleScene: no stage data for layer %d" % current_layer)
		return
	_affix_pool = GameData.affixes.values()

	var loot_rng := RandomNumberGenerator.new()
	loot_rng.seed = Rng.master_seed * 1000 + current_layer * 100 + _run_counter
	_loot = LootSystem.new(loot_rng)

	_engine = BattleEngine.new()
	_engine.enemy_spawned.connect(_on_enemy_spawned)
	_engine.actor_died.connect(_on_actor_died)
	_engine.hit_landed.connect(_on_hit_landed)
	_engine.battle_won.connect(_on_battle_won)
	_engine.battle_lost.connect(_on_battle_lost)
	_engine.aoe_cast.connect(_on_aoe_cast)

	var hero := _make_hero()
	hero.id = 0
	var combat_rng := RandomNumberGenerator.new()
	combat_rng.seed = Rng.master_seed + current_layer
	_engine.setup(hero, _stage, GameData.enemies, GameData.skills.values(), combat_rng)

	_hero_view = HeroView.new()
	_hero_view.actor = hero
	_world.add_child(_hero_view)
	_hero_view.sync()

	_hud.set_layer_number(current_layer)
	_hud.set_inventory_count(Player.equipment.inventory.size())
	_hud.update_live(_engine)


func _process(delta: float) -> void:
	if _paused or _engine == null or _engine.state != BattleEngine.STATE_RUNNING:
		return
	_engine.tick(delta)
	if _hero_view != null:
		_hero_view.sync()
	for actor in _views:
		_views[actor].sync()
	_hud.update_live(_engine)
	_update_shake(delta)


func _update_shake(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 40.0)
		_world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	elif _world.position != Vector2.ZERO:
		_world.position = Vector2.ZERO


func _make_hero() -> CombatActor:
	var st := Player.current_stats()
	var h := CombatActor.new()
	h.display_name = "余烬守望者 Ashen Warden"
	h.is_hero = true
	h.max_hp = st.hp
	h.hp = st.hp
	h.attack = st.attack
	h.armor = st.armor
	h.crit_rate = st.crit_rate
	h.crit_damage = st.crit_damage
	h.attack_speed = st.attack_speed
	h.elemental_damage = st.elemental_damage
	h.attack_range = 260.0
	return h


func _clear_views() -> void:
	for v in _views.values():
		if is_instance_valid(v):
			v.queue_free()
	_views.clear()
	_actor_by_id.clear()
	if _hero_view != null and is_instance_valid(_hero_view):
		_hero_view.queue_free()
	_hero_view = null
	if _world != null:
		for c in _world.get_children():
			if c is DamageText:
				c.queue_free()


func _on_enemy_spawned(actor: CombatActor) -> void:
	var v := EnemyView.new()
	v.actor = actor
	_world.add_child(v)
	v.sync()
	_views[actor] = v
	_actor_by_id[actor.id] = actor


func _on_actor_died(actor: CombatActor) -> void:
	_actor_by_id.erase(actor.id)
	if _views.has(actor):
		var v: EnemyView = _views[actor]
		_views.erase(actor)
		if is_instance_valid(v):
			v.play_death()
	# loot roll (seeded). Boss always drops; normal kills at LootSystem.NORMAL_DROP_CHANCE.
	# rewards accrue per kill (visible mid-fight level-ups); failure keeps what was earned
	var lv0 := Player.level
	Player.add_rewards(actor.xp_reward, actor.gold_reward)
	if Player.level > lv0:
		_hud.toast("升级! Lv %d" % Player.level, Color(0.45, 1.0, 0.55))
	var item := _loot.maybe_drop(actor.is_boss, _stage.drop_level, _stage.drop_quality_weights, _affix_pool)
	if item != null:
		Player.add_loot(item)
		_hud.set_inventory_count(Player.equipment.inventory.size())
		_hud.notify_loot("%s装备" % QUALITY_CN.get(item.quality, "新"))


func _on_hit_landed(target_id: int, amount: float, is_crit: bool, element: StringName) -> void:
	var pos: Vector2
	if target_id == 0:
		pos = _engine.hero.position
		_shake = maxf(_shake, 5.0)   # M5: hero got hit
	else:
		var a: CombatActor = _actor_by_id.get(target_id)
		if a == null:
			return
		pos = a.position
		var v: EnemyView = _views.get(a)
		if v != null:
			v.hit_flash()
		if a.is_boss:
			_shake = maxf(_shake, 7.0)
	if is_crit:
		_shake = maxf(_shake, 11.0)   # M5: crits punch
	var dt := DamageText.new()
	dt.setup(int(round(amount)), is_crit, element)
	dt.position = pos + Vector2(0.0, -50.0)
	_world.add_child(dt)


func _on_battle_won(layer: int) -> void:
	# rewards already accrued per kill in _on_actor_died
	Player.max_layer_cleared = maxi(Player.max_layer_cleared, layer)
	Player.save()
	_result.show_result(true, layer)


func _on_battle_lost(layer: int) -> void:
	Player.save()
	_result.show_result(false, layer)


func _on_aoe_cast(center: Vector2, radius: float, element: StringName) -> void:
	var ring := SkillRing.new()
	var col := Color(0.6, 0.85, 1.0) if element == &"ice" else Color(1.0, 0.6, 0.25)
	ring.setup(radius, col)
	ring.position = center
	_world.add_child(ring)


func _make_background() -> void:
	var bg := CanvasLayer.new()
	bg.layer = -10
	var tr := TextureRect.new()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var grad := Gradient.new()
	grad.set_color(0, Color(0.12, 0.03, 0.04))
	grad.set_color(1, Color(0.02, 0.01, 0.02))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 64
	gt.height = 256
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	tr.texture = gt
	bg.add_child(tr)
	add_child(bg)


# --- Inventory ----------------------------------------------------------------

func _open_inventory() -> void:
	_paused = true
	_inv.open(Player.equipment, Player.base_stats)


func _open_talents() -> void:
	_paused = true
	_talents.open(Player.talents)


func _on_panel_closed() -> void:
	_paused = false
	_apply_player_stats_to_hero()
	_hud.set_inventory_count(Player.equipment.inventory.size())
	Player.save()


## Apply equipment changes to the LIVE hero so the player sees numbers update immediately
## (preserves current hp fraction). Next layer also rebuilds from Player.current_stats().
func _apply_player_stats_to_hero() -> void:
	if _engine == null or _engine.hero == null:
		return
	var st := Player.current_stats()
	var h := _engine.hero
	var ratio := h.hp / maxf(h.max_hp, 1.0)
	h.attack = st.attack
	h.armor = st.armor
	h.crit_rate = st.crit_rate
	h.crit_damage = st.crit_damage
	h.attack_speed = st.attack_speed
	h.elemental_damage = st.elemental_damage
	h.max_hp = st.hp
	h.hp = st.hp * ratio
	if _hud != null:
		_hud.update_live(_engine)


func _on_skill_tapped(index: int) -> void:
	if _engine == null:
		return
	var status: Array = _engine.skill_status()
	if index >= 0 and index < status.size():
		_engine.manual_cast(status[index]["id"])


func _on_auto_toggled(on: bool) -> void:
	if _engine != null:
		_engine.auto_cast = on


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")
