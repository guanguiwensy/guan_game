class_name LootSystem
extends RefCounted
## Rolls equipment drops (GDD §4/§7). Fully seeded (ADR-003) so a drop reproduces from
## its RNG. Builds an Item: slot, quality (weighted by layer), itemLevel, main stat, and
## distinct affixes whose count scales with quality and whose values scale by qualityMultiplier.

var rng: RandomNumberGenerator

const SLOTS: Array[StringName] = [&"weapon", &"helm", &"chest", &"gloves", &"boots", &"amulet"]

# Slot → main stat (GDD §4). chest is resolved per-item (hp or armor) from the item seed.
const SLOT_MAIN := {
	&"weapon": &"attack",
	&"helm": &"hp",
	&"chest": &"hp",
	&"gloves": &"attack_speed",
	&"boots": &"armor",
	&"amulet": &"elemental_damage",
}

# Main-stat coefficient: main_value = itemPower * coeff. TUNABLE (economy-designer owns).
const MAIN_COEFF := {
	&"attack": 3.0,
	&"hp": 12.0,
	&"armor": 2.0,
	&"attack_speed": 0.02,
	&"crit_rate": 0.01,
	&"crit_damage": 0.03,
	&"elemental_damage": 2.0,
}

const AFFIX_COUNT := {&"common": 0, &"magic": 1, &"rare": 2, &"epic": 3, &"legendary": 4}

const NORMAL_DROP_CHANCE := 0.35


func _init(rng_stream: RandomNumberGenerator = null) -> void:
	rng = rng_stream if rng_stream != null else RandomNumberGenerator.new()


## Roll-with-chance: bosses always drop; normal kills drop at `chance`. Returns Item or null.
func maybe_drop(is_boss: bool, drop_level: int, quality_weights: Dictionary, affix_pool: Array, chance: float = NORMAL_DROP_CHANCE) -> Item:
	if not is_boss and rng.randf() >= chance:
		return null
	return roll_drop(is_boss, drop_level, quality_weights, affix_pool)


func roll_drop(is_boss: bool, drop_level: int, quality_weights: Dictionary, affix_pool: Array) -> Item:
	var item := Item.new()
	item.seed_value = rng.randi()
	item.slot = SLOTS[rng.randi_range(0, SLOTS.size() - 1)]
	item.quality = _roll_quality(quality_weights, is_boss)
	item.item_level = drop_level

	var ip := Formulas.item_power(drop_level, item.quality)
	var main: StringName = SLOT_MAIN[item.slot]
	if item.slot == &"chest":
		main = &"hp" if (item.seed_value % 2 == 0) else &"armor"
	item.main_stat = main
	item.main_value = ip * float(MAIN_COEFF.get(main, 1.0))

	var qmult := Formulas.quality_multiplier(item.quality)
	var n := int(AFFIX_COUNT.get(item.quality, 0))
	var pool := affix_pool.duplicate()   # distinct affixes per item (no stat repeats)
	for i in n:
		if pool.is_empty():
			break
		var idx := rng.randi_range(0, pool.size() - 1)
		var aff: AffixData = pool[idx]
		pool.remove_at(idx)
		var value := rng.randf_range(aff.min_value, aff.max_value) * qmult
		item.affixes.append({"stat": aff.stat, "value": value, "is_percent": aff.is_percent})
	return item


func _roll_quality(weights: Dictionary, is_boss: bool) -> StringName:
	var keys: Array = [&"common", &"magic", &"rare", &"epic", &"legendary"]
	if is_boss:
		keys = [&"epic", &"legendary"]   # boss loot is gated epic+
	var total := 0.0
	for k in keys:
		total += float(weights.get(k, 0.0))
	if total <= 0.0:
		return keys[0]
	var r := rng.randf() * total
	var acc := 0.0
	for k in keys:
		acc += float(weights.get(k, 0.0))
		if r <= acc:
			return k
	return keys[keys.size() - 1]
