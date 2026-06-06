extends Node
## Persistent player profile (autoload `Player`). Base hero stats + equipment + talents +
## run progress. Final combat stats = base + equipment + talents via current_stats().
## M4: loads from user://save.json on boot and saves on demand (survives app/browser refresh).

const TALENT_POINTS_PER_LEVEL := 1
const STARTING_TALENT_POINTS := 5

var base_stats: HeroStats
var equipment: EquipmentSystem
var talents: TalentSystem
var gold: int = 0
var xp: int = 0
var level: int = 1
var max_layer_cleared: int = 0


func _ready() -> void:
	var data: Dictionary = SaveSystem.load_game() if SaveSystem.has_save() else {}
	if data.is_empty():
		reset()
	else:
		load_from_dict(data)


func reset() -> void:
	base_stats = _make_base()
	equipment = EquipmentSystem.new()
	talents = TalentSystem.new()
	talents.setup(GameData.talents.values(), STARTING_TALENT_POINTS)
	gold = 0
	xp = 0
	level = 1
	max_layer_cleared = 0


func current_stats() -> HeroStats:
	var s := equipment.recompute(base_stats)
	talents.apply(s)
	return s


func add_loot(item: Item) -> void:
	equipment.add_to_inventory(item)


func equip(item: Item) -> void:
	equipment.equip(item)


## Grants xp/gold and processes any level-ups (each grants talent points).
func add_rewards(xp_amount: int, gold_amount: int) -> void:
	gold += gold_amount
	xp += xp_amount
	while xp >= Formulas.xp_to_next(level):
		xp -= Formulas.xp_to_next(level)
		level += 1
		talents.grant_points(TALENT_POINTS_PER_LEVEL)


# --- Save (M4) -------------------------------------------------------------

func save() -> void:
	SaveSystem.save_game(to_dict())


func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"xp": xp,
		"level": level,
		"max_layer_cleared": max_layer_cleared,
		"equipment": equipment.to_dict(),
		"talents": talents.to_dict(),
		"rng_seed": Rng.master_seed,
	}


func load_from_dict(d: Dictionary) -> void:
	base_stats = _make_base()
	equipment = EquipmentSystem.new()
	equipment.load_from_dict(d.get("equipment", {}))
	talents = TalentSystem.new()
	talents.setup(GameData.talents.values(), 0)
	talents.load_from_dict(d.get("talents", {}))
	gold = int(d.get("gold", 0))
	xp = int(d.get("xp", 0))
	level = int(d.get("level", 1))
	max_layer_cleared = int(d.get("max_layer_cleared", 0))
	if d.has("rng_seed"):
		Rng.reseed(int(d["rng_seed"]))


func _make_base() -> HeroStats:
	var s := HeroStats.new()
	s.attack = 45.0
	s.hp = 600.0
	s.armor = 12.0
	s.crit_rate = 0.12
	s.crit_damage = 0.6
	s.attack_speed = 1.3
	s.elemental_damage = 0.0
	return s
