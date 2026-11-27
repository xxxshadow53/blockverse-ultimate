class_name WorldEnvironmentController
extends Node3D

## Dinamik güneş, gökyüzü, sis, bulutlar, gece/gündüz ve hava olayları.
var world_env: WorldEnvironment
var environment: Environment
var sky: ProceduralSkyMaterial
var sun: DirectionalLight3D
var clouds: Array[MeshInstance3D] = []
var rain: GPUParticles3D
var snow: GPUParticles3D
var time_of_day := 8.0 * 3600.0
var day_length := 720.0
var weather := "clear"
var storm := false
var _lightning := 0.0
var _weather_timer := 50.0
var _light_timer := 0.0
var _cloud_material: ShaderMaterial

func setup() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	sky = ProceduralSkyMaterial.new()
	sky.sky_top_color = Color(0.26, 0.48, 0.78)
	sky.sky_horizon_color = Color(0.68, 0.82, 0.92)
	sky.ground_bottom_color = Color(0.30, 0.34, 0.38)
	sky.ground_horizon_color = Color(0.62, 0.68, 0.70)
	sky.sun_curve = 0.12
	sky.energy_multiplier = 1.0
	var sky_resource := Sky.new()
	sky_resource.sky_material = sky
	environment.sky = sky_resource
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.95
	var fog_density := clampf(float(GameSettings.p("fog_density", 0.0022)), 0.0, 0.01)
	environment.fog_enabled = fog_density > 0.0
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_density = fog_density
	environment.fog_light_color = Color(0.68, 0.80, 0.91)
	environment.fog_sky_affect = 0.35
	environment.glow_enabled = bool(GameSettings.p("bloom", false))
	environment.glow_intensity = 0.45
	environment.glow_bloom = 0.18
	environment.glow_hdr_threshold = 1.1
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.tonemap_exposure = 1.12
	# Daha canlı ve net bir görüntü; ağır post-processing yerine renk ayarı kullanılır.
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.12
	environment.adjustment_contrast = 1.06
	TextureFactory.set_reflection(bool(GameSettings.p("water_refl", false)))
	world_env = WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.light_energy = 1.5
	sun.light_color = Color(1.0, 0.94, 0.84)
	sun.shadow_enabled = int(GameSettings.p("shadow", 0)) > 0
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_bias = 0.025
	sun.rotation_order = EulerOrder.EULER_ORDER_YXZ
	add_child(sun)
	_build_clouds()
	_build_precipitation()

