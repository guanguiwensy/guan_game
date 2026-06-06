class_name AffixData
extends Resource
## Config schema for an equipment affix (GDD §4). Authored under src/data/affixes/.

@export var id: StringName = &""
@export var stat: StringName = &""            # hp/attack/armor/crit_rate/crit_damage/attack_speed/cooldown/elemental_damage
@export var min_value: float = 0.0
@export var max_value: float = 0.0
@export var is_percent: bool = false
@export var allowed_slots: Array[StringName] = []   # empty = any slot
