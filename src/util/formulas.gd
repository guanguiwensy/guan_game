class_name Formulas
extends RefCounted
## Authoritative gameplay formulas (source spec §8).
## Pure, static, stateless — the single home for all combat/progression math.
## Unit-tested in tests/unit/formulas_test.gd.

# --- Damage pipeline -------------------------------------------------------

static func base_damage(attack: float, skill_multiplier: float) -> float:
	return attack * skill_multiplier


static func crit_multiplier(is_crit: bool, crit_damage: float) -> float:
	return (1.0 + crit_damage) if is_crit else 1.0


static func armor_reduction(enemy_armor: float) -> float:
	return enemy_armor / (enemy_armor + 100.0)


static func final_damage(attack: float, skill_multiplier: float, is_crit: bool, crit_damage: float, enemy_armor: float) -> float:
	return base_damage(attack, skill_multiplier) * crit_multiplier(is_crit, crit_damage) * (1.0 - armor_reduction(enemy_armor))


# --- Power rating (player-facing 战力) -------------------------------------

static func power(attack: float, hp: float, armor: float, crit_rate: float, crit_damage: float, attack_speed: float, elemental_damage: float) -> float:
	return attack * 3.0 + hp * 0.3 + armor * 2.0 + crit_rate * 100.0 + crit_damage * 50.0 + attack_speed * 80.0 + elemental_damage * 2.0


# --- Enemy growth by layer (stage_level 1..10) -----------------------------

static func enemy_hp(base_hp: float, stage_level: int) -> float:
	return base_hp * (1.0 + stage_level * 0.18)


static func enemy_attack(base_attack: float, stage_level: int) -> float:
	return base_attack * (1.0 + stage_level * 0.12)


static func enemy_armor(base_armor: float, stage_level: int) -> float:
	return base_armor * (1.0 + stage_level * 0.08)


# --- Equipment -------------------------------------------------------------

static func quality_multiplier(quality: StringName) -> float:
	match quality:
		&"common": return 1.0
		&"magic": return 1.25
		&"rare": return 1.6
		&"epic": return 2.1
		&"legendary": return 2.8
	return 1.0


static func item_power(item_level: int, quality: StringName) -> float:
	return item_level * quality_multiplier(quality)


# --- Progression -----------------------------------------------------------

## EXP needed to advance from `level` to `level + 1`. Starter curve (GDD §7, tunable).
static func xp_to_next(level: int) -> int:
	return int(round(50.0 * pow(float(level), 1.6)))
