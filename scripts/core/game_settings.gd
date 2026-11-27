extends Node

## Kalıcı ayarlar. Grafik profilleri cihaz kapasitesine göre ölçeklenir.
const SETTINGS_PATH := "user://blockverse_settings.cfg"

const PROFILES: Array = ["Otomatik", "Düşük", "Orta", "Yüksek", "Ultra"]

const PROFILE_DATA: Dictionary = {
	"Düşük": {"render": 3, "shadow": 0, "bloom": false, "fog": 1, "particles": 0.4, "res": 0.75, "water_refl": false, "msaa": 0, "ai": 3, "fps_cap": 30},
	"Orta": {"render": 5, "shadow": 1, "bloom": true, "fog": 1, "particles": 0.7, "res": 1.0, "water_refl": false, "msaa": 1, "ai": 5, "fps_cap": 60},
	"Yüksek": {"render": 8, "shadow": 2, "bloom": true, "fog": 2, "particles": 1.0, "res": 1.0, "water_refl": true, "msaa": 2, "ai": 8, "fps_cap": 60},
	"Ultra": {"render": 11, "shadow": 2, "bloom": true, "fog": 2, "particles": 1.0, "res": 1.0, "water_refl": true, "msaa": 3, "ai": 10, "fps_cap": 60}
}

var data: Dictionary = {
	"profile": "Otomatik",
	"render_distance": 5,
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
	var model := OS.get_model_name().to_lower()
	if model.contains("note 8") or model.contains("redmi 8") or OS.get_processor_count() <= 4:
		return "Düşük"
	if model.contains("note 12") or model.contains("note 13") or model.contains("note 14"):
		return "Yüksek"
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
	save_settings()

func p(key: String, fallback: Variant = null) -> Variant:
	if profile_values.is_empty():
		resolve_profile()
	return profile_values.get(key, fallback)
