extends "res://tests/test_case.gd"
## M4 — serialization round-trips for equipment, talents, and the save file (GDD §8).
## These are the logic behind "refresh keeps progress". BLOCKING.

const EquipmentSystemScript := preload("res://src/equipment/equipment_system.gd")
const TalentSystemScript := preload("res://src/talents/talent_system.gd")
const TalentNodeScript := preload("res://src/types/talent_node.gd")
const ItemScript := preload("res://src/types/item.gd")
const SaveSystemScript := preload("res://src/autoload/save_system.gd")


func _item(slot: StringName, main_stat: StringName, mv: float, affixes: Array = []) -> Item:
	var it := Item.new()
	it.slot = slot
	it.quality = &"epic"
	it.item_level = 7
	it.main_stat = main_stat
	it.main_value = mv
	it.seed_value = 1234
	for a in affixes:
		it.affixes.append(a)
	return it


func _node(id: StringName, stat: StringName, val: float, max_rank: int = 3) -> TalentNode:
	var n := TalentNode.new()
	n.id = id
	n.stat = stat
	n.value_per_rank = val
	n.max_rank = max_rank
	n.cost_per_rank = 1
	return n


func test_equipment_roundtrip() -> void:
	var eq := EquipmentSystemScript.new()
	var sword := _item(&"weapon", &"attack", 30.0, [{"stat": &"crit_rate", "value": 0.05, "is_percent": false}])
	eq.add_to_inventory(sword)
	eq.equip(sword)
	eq.add_to_inventory(_item(&"helm", &"hp", 100.0))

	var eq2 := EquipmentSystemScript.new()
	eq2.load_from_dict(eq.to_dict())
	assert_true(eq2.equipped.has(&"weapon"), "equipped weapon restored")
	assert_almost(eq2.equipped[&"weapon"].main_value, 30.0)
	assert_eq(eq2.equipped[&"weapon"].affixes.size(), 1)
	assert_eq(eq2.inventory.size(), 1)
	assert_eq(eq2.inventory[0].slot, &"helm")


func test_talent_roundtrip() -> void:
	var nodes := [_node(&"might", &"attack", 10.0, 3)]
	var ts := TalentSystemScript.new()
	ts.setup(nodes, 5)
	ts.spend(&"might")
	ts.spend(&"might")

	var ts2 := TalentSystemScript.new()
	ts2.setup(nodes, 0)
	ts2.load_from_dict(ts.to_dict())
	assert_eq(ts2.rank(&"might"), 2)
	assert_eq(ts2.available_points, 3)


func test_savesystem_file_roundtrip() -> void:
	var ss := SaveSystemScript.new()
	var data := {"level": 7, "nested": {"a": 1}, "list": [1, 2, 3]}
	assert_true(ss.save_game(data), "save should succeed")
	var loaded := ss.load_game()
	assert_eq(int(loaded["level"]), 7)
	assert_eq(int(loaded["nested"]["a"]), 1)
	assert_eq(int(loaded["list"][2]), 3)
	ss.clear_save()
