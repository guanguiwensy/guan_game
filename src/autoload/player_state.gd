extends Node
## Persistent player profile (autoload `Player`). Base hero stats + equipment + talents +
## run progress. Final combat stats = base + equipment + talents via current_stats().
## M2: equipment. M3: talents + leveling. M4 will serialize this to the save file.

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
	reset()


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
