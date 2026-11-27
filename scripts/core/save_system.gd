extends Node

## Dünya değişiklikleri chunk başına, oyuncu durumu slot başına kaydedilir.
const ROOT := "user://worlds"

func world_dir(seed: int) -> String:
	return "%s/w_%d" % [ROOT, seed]

func _ensure(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func chunk_path(seed: int, cx: int, cz: int) -> String:
	return "%s/c_%d_%d.dat" % [world_dir(seed), cx, cz]

func save_chunk(seed: int, cx: int, cz: int, edits: Dictionary) -> void:
	if edits.is_empty():
		return
	_ensure(world_dir(seed))
	var f := FileAccess.open(chunk_path(seed, cx, cz), FileAccess.WRITE)
	if f == null:
		push_warning("Chunk kaydedilemedi: %s" % chunk_path(seed, cx, cz))
		return
	f.store_var(edits, true)
	f.close()

func load_chunk(seed: int, cx: int, cz: int) -> Dictionary:
	var path := chunk_path(seed, cx, cz)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = f.get_var(true)
	f.close()
	if v is Dictionary:
		return v
	return {}

func player_path(slot: int) -> String:
	return "%s/player_%d.json" % [ROOT, slot]

func save_player(slot: int, payload: Dictionary) -> void:
	_ensure(ROOT)
	var f := FileAccess.open(player_path(slot), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()

func load_player(slot: int) -> Dictionary:
	var path := player_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(player_path(slot))

func list_worlds() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var d := DirAccess.open(ROOT)
	if d == null:
		return out
	for entry in d.get_directories():
		if not entry.begins_with("w_"):
			continue
		var seed_str := entry.substr(2)
		var seed := seed_str.to_int()
		var payload := load_player(0)
		var name := String(payload.get("world_name", "Dünya %d" % seed))
		if int(payload.get("seed", -999)) != seed:
			name = "Dünya %d" % seed
		out.append({"seed": seed, "name": name, "path": entry})
	return out

func delete_world(seed: int) -> void:
	var d := DirAccess.open(world_dir(seed))
	if d == null:
		return
	for file in d.get_files():
		d.remove(file)
	d.erase_contents_absolute(ProjectSettings.globalize_path(world_dir(seed)))

func format_time(t: float) -> String:
	var minutes := int(t) / 60
	var hours := int(t) / 3600
	return "%02d:%02d" % [hours % 24, minutes % 60]
