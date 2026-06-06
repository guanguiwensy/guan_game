class_name CombatActor
extends RefCounted
## Pure combat state for one fighter (hero or enemy). No node/scene dependency, so the
## whole battle is simulatable headlessly (ADR-002). Entities (Hero/Enemy nodes) render it.

var id: int = 0
var display_name: String = ""
var is_hero: bool = false
var is_boss: bool = false

# stats
var max_hp: float = 1.0
var hp: float = 1.0
var attack: float = 0.0
var armor: float = 0.0
var crit_rate: float = 0.0          # 0..1
var crit_damage: float = 0.0        # bonus, e.g. 0.5 = +50%
var attack_speed: float = 1.0       # attacks/sec (hero)
var elemental_damage: float = 0.0

# movement / pacing
var move_speed: float = 0.0         # px/sec (enemies)
var attack_range: float = 70.0
var attack_interval: float = 1.0    # enemy basic-attack cadence
var attack_cooldown: float = 0.0    # time until next basic attack
var position: Vector2 = Vector2.ZERO

# rewards (enemies)
var xp_reward: int = 0
var gold_reward: int = 0

var statuses: Array[StatusEffect] = []


func is_alive() -> bool:
	return hp > 0.0


func is_frozen() -> bool:
	for s in statuses:
		if s.kind == &"freeze" and s.remaining > 0.0:
			return true
	return false


## Multiplier applied to movement from slow statuses (1.0 = full speed, floored at 0.1).
func slow_factor() -> float:
	var f := 1.0
	for s in statuses:
		if s.kind == &"slow" and s.remaining > 0.0:
			f = minf(f, 1.0 - s.magnitude)
	return maxf(f, 0.1)
