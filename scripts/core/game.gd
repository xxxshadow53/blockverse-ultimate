class_name Game
extends Node3D

## Oyun oturumu: dünya, oyuncu, AI, çevre, HUD, kayıt ve duraklatma.
signal world_ready
signal exit_requested

var world_seed: int = 20261127
var world_name: String = "Yeni Dünya"
var character_index: int = 0
var load_existing := false
var world: VoxelWorld
var player: Player
var environment: WorldEnvironmentController
var hud: HUD
var controls: MobileControls
var enemies: Array[Enemy] = []
var pickups: Array[Node3D] = []
var pause_layer: CanvasLayer
var inventory_layer: CanvasLayer
var settings_layer: CanvasLayer
var overlay_layer: CanvasLayer
var paused := false
var inventory_open := false
var game_over := false
var started := false
var _spawn_timer := 2.0
var _save_timer := 55.0
var _fps_smooth := 60.0
var _frame_timer := 0.0
var _frames := 0
var _quest := "Görev: Çevreyi keşfet ve kaynak topla"
var _mined := 0
var _kills := 0

func begin(world_data: Dictionary) -> void:
	world_seed = int(world_data.get("seed", 20261127))
	world_name = String(world_data.get("name", "Yeni Dünya"))
	character_index = int(world_data.get("character", 0))
	load_existing = bool(world_data.get("continue", false))
	GameSettings.set_v("seed", world_seed)
	GameSettings.set_v("world_name", world_name)
	GameSettings.set_v("last_character", character_index)
	GameSettings.save_settings()
	_build()

func _build() -> void:
	environment = WorldEnvironmentController.new()
	add_child(environment)
	environment.setup()
	world = VoxelWorld.new()
	world.name = "VoxelWorld"
	add_child(world)
	world.setup(world_seed, int(GameSettings.get_v("render_distance", 5)))
	world.ensure_spawn_chunk()
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.setup(self, world, character_index)
	world.player = player
	player.set_physics_process(false)
	var saved := SaveSystem.load_player(0)
	environment.set_weather("clear")
	hud = HUD.new()
	add_child(hud)
	controls = MobileControls.new()
	add_child(controls)
	controls.setup(player)
	_build_pause()
	_build_inventory()
	_build_settings()
	_build_overlay()
	player.set_active(true)
	AudioLibrary.play_music()
	AudioLibrary.play_ambient(true, true, false)
	await get_tree().process_frame
	var waited := 0
	while world.get_chunk(0, 0) == null and waited < 30:
		await get_tree().process_frame
		waited += 1
	if not load_existing or saved.is_empty() or int(saved.get("seed", -1)) != world_seed:
		player.global_position = world.find_spawn()
	else:
		player.restore(saved)
		environment.time_of_day = float(saved.get("time", environment.time_of_day))
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	started = true
	world_ready.emit()
	if load_existing:
		hud.toast("Dünya yüklendi: " + world_name)
	else:
		hud.toast("BLOCKVERSE'e hoş geldin!")

func _process(delta: float) -> void:
	if not started or player == null:
		return
	_frame_timer += delta
	_frames += 1
	if _frame_timer >= 0.5:
		_fps_smooth = float(_frames) / _frame_timer
		_frame_timer = 0.0
		_frames = 0
		if bool(GameSettings.get_v("dynamic_resolution", true)):
			_apply_dynamic_resolution(_fps_smooth)
	if not paused and not inventory_open and not game_over:
		environment.follow(player.global_position)
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = 9.0 if OS.get_name() == "Android" else 3.2
			_try_spawn()
		_save_timer -= delta
		if _save_timer <= 0.0:
			_save_timer = 60.0
			save_game()
	_update_quest()
	hud.tick(delta, player, world, environment, _fps_smooth, _quest)

