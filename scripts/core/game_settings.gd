extends Node

## Kalıcı ayarlar. Grafik profilleri cihaz kapasitesine göre ölçeklenir.
const SETTINGS_PATH := "user://blockverse_settings.cfg"

const PROFILES: Array = ["Otomatik", "Düşük", "Orta", "Yüksek", "Ultra"]

const PROFILE_DATA: Dictionary = {
	"Düşük": {"render": 1, "shadow": 0, "bloom": false, "fog_density": 0.0, "particles": 0, "res": 0.60, "water_refl": false, "msaa": 0, "ai": 1, "fps_cap": 24, "normal_map": false, "clouds": 0, "stream_interval": 0.5, "hud_interval": 0.2, "minimap_interval": 2.0},
	"Orta": {"render": 2, "shadow": 0, "bloom": false, "fog_density": 0.0015, "particles": 0.10, "res": 0.75, "water_refl": false, "msaa": 0, "ai": 2, "fps_cap": 30, "normal_map": true, "clouds": 3, "stream_interval": 0.4, "hud_interval": 0.15, "minimap_interval": 1.5},
	"Yüksek": {"render": 3, "shadow": 0, "bloom": false, "fog_density": 0.0025, "particles": 0.25, "res": 0.90, "water_refl": false, "msaa": 0, "ai": 3, "fps_cap": 40, "normal_map": true, "clouds": 5, "stream_interval": 0.35, "hud_interval": 0.12, "minimap_interval": 1.0},
	"Ultra": {"render": 4, "shadow": 1, "bloom": true, "fog_density": 0.0040, "particles": 0.50, "res": 1.00, "water_refl": true, "msaa": 1, "ai": 4, "fps_cap": 60, "normal_map": true, "clouds": 7, "stream_interval": 0.3, "hud_interval": 0.10, "minimap_interval": 0.8}
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
	if _is_low_end_device():
		return "Düşük"
	return "Orta"

## SM200/SM-T200 gibi zayıf Samsung tabletlerinde üst profilleri zorla kapatır.
func _is_low_end_device() -> bool:
	if OS.get_name() != "Android":
		return false
	var raw := OS.get_model_name().to_lower()
	var model := raw.replace("-", "").replace("_", "").replace(" ", "")
	# SM-S200 / SM-X200 / SM-T200 ve benzerleri; tire alt çizgi fark etmez.
	if model.begins_with("sm") and model.contains("200"):
		return true
	if model.contains("smt580") or model.contains("smt550") or model.contains("smt530") or model.contains("smt230"):
		return true
	if raw.contains("tab") or model.contains("taba"):
		return true
	return OS.get_processor_count() <= 4

func resolve_profile() -> void:
	var requested := String(data.get("profile", "Otomatik"))
	if _is_low_end_device():
		active_profile = "Düşük"
	else:
		active_profile = detect_profile() if requested == "Otomatik" else requested
	if not PROFILE_DATA.has(active_profile):
		active_profile = "Düşük"
	profile_values = PROFILE_DATA[active_profile]
	data["render_distance"] = int(profile_values.get("render", 1))

func set_profile(profile: String) -> void:
	data["profile"] = profile
	resolve_profile()
	apply_runtime()
	TextureFactory.apply_quality()
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
