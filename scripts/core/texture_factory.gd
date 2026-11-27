extends Node

## Çalışma zamanında prosedürel PBR doku atlasları ve shader materyalleri üretir.
## Harici telifli varlık kullanılmaz; tüm dokular matematiksel olarak oluşturulur.
const TILE := 32
const ATLAS_COLS := 16
const ATLAS_ROWS := 16

var atlas: ImageTexture
var solid_material: StandardMaterial3D
var foliage_material: ShaderMaterial
var water_material: ShaderMaterial
var cloud_texture: ImageTexture
var particle_texture: ImageTexture
var _time := 0.0

func _ready() -> void:
	atlas = _build_atlas()
	solid_material = _make_solid_material()
	foliage_material = _make_foliage_material()
	water_material = _make_water_material()
	cloud_texture = _build_cloud_texture()
	particle_texture = _build_particle_texture()

func process(delta: float) -> void:
	_time += delta
	if foliage_material:
		foliage_material.set_shader_parameter("time", _time)
	if water_material:
		water_material.set_shader_parameter("time", _time)

func set_reflection(enabled: bool) -> void:
	if water_material:
		water_material.set_shader_parameter("reflection", 0.55 if enabled else 0.12)

func _make_solid_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = atlas
	m.roughness = 0.86
	m.metallic = 0.03
	return m

func _make_foliage_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back;
uniform sampler2D atlas : hint_default_black;
uniform float time = 0.0;
uniform float wind_strength = 0.075;
void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float sway = sin(time * 1.35 + wp.x * 0.43 + wp.z * 0.31) * cos(time * 0.72 + wp.z * 0.21);
	float mask = clamp(VERTEX.y + 0.5, 0.0, 1.0);
	VERTEX.x += sway * wind_strength * mask;
	VERTEX.z += sway * wind_strength * 0.45 * mask;
}
void fragment() {
	vec4 t = texture(atlas, UV);
	ALBEDO = t.rgb;
	ROUGHNESS = 0.94;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("atlas", atlas)
	m.set_shader_parameter("time", 0.0)
	return m

func _make_water_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never;
uniform float time = 0.0;
uniform float reflection = 0.35;
void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float wave = sin(time * 1.15 + wp.x * 0.72) * 0.045 + sin(time * 1.73 + wp.z * 0.91) * 0.028;
	VERTEX.y += wave;
}
void fragment() {
	vec3 deep = vec3(0.035, 0.16, 0.30);
	vec3 shallow = vec3(0.11, 0.43, 0.56);
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.4);
	vec3 rdir = reflect(-VIEW, NORMAL);
	vec3 sky = mix(vec3(0.12, 0.27, 0.45), vec3(0.58, 0.76, 0.93), clamp(rdir.y * 0.5 + 0.5, 0.0, 1.0));
	ALBEDO = mix(deep, shallow, fres) + sky * reflection * fres;
	ALPHA = 0.76 + fres * 0.2;
	ROUGHNESS = 0.14;
	METALLIC = 0.18;
	EMISSION = vec3(0.008, 0.02, 0.035);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("time", 0.0)
	m.set_shader_parameter("reflection", 0.35)
	return m

func _build_atlas() -> ImageTexture:
	var img := Image.create(TILE * ATLAS_COLS, TILE * ATLAS_ROWS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.1, 0.1, 1))
	for id in range(BlockDefs.COUNT):
		for face in range(3):
			_paint_tile(img, id, face, id * 3 + face)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _tile_origin(index: int) -> Vector2i:
	return Vector2i((index % ATLAS_COLS) * TILE, (index / ATLAS_COLS) * TILE)

