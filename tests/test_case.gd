extends RefCounted
## Minimal zero-dependency test base (M0 bootstrap — no addon needed so CI is green
## immediately). GDUnit4 can be layered in once the toolchain is installed; test bodies
## port over with trivial changes. Test methods are named `test_*` and use these asserts.

var assert_failures: Array[String] = []


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		assert_failures.append("assert_eq: got %s, expected %s. %s" % [str(actual), str(expected), msg])


func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		assert_failures.append("assert_true failed. %s" % msg)


func assert_almost(actual: float, expected: float, eps: float = 0.0001, msg: String = "") -> void:
	if absf(actual - expected) > eps:
		assert_failures.append("assert_almost: got %f, expected %f (eps %f). %s" % [actual, expected, eps, msg])
