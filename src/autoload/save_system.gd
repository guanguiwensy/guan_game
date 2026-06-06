extends Node
## Save/load to user://save.json (save isolation principle). JSON so Web exports persist
## via the browser's IndexedDB-backed user:// — satisfies "refresh keeps progress" (M4).

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(data: Dictionary) -> bool:
	var payload := data.duplicate(true)
	payload["save_version"] = SAVE_VERSION
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot open %s for write (err %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	return true


func load_game() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveSystem: corrupt or empty save at %s" % SAVE_PATH)
		return {}
	return parsed


func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
