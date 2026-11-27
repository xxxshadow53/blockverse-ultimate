extends Node

## Kalıcı ayarlar. Grafik profilleri cihaz kapasitesine göre ölçeklenir.
const SETTINGS_PATH := "user://blockverse_settings.cfg"

const PROFILES: Array = ["Otomatik", "Düşük", "Orta", "Yüksek", "Ultra"]

const PROFILE_DATA: Dictionary = {
	"Düşük": {"render": 2, "shadow": 0, "bloom": false, "fog_density": 0.0016, "particles": 0.15, "res": 0.70, "water_refl": false, "msaa": 0, "ai": 2, "fps_cap": 30},
	"Orta": {"render": 3, "shadow": 0, "bloom": false, "fog_density": 0.0022, "particles": 0.25, "res": 0.85, "water_refl": false, "msaa": 0, "ai": 3, "fps_cap": 30},
	"Yüksek": {"render": 4, "shadow": 1, "bloom": true, "fog_density": 0.0035, "particles": 0.50, "res": 1.00, "water_refl": true, "msaa": 0, "ai": 4, "fps_cap": 45},
	"Ultra": {"render": 5, "shadow": 1, "bloom": true, "fog_density": 0.0050, "particles": 0.70, "res": 1.00, "water_refl": true, "msaa": 1, "ai": 6, "fps_cap": 60}
}

var data: Dictionary = {
	"profile": "Otomatik",
	"render_distance": 3,
	"camera_sensitivity": 0.45,
	"invert_y": false,
	"vibration": true,
	"master_volume": 0.8,
	"music_volume": 0.55,
	"sfx_volume": 0.85,
	"fps_visible": true,
	"minimap_visible": true,
	"dynamic_resolution": true,
	"show_tips": true,
	"last_character": 0,
	"seed": 20261127,
	"world_name": "Yeni Dünya"
}

var active_profile: String = "Orta"
var profile_values: Dictionary = {}

func _ready() -> void:
	load_settings()
	resolve_profile()
	apply_runtime()

func get_v(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)

func set_v(key: String, value: Variant) -> void:
	data[key] = value

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in data.keys():
		cfg.set_value("game", k, data[k])
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for k in data.keys():
		if cfg.has_section_key("game", k):
			data[k] = cfg.get_value("game", k, data[k])

func detect_profile() -> String:
	if OS.get_name() != "Android":
		return "Yüksek"
	# Mobilde otomatik profil en fazla Orta olur; cihaz adına göre agresif "Yüksek" seçimi kaldırıldı.
	if OS.get_processor_count() <= 4:
		return "Düşük"
	return "Orta"

func resolve_profile() -> void:
	var requested := String(data.get("profile", "Otomatik"))
	active_profile = detect_profile() if requested == "Otomatik" else requested
	if not PROFILE_DATA.has(active_profile):
		active_profile = "Orta"
	profile_values = PROFILE_DATA[active_profile]
	data["render_distance"] = int(profile_values.get("render", 5))

func set_profile(profile: String) -> void:
	data["profile"] = profile
	resolve_profile()
	apply_runtime()
	save_settings()

## Profil anahtarlarını gerçek çalışma zamanı ayarlarına bağlar.
func apply_runtime() -> void:
	if profile_values.is_empty():
		resolve_profile()
	Engine.max_fps = clampi(int(profile_values.get("fps_cap", 30)), 20, 60)
	call_deferred("_apply_viewport_scale", clampf(float(profile_values.get("res", 0.85)), 0.5, 1.0))

func _apply_viewport_scale(scale: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.root.scaling_3d_scale = scale

func p(key: String, fallback: Variant = null) -> Variant:
	if profile_values.is_empty():
		resolve_profile()
	return profile_values.get(key, fallback)
