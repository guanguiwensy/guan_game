class_name BattleEngine
extends RefCounted
## The headless-simulatable heart of a battle (GDD §1). Owns the hero + enemy CombatActors
## and drives one layer: spawning waves, movement, targeting, auto-attack, skill auto-cast,
## status ticks, deaths/rewards, and win/lose. Emits its OWN signals (NOT the EventBus
## autoload) so it runs in tests without the scene tree; BattleScene relays these to the HUD.

signal hit_landed(target_id: int, amount: float, is_crit: bool, element: StringName)
signal actor_died(actor: CombatActor)
signal enemy_spawned(actor: CombatActor)
signal wave_started(wave_index: int)
signal reward_gained(xp: int, gold: int)
signal battle_won(layer: int)
signal battle_lost(layer: int)
signal aoe_cast(center: Vector2, radius: float, element: StringName)

const STATE_RUNNING := 0
const STATE_WON := 1
const STATE_LOST := 2

# Field geometry (portrait 1080x1920 logical). Hero near bottom; enemies descend.
const HERO_POS := Vector2(540, 1640)
const SPAWN_Y := 220.0
const SPAWN_X_MIN := 160.0
const SPAWN_X_MAX := 920.0

var state: int = STATE_RUNNING
var auto_cast: bool = true     # M5: toggle for auto-releasing active skills
var layer: int = 1
var hero: CombatActor
var enemies: Array[CombatActor] = []
var total_xp: int = 0
var total_gold: int = 0

var _combat: CombatSystem
var _skills: SkillSystem
var _rng: RandomNumberGenerator
var _stage: StageData
var _enemy_data: Dictionary = {}        # StringName -> EnemyData
var _next_actor_id: int = 1
var _wave_index: int = -1
var _wave_gap_timer: float = 0.0
var _spawned_first: bool = false


## Inject everything (DI → testable). skill_list includes the auto-attack + actives.
func setup(hero_actor: CombatActor, stage: StageData, enemy_data_by_id: Dictionary, skill_list: Array, rng_stream: RandomNumberGenerator) -> void:
	hero = hero_actor
	hero.is_hero = true
	hero.position = HERO_POS
	hero.attack_range = maxf(hero.attack_range, 240.0)
	_stage = stage
	layer = stage.layer
	_enemy_data = enemy_data_by_id
	_rng = rng_stream
	_combat = CombatSystem.new(rng_stream)
	_skills = SkillSystem.new()
	_skills.setup(skill_list)
	state = STATE_RUNNING


func tick(delta: float) -> void:
	if state != STATE_RUNNING:
		return
	_skills.update(delta)
	_spawn_logic(delta)
	_hero_act(delta)
	_enemies_act(delta)
	_tick_all_statuses(delta)
	_cleanup_dead()
	_check_end()


# --- Wave spawning ---------------------------------------------------------

func _spawn_logic(delta: float) -> void:
	if not _spawned_first:
		_spawned_first = true
		_wave_index = 0
		_spawn_wave(_stage.waves[0])
		wave_started.emit(_wave_index)
		return
	if _enemies_alive() > 0:
		return
	if _wave_index + 1 < _stage.waves.size():
		_wave_gap_timer += delta
		if _wave_gap_timer >= _stage.wave_gap:
			_wave_gap_timer = 0.0
			_wave_index += 1
			_spawn_wave(_stage.waves[_wave_index])
			wave_started.emit(_wave_index)


func _spawn_wave(wave: Dictionary) -> void:
	for enemy_id in wave:
		var data: EnemyData = _enemy_data.get(enemy_id)
		if data == null:
			continue
		var count := int(wave[enemy_id])
		for i in count:
			enemies.append(_make_enemy(data))


func _make_enemy(data: EnemyData) -> CombatActor:
	var e := CombatActor.new()
	e.id = _next_actor_id
	_next_actor_id += 1
	e.display_name = data.display_name
	e.is_boss = data.is_boss
	e.max_hp = Formulas.enemy_hp(data.base_hp, layer)
	e.hp = e.max_hp
	e.attack = Formulas.enemy_attack(data.base_attack, layer)
	e.armor = Formulas.enemy_armor(data.base_armor, layer)
	e.move_speed = data.move_speed
	e.attack_interval = data.attack_interval
	e.attack_range = 70.0
	e.xp_reward = data.xp_reward
	e.gold_reward = data.gold_reward
	e.position = Vector2(_rng.randf_range(SPAWN_X_MIN, SPAWN_X_MAX), SPAWN_Y)
	enemy_spawned.emit(e)
	return e


# --- Hero turn -------------------------------------------------------------

func _hero_act(delta: float) -> void:
	hero.attack_cooldown -= delta
	var target := _nearest_enemy()
	if target == null:
		return
	if auto_cast:
		for s in _skills.ready_skills():
			_cast_skill(s, target)
			_skills.trigger(s)
	if hero.attack_cooldown <= 0.0 and hero.position.distance_to(target.position) <= hero.attack_range:
		if _skills.auto_skill != null:
			_apply_skill_damage(_skills.auto_skill, hero, target)
		hero.attack_cooldown = 1.0 / maxf(hero.attack_speed, 0.01)


