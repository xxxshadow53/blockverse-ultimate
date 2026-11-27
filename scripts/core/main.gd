extends Node

## Uygulama akışı: açılış, ana menü, karakter/dünya seçimi, ayarlar, yükleme ve oyun.
var ui: CanvasLayer
var screens: Dictionary = {}
var showcase: Node3D
var showcase_rig: CharacterRig
var showcase_camera: Camera3D
var preview_rig: CharacterRig
var preview_camera: Camera3D
var selected_character := 0
var pending_start := false
var current_game: Game
var _splash_tween: Tween
var _tip_labels: Array[Label] = []

func _ready() -> void:
	selected_character = clampi(int(GameSettings.get_v("last_character", 0)), 0, CharacterDefs.count() - 1)
	_build_showcase()
	_build_ui()
	show_screen("splash")
	await get_tree().create_timer(0.35).timeout
	_animate_splash()

func _build_showcase() -> void:
	showcase = Node3D.new()
	add_child(showcase)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.025, 0.035, 0.075)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.28, 0.34, 0.48)
	e.glow_enabled = false
	e.glow_intensity = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	showcase.add_child(env)
	var key := DirectionalLight3D.new()
	key.light_energy = 2.1
	key.light_color = Color(0.75, 0.85, 1.0)
	key.rotation = Vector3(deg_to_rad(-35), deg_to_rad(140), 0)
	showcase.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 2.6
	rim.light_color = Color(0.8, 0.25, 0.55)
	rim.rotation = Vector3(deg_to_rad(-10), deg_to_rad(-40), 0)
	showcase.add_child(rim)
	var pedestal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.6
	cyl.height = 0.24
	cyl.radial_segments = 48
	pedestal.mesh = cyl
	pedestal.position.y = -0.12
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.07, 0.10, 0.18)
	pm.metallic = 0.85
	pm.roughness = 0.22
	pedestal.material_override = pm
	showcase.add_child(pedestal)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.62
	torus.outer_radius = 1.70
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.1, 0.7, 1.0)
	rm.emission_enabled = true
	rm.emission = Color(0.1, 0.7, 1.0)
	rm.emission_energy_multiplier = 2.4
	ring.material_override = rm
	showcase.add_child(ring)
	showcase_rig = CharacterRig.new(CharacterDefs.get_def(selected_character), 1.0)
	showcase.add_child(showcase_rig)
	showcase_camera = Camera3D.new()
	showcase.add_child(showcase_camera)
	showcase_camera.position = Vector3(3.2, 2.3, 4.6)
	showcase_camera.look_at(Vector3(0, 1.0, 0))
	showcase_camera.make_current()

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 100
	add_child(ui)
	_splash()
	_menu()
	_character_select()
	_world_select()
	_settings()
	_loading()

func _screen(name: String) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	screens[name] = c
	ui.add_child(c)
	return c

func _bg(parent: Control, top: Color, bottom: Color) -> void:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = top
	parent.add_child(rect)
	var grad := ColorRect.new()
	grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad.anchor_top = 0.45
	grad.color = bottom
	parent.add_child(grad)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0.18)
	parent.add_child(vignette)

func _style(bg: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	return sb

func _label(parent: Node, text: String, x: float, y: float, w: float, h: float, size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.set_anchors_preset(Control.PRESET_TOP_LEFT)
	l.offset_left = x
	l.offset_top = y
	l.offset_right = x + w
	l.offset_bottom = y + h
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, x: float, y: float, w: float, h: float, callback: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.set_anchors_preset(Control.PRESET_TOP_LEFT)
	b.offset_left = x
	b.offset_top = y
	b.offset_right = x + w
	b.offset_bottom = y + h
	var bg := Color(0.06, 0.10, 0.20, 0.88) if not primary else Color(0.12, 0.35, 0.58, 0.95)
	var border := Color(0.30, 0.60, 0.90, 0.55) if not primary else Color(0.45, 0.90, 1.0, 0.9)
	b.add_theme_stylebox_override("normal", _style(bg, border))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.18), border.lightened(0.2)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.18, 0.50, 0.75, 0.95), Color.WHITE))
	b.add_theme_font_size_override("font_size", 21)
	b.pressed.connect(callback)
	b.pressed.connect(func(): AudioLibrary.play_sfx("menu", 0.5))
	parent.add_child(b)
	return b

