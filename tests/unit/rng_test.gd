extends "res://tests/test_case.gd"
## Determinism tests for seeded RNG (ADR-003). Asserts same seed → same sequence.

func test_same_seed_same_sequence() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 12345
	b.seed = 12345
	for i in 8:
		assert_almost(a.randf(), b.randf(), 0.0, "value %d must match" % i)


func test_different_seed_diverges() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 1
	b.seed = 999
	var diverged := false
	for i in 8:
		if not is_equal_approx(a.randf(), b.randf()):
			diverged = true
	assert_true(diverged, "different seeds should produce different sequences")


func test_derived_stream_seeds_are_stable() -> void:
	# Same master + stream name must hash to the same seed every time (reproducibility).
	var s1 := hash("%d::%s" % [42, "loot"])
	var s2 := hash("%d::%s" % [42, "loot"])
	assert_eq(s1, s2)
