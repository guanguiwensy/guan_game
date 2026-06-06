extends Node
## Persistent player profile (autoload `Player`). Holds base hero stats, the EquipmentSystem
## (equipped + inventory), and run progress. M2: lives in memory; M4 serializes it to save.
## Final combat stats = base + equipment (+ talents in M3) via current_stats().

var base_stats: HeroStats
var equipment: EquipmentSystem
var gold: int = 0
var xp: int = 0
var level: int = 1
var max_layer_cleared: int = 0


func _ready() -> void:
	reset()


func reset() -> void:
	base_stats = _make_base()
	equipment = EquipmentSystem.new()
	gold = 0
	xp = 0
	level = 1
	max_layer_cleared = 0


func current_stats() -> HeroStats:
	return equipment.recompute(base_stats)


func add_loot(item: Item) -> void:
	equipment.add_to_inventory(item)


func equip(item: Item) -> void:
	equipment.equip(item)


func add_rewards(xp_amount: int, gold_amount: int) -> void:
	xp += xp_amount
	gold += gold_amount


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