func _cast_skill(skill: SkillData, primary: CombatActor) -> void:
	match skill.target_mode:
		"single":
			_apply_skill_damage(skill, hero, primary)
		"aoe_around_hero":
			aoe_cast.emit(hero.position, skill.aoe_radius, StringName(skill.tag))
			for e in enemies:
				if e.is_alive() and hero.position.distance_to(e.position) <= skill.aoe_radius:
					_apply_skill_damage(skill, hero, e)
		"aoe_at_target":
			aoe_cast.emit(primary.position, skill.aoe_radius, StringName(skill.tag))
			for e in enemies:
				if e.is_alive() and primary.position.distance_to(e.position) <= skill.aoe_radius:
					_apply_skill_damage(skill, hero, e)


func _apply_skill_damage(skill: SkillData, attacker: CombatActor, defender: CombatActor) -> void:
	var res := _combat.resolve_hit(attacker, defender, skill.skill_multiplier)
	var dmg := float(res["damage"])
	# Elemental skills add the attacker's elemental_damage as flat bonus (GDD §1).
	if skill.tag != "physical" and attacker.elemental_damage > 0.0:
		defender.hp -= attacker.elemental_damage
		dmg += attacker.elemental_damage
	hit_landed.emit(defender.id, dmg, bool(res["is_crit"]), StringName(skill.tag))
	if skill.status != &"" and _rng.randf() < skill.status_chance:
		_apply_skill_status(skill, defender)


func _apply_skill_status(skill: SkillData, defender: CombatActor) -> void:
	match skill.status:
		&"freeze":
			_combat.apply_status(defender, &"freeze", 1.5)
		&"burn":
			_combat.apply_status(defender, &"burn", 3.0, attacker_burn_dps(skill))
		&"poison":
			_combat.apply_status(defender, &"poison", 4.0, attacker_burn_dps(skill))
		&"slow":
			_combat.apply_status(defender, &"slow", 2.0, 0.0, 0.4)


func attacker_burn_dps(skill: SkillData) -> float:
	return hero.attack * skill.skill_multiplier * 0.25


# --- Enemy turn ------------------------------------------------------------

func _enemies_act(delta: float) -> void:
	for e in enemies:
		if not e.is_alive() or e.is_frozen():
			continue
		var d := e.position.distance_to(hero.position)
		if d > e.attack_range:
			var step := e.move_speed * e.slow_factor() * delta
			e.position = e.position.move_toward(hero.position, step)
		else:
			e.attack_cooldown -= delta
			if e.attack_cooldown <= 0.0:
				var res := _combat.resolve_hit(e, hero, 1.0)
				hit_landed.emit(hero.id, float(res["damage"]), bool(res["is_crit"]), &"physical")
				e.attack_cooldown = e.attack_interval


# --- Status / deaths / end -------------------------------------------------

func _tick_all_statuses(delta: float) -> void:
	_combat.tick_statuses(hero, delta)
	for e in enemies:
		_combat.tick_statuses(e, delta)


func _cleanup_dead() -> void:
	var survivors: Array[CombatActor] = []
	for e in enemies:
		if e.is_alive():
			survivors.append(e)
		else:
			total_xp += e.xp_reward
			total_gold += e.gold_reward
			reward_gained.emit(e.xp_reward, e.gold_reward)
			actor_died.emit(e)
	enemies = survivors


func _check_end() -> void:
	if not hero.is_alive():
		state = STATE_LOST
		battle_lost.emit(layer)
		return
	if _spawned_first and _enemies_alive() == 0 and _wave_index + 1 >= _stage.waves.size():
		state = STATE_WON
		battle_won.emit(layer)


# --- Helpers ---------------------------------------------------------------

func _enemies_alive() -> int:
	var n := 0
	for e in enemies:
		if e.is_alive():
			n += 1
	return n


func _nearest_enemy() -> CombatActor:
	var best: CombatActor = null
	var best_d := INF
	for e in enemies:
		if not e.is_alive():
			continue
		var d := hero.position.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best


# --- Read-only accessors for the presentation layer (HUD) ------------------

func enemies_alive_count() -> int:
	return _enemies_alive()


func current_wave_index() -> int:
	return _wave_index


func total_waves() -> int:
	return _stage.waves.size() if _stage != null else 0


## [{id, name, remaining, cooldown}] for each active skill — feeds the skill bar.
func skill_status() -> Array:
	var out: Array = []
	for s in _skills.actives:
		out.append({"id": s.id, "name": s.display_name, "remaining": _skills.remaining(s.id), "cooldown": s.cooldown})
	return out


## Manually fire an active skill by id (M5 — tap a skill chip). Casts only if off cooldown
## and a target exists. Returns true if it fired.
func manual_cast(skill_id: StringName) -> bool:
	if state != STATE_RUNNING:
		return false
	var target := _nearest_enemy()
	if target == null:
		return false
	for s in _skills.actives:
		if s.id == skill_id and _skills.is_ready(s):
			_cast_skill(s, target)
			_skills.trigger(s)
			return true
	return false