func _apply_dynamic_resolution(fps: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var vp := tree.root
	var target := clampf(float(GameSettings.p("res", 0.85)), 0.5, 1.0)
	var current := vp.scaling_3d_scale
	if fps < 24.0 and current > 0.55:
		vp.scaling_3d_scale = maxf(0.55, current - 0.05)
	elif fps > 45.0 and current < target:
		vp.scaling_3d_scale = minf(target, current + 0.03)

func _update_quest() -> void:
	if _kills >= 5 and _mined < 20:
		_quest = "Görev: 5 yaratık yenildi ✓ | 20 blok kaz"
	elif _mined >= 20 and _kills >= 5:
		_quest = "Görev tamamlandı! Yeni bölgeler keşfet"
	else:
		_quest = "Görev: %d/20 blok kaz, %d/5 yaratık yen" % [_mined, mini(_kills, 5)]

func _try_spawn() -> void:
	if player == null:
		return
	var max_enemies := int(GameSettings.p("ai", 5))
	if enemies.size() >= max_enemies:
		return
	var dir := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var dist := randf_range(18.0, 32.0)
	var pos := player.global_position + dir * dist
	var types := EnemyDefs.demo_indices()
	var index: int = types[randi() % types.size()]
	var y := _find_surface(pos)
	if y < 0:
		return
	var enemy := Enemy.new()
	add_child(enemy)
	enemy.global_position = Vector3(pos.x, float(y) + 1.0, pos.z)
	enemy.setup(index, self, world, player)
	enemies.append(enemy)

func _find_surface(pos: Vector3) -> int:
	var gx := int(floor(pos.x))
	var gz := int(floor(pos.z))
	for y in range(100, 2, -1):
		var id := world.get_block(gx, y, gz)
		if BlockDefs.is_solid(id) and id != BlockDefs.WATER:
			if world.get_block(gx, y + 1, gz) == BlockDefs.AIR:
				return y
	return -1

func spawn_projectile(origin: Vector3, dir: Vector3, kind: String, dmg: float, hostile: bool = false) -> void:
	var p := Projectile.new()
	add_child(p)
	p.setup(self, world, origin, dir, kind, dmg, hostile)

func check_projectile_hit(p: Projectile) -> void:
	for e in enemies:
		if e == null or e.dead:
			continue
		if p.global_position.distance_to(e.global_position + Vector3(0, 1.0, 0)) < 1.1:
			var status := "fire" if p.kind == "fire" else ("ice" if p.kind == "ice" else "")
			e.take_damage(p.damage, status)
			p._explode()
			return

func melee_attack(origin: Vector3, dir: Vector3, range: float, dmg: float) -> void:
	var status := ""
	var ability := String(CharacterDefs.get_def(character_index).get("ability", ""))
	if ability == "fire":
		status = "fire"
	elif ability == "ice":
		status = "ice"
	for e in enemies:
		if e == null or e.dead:
			continue
		var to := e.global_position + Vector3(0, 1, 0) - origin
		if to.length() <= range and to.normalized().dot(dir.normalized()) > 0.15:
			e.take_damage(dmg, status)

func radial_damage(center: Vector3, radius: float, dmg: float) -> void:
	for e in enemies:
		if e != null and not e.dead and e.global_position.distance_to(center) <= radius:
			e.take_damage(dmg, "fire")

func on_enemy_died(e: Enemy) -> void:
	_kills += 1
	var xp := float(e.type_def.get("xp", 8))
	player.gain_xp(xp)
	var drop := BlockDefs.COAL_ORE if e.type_index == 0 else BlockDefs.IRON_ORE
	if player.inventory.add(drop, 1) != 0:
		spawn_pickup(e.global_position, drop)
	spawn_pickup(e.global_position + Vector3(0, 0.5, 0), BlockDefs.FLOWER, Color(1, 0.7, 0.2), 10)

func spawn_pickup(pos: Vector3, id: int, color: Color = Color.WHITE, count: int = 1) -> void:
	var color_use := color
	if color == Color.WHITE:
		color_use = BlockDefs.color_of(id)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_use
	mat.emission_enabled = true
	mat.emission = color_use
	mat.emission_energy_multiplier = 1.6
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.16, 0.16, 0.16) * (1.0 + float(count) * 0.02)
	mesh.mesh = box
	mesh.material_override = mat
	add_child(mesh)
	mesh.global_position = pos
	pickups.append(mesh)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh, "global_position:y", pos.y + 1.1, 0.5)
	tween.tween_property(mesh, "scale", Vector3.ZERO, 0.65).set_delay(0.12)
	tween.chain().tween_callback(func():
		pickups.erase(mesh)
		mesh.queue_free())

