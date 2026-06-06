class_name EnemyData
extends Resource
## Config schema for an enemy archetype (GDD §3). Per-layer scaling via Formulas.enemy_*.

@export var id: StringName = &""
@export var display_name: String = ""
@export var base_hp: float = 10.0
@export var base_attack: float = 1.0
@export var base_armor: float = 0.0
@export var move_speed: float = 80.0          # px/sec
@export var attack_interval: float = 1.0      # seconds between enemy attacks
@export var xp_reward: int = 0
@export var gold_reward: int = 0
@export var is_boss: bool = false
@export var sprite_key: String = ""           # art lookup key (placeholder in MVP)
