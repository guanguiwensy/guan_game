extends SceneTree
## Zero-dependency headless test runner (M0 bootstrap, auto-discovering).
## Run:  godot --headless --path . --script tests/run_tests.gd
## Discovers every *_test.gd under tests/unit and tests/integration, runs each test_*
## method, and exits 1 if any assertion failed (so CI gates on it). No GDUnit4 addon.

func _initialize() -> void:
	var total := 0
	var failed := 0
	for suite_script in _discover():
		var suite: Variant = suite_script.new()
		for method in suite.get_method_list():
			var m := String(method["name"])
			if not m.begins_with("test_"):
				continue
			total += 1
			suite.assert_failures.clear()
			suite.call(m)
			if suite.assert_failures.is_empty():
				print("  PASS  ", m)
			else:
				failed += 1
				print("  FAIL  ", m)
				for msg in suite.assert_failures:
					print("        ", msg)
	print("\n%d tests run, %d failed." % [total, failed])
	quit(1 if failed > 0 else 0)


func _discover() -> Array:
	var out: Array = []
	for dir in ["res://tests/unit", "res://tests/integration"]:
		if not DirAccess.dir_exists_absolute(dir):
			continue
		var files := DirAccess.get_files_at(dir)
		files.sort()
		for f in files:
			if f.ends_with("_test.gd"):
				out.append(load(dir.path_join(f)))
	return out
