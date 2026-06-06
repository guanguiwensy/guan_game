extends Node
## Loads & caches config resources from src/data/ (ADR-001) and serves read-only
## lookups by id. M0: loader + lookup API ready; data resources authored per system in M1+.
## NOTE: directory scanning works in editor/debug. For exported builds, M1 may switch to
## an explicit manifest (DirAccess on res:// is unreliable once packed).

var skills: Dictionary = {}     # StringName -> SkillData
var enemies: Dictionary = {}    # StringName -> EnemyData
var affixes: Dictionary = {}    # StringName -> AffixData
var stages: Dictionary = {}     # int        -> StageData
var talents: Dictionary = {}    # StringName -> TalentNode


func _ready() -> void:
	reload()


func reload() -> void:
	skills = _load_by_key("res://src/data/skills", "id")
	enemies = _load_by_key("res://src/data/enemies", "id")
	affixes = _load_by_key("res://src/data/affixes", "id")
	talents = _load_by_key("res://src/data/talents", "id")
	stages = _load_by_key("res://src/data/stages", "layer")


func _load_by_key(path: String, key: String) -> Dictionary:
	var out: Dictionary = {}
	if not DirAccess.dir_exists_absolute(path):
		return out
	for file in DirAccess.get_files_at(path):
		if not file.ends_with(".tres"):
			continue
		var res := ResourceLoader.load(path.path_join(file))
		if res != null and key in res:
			out[res.get(key)] = res
	return out


func get_skill(id: StringName) -> SkillData:
	return skills.get(id) as SkillData


func get_enemy(id: StringName) -> EnemyData:
	return enemies.get(id) as EnemyData


func get_affix(id: StringName) -> AffixData:
	return affixes.get(id) as AffixData


func get_stage(layer: int) -> StageData:
	return stages.get(layer) as StageData


func get_talent(id: StringName) -> TalentNode:
	return talents.get(id) as TalentNode
