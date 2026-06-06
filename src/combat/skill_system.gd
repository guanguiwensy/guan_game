class_name SkillSystem
extends RefCounted
## Tracks the hero's active-skill cooldowns and auto-cast ordering (GDD §2). Pure logic.

var actives: Array[SkillData] = []      # non-auto skills, sorted by auto_cast_priority
var auto_skill: SkillData = null         # the auto-attack (ember_swing)
var _cooldowns: Dictionary = {}          # StringName -> remaining seconds


func setup(all_skills: Array) -> void:
	actives.clear()
	_cooldowns.clear()
	auto_skill = null
	for s in all_skills:
		if s.is_auto_attack:
			auto_skill = s
		else:
			actives.append(s)
			_cooldowns[s.id] = 0.0
	actives.sort_custom(func(a: SkillData, b: SkillData) -> bool:
		return a.auto_cast_priority < b.auto_cast_priority)


func update(delta: float) -> void:
	for id in _cooldowns:
		_cooldowns[id] = maxf(0.0, float(_cooldowns[id]) - delta)


func is_ready(skill: SkillData) -> bool:
	return float(_cooldowns.get(skill.id, 0.0)) <= 0.0


func ready_skills() -> Array[SkillData]:
	var out: Array[SkillData] = []
	for s in actives:
		if is_ready(s):
			out.append(s)
	return out


func trigger(skill: SkillData) -> void:
	_cooldowns[skill.id] = skill.cooldown


func remaining(skill_id: StringName) -> float:
	return float(_cooldowns.get(skill_id, 0.0))
