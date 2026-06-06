extends "res://tests/test_case.gd"
## Unit tests for SkillSystem cooldowns + auto-cast ordering (GDD §2). BLOCKING.

const SkillSystemScript := preload("res://src/combat/skill_system.gd")


func _skill(id: StringName, cd: float, is_auto: bool = false, prio: int = 0) -> SkillData:
	var s := SkillData.new()
	s.id = id
	s.cooldown = cd
	s.is_auto_attack = is_auto
	s.auto_cast_priority = prio
	return s


func test_auto_skill_is_separated() -> void:
	var ss := SkillSystemScript.new()
	ss.setup([_skill(&"auto", 0.0, true), _skill(&"a", 4.0, false, 1)])
	assert_true(ss.auto_skill != null and ss.auto_skill.id == &"auto")
	assert_eq(ss.actives.size(), 1)


func test_cooldown_blocks_then_recovers() -> void:
	var ss := SkillSystemScript.new()
	var a := _skill(&"a", 4.0, false, 1)
	ss.setup([a])
	assert_true(ss.is_ready(a))
	ss.trigger(a)
	assert_true(not ss.is_ready(a))
	ss.update(3.9)
	assert_true(not ss.is_ready(a))
	ss.update(0.2)
	assert_true(ss.is_ready(a))


func test_ready_skills_in_priority_order() -> void:
	var ss := SkillSystemScript.new()
	ss.setup([_skill(&"c", 1.0, false, 3), _skill(&"a", 1.0, false, 1), _skill(&"b", 1.0, false, 2)])
	var ready := ss.ready_skills()
	assert_eq(ready.size(), 3)
	assert_eq(ready[0].id, &"a")
	assert_eq(ready[1].id, &"b")
	assert_eq(ready[2].id, &"c")