func _splash() -> void:
	var s := _screen("splash")
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.015, 0.04)
	s.add_child(bg)
	var logo := Label.new()
	logo.name = "Logo"
	logo.text = "BLOCKVERSE"
	logo.set_anchors_preset(Control.PRESET_CENTER)
	logo.offset_left = -420
	logo.offset_right = 420
	logo.offset_top = -90
	logo.offset_bottom = 40
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 86)
	logo.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	s.add_child(logo)
	_label(s, "ULTIMATE EDITION  •  ANDROID VERTICAL SLICE", 0, 250, 1280, 40, 24, Color(0.95, 0.45, 0.55), HORIZONTAL_ALIGNMENT_CENTER).set_anchors_preset(Control.PRESET_CENTER)
	var bar := ProgressBar.new()
	bar.name = "Progress"
	bar.set_anchors_preset(Control.PRESET_CENTER)
	bar.offset_left = -220
	bar.offset_right = 220
	bar.offset_top = 90
	bar.offset_bottom = 104
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = 0
	bar.add_theme_stylebox_override("background", _style(Color(0.05, 0.08, 0.14, 1), Color(0.2, 0.4, 0.6, 0.5), 6))
	bar.add_theme_stylebox_override("fill", _style(Color(0.25, 0.75, 1.0), Color(0.5, 0.9, 1.0), 6))
	s.add_child(bar)

func _animate_splash() -> void:
	var s: Control = screens["splash"]
	var logo := s.get_node("Logo")
	var bar := s.get_node("Progress") as ProgressBar
	_splash_tween = create_tween()
	_splash_tween.tween_property(logo, "scale", Vector2(1.08, 1.08), 0.8).set_trans(Tween.TRANS_CUBIC)
	_splash_tween.parallel().tween_property(logo, "modulate:a", 1.0, 0.8)
	logo.modulate.a = 0.0
	_splash_tween.parallel().tween_property(bar, "value", 100.0, 1.9).set_trans(Tween.TRANS_SINE)
	_splash_tween.tween_interval(0.35)
	_splash_tween.tween_callback(func(): show_screen("menu"))

func _menu() -> void:
	var s := _screen("menu")
	_bg(s, Color(0.02, 0.03, 0.08, 0.35), Color(0.01, 0.01, 0.03, 0.72))
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 60
	panel.offset_top = 70
	panel.offset_right = 520
	panel.offset_bottom = 660
	panel.add_theme_stylebox_override("panel", _style(Color(0.02, 0.04, 0.10, 0.84), Color(0.3, 0.6, 0.95, 0.5), 20))
	s.add_child(panel)
	_label(panel, "BLOCKVERSE", 30, 20, 400, 70, 52, Color(0.55, 0.88, 1.0))
	_label(panel, "ULTIMATE EDITION", 32, 84, 400, 34, 22, Color(1, 0.45, 0.45))
	_label(panel, "Açık dünya • Madencilik • Macera", 32, 120, 400, 30, 17, Color(0.72, 0.82, 0.95))
	_button(panel, "YENİ OYUN", 30, 175, 400, 60, func(): _go_world_select(), true)
	_button(panel, "OYUNA DEVAM ET", 30, 248, 400, 60, func(): _continue_game())
	_button(panel, "KARAKTER SEÇİMİ", 30, 321, 400, 56, func(): _go_character_select(false))
	_button(panel, "DÜNYA SEÇİMİ", 30, 390, 400, 56, func(): _go_world_select())
	_button(panel, "GRAFİK AYARLARI", 30, 459, 190, 50, func(): _go_settings("graphics"))
	_button(panel, "SES AYARLARI", 230, 459, 200, 50, func(): _go_settings("audio"))
	_button(panel, "KONTROLLER", 30, 520, 190, 50, func(): _go_settings("controls"))
	_button(panel, "ÇIKIŞ", 230, 520, 200, 50, func(): get_tree().quit())
	_label(panel, "Godot 4.7.2 • Procedürel voksel dünya • v1.0 Demo", 30, 620, 420, 24, 13, Color(0.45, 0.55, 0.7))

