class_name Item
extends RefCounted
## Runtime equipment instance (NOT config). Built by LootSystem and fully reproducible
## from `seed_value` (ADR-003). Serialized into the save file as a plain Dictionary.

var slot: StringName = &""
var quality: StringName = &"common"
var item_level: int = 1
var main_stat: StringName = &""
var main_value: float = 0.0
var affixes: Array[Dictionary] = []   # [{stat:StringName, value:float, is_percent:bool}]
var seed_value: int = 0


func power() -> float:
	return Formulas.item_power(item_level, quality)


func to_dict() -> Dictionary:
	return {
		"slot": String(slot),
		"quality": String(quality),
		"item_level": item_level,
		"main_stat": String(main_stat),
		"main_value": main_value,
		"affixes": affixes.duplicate(true),
		"seed_value": seed_value,
	}


static func from_dict(d: Dictionary) -> Item:
	var it := Item.new()
	it.slot = StringName(d.get("slot", ""))
	it.quality = StringName(d.get("quality", "common"))
	it.item_level = int(d.get("item_level", 1))
	it.main_stat = StringName(d.get("main_stat", ""))
	it.main_value = float(d.get("main_value", 0.0))
	it.seed_value = int(d.get("seed_value", 0))
	it.affixes.clear()
	for a in d.get("affixes", []):
		it.affixes.append(a)
	return it
