extends "res://tests/test_case.gd"
## Unit tests for EquipmentSystem (GDD §4) — the M2 PASS at logic level:
## equipping changes final stats; compare previews without mutating. BLOCKING.

const EquipmentSystemScript := preload("res://src/equipment/equipment_system.gd")
const ItemScript := preload("res://src/types/item.gd")


func _base() -> HeroStats:
	var s := HeroStats.new()
	s.attack = 45.0
	s.hp = 600.0
	s.armor = 12.0
	s.crit_rate = 0.12
	s.crit_damage = 0.6
	s.attack_speed = 1.3
	return s


func _item(slot: StringName, main_stat: StringName, main_value: float, affixes: Array = []) -> Item:
	var it := Item.new()
	it.slot = slot
	it.quality = &"rare"
	it.item_level = 5
	it.main_stat = main_stat
	it.main_value = main_value
	for a in affixes:
		it.affixes.append(a)
	return it


func test_equip_changes_stats() -> void:
	var eq := EquipmentSystemScript.new()
	var before := eq.recompute(_base())
	var sword := _item(&"weapon", &"attack", 30.0)
	eq.add_to_inventory(sword)
	eq.equip(sword)
	var after := eq.recompute(_base())
	assert_almost(after.attack, before.attack + 30.0)
	assert_true(after.power() > before.power(), "power must rise after equipping")


func test_equip_swaps_old_back_to_inventory() -> void:
	var eq := EquipmentSystemScript.new()
	var s1 := _item(&"weapon", &"attack", 20.0)
	var s2 := _item(&"weapon", &"attack", 40.0)
	eq.add_to_inventory(s1)
	eq.add_to_inventory(s2)
	eq.equip(s1)
	eq.equip(s2)
	assert_eq(eq.equipped[&"weapon"], s2)
	assert_true(eq.inventory.has(s1), "swapped-out item returns to inventory")
	assert_true(not eq.inventory.has(s2), "equipped item leaves inventory")


func test_main_and_affixes_apply() -> void:
	var eq := EquipmentSystemScript.new()
	var helm := _item(&"helm", &"hp", 100.0, [
		{"stat": &"armor", "value": 10.0, "is_percent": false},
		{"stat": &"crit_rate", "value": 0.05, "is_percent": false},
	])
	eq.add_to_inventory(helm)
	eq.equip(helm)
	var after := eq.recompute(_base())
	assert_almost(after.hp, 700.0)
	assert_almost(after.armor, 22.0)
	assert_almost(after.crit_rate, 0.17)


func test_compare_is_non_mutating() -> void:
	var eq := EquipmentSystemScript.new()
	var sword := _item(&"weapon", &"attack", 30.0)
	var cmp := eq.compare(sword, _base())
	var before: HeroStats = cmp["before"]
	var after: HeroStats = cmp["after"]
	assert_almost(after.attack - before.attack, 30.0)
	assert_true(not eq.equipped.has(&"weapon"), "compare must not actually equip")