func _character_select() -> void:
	var s := _screen("characters")
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.015, 0.02, 0.05, 0.86)
	s.add_child(bg)
	_label(s, "SAVAŞÇI SEÇİMİ", 60, 40, 600, 60, 44, Color(0.55, 0.88, 1.0))
	_label(s, "Her karakterin kendine özel modeli, silahı, yeteneği ve animasyonları vardır.", 62, 96, 900, 32, 18, Color(0.7, 0.8, 0.95))
	var container := SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	container.offset_left = 60
	container.offset_top = 145
	container.offset_right = 520
	container.offset_bottom = 620
	container.stretch = true
	s.add_child(container)
	var vp := SubViewport.new()
	vp.size = Vector2i(460, 475)
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	container.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.04, 0.05, 0.10)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.40, 0.55)
	e.glow_enabled = false
	env.environment = e
	vp.add_child(env)
	var light := DirectionalLight3D.new()
	light.light_energy = 2.4
	light.rotation = Vector3(deg_to_rad(-35), deg_to_rad(130), 0)
	vp.add_child(light)
	var light2 := DirectionalLight3D.new()
	light2.light_color = Color(0.4, 0.6, 1.0)
	light2.light_energy = 1.8
	light2.rotation = Vector3(deg_to_rad(-20), deg_to_rad(-60), 0)
	vp.add_child(light2)
	preview_rig = CharacterRig.new(CharacterDefs.get_def(selected_character), 1.0)
	vp.add_child(preview_rig)
	preview_camera = Camera3D.new()
	vp.add_child(preview_camera)
	preview_camera.position = Vector3(2.7, 1.8, 3.8)
	preview_camera.look_at(Vector3(0, 1.0, 0))
	preview_camera.make_current()
	for i in range(CharacterDefs.count()):
		var cdef := CharacterDefs.get_def(i)
		var b := _button(s, "%s  —  %s" % [cdef["id"], cdef["title"]], 560, 145 + i * 72, 640, 62, Callable(self, "_select_character").bind(i))
		b.add_theme_font_size_override("font_size", 20)
	_info_label = _label(s, "", 560, 590, 640, 110, 17, Color(0.82, 0.88, 0.98))
	_button(s, "GERİ", 60, 640, 200, 54, func(): _back_from_characters())
	_button(s, "SEÇ VE DEVAM ET", 850, 640, 350, 54, func(): _confirm_character(), true)

var _info_label: Label

func _select_character(index: int) -> void:
	selected_character = index
	if preview_rig:
		preview_rig.queue_free()
	var vp := preview_rig.get_parent() as SubViewport
	if vp:
		preview_rig = CharacterRig.new(CharacterDefs.get_def(index), 1.0)
		vp.add_child(preview_rig)
	if showcase_rig:
		showcase_rig.queue_free()
	showcase_rig = CharacterRig.new(CharacterDefs.get_def(index), 1.0)
	showcase.add_child(showcase_rig)
	GameSettings.set_v("last_character", index)
	GameSettings.save_settings()
	_refresh_character_info()
	AudioLibrary.play_sfx("menu", 0.7)

func _refresh_character_info() -> void:
	var cdef := CharacterDefs.get_def(selected_character)
	var ability_names := {"fire": "Alev topu", "ice": "Buz kristali", "stealth": "Görünmezlik", "shock": "Şok dalgası", "volley": "Ok yağmuru", "repair": "Onarım"}
	_info_label.text = String(cdef["desc"]) + "\nCan: %d   Enerji: %d   Hız: %.1f   Hasar: %d   Yetenek: %s" % [
		int(cdef["hp"]), int(cdef["energy"]), float(cdef["speed"]), int(cdef["damage"]), String(ability_names.get(cdef["ability"], "?"))]

func _back_from_characters() -> void:
	if pending_start:
		show_screen("worlds")
	else:
		show_screen("menu")

func _confirm_character() -> void:
	_refresh_character_info()
	if pending_start:
		_start_game()
	else:
		show_screen("menu")

