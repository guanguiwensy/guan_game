class_name EquipmentSystem
extends RefCounted
## Owns the player's equipped items + inventory and is the single source of truth for
## final hero stats (ADR-002): recompute(base) = base + equipped main stats + affixes
## (+ talent mods later, M3). Provides compare() for the swap-preview UI. Pure logic.

var equipped: Dictionary = {}      # StringName slot -> Item
var inventory: Array[Item] = []


func add_to_inventory(item: Item) -> void:
	inventory.append(item)


func equip(item: Item) -> void:
	var slot := item.slot
	inventory.erase(item)
	if equipped.has(slot):
		inventory.append(equipped[slot])
	equipped[slot] = item


func recompute(base: HeroStats) -> HeroStats:
	var s := base.duplicate_stats()
	for slot in equipped:
		_apply_item(s, equipped[slot])
	return s


## Returns {"before": HeroStats, "after": HeroStats} for previewing a swap. Non-mutating.
func compare(item: Item, base: HeroStats) -> Dictionary:
	var before := recompute(base)
	var prev: Item = equipped.get(item.slot)
	equipped[item.slot] = item
	var after := recompute(base)
	if prev != null:
		equipped[item.slot] = prev
	else:
		equipped.erase(item.slot)
	return {"before": before, "after": after}


func _apply_item(s: HeroStats, item: Item) -> void:
	_apply_stat(s, item.main_stat, item.main_value)
	for aff in item.affixes:
		_apply_stat(s, aff["stat"], float(aff["value"]))


func _apply_stat(s: HeroStats, stat: StringName, value: float) -> void:
	match stat:
		&"hp": s.hp += value
		&"attack": s.attack += value
		&"armor": s.armor += value
		&"crit_rate": s.crit_rate += value
		&"crit_damage": s.crit_damage += value
		&"attack_speed": s.attack_speed += value
		&"elemental_damage": s.elemental_damage += value
		# &"cooldown" — cooldown reduction wired in M3


# --- Save serialization (M4) ----------------------------------------------

func to_dict() -> Dictionary:
	var eq: Dictionary = {}
	for slot in equipped:
		eq[String(slot)] = (equipped[slot] as Item).to_dict()
	var inv: Array = []
	for it in inventory:
		inv.append(it.to_dict())
	return {"equipped": eq, "inventory": inv}


func load_from_dict(d: Dictionary) -> void:
	equipped.clear()
	inventory.clear()
	var eq: Dictionary = d.get("equipped", {})
	for slot in eq:
		equipped[StringName(slot)] = Item.from_dict(eq[slot])
	for raw in d.get("inventory", []):
		inventory.append(Item.from_dict(raw))
