class_name HUD
extends CanvasLayer

## Oyun içi arayüz: can/enerji/deneyim, sıcak çubuk, mini harita, FPS, görev ve bildirimler.
var root: Control
var health_bar: ProgressBar
var energy_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var time_label: Label
var fps_label: Label
var weather_label: Label
var quest_label: Label
var toast_label: Label
var minimap: Minimap
var hotbar: HBoxContainer
var slot_panels: Array[Panel] = []
var slot_labels: Array[Label] = []
var _toast_time := 0.0
var _last_selected := -1

const SHORT := {
	BlockDefs.STONE: "TAŞ", BlockDefs.DIRT: "TOP", BlockDefs.COBBLESTONE: "KIR",
	BlockDefs.PLANK: "TAH", BlockDefs.TORCH: "MEŞ", BlockDefs.GLASS: "CAM",
	BlockDefs.SAND: "KUM", BlockDefs.LEAVES: "YAP", BlockDefs.CHEST: "SND",
	BlockDefs.GRASS: "ÇMN", BlockDefs.LOG: "KÜT", BlockDefs.BRICK: "TĞL",
	BlockDefs.PATH_STONE: "YOL", BlockDefs.SNOW: "KAR", BlockDefs.WATER: "SU"
}

func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_bars()
	_build_top()
	_build_hotbar()
	_build_crosshair()
	minimap = Minimap.new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -164
	minimap.offset_top = 18
	minimap.offset_right = -18
	minimap.offset_bottom = 164
	root.add_child(minimap)

func _fill_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	return sb

func _add_bar(x: float, y: float, width: float, height: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.offset_left = x
	bar.offset_top = y
	bar.offset_right = x + width
	bar.offset_bottom = y + height
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 100
	bar.add_theme_stylebox_override("background", _fill_style(Color(0.04, 0.06, 0.10, 0.78)))
	bar.add_theme_stylebox_override("fill", _fill_style(fill))
	root.add_child(bar)
	return bar

func _label(text: String, x: float, y: float, size: int = 16, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.set_anchors_preset(Control.PRESET_TOP_LEFT)
	l.offset_left = x
	l.offset_top = y
	l.offset_right = x + 320
	l.offset_bottom = y + 26
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l

func _build_bars() -> void:
	health_bar = _add_bar(20, 20, 230, 18, Color(0.86, 0.18, 0.25))
	energy_bar = _add_bar(20, 44, 230, 13, Color(0.20, 0.70, 0.95))
	xp_bar = _add_bar(20, 63, 230, 9, Color(0.72, 0.42, 0.95))
	level_label = _label("Seviye 1", 258, 16, 16, Color(1, 0.9, 0.5))

func _build_top() -> void:
	time_label = _label("08:00", 20, 82, 14, Color(0.85, 0.92, 1))
	weather_label = _label("Açık", 100, 82, 14, Color(0.85, 0.92, 1))
	fps_label = _label("FPS 60", 20, 104, 13, Color(0.55, 1, 0.7))
	quest_label = _label("Görev: Dünyayı keşfet", 20, 126, 14, Color(1, 0.92, 0.68))
	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER)
	toast_label.offset_left = -260
	toast_label.offset_right = 260
	toast_label.offset_top = -140
	toast_label.offset_bottom = -100
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 22)
	toast_label.add_theme_color_override("font_color", Color(1, 0.93, 0.62))
	root.add_child(toast_label)

func _build_hotbar() -> void:
	hotbar = HBoxContainer.new()
	hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar.offset_left = -360
	hotbar.offset_right = 360
	hotbar.offset_top = -88
	hotbar.offset_bottom = -18
	hotbar.add_theme_constant_override("separation", 6)
	root.add_child(hotbar)
	for i in range(9):
		var p := Panel.new()
		p.custom_minimum_size = Vector2(68, 64)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.05, 0.08, 0.14, 0.78)
		normal.set_corner_radius_all(8)
		normal.set_border_width_all(2)
		normal.border_color = Color(0.35, 0.55, 0.75, 0.5)
		p.add_theme_stylebox_override("panel", normal)
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 13)
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
		hotbar.add_child(p)
		slot_panels.append(p)
		slot_labels.append(l)

func _build_crosshair() -> void:
	var cross := Control.new()
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.offset_left = -12
	cross.offset_top = -12
	cross.offset_right = 12
	cross.offset_bottom = 12
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross.draw.connect(func():
		cross.draw_line(Vector2(2, 12), Vector2(2, 9), Color(1, 1, 1, 0.8), 2)
		cross.draw_line(Vector2(2, 15), Vector2(2, 18), Color(1, 1, 1, 0.8), 2)
		cross.draw_line(Vector2(-8, 13.5), Vector2(-5, 13.5), Color(1, 1, 1, 0.8), 2)
		cross.draw_line(Vector2(9, 13.5), Vector2(12, 13.5), Color(1, 1, 1, 0.8), 2))
	root.add_child(cross)

func tick(delta: float, player: Player, world: VoxelWorld, env: WorldEnvironmentController, fps: float, quest: String) -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	energy_bar.max_value = player.max_energy
	energy_bar.value = player.energy
	xp_bar.value = player.xp / maxf(1.0, float(player.level) * 40.0) * 100.0
	level_label.text = "Seviye %d" % player.level
	time_label.text = "Saat " + env.time_string()
	var weather_names := {"clear": "Açık", "rain": "Yağmur", "snow": "Kar", "storm": "Fırtına"}
	weather_label.text = "Hava: " + String(weather_names.get(env.weather, "Açık"))
	fps_label.visible = bool(GameSettings.get_v("fps_visible", true))
	fps_label.text = "FPS %d  |  Chunk %d" % [int(fps), world.chunks.size()]
	quest_label.text = quest
	minimap.visible = bool(GameSettings.get_v("minimap_visible", true))
	if minimap.visible:
		minimap.setup(player, world)
		minimap.tick(delta)
	if player.inventory.selected != _last_selected:
		_last_selected = player.inventory.selected
		_update_hotbar(player)
	elif player.inventory.selected_count() <= 1:
		_update_hotbar(player)
	if _toast_time > 0.0:
		_toast_time -= delta
		toast_label.modulate.a = clampf(_toast_time, 0.0, 1.0)
		if _toast_time <= 0.0:
			toast_label.text = ""

func _update_hotbar(player: Player) -> void:
	for i in range(9):
		var id: int = int(player.inventory.slots[i].get("id", 0))
		var count := int(player.inventory.slots[i].get("count", 0))
		slot_labels[i].text = "%s\n%d" % [String(SHORT.get(id, BlockDefs.name_of(id)).substr(0, 5)), count]
		var sb := slot_panels[i].get_theme_stylebox("panel") as StyleBoxFlat
		sb.border_color = Color(0.4, 0.9, 1, 1) if i == player.inventory.selected else Color(0.35, 0.55, 0.75, 0.5)

func toast(text: String) -> void:
	toast_label.text = text
	_toast_time = 2.6
	toast_label.modulate.a = 1.0
