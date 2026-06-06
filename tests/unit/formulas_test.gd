extends "res://tests/test_case.gd"
## Unit tests for the authoritative formulas (source §8). BLOCKING per coding standards.

const F := preload("res://src/util/formulas.gd")


func test_final_damage_no_crit_no_armor() -> void:
	# attack 100 * mult 2.0, no crit, no armor → 200
	assert_almost(F.final_damage(100.0, 2.0, false, 0.5, 0.0), 200.0)


func test_final_damage_with_crit() -> void:
	# crit_damage 0.5 → x1.5 → 300
	assert_almost(F.final_damage(100.0, 2.0, true, 0.5, 0.0), 300.0)


func test_armor_reduction_half_at_100() -> void:
	# 100 / (100 + 100) = 0.5
	assert_almost(F.armor_reduction(100.0), 0.5)


func test_final_damage_with_armor() -> void:
	# 200 base * (1 - 0.5) = 100
	assert_almost(F.final_damage(100.0, 2.0, false, 0.0, 100.0), 100.0)


func test_power_attack_only() -> void:
	# attack 10 * 3 = 30, all else 0
	assert_almost(F.power(10, 0, 0, 0, 0, 0, 0), 30.0)


func test_enemy_hp_layer10() -> void:
	# 100 * (1 + 10*0.18) = 280
	assert_almost(F.enemy_hp(100.0, 10), 280.0)


func test_enemy_attack_layer10() -> void:
	# 100 * (1 + 10*0.12) = 220
	assert_almost(F.enemy_attack(100.0, 10), 220.0)


func test_enemy_armor_layer5() -> void:
	# 100 * (1 + 5*0.08) = 140
	assert_almost(F.enemy_armor(100.0, 5), 140.0)


func test_quality_multiplier_epic() -> void:
	assert_almost(F.quality_multiplier(&"epic"), 2.1)


func test_quality_multiplier_unknown_defaults_one() -> void:
	assert_almost(F.quality_multiplier(&"bogus"), 1.0)


func test_item_power_epic_l10() -> void:
	# 10 * 2.1 = 21
	assert_almost(F.item_power(10, &"epic"), 21.0)


func test_xp_to_next_level1() -> void:
	# round(50 * 1^1.6) = 50
	assert_eq(F.xp_to_next(1), 50)
