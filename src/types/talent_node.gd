class_name TalentNode
extends Resource
## Config schema for a Path of Cinders talent node (GDD §5). Under src/data/talents/.

@export var id: StringName = &""
@export var display_name: String = ""
@export_enum("attack", "hp", "crit", "cooldown", "elemental") var category: String = "attack"
@export var stat: StringName = &""
@export var value_per_rank: float = 0.0
@export var is_percent: bool = false
@export var max_rank: int = 1
@export var cost_per_rank: int = 1
@export var requires: Array[StringName] = []        # prerequisite node ids
@export var grid_pos: Vector2i = Vector2i.ZERO       # layout position in the tree panel