func _world_select() -> void:
	var s := _screen("worlds")
	_bg(s, Color(0.02, 0.03, 0.08, 0.75), Color(0.01, 0.01, 0.03, 0.85))
	_label(s, "DÜNYA SEÇİMİ", 70, 50, 600, 60, 44, Color(0.55, 0.88, 1.0))
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 70
	panel.offset_top = 130
	panel.offset_right = 720
	panel.offset_bottom = 620
	panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.05, 0.11, 0.92), Color(0.3, 0.6, 0.95, 0.5), 18))
	s.add_child(panel)
	_label(panel, "Dünya adı", 30, 25, 200, 30, 20, Color.WHITE)
	_name_edit = LineEdit.new()
	_name_edit.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_name_edit.offset_left = 30
	_name_edit.offset_top = 60
	_name_edit.offset_right = 530
	_name_edit.offset_bottom = 100
	_name_edit.text = String(GameSettings.get_v("world_name", "Yeni Dünya"))
	panel.add_child(_name_edit)
	_label(panel, "Dünya tohumu (seed)", 30, 120, 240, 30, 20, Color.WHITE)
	_seed_edit = LineEdit.new()
	_seed_edit.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_seed_edit.offset_left = 30
	_seed_edit.offset_top = 155
	_seed_edit.offset_right = 300
	_seed_edit.offset_bottom = 195
	_seed_edit.text = str(int(GameSettings.get_v("seed", 20261127)))
	panel.add_child(_seed_edit)
	_button(panel, "Rastgele Tohum", 320, 155, 220, 40, func(): _seed_edit.text = str(randi_range(1, 999999999)))
	_button(panel, "KAYDETLİ DÜNYALAR", 30, 220, 520, 44, func(): _refresh_world_list())
	_world_list = Label.new()
	_world_list.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_world_list.offset_left = 30
	_world_list.offset_top = 275
	_world_list.offset_right = 530
	_world_list.offset_bottom = 440
	_world_list.add_theme_font_size_override("font_size", 17)
	panel.add_child(_world_list)
	_button(panel, "KARAKTER SEÇİMİNE GEÇ", 30, 440, 520, 54, func(): _world_to_characters(), true)
	_button(s, "GERİ", 70, 640, 200, 54, func(): show_screen("menu"))
	_refresh_world_list()

var _name_edit: LineEdit
var _seed_edit: LineEdit
var _world_list: Label

func _refresh_world_list() -> void:
	var worlds := SaveSystem.list_worlds()
	if worlds.is_empty():
		_world_list.text = "Kayıtlı dünya yok. Yeni bir dünya oluşturabilirsin."
	else:
		var lines: Array[String] = []
		for w in worlds:
			lines.append("• %s  (seed: %d)" % [String(w["name"]), int(w["seed"])])
		_world_list.text = "\n".join(lines)

func _world_to_characters() -> void:
	pending_start = true
	_refresh_character_info()
	show_screen("characters")

func _go_world_select() -> void:
	pending_start = true
	show_screen("worlds")

func _go_character_select(from_game: bool) -> void:
	pending_start = from_game
	_refresh_character_info()
	show_screen("characters")

func _continue_game() -> void:
	var saved := SaveSystem.load_player(0)
	if saved.is_empty():
		_toast_menu("Kayıt bulunamadı. Önce yeni oyun başlat.")
		return
	_start_game(int(saved.get("seed", 20261127)), true)

func _start_game(seed_override: int = -1, continued: bool = false) -> void:
	var seed_value := seed_override
	if seed_value < 0:
		var text := _seed_edit.text.strip_edges()
		seed_value = text.to_int() if text.is_valid_int() else 20261127
	var wname := _name_edit.text.strip_edges() if _name_edit else "Yeni Dünya"
	if wname.is_empty():
		wname = "Yeni Dünya"
	show_screen("loading")
	_animate_loading()
	await get_tree().process_frame
	current_game = Game.new()
	add_child(current_game)
	current_game.world_ready.connect(_on_world_ready)
	current_game.exit_requested.connect(_on_exit_requested)
	current_game.begin({"seed": seed_value, "name": wname, "character": selected_character, "continue": continued})

func _on_world_ready() -> void:
	var loading: Control = screens["loading"]
	var tween := create_tween()
	tween.tween_property(loading, "modulate:a", 0.0, 0.55)
	tween.tween_callback(func():
		loading.modulate.a = 1.0
		show_screen("none")
		showcase.visible = false)

