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
var _hero_view: HeroView
var _views: Dictionary = {}        # CombatActor -> EnemyView
var _actor_by_id: Dictionary = {}  # int -> CombatActor (enemies; hero is id 0)

var _loot: LootSystem
var _stage: StageData
var _affix_pool: Array = []
var _paused := false
var _run_counter := 0
var current_layer: int = 1


func _ready() -> void:
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	_hud = BattleHud.new()
	add_child(_hud)
	_hud.debug_jump.connect(start_layer)
	_hud.inventory_pressed.connect(_open_inventory)

	_result = ResultPanel.new()
	add_child(_result)
	_result.again.connect(start_layer)
	_result.to_menu.connect(_go_menu)
	_result.inventory_requested.connect(_open_inventory)

	_inv = InventoryPanel.new()
	add_child(_inv)
	_inv.closed.connect(_on_inventory_closed)

	start_layer(current_layer)


func start_layer(layer: int) -> void:
	current_layer = clampi(layer, 1, 10)
	_run_counter += 1
	_clear_views()
	_result.hide_panel()
	_paused = false

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
	var item := _loot.maybe_drop(actor.is_boss, _stage.drop_level, _stage.drop_quality_weights, _affix_pool)
	if item != null:
		Player.add_loot(item)
		_hud.set_inventory_count(Player.equipment.inventory.size())


func _on_hit_landed(target_id: int, amount: float, is_crit: bool, element: StringName) -> void:
	var pos: Vector2
	if target_id == 0:
		pos = _engine.hero.position
	else:
		var a: CombatActor = _actor_by_id.get(target_id)
		if a == null:
			return
		pos = a.position
	var dt := DamageText.new()
	dt.setup(int(round(amount)), is_crit, element)
	dt.position = pos + Vector2(0.0, -50.0)
	_world.add_child(dt)


func _on_battle_won(layer: int) -> void:
	Player.add_rewards(_engine.total_xp, _engine.total_gold)
	Player.max_layer_cleared = maxi(Player.max_layer_cleared, layer)
	_result.show_result(true, layer)


func _on_battle_lost(layer: int) -> void:
	Player.add_rewards(_engine.total_xp, _engine.total_gold)
	_result.show_result(false, layer)


# --- Inventory ----------------------------------------------------------------

func _open_inventory() -> void:
	_paused = true
	_inv.open(Player.equipment, Player.base_stats)


func _on_inventory_closed() -> void:
	_paused = false
	_apply_player_stats_to_hero()
	_hud.set_inventory_count(Player.equipment.inventory.size())


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


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")
