class_name TalentSystem
extends RefCounted
## Path of Cinders (GDD §5). Tracks node ranks + available points, enforces prerequisites
## and max ranks, applies node bonuses to HeroStats (flat then percent), and refunds on
## reset. Pure logic — the single source of talent stat mods feeding Player.current_stats().

var defs: Dictionary = {}          # StringName -> TalentNode
var ranks: Dictionary = {}         # StringName -> int
var available_points: int = 0


func setup(nodes: Array, points: int) -> void:
	defs.clear()
	ranks.clear()
	for n in nodes:
		defs[n.id] = n
		ranks[n.id] = 0
	available_points = points


func rank(id: StringName) -> int:
	return int(ranks.get(id, 0))


func can_spend(id: StringName) -> bool:
	var node: TalentNode = defs.get(id)
	if node == null:
		return false
	if rank(id) >= node.max_rank:
		return false
	if available_points < node.cost_per_rank:
		return false
	for req in node.requires:
		if rank(req) < 1:
			return false
	return true


func spend(id: StringName) -> bool:
	if not can_spend(id):
		return false
	var node: TalentNode = defs[id]
	ranks[id] = rank(id) + 1
	available_points -= node.cost_per_rank
	return true


func reset() -> void:
	var refund := 0
	for id in ranks:
		var node: TalentNode = defs[id]
		refund += rank(id) * node.cost_per_rank
		ranks[id] = 0
	available_points += refund


func grant_points(n: int) -> void:
	available_points += n


func spent_points() -> int:
	var t := 0
	for id in ranks:
		t += rank(id) * int(defs[id].cost_per_rank)
	return t


## Applies all lit nodes to `s`: flat bonuses first, then percent bonuses (multiplicative).
func apply(s: HeroStats) -> void:
	var flat: Dictionary = {}
	var pct: Dictionary = {}
	for id in ranks:
		var r := rank(id)
		if r <= 0:
			continue
		var node: TalentNode = defs[id]
		var amt := node.value_per_rank * r
		if node.is_percent:
			pct[node.stat] = float(pct.get(node.stat, 0.0)) + amt
		else:
			flat[node.stat] = float(flat.get(node.stat, 0.0)) + amt
	for stat in flat:
		_add(s, stat, float(flat[stat]))
	for stat in pct:
		_mult(s, stat, float(pct[stat]))


func _add(s: HeroStats, stat: StringName, v: float) -> void:
	match stat:
		&"attack": s.attack += v
		&"hp": s.hp += v
		&"armor": s.armor += v
		&"crit_rate": s.crit_rate += v
		&"crit_damage": s.crit_damage += v
		&"attack_speed": s.attack_speed += v
		&"elemental_damage": s.elemental_damage += v


func _mult(s: HeroStats, stat: StringName, p: float) -> void:
	match stat:
		&"attack": s.attack *= (1.0 + p)
		&"hp": s.hp *= (1.0 + p)
		&"armor": s.armor *= (1.0 + p)
		&"crit_rate": s.crit_rate *= (1.0 + p)
		&"crit_damage": s.crit_damage *= (1.0 + p)
		&"attack_speed": s.attack_speed *= (1.0 + p)
		&"elemental_damage": s.elemental_damage *= (1.0 + p)


# --- Save serialization (M4). load_from_dict assumes setup() already ran. ---

func to_dict() -> Dictionary:
	var r: Dictionary = {}
	for id in ranks:
		if int(ranks[id]) > 0:
			r[String(id)] = int(ranks[id])
	return {"ranks": r, "available_points": available_points}


func load_from_dict(d: Dictionary) -> void:
	for id in ranks.keys():
		ranks[id] = 0
	var r: Dictionary = d.get("ranks", {})
	for id in r:
		ranks[StringName(id)] = int(r[id])
	available_points = int(d.get("available_points", available_points))