func notify_block_mined() -> void:
	_mined += 1

func save_game() -> void:
	if player == null:
		return
	var payload := player.to_dict()
	payload["seed"] = world_seed
	payload["world_name"] = world_name
	payload["time"] = environment.time_of_day
	payload["version"] = 1
	SaveSystem.save_player(0, payload)
	world.save_all()

func player_died() -> void:
	game_over = true
	player.set_active(false)
	overlay_layer.visible = true
	AudioLibrary.play_sfx("death", 0.8)

func toggle_pause() -> void:
	if game_over:
		return
	paused = not paused
	pause_layer.visible = paused
	player.set_active(not paused)
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_inventory() -> void:
	if game_over:
		return
	inventory_open = not inventory_open
	inventory_layer.visible = inventory_open
	player.set_active(not inventory_open)
	_refresh_inventory()

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.035, 0.05, 0.10, 0.94)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.35, 0.62, 0.92, 0.6)
	return sb

func _make_panel(parent: CanvasLayer, title: String, w: float, h: float) -> Panel:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	parent.add_child(dim)
	var p := Panel.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -w * 0.5
	p.offset_right = w * 0.5
	p.offset_top = -h * 0.5
	p.offset_bottom = h * 0.5
	p.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(p)
	var l := Label.new()
	l.text = title
	l.set_anchors_preset(Control.PRESET_TOP_LEFT)
	l.offset_left = 28
	l.offset_top = 18
	l.offset_right = w - 28
	l.offset_bottom = 60
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color(0.45, 0.88, 1.0))
	p.add_child(l)
	return p

func _menu_button(parent: Node, text: String, y: float, callback: Callable, x: float = 40, width: float = 320) -> Button:
	var b := Button.new()
	b.text = text
	b.set_anchors_preset(Control.PRESET_TOP_LEFT)
	b.offset_left = x
	b.offset_top = y
	b.offset_right = x + width
	b.offset_bottom = y + 52
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.18, 0.30, 0.9)
	sb.set_corner_radius_all(10)
	sb.border_color = Color(0.35, 0.7, 1.0, 0.5)
	sb.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _build_pause() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 40
	pause_layer.visible = false
	add_child(pause_layer)
	var p := _make_panel(pause_layer, "DURAKLATILDI", 480, 430)
	_menu_button(p, "Devam Et", 90, func(): toggle_pause())
	_menu_button(p, "Envanter / Üretim", 152, func(): toggle_inventory())
	_menu_button(p, "Ayarlar", 214, func(): settings_layer.visible = true)
	_menu_button(p, "Kaydet", 276, Callable(self, "_save_and_toast"))
	_menu_button(p, "Kaydet ve Ana Menü", 338, func(): save_game(); exit_requested.emit())

func _build_inventory() -> void:
	inventory_layer = CanvasLayer.new()
	inventory_layer.layer = 42
	inventory_layer.visible = false
	add_child(inventory_layer)
	inv_panel = _make_panel(inventory_layer, "ENVANTER VE ÜRETİM", 760, 540)
	inv_slots_label = Label.new()
	inv_slots_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	inv_slots_label.offset_left = 40
	inv_slots_label.offset_top = 80
	inv_slots_label.offset_right = 380
	inv_slots_label.offset_bottom = 480
	inv_slots_label.add_theme_font_size_override("font_size", 17)
	inv_panel.add_child(inv_slots_label)
	var craft_label := Label.new()
	craft_label.text = "ÜRETİM TARİFLERİ"
	craft_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	craft_label.offset_left = 400
	craft_label.offset_top = 80
	craft_label.offset_right = 740
	craft_label.offset_bottom = 110
	craft_label.add_theme_font_size_override("font_size", 19)
	craft_label.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	inv_panel.add_child(craft_label)
	for i in range(Inventory.RECIPES.size()):
		var recipe: Dictionary = Inventory.RECIPES[i]
		_menu_button(inv_panel, "Üret: " + String(recipe["name"]), 118 + i * 56, Callable(self, "_craft").bind(i), 400, 320)
	_menu_button(inv_panel, "Kapat", 470, func(): toggle_inventory(), 400, 320)

