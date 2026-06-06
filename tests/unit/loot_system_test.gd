extends "res://tests/test_case.gd"
## Unit tests for LootSystem rolls (GDD §4). Seeded → deterministic. BLOCKING.

const LootSystemScript := preload("res://src/loot/loot_system.gd")
const AffixDataScript := preload("res://src/types/affix_data.gd")


func _ls(seed_value: int = 1) -> LootSystem:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return LootSystemScript.new(r)


func _pool() -> Array:
	var defs := [[&"hp", 20.0, 60.0], [&"attack", 4.0, 12.0], [&"armor", 3.0, 10.0], [&"crit_rate", 0.02, 0.06], [&"attack_speed", 0.03, 0.10]]
	var pool: Array = []
	for d in defs:
		var a := AffixData.new()
		a.id = StringName("aff_" + String(d[0]))
		a.stat = d[0]
		a.min_value = d[1]
		a.max_value = d[2]
		pool.append(a)
	return pool


func _weights() -> Dictionary:
	return {&"common": 20.0, &"magic": 30.0, &"rare": 30.0, &"epic": 16.0, &"legendary": 4.0}


func test_drop_is_deterministic_for_same_seed() -> void:
	var a := _ls(42).roll_drop(false, 5, _weights(), _pool())
	var b := _ls(42).roll_drop(false, 5, _weights(), _pool())
	assert_eq(a.quality, b.quality)
	assert_eq(a.slot, b.slot)
	assert_almost(a.main_value, b.main_value)
	assert_eq(a.affixes.size(), b.affixes.size())


func test_boss_drop_is_epic_or_better() -> void:
	for s in range(1, 14):
		var it := _ls(s).roll_drop(true, 10, _weights(), _pool())
		assert_true(it.quality == &"epic" or it.quality == &"legendary", "boss drop must be epic+ (seed %d -> %s)" % [s, it.quality])


func test_affix_count_matches_quality() -> void:
	var rare_only := {&"rare": 1.0}
	var it := _ls(3).roll_drop(false, 5, rare_only, _pool())
	assert_eq(it.quality, &"rare")
	assert_eq(it.affixes.size(), 2, "rare grants 2 affixes")


func test_item_power_scales_with_quality() -> void:
	var c := _ls(5).roll_drop(false, 10, {&"common": 1.0}, _pool())
	var l := _ls(5).roll_drop(false, 10, {&"legendary": 1.0}, _pool())
	assert_true(l.power() > c.power(), "legendary itemPower must exceed common")


func test_no_duplicate_affix_stats() -> void:
	var it := _ls(7).roll_drop(false, 10, {&"legendary": 1.0}, _pool())  # 4 affixes, pool of 5
	assert_eq(it.affixes.size(), 4)
	var seen := {}
	for aff in it.affixes:
		assert_true(not seen.has(aff["stat"]), "affix stats must be distinct")
		seen[aff["stat"]] = true
