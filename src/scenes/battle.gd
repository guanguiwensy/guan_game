extends Node2D
## BattleScene — drives + renders a BattleEngine run for the current layer (M1).
## The engine is the verified logic core; this scene only visualizes it and feeds back
## win/lose to the result panel. Hero stats are placeholder base values until equipment
## (M2) and talents (M3) feed recompute_stats().

var _engine: BattleEngine
var _world: Node2D
var _hud: BattleHud
var _result: ResultPanel
var _hero_view: HeroView
var _views: Dictionary = {}        # CombatActor -> EnemyView
var _actor_by_id: Dictionary = {}  # int -> CombatActor (enemies; hero is id 0)
var current_layer: int = 1


func _ready() -> void:
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	_hud = BattleHud.new()
	add_child(_hud)
	_hud.debug_jump.connect(start_layer)

	_result = ResultPanel.new()
	add_child(_result)
	_result.again.connect(start_layer)
	_result.to_menu.connect(_go_menu)

	start_layer(current_layer)


func start_layer(layer: int) -> void:
	current_layer = clampi(layer, 1, 10)
	_clear_views()
	_result.hide_panel()

	var stage := GameData.get_stage(current_layer)
	if stage == null:
		push_error("BattleScene: no stage data for layer %d" % current_layer)
		return

	_engine = BattleEngine.new()
	_engine.enemy_spawned.connect(_on_enemy_spawned)
	_engine.actor_died.connect(_on_actor_died)
	_engine.hit_landed.connect(_on_hit_landed)
	_engine.battle_won.connect(_on_battle_won)
	_engine.battle_lost.connect(_on_battle_lost)

	var hero := _make_hero()
	hero.id = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = Rng.master_seed + current_layer
	_engine.setup(hero, stage, GameData.enemies, GameData.skills.values(), rng)

	_hero_view = HeroView.new()
	_hero_view.actor = hero
	_world.add_child(_hero_view)
	_hero_view.sync()

	_hud.set_layer_number(current_layer)
	_hud.update_live(_engine)


func _process(delta: float) -> void:
	if _engine == null or _engine.state != BattleEngine.STATE_RUNNING:
		return
	_engine.tick(delta)
	if _hero_view != null:
		_hero_view.sync()
	for actor in _views:
		_views[actor].sync()
	_hud.update_live(_engine)


func _make_hero() -> CombatActor:
	var h := CombatActor.new()
	h.display_name = "余烬守望者 Ashen Warden"
	h.is_hero = true
	h.max_hp = 600.0
	h.hp = 600.0
	h.attack = 45.0
	h.armor = 12.0
	h.crit_rate = 0.12
	h.crit_damage = 0.6
	h.attack_speed = 1.3
	h.elemental_damage = 0.0
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
	_result.show_result(true, layer)


func _on_battle_lost(layer: int) -> void:
	_result.show_result(false, layer)


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")