var inv_panel: Panel
var inv_slots_label: Label

func _refresh_inventory() -> void:
	if inv_slots_label == null or player == null:
		return
	var lines: Array[String] = []
	for i in range(player.inventory.slots.size()):
		var s: Dictionary = player.inventory.slots[i]
		lines.append("%d) %s  x%d" % [i + 1, BlockDefs.name_of(int(s["id"])), int(s["count"])])
	inv_slots_label.text = "\n".join(lines)

func _save_and_toast() -> void:
	save_game()
	if hud:
		hud.toast("Dünya kaydedildi")

func _craft(index: int) -> void:
	var recipe: Dictionary = Inventory.RECIPES[index]
	if player.inventory.craft(recipe):
		AudioLibrary.play_sfx("pickup", 0.6)
		hud.toast("Üretildi: " + String(recipe["name"]))
	else:
		hud.toast("Malzeme yetersiz")
	_refresh_inventory()

func _build_settings() -> void:
	settings_layer = CanvasLayer.new()
	settings_layer.layer = 44
	settings_layer.visible = false
	add_child(settings_layer)
	var p := _make_panel(settings_layer, "AYARLAR", 560, 480)
	_add_slider(p, "Kamera hassasiyeti", 88, "camera_sensitivity", 0.1, 1.5)
	_add_slider(p, "Müzik sesi", 154, "music_volume", 0.0, 1.0)
	_add_slider(p, "Efekt sesi", 220, "sfx_volume", 0.0, 1.0)
	_menu_button(p, "Grafik profili: " + String(GameSettings.get_v("profile", "Otomatik")), 290, func(): _cycle_profile())
	_menu_button(p, "Titreşim: " + ("Açık" if bool(GameSettings.get_v("vibration", true)) else "Kapalı"), 352, func(): _toggle_vibration())
	_menu_button(p, "Kapat", 414, func(): settings_layer.visible = false)

func _add_slider(parent: Node, text: String, y: float, key: String, min_v: float, max_v: float) -> void:
	var l := Label.new()
	l.text = text
	l.set_anchors_preset(Control.PRESET_TOP_LEFT)
	l.offset_left = 40
	l.offset_top = y
	l.offset_right = 180
	l.offset_bottom = y + 30
	parent.add_child(l)
	var s := HSlider.new()
	s.set_anchors_preset(Control.PRESET_TOP_LEFT)
	s.offset_left = 190
	s.offset_top = y
	s.offset_right = 500
	s.offset_bottom = y + 32
	s.min_value = min_v
	s.max_value = max_v
	s.step = 0.05
	s.value = float(GameSettings.get_v(key, min_v))
	s.value_changed.connect(func(v): GameSettings.set_v(key, v); GameSettings.save_settings(); AudioLibrary.set_volumes())
	parent.add_child(s)

func _cycle_profile() -> void:
	var current := String(GameSettings.get_v("profile", "Otomatik"))
	var idx := (GameSettings.PROFILES.find(current) + 1) % GameSettings.PROFILES.size()
	GameSettings.set_profile(GameSettings.PROFILES[idx])
	settings_layer.visible = false
	hud.toast("Profil: " + GameSettings.active_profile + " (sonraki oyunda tam etkin)")

func _toggle_vibration() -> void:
	GameSettings.set_v("vibration", not bool(GameSettings.get_v("vibration", true)))
	GameSettings.save_settings()

func _build_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 50
	overlay_layer.visible = false
	add_child(overlay_layer)
	var p := _make_panel(overlay_layer, "OYUN BİTTİ", 460, 320)
	_menu_button(p, "Son kayıttan yeniden dene", 90, func(): _restart())
	_menu_button(p, "Ana Menüye Dön", 160, func(): exit_requested.emit())

func _restart() -> void:
	get_tree().reload_current_scene()

func vibrate(ms: int = 40) -> void:
	if bool(GameSettings.get_v("vibration", true)):
		Input.vibrate_handheld(ms)
