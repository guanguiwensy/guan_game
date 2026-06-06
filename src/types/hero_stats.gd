class_name HeroStats
extends RefCounted
## Computed hero combat stats. Source of truth is EquipmentSystem.recompute_stats()
## (= base + equipment main+affixes + talent mods). See ADR-002.

var attack: float = 0.0
var hp: float = 0.0
var armor: float = 0.0
var crit_rate: float = 0.0      # 0..1
var crit_damage: float = 0.0    # bonus, e.g. 0.5 = +50%
var attack_speed: float = 1.0   # attacks per second
var elemental_damage: float = 0.0


func power() -> float:
	return Formulas.power(attack, hp, armor, crit_rate, crit_damage, attack_speed, elemental_damage)


func duplicate_stats() -> HeroStats:
	var s := HeroStats.new()
	s.attack = attack
	s.hp = hp
	s.armor = armor
	s.crit_rate = crit_rate
	s.crit_damage = crit_damage
	s.attack_speed = attack_speed
	s.elemental_damage = elemental_damage
	return s
