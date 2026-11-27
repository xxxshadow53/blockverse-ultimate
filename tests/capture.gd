extends Node

## Gerçek çalışan oyundan ekran görüntüsü alır (sahte görsel kullanılmaz).
const OUT_DIR := "res://screenshots"
var _saved := 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(4.0).timeout
	_capture("01_ana_menu.png")
	main._go_world_select()
	await get_tree().create_timer(0.4).timeout
	_capture("02_dunya_secimi.png")
	main._world_to_characters()
	await get_tree().create_timer(0.4).timeout
	_capture("03_karakter_secimi.png")
	main.pending_start = true
	main._start_game()
	await get_tree().create_timer(8.0).timeout
	_capture("04_oyun_ici.png")
	print("CAPTURE: ", _saved, "/4 ekran görüntüsü kaydedildi")
	get_tree().quit()

func _capture(name: String) -> void:
	var tex := get_viewport().get_texture()
	if tex == null:
		push_error("CAPTURE: viewport texture null -> " + name)
		return
	var img := tex.get_image()
	if img == null:
		push_error("CAPTURE: viewport image null -> " + name)
		return
	var path := ProjectSettings.globalize_path(OUT_DIR.path_join(name))
	var err := img.save_png(path)
	if err == OK:
		_saved += 1
	print("CAPTURE ", name, " -> ", path, " err=", err)
