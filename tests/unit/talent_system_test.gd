extends "res://tests/test_case.gd"
## Unit tests for TalentSystem (GDD §5) — incl. the M3 PASS: an attack node raises damage
## and reset restores it. BLOCKING.

const TalentSystemScript := preload("res://src/talents/talent_system.gd")
const TalentNodeScript := preload("res://src/types/talent_node.gd")


func _node(id: StringName, stat: StringName, val: float, max_rank: int = 1, cost: int = 1, requires: Array = [], pct: bool = false) -> TalentNode:
	var n := TalentNode.new()
	n.id = id
	n.stat = stat
	n.value_per_rank = val
	n.max_rank = max_rank
	n.cost_per_rank = cost
	n.is_percent = pct
	var reqs: Array[StringName] = []
	for r in requires:
		reqs.append(r)
	n.requires = reqs
	return n


func _sys(points: int = 9) -> TalentSystem:
	var ts := TalentSystemScript.new()
	ts.setup([
		_node(&"might", &"attack", 10.0, 3),
		_node(&"edge", &"crit_rate", 0.03, 1, 1, [&"might"]),
		_node(&"vigor", &"hp", 0.1, 1, 2, [], true),
	], points)
	return ts


func test_spend_raises_rank_and_consumes_points() -> void:
	var ts := _sys(5)
	assert_true(ts.spend(&"might"))
	assert_eq(ts.rank(&"might"), 1)
	assert_eq(ts.available_points, 4)


func test_prereq_blocks_until_met() -> void:
	var ts := _sys(5)
	assert_true(not ts.can_spend(&"edge"), "edge needs might rank >= 1")
	ts.spend(&"might")
	assert_true(ts.can_spend(&"edge"))


func test_max_rank_caps() -> void:
	var ts := _sys(9)
	ts.spend(&"might")
	ts.spend(&"might")
	ts.spend(&"might")
	assert_eq(ts.rank(&"might"), 3)
	assert_true(not ts.can_spend(&"might"), "capped at max_rank 3")


func test_apply_flat_and_percent() -> void:
	var ts := _sys(9)
	ts.spend(&"might")
	ts.spend(&"might")   # +20 attack
	ts.spend(&"vigor")   # +10% hp
	var s := HeroStats.new()
	s.attack = 45.0
	s.hp = 600.0
	ts.apply(s)
	assert_almost(s.attack, 65.0)
	assert_almost(s.hp, 660.0)


func test_reset_refunds_all_points() -> void:
	var ts := _sys(5)
	ts.spend(&"might")
	ts.spend(&"might")
	assert_eq(ts.available_points, 3)
	ts.reset()
	assert_eq(ts.available_points, 5)
	assert_eq(ts.rank(&"might"), 0)


func test_attack_node_raises_damage_then_reset_restores() -> void:
	var ts := _sys(5)
	var s0 := HeroStats.new()
	s0.attack = 45.0
	ts.apply(s0)
	assert_almost(s0.attack, 45.0, 0.0001, "no points spent -> unchanged")
	ts.spend(&"might")
	var s1 := HeroStats.new()
	s1.attack = 45.0
	ts.apply(s1)
	assert_almost(s1.attack, 55.0, 0.0001, "attack node adds +10")
	ts.reset()
	var s2 := HeroStats.new()
	s2.attack = 45.0
	ts.apply(s2)
	assert_almost(s2.attack, 45.0, 0.0001, "reset restores")