func _paint_tile(img: Image, id: int, face: int, index: int) -> void:
	var origin := _tile_origin(index)
	var base: Color = BlockDefs.color_of(id)
	var pattern := BlockDefs.pattern_of(id)
	var noise := FastNoiseLite.new()
	noise.seed = 1000 + id * 31 + face * 7
	noise.frequency = 0.11
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + id * 613 + face * 41
	var spots: Array[Vector2] = []
	for i in range(7):
		spots.append(Vector2(rng.randf_range(4, TILE - 4), rng.randf_range(4, TILE - 4)))
	var ore_color := Color(0.12, 0.12, 0.13)
	match id:
		BlockDefs.IRON_ORE: ore_color = Color(0.78, 0.62, 0.44)
		BlockDefs.GOLD_ORE: ore_color = Color(0.98, 0.78, 0.22)
		BlockDefs.DIAMOND_ORE: ore_color = Color(0.35, 0.92, 0.95)
		BlockDefs.CRYSTAL_ORE: ore_color = Color(0.42, 0.86, 1.0)
		BlockDefs.STAR_ORE: ore_color = Color(0.62, 0.70, 1.0)
	for y in range(TILE):
		for x in range(TILE):
			var n := noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var c := base
			match pattern:
				"grass":
					if face == BlockDefs.F_TOP:
						c = base * (0.78 + n * 0.42)
					elif face == BlockDefs.F_BOTTOM:
						c = Color(0.40, 0.29, 0.18) * (0.82 + n * 0.3)
					else:
						var edge := 7 + int(n * 4)
						c = Color(0.40, 0.29, 0.18) * (0.8 + n * 0.35)
						if y < edge:
							c = base * (0.75 + n * 0.45)
				"speckle":
					c = base * (0.78 + n * 0.4)
					if rng.randf() < 0.035:
						c = base * 1.35
				"stripe":
					var s := 0.75 + 0.32 * absf(sin(float(x) * 0.55 + n * 1.4))
					c = base * s
				"ore":
					c = Color(0.40, 0.41, 0.43) * (0.8 + n * 0.35)
					for p in spots:
						if Vector2(x, y).distance_to(p) < 3.4:
							c = ore_color * (0.8 + n * 0.3)
				"crystal":
					var streak := absf(sin(float(x + y) * 0.45)) * 0.25
					c = base * (0.72 + n * 0.5 + streak)
				"glass":
					c = Color(0.55, 0.82, 0.92) * (0.86 + n * 0.2)
					if x < 2 or y < 2 or x > TILE - 3 or y > TILE - 3:
						c = Color(0.82, 0.94, 1.0)
				"emblem":
					if id == BlockDefs.BRICK:
						var row := y / 8
						var offset := 0 if row % 2 == 0 else 8
						if y % 8 == 0 or (x + offset) % 16 == 0:
							c = Color(0.32, 0.30, 0.28)
						else:
							c = base * (0.82 + n * 0.32)
					else:
						c = base * (0.82 + n * 0.34)
						if x % 12 < 2 or y % 14 < 2:
							c = base * 0.55
				"glow":
					c = base * (0.9 + n * 0.45) + Color(0.12, 0.05, 0.02, 0)
				_:
					c = base * (0.8 + n * 0.38)
			c.a = 1.0
			img.set_pixel(origin.x + x, origin.y + y, c)

func _build_cloud_texture() -> ImageTexture:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 4242
	noise.frequency = 0.018
	noise.fractal_octaves = 4
	for y in range(256):
		for x in range(256):
			var n := noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var a := clampf((n - 0.52) * 3.4, 0.0, 0.75)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _build_particle_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var d := Vector2(x - 31.5, y - 31.5).length() / 32.0
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 1.6)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func uv_for(index: int, u: float = 0.0, v: float = 0.0) -> Vector2:
	var pad := 0.002
	var tx := float(index % ATLAS_COLS) / float(ATLAS_COLS)
	var ty := float(index / ATLAS_COLS) / float(ATLAS_ROWS)
	var step := 1.0 / float(ATLAS_COLS)
	return Vector2(tx + pad + u * (step - pad * 2.0), ty + pad + v * (step - pad * 2.0))
