class_name CombatSystem
extends RefCounted
## Stateless-ish damage & status resolver. All math goes through Formulas; all randomness
## through the injected RNG stream (ADR-003). Operates on CombatActors — no UI deps.

var rng: RandomNumberGenerator


func _init(rng_stream: RandomNumberGenerator = null) -> void:
	rng = rng_stream if rng_stream != null else RandomNumberGenerator.new()


## Applies one hit from attacker to defender. Returns {"damage": float, "is_crit": bool}.
func resolve_hit(attacker: CombatActor, defender: CombatActor, skill_multiplier: float) -> Dictionary:
	var is_crit := rng.randf() < attacker.crit_rate
	var dmg := Formulas.final_damage(attacker.attack, skill_multiplier, is_crit, attacker.crit_damage, defender.armor)
	defender.hp -= dmg
	return {"damage": dmg, "is_crit": is_crit}


## Adds or refreshes a status on the target.
func apply_status(target: CombatActor, kind: StringName, duration: float, dps: float = 0.0, magnitude: float = 0.0, element: StringName = &"physical") -> void:
	for s in target.statuses:
		if s.kind == kind:
			s.remaining = maxf(s.remaining, duration)
			s.dps = maxf(s.dps, dps)
			s.magnitude = maxf(s.magnitude, magnitude)
			return
	var se := StatusEffect.new()
	se.kind = kind
	se.remaining = duration
	se.dps = dps
	se.magnitude = magnitude
	se.element = element
	target.statuses.append(se)


## Advances all statuses on an actor by delta: applies DoT, expires finished effects.
## Returns total DoT damage dealt this tick.
func tick_statuses(actor: CombatActor, delta: float) -> float:
	var dot_total := 0.0
	var kept: Array[StatusEffect] = []
	for s in actor.statuses:
		s.remaining -= delta
		if s.dps > 0.0:
			var d := s.dps * delta
			actor.hp -= d
			dot_total += d
		if s.remaining > 0.0:
			kept.append(s)
	actor.statuses = kept
	return dot_total
