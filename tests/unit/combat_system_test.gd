extends "res://tests/test_case.gd"
## Unit tests for CombatSystem damage + status (GDD §1). BLOCKING.

const CombatSystemScript := preload("res://src/combat/combat_system.gd")


func _actor(hp: float, atk: float, armor: float = 0.0, crit: float = 0.0, critdmg: float = 0.0) -> CombatActor:
	var a := CombatActor.new()
	a.max_hp = hp
	a.hp = hp
	a.attack = atk
	a.armor = armor
	a.crit_rate = crit
	a.crit_damage = critdmg
	return a


func _cs() -> CombatSystem:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return CombatSystemScript.new(rng)


func test_resolve_hit_no_crit_no_armor() -> void:
	var cs := _cs()
	var atk := _actor(100, 50, 0, 0.0)
	var def := _actor(1000, 0, 0)
	var res := cs.resolve_hit(atk, def, 2.0)   # 50 * 2 = 100
	assert_almost(res["damage"], 100.0)
	assert_true(not res["is_crit"], "crit_rate 0 must never crit")
	assert_almost(def.hp, 900.0)


func test_resolve_hit_with_armor() -> void:
	var cs := _cs()
	var atk := _actor(100, 50, 0, 0.0)
	var def := _actor(1000, 0, 100)            # armor 100 → -50%
	var res := cs.resolve_hit(atk, def, 2.0)   # 100 * 0.5 = 50
	assert_almost(res["damage"], 50.0)


func test_resolve_hit_always_crit() -> void:
	var cs := _cs()
	var atk := _actor(100, 50, 0, 1.0, 0.5)    # always crit, x1.5
	var def := _actor(1000, 0, 0)
	var res := cs.resolve_hit(atk, def, 2.0)   # 100 * 1.5 = 150
	assert_true(res["is_crit"], "crit_rate 1 must crit")
	assert_almost(res["damage"], 150.0)


func test_burn_dot_ticks_and_expires() -> void:
	var cs := _cs()
	var t := _actor(100, 0, 0)
	cs.apply_status(t, &"burn", 1.0, 10.0)     # 10 dps for 1s
	cs.tick_statuses(t, 0.5)                    # -5 → 95, 0.5 left
	assert_almost(t.hp, 95.0)
	cs.tick_statuses(t, 0.6)                    # -6 → 89, then expires
	assert_almost(t.hp, 89.0)
	assert_eq(t.statuses.size(), 0)


func test_freeze_applies_and_expires() -> void:
	var cs := _cs()
	var t := _actor(100, 0, 0)
	cs.apply_status(t, &"freeze", 1.0)
	assert_true(t.is_frozen())
	cs.tick_statuses(t, 1.1)
	assert_true(not t.is_frozen())


func test_status_refresh_does_not_stack_duplicates() -> void:
	var cs := _cs()
	var t := _actor(100, 0, 0)
	cs.apply_status(t, &"freeze", 1.0)
	cs.apply_status(t, &"freeze", 2.0)
	assert_eq(t.statuses.size(), 1, "same kind refreshes, not stacks")
