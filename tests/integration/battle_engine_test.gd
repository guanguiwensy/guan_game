extends "res://tests/test_case.gd"
## Integration: drive a full headless battle through BattleEngine and assert the M1 PASS
## criterion at the logic level — boss death → victory; hero death → defeat (progression
## is structurally intact because BattleEngine never touches persistent state).

const BattleEngineScript := preload("res://src/combat/battle_engine.gd")


func _rng(s: int = 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _hero(atk: float, hp: float, aspd: float, rng_range: float) -> CombatActor:
	var h := CombatActor.new()
	h.attack = atk
	h.max_hp = hp
	h.hp = hp
	h.attack_speed = aspd
	h.attack_range = rng_range
	h.crit_rate = 0.0
	return h


func _auto_skill() -> SkillData:
	var s := SkillData.new()
	s.id = &"ember_swing"
	s.is_auto_attack = true
	s.skill_multiplier = 1.0
	s.tag = "physical"
	s.target_mode = "single"
	return s


func _cleave() -> SkillData:
	var s := SkillData.new()
	s.id = &"cleaving_blow"
	s.skill_multiplier = 2.4
	s.cooldown = 4.0
	s.target_mode = "single"
	s.auto_cast_priority = 1
	s.tag = "physical"
	return s


func _enemy_data() -> Dictionary:
	var wisp := EnemyData.new()
	wisp.id = &"cinder_wisp"
	wisp.display_name = "Wisp"
	wisp.base_hp = 60
	wisp.base_attack = 8
	wisp.base_armor = 0
	wisp.move_speed = 140
	wisp.attack_interval = 1.0
	wisp.xp_reward = 5
	wisp.gold_reward = 3
	var boss := EnemyData.new()
	boss.id = &"lord_of_cinders"
	boss.display_name = "Boss"
	boss.base_hp = 1400
	boss.base_attack = 30
	boss.base_armor = 30
	boss.move_speed = 45
	boss.attack_interval = 1.5
	boss.is_boss = true
	boss.xp_reward = 100
	boss.gold_reward = 80
	return {&"cinder_wisp": wisp, &"lord_of_cinders": boss}


func _boss_stage() -> StageData:
	var s := StageData.new()
	s.layer = 10
	s.wave_gap = 0.1
	s.is_boss_layer = true
	s.waves = [{&"cinder_wisp": 2}, {&"lord_of_cinders": 1}]
	return s


func _run(engine: Variant, max_ticks: int = 5000, dt: float = 0.1) -> int:
	var i := 0
	while engine.state == BattleEngineScript.STATE_RUNNING and i < max_ticks:
		engine.tick(dt)
		i += 1
	return i


func test_strong_hero_clears_boss_layer_to_victory() -> void:
	var engine: Variant = BattleEngineScript.new()
	var won_layer := [-1]
	engine.battle_won.connect(func(l: int) -> void: won_layer[0] = l)
	engine.setup(_hero(400.0, 8000.0, 2.0, 260.0), _boss_stage(), _enemy_data(), [_auto_skill(), _cleave()], _rng(7))
	_run(engine)
	assert_eq(engine.state, BattleEngineScript.STATE_WON, "boss layer should end in victory")
	assert_eq(won_layer[0], 10, "battle_won emits the cleared layer")
	assert_true(engine.total_xp > 0, "kills should accrue xp")


func test_weak_hero_dies_to_defeat() -> void:
	var engine: Variant = BattleEngineScript.new()
	var lost := [false]
	engine.battle_lost.connect(func(_l: int) -> void: lost[0] = true)
	var stage := StageData.new()
	stage.layer = 10
	stage.wave_gap = 0.1
	stage.waves = [{&"cinder_wisp": 5}]
	engine.setup(_hero(3.0, 40.0, 1.0, 260.0), stage, _enemy_data(), [_auto_skill()], _rng(3))
	_run(engine)
	assert_eq(engine.state, BattleEngineScript.STATE_LOST, "overwhelmed hero should lose")
	assert_true(lost[0], "battle_lost should emit")
	assert_true(not engine.hero.is_alive(), "hero should be dead on defeat")
