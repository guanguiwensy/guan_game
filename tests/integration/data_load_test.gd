extends "res://tests/test_case.gd"
## Integration: verify GameData loads the generated .tres config (ADR-001 pipeline).
## Requires tools/generate_data.gd to have produced src/data/{skills,enemies,stages}.

const GameDataScript := preload("res://src/autoload/game_data.gd")


func test_generated_config_loads() -> void:
	var gd: Variant = GameDataScript.new()
	gd.reload()
	assert_eq(gd.skills.size(), 4, "expected 4 skills")
	assert_eq(gd.enemies.size(), 4, "expected 4 enemies")
	assert_eq(gd.stages.size(), 10, "expected 10 stages")
	assert_eq(gd.affixes.size(), 7, "expected 7 affixes")

	var cleave: SkillData = gd.get_skill(&"cleaving_blow")
	assert_true(cleave != null, "cleaving_blow should load")
	if cleave != null:
		assert_almost(cleave.skill_multiplier, 2.4)

	var boss: EnemyData = gd.get_enemy(&"lord_of_cinders")
	assert_true(boss != null and boss.is_boss, "boss should load and be flagged")

	var layer10: StageData = gd.get_stage(10)
	assert_true(layer10 != null and layer10.is_boss_layer, "layer 10 should be a boss layer")

	gd.free()