func _build_clouds() -> void:
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform sampler2D cloud_tex;
uniform vec3 tint = vec3(1.0, 1.0, 1.0);
void fragment() {
	float a = texture(cloud_tex, UV).a;
	ALBEDO = tint * mix(vec3(0.85, 0.88, 0.95), vec3(1.0, 0.85, 0.75), 0.2);
	ALPHA = a * 0.8;
}
"""
	mat.shader = sh
	mat.set_shader_parameter("cloud_tex", TextureFactory.cloud_texture)
	_cloud_material = mat
	var rng := RandomNumberGenerator.new()
	rng.seed = 8181
	for i in range(7):
		var plane := PlaneMesh.new()
		plane.size = Vector2(rng.randf_range(80, 160), rng.randf_range(60, 120))
		var mi := MeshInstance3D.new()
		mi.mesh = plane
		mi.material_override = mat
		mi.rotation.x = -PI * 0.5
		mi.position = Vector3(rng.randf_range(-220, 220), rng.randf_range(105, 145), rng.randf_range(-220, 220))
		add_child(mi)
		clouds.append(mi)

func _build_precipitation() -> void:
	rain = _make_particles(Color(0.62, 0.80, 0.96), 0.55, 15.0)
	snow = _make_particles(Color(1, 1, 1), 0.10, 2.0)
	add_child(rain)
	add_child(snow)

func _make_particles(color: Color, size: float, fall_speed: float) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(24, 3, 24)
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 8.0
	pm.gravity = Vector3(0, -fall_speed, 0)
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 4.0
	pm.scale_min = size * 0.7
	pm.scale_max = size * 1.3
	pm.color = color
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size * (3.0 if fall_speed > 10.0 else 1.0))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = TextureFactory.particle_texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.emission_enabled = true
	mat.emission = color * 0.4
	quad.material = mat
	var p := GPUParticles3D.new()
	p.process_material = pm
	p.draw_pass_1 = quad
	p.amount = mini(180, int(360.0 * float(GameSettings.p("particles", 0.25))))
	p.lifetime = 1.6
	p.emitting = false
	p.local_coords = false
	return p

func _process(delta: float) -> void:
	time_of_day = fmod(time_of_day + delta * (86400.0 / day_length), 86400.0)
	_lightning = maxf(0.0, _lightning - delta)
	for c in clouds:
		c.position.x += delta * 1.1
		if c.position.x > 250.0:
			c.position.x = -250.0
	_weather_timer -= delta
	if _weather_timer <= 0.0:
		_weather_timer = randf_range(70.0, 150.0)
		_roll_weather()
	# Işık/gökyüzü uniform'ları ve güneş rotasyonu 5 Hz'de güncellenir; her kare gölge atlasını bozmaz.
	_light_timer -= delta
	if _light_timer > 0.0:
		return
	_light_timer = 0.2
	_update_lighting()

func _update_lighting() -> void:
	var phase := time_of_day / 86400.0
	var angle := (phase - 0.25) * TAU
	var elevation := sin(angle)
	sun.rotation = Vector3(angle, deg_to_rad(38.0), 0)
	sun.light_energy = clampf(elevation * 2.2, 0.0, 2.0) + _lightning * 6.0
	sun.light_color = Color(1.0, clampf(0.72 + elevation * 0.28, 0.45, 1), clampf(0.52 + elevation * 0.42, 0.35, 1))
	var night := clampf(-elevation * 2.4, 0.0, 1.0)
	var dusk := clampf(1.0 - absf(elevation) * 3.0, 0.0, 1.0)
	sky.sky_top_color = Color(0.30, 0.52, 0.82).lerp(Color(0.015, 0.025, 0.09), night)
	sky.sky_horizon_color = Color(0.72, 0.86, 0.95).lerp(Color(0.10, 0.08, 0.20), night).lerp(Color(0.95, 0.45, 0.22), dusk * 0.6)
	sky.ground_horizon_color = Color(0.66, 0.72, 0.74).lerp(Color(0.05, 0.06, 0.10), night)
	environment.fog_light_color = Color(0.68, 0.80, 0.91).lerp(Color(0.04, 0.06, 0.13), night)
	var base_fog := clampf(float(GameSettings.p("fog_density", 0.0022)), 0.0, 0.01)
	environment.fog_density = base_fog + night * 0.0015 + (0.002 if storm else 0.0)
	if _cloud_material:
		_cloud_material.set_shader_parameter("tint", Color(1, 1, 1).lerp(Color(0.22, 0.24, 0.34), night * 0.8))

func _roll_weather() -> void:
	var roll := randf()
	if roll < 0.45:
		set_weather("clear")
	elif roll < 0.75:
		set_weather("rain")
	elif roll < 0.9:
		set_weather("snow")
	else:
		set_weather("storm")

func set_weather(mode: String) -> void:
	weather = mode
	storm = mode == "storm"
	rain.emitting = mode == "rain" or storm
	snow.emitting = mode == "snow"
	if storm:
		_lightning = 0.12

func follow(pos: Vector3) -> void:
	rain.global_position = pos + Vector3(0, 12, 0)
	snow.global_position = pos + Vector3(0, 12, 0)

func is_night() -> bool:
	return time_of_day < 6.0 * 3600.0 or time_of_day > 19.5 * 3600.0

func time_string() -> String:
	var h := int(time_of_day / 3600.0) % 24
	var m := int(fmod(time_of_day, 3600.0) / 60.0)
	return "%02d:%02d" % [h, m]
