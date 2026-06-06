extends Node
## Single seeded RNG service (ADR-003). All gameplay randomness flows through here so
## results replay deterministically. Named sub-streams (e.g. &"combat", &"loot", &"affix")
## are derived from one master seed, keeping categories independent yet reproducible.
## NEVER call randomize() in gameplay code.

var master_seed: int = 1
var _streams: Dictionary = {}     # StringName -> RandomNumberGenerator


func _ready() -> void:
	reseed(master_seed)


func reseed(seed_value: int) -> void:
	master_seed = seed_value
	_streams.clear()


func stream(stream_name: StringName) -> RandomNumberGenerator:
	var existing := _streams.get(stream_name) as RandomNumberGenerator
	if existing != null:
		return existing
	var rng := RandomNumberGenerator.new()
	rng.seed = _derive_seed(master_seed, stream_name)
	_streams[stream_name] = rng
	return rng


func _derive_seed(base: int, stream_name: StringName) -> int:
	return hash("%d::%s" % [base, String(stream_name)])


func randf(stream_name: StringName) -> float:
	return stream(stream_name).randf()


func randf_range(stream_name: StringName, from: float, to: float) -> float:
	return stream(stream_name).randf_range(from, to)


func randi_range(stream_name: StringName, from: int, to: int) -> int:
	return stream(stream_name).randi_range(from, to)
