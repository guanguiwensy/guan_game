class_name SkillData
extends Resource
## Config schema for a skill (GDD §2). Authored as .tres under src/data/skills/.

@export var id: StringName = &""
@export var display_name: String = ""
@export_enum("physical", "fire", "ice", "lightning") var tag: String = "physical"
@export var skill_multiplier: float = 1.0
@export var cooldown: float = 0.0                 # seconds; 0 = auto-attack pacing
@export_enum("single", "aoe_around_hero", "aoe_at_target") var target_mode: String = "single"
@export var aoe_radius: float = 0.0               # px (0 for single-target)
@export var status: StringName = &""              # applied status id ("" = none)
@export var status_chance: float = 0.0            # 0..1
@export var is_auto_attack: bool = false
@export var auto_cast_priority: int = 0           # lower casts earlier
