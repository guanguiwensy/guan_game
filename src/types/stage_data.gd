class_name StageData
extends Resource
## Config schema for a layer/stage (GDD §6). Authored as .tres under src/data/stages/.

@export var layer: int = 1
@export var waves: Array[Dictionary] = []           # each wave: {enemy_id: count, ...}
@export var wave_gap: float = 1.5                    # seconds between waves
@export var gold_reward: int = 0
@export var xp_reward: int = 0
@export var drop_level: int = 1                      # feeds itemLevel of drops
@export var drop_quality_weights: Dictionary = {}    # quality -> weight
@export var is_boss_layer: bool = false