func _on_exit_requested() -> void:
	if current_game:
		current_game.save_game()
		current_game.queue_free()
		current_game = null
	showcase.visible = true
	show_screen("menu")

func _toast_menu(text: String) -> void:
	var l := _label(screens["menu"], text, 560, 600, 600, 40, 20, Color(1, 0.5, 0.5))

func _settings() -> void:
	var s := _screen("settings")
	_bg(s, Color(0.02, 0.03, 0.08, 0.78), Color(0.01, 0.01, 0.03, 0.9))
	_label(s, "AYARLAR", 70, 50, 500, 60, 44, Color(0.55, 0.88, 1.0))
	_settings_content = _label(s, "", 70, 120, 900, 400, 21, Color(0.85, 0.9, 0.98))
	_button(s, "GERİ", 70, 640, 200, 54, func(): show_screen("menu"))

var _settings_content: Label
var _current_settings_tab := "graphics"

func _go_settings(tab: String) -> void:
	_current_settings_tab = tab
	var lines: Array[String] = []
	lines.append("Profil: %s (aktif: %s)" % [GameSettings.get_v("profile", "Otomatik"), GameSettings.active_profile])
	lines.append("Görüş mesafesi: %d chunk" % int(GameSettings.get_v("render_distance", 5)))
	lines.append("Kamera hassasiyeti: %.2f" % float(GameSettings.get_v("camera_sensitivity", 0.45)))
	lines.append("Müzik: %.0f%%   Efekt: %.0f%%   Ana: %.0f%%" % [float(GameSettings.get_v("music_volume", 0.55)) * 100, float(GameSettings.get_v("sfx_volume", 0.85)) * 100, float(GameSettings.get_v("master_volume", 0.8)) * 100])
	lines.append("Titreşim: %s   FPS göstergesi: %s" % ["Açık" if bool(GameSettings.get_v("vibration", true)) else "Kapalı", "Açık" if bool(GameSettings.get_v("fps_visible", true)) else "Kapalı"])
	lines.append("")
	lines.append("İpucu: Ayarlar oyun içinde Duraklat → Ayarlar menüsünden de değiştirilebilir.")
	_settings_content.text = "\n".join(lines)
	show_screen("settings")

func _loading() -> void:
	var s := _screen("loading")
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.015, 0.035)
	s.add_child(bg)
	_label(s, "DÜNYA OLUŞTURULUYOR", 0, -60, 1280, 70, 46, Color(0.55, 0.88, 1.0), HORIZONTAL_ALIGNMENT_CENTER).set_anchors_preset(Control.PRESET_CENTER)
	var tips := [
		"İpucu: Blok kırmak için Kır tuşunu, yerleştirmek için Koy tuşunu kullan.",
		"İpucu: INFERNO'nun alev topu düşmanları yakar.",
		"İpucu: Gece düşmanlar daha agresif hale gelir.",
		"İpucu: Tuğla ve tahtayı envanterden üretebilirsin.",
		"İpucu: Sağ ekranı kaydırarak kamerayı döndür."
	]
	var tip := Label.new()
	tip.set_anchors_preset(Control.PRESET_CENTER)
	tip.offset_left = -500
	tip.offset_right = 500
	tip.offset_top = 40
	tip.offset_bottom = 80
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.text = tips[randi() % tips.size()]
	tip.add_theme_font_size_override("font_size", 19)
	tip.add_theme_color_override("font_color", Color(0.8, 0.86, 0.96))
	s.add_child(tip)

func _animate_loading() -> void:
	var s: Control = screens["loading"]
	s.modulate.a = 1.0

func show_screen(name: String) -> void:
	for key in screens.keys():
		var c: Control = screens[key]
		c.visible = key == name
	if name == "characters":
		_refresh_character_info()

func _process(delta: float) -> void:
	if showcase and showcase.visible:
		showcase_rig.rotation.y -= delta * 0.35
	if preview_rig and preview_rig.visible and screens.get("characters") and (screens["characters"] as Control).visible:
		preview_rig.rotation.y -= delta * 0.55
	TextureFactory.process(delta)
