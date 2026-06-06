class_name StatusEffect
extends RefCounted
## A live status effect on a CombatActor (GDD §1). burn/poison deal DoT; freeze stuns;
## slow reduces movement. Created/refreshed by CombatSystem.apply_status.

var kind: StringName = &""          # &"burn" / &"poison" / &"freeze" / &"slow"
var remaining: float = 0.0          # seconds left
var dps: float = 0.0                # damage/sec for burn & poison
var magnitude: float = 0.0          # slow: fraction of speed removed (0..1)
var element: StringName = &"physical"
