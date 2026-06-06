extends "res://tests/test_case.gd"
## Integration: the M2 loop end-to-end — roll a drop (LootSystem) → equip it
## (EquipmentSystem) → final stats/power rise. This is the M2 PASS at logic level
## ("equipping changes the next fight's numbers").

const LootSystemScript := preload("res://src/loot/loot_system.gd")
const EquipmentSystemScript := preload("res://src/equipment/equipment_system.gd")
const AffixDataScript := preload("res://src/types/affix_data.gd")


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


func _base() -> HeroStats:
	var s := HeroStats.new()
	s.attack = 45.0
	s.hp = 600.0
	s.armor = 12.0
	s.attack_speed = 1.3
	return s


func test_loot_then_equip_raises_power() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var loot: LootSystem = LootSystemScript.new(rng)
	var eq: EquipmentSystem = EquipmentSystemScript.new()
	var base := _base()

	var before := eq.recompute(base).power()
	var item := loot.roll_drop(true, 10, {&"legendary": 1.0}, _pool())  # boss-grade legendary
	assert_true(item != null and item.main_value > 0.0, "drop should have a positive main stat")
	eq.add_to_inventory(item)
	eq.equip(item)
	var after := eq.recompute(base).power()

	assert_true(after > before, "equipping a dropped item must raise power (%.1f -> %.1f)" % [before, after])
	assert_eq(eq.inventory.size(), 0, "equipped item leaves the bag")
