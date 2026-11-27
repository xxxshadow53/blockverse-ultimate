extends Node

## Tüm GDScript dosyalarını otoload'lar yüklü iken ayrıştırır.
func _ready() -> void:
	var files: Array[String] = []
	_collect("res://scripts", files)
	var failed := 0
	for path in files:
		var res := ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
		if res == null:
			failed += 1
			printerr("YÜKLEME HATASI: ", path)
	print("DOĞRLANAN GDSCRIPT: %d, HATA: %d" % [files.size(), failed])
	get_tree().quit(1 if failed > 0 else 0)

func _collect(path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		if file.ends_with(".gd"):
			out.append(path.path_join(file))
	for sub in dir.get_directories():
		_collect(path.path_join(sub), out)
