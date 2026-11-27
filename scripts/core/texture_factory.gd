extends Node

## Çalışma zamanında prosedürel PBR doku atlasları ve shader materyalleri üretir.
## Harici telifli varlık kullanılmaz; tüm dokular matematiksel olarak oluşturulur.
const TILE := 64
const ATLAS_COLS := 16
const ATLAS_ROWS := 16

var atlas: ImageTexture
var normal_atlas: ImageTexture
var solid_material: StandardMaterial3D
var foliage_material: ShaderMaterial
var water_material: ShaderMaterial
var cloud_texture: ImageTexture
var particle_texture: ImageTexture
var _time := 0.0

func _ready() -> void:
	var textures := _build_atlas()
	atlas = textures[0]
	normal_atlas = textures[1]
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
	m.normal_texture = normal_atlas
	m.normal_scale = 0.85
	m.roughness = 0.82
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

func _build_atlas() -> Array:
	var size := TILE * ATLAS_COLS
	var height := TILE * ATLAS_ROWS
	var pixels := size * height
	# set_pixel yerine tek seferde ham bayt yazımı: 1M GDScript çağrısı kalkar.
	var albedo_data := PackedByteArray()
	albedo_data.resize(pixels * 4)
	var normal_data := PackedByteArray()
	normal_data.resize(pixels * 4)
	for i in range(pixels):
		var o := i * 4
		albedo_data[o] = 26
		albedo_data[o + 1] = 26
		albedo_data[o + 2] = 26
		albedo_data[o + 3] = 255
		normal_data[o] = 128
		normal_data[o + 1] = 128
		normal_data[o + 2] = 255
		normal_data[o + 3] = 255
	for id in range(BlockDefs.COUNT):
		for face in range(3):
			_paint_tile(albedo_data, normal_data, size, id, face, id * 3 + face)
	var img := Image.create(size, height, false, Image.FORMAT_RGBA8)
	img.set_data(size, height, false, Image.FORMAT_RGBA8, albedo_data)
	img.generate_mipmaps()
	var normal_img := Image.create(size, height, false, Image.FORMAT_RGBA8)
	normal_img.set_data(size, height, false, Image.FORMAT_RGBA8, normal_data)
	normal_img.generate_mipmaps()
	return [ImageTexture.create_from_image(img), ImageTexture.create_from_image(normal_img)]

func _write_rgba(data: PackedByteArray, offset: int, c: Color) -> void:
	data[offset] = clampi(int(c.r * 255.0), 0, 255)
	data[offset + 1] = clampi(int(c.g * 255.0), 0, 255)
	data[offset + 2] = clampi(int(c.b * 255.0), 0, 255)
	data[offset + 3] = 255

func _tile_origin(index: int) -> Vector2i:
	return Vector2i((index % ATLAS_COLS) * TILE, (index / ATLAS_COLS) * TILE)

func _paint_tile(albedo_data: PackedByteArray, normal_data: PackedByteArray, atlas_size: int, id: int, face: int, index: int) -> void:
	var origin := _tile_origin(index)
	var base: Color = BlockDefs.color_of(id)
	var pattern := BlockDefs.pattern_of(id)
	var noise := FastNoiseLite.new()
	noise.seed = 1000 + id * 31 + face * 7
	noise.frequency = 0.085
	noise.fractal_octaves = 2
	noise.fractal_gain = 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + id * 613 + face * 41
	var spots: Array[Vector2] = []
	for i in range(9):
		spots.append(Vector2(rng.randf_range(5, TILE - 5), rng.randf_range(5, TILE - 5)))
	var ore_color := Color(0.12, 0.12, 0.13)
	match id:
		BlockDefs.IRON_ORE: ore_color = Color(0.78, 0.62, 0.44)
		BlockDefs.GOLD_ORE: ore_color = Color(0.98, 0.78, 0.22)
		BlockDefs.DIAMOND_ORE: ore_color = Color(0.35, 0.92, 0.95)
		BlockDefs.CRYSTAL_ORE: ore_color = Color(0.42, 0.86, 1.0)
		BlockDefs.STAR_ORE: ore_color = Color(0.62, 0.70, 1.0)
	var heights := PackedFloat32Array()
	heights.resize(TILE * TILE)
	for y in range(TILE):
		for x in range(TILE):
			var n := noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var grain := (rng.randf() - 0.5) * 0.055
			var c := base
			match pattern:
				"grass":
					if face == BlockDefs.F_TOP:
						c = base * (0.74 + n * 0.48 + grain)
					elif face == BlockDefs.F_BOTTOM:
						c = Color(0.40, 0.29, 0.18) * (0.78 + n * 0.34 + grain)
					else:
						var edge := 14 + int(n * 8)
						c = Color(0.40, 0.29, 0.18) * (0.76 + n * 0.4 + grain)
						if y < edge:
							c = base * (0.72 + n * 0.5 + grain)
				"speckle":
					c = base * (0.74 + n * 0.44 + grain)
					if rng.randf() < 0.045:
						c = base * 1.4
				"stripe":
					var s := 0.72 + 0.36 * absf(sin(float(x) * 0.28 + n * 1.6)) + grain
					c = base * s
				"ore":
					c = Color(0.40, 0.41, 0.43) * (0.76 + n * 0.4 + grain)
					for p in spots:
						var dist := Vector2(x, y).distance_to(p)
						if dist < 6.8:
							c = ore_color * (0.78 + n * 0.34)
							if dist < 2.2:
								c = c * 1.25
				"crystal":
					var streak := absf(sin(float(x + y) * 0.23)) * 0.3
					c = base * (0.68 + n * 0.55 + streak + grain)
				"glass":
					c = Color(0.55, 0.82, 0.92) * (0.84 + n * 0.24)
					if x < 4 or y < 4 or x > TILE - 5 or y > TILE - 5:
						c = Color(0.82, 0.94, 1.0)
					elif x + y > TILE * 0.6 and x + y < TILE * 0.72:
						c = Color(0.88, 0.97, 1.0)
				"emblem":
					if id == BlockDefs.BRICK:
						var row := y / 16
						var offset := 0 if row % 2 == 0 else 16
						if y % 16 == 0 or (x + offset) % 32 == 0:
							c = Color(0.30, 0.28, 0.26)
						else:
							c = base * (0.78 + n * 0.36 + grain)
					else:
						c = base * (0.78 + n * 0.38 + grain)
						if x % 24 < 3 or y % 28 < 3:
							c = base * 0.52
				"glow":
					c = base * (0.86 + n * 0.5 + grain)
				_:
					c = base * (0.76 + n * 0.42 + grain)
			# Hafif kenar gölgesi blokların ayrışmasını belirginleştirir.
			if x < 2 or y < 2 or x >= TILE - 2 or y >= TILE - 2:
				c *= 0.9
			c.a = 1.0
			heights[y * TILE + x] = clampf(c.r * 0.3 + c.g * 0.59 + c.b * 0.11, 0.0, 1.0)
			var off := ((origin.y + y) * atlas_size + origin.x + x) * 4
			_write_rgba(albedo_data, off, c)
	# Yükseklikten basit tangent-space normal harita üret (komşu blok sızıntısı yok).
	for y in range(TILE):
		for x in range(TILE):
			var l := heights[y * TILE + maxi(x - 1, 0)]
			var r := heights[y * TILE + mini(x + 1, TILE - 1)]
			var u := heights[maxi(y - 1, 0) * TILE + x]
			var d := heights[mini(y + 1, TILE - 1) * TILE + x]
			var nx := (l - r) * 3.2
			var ny := (u - d) * 3.2
			var inv_len := 1.0 / sqrt(nx * nx + ny * ny + 1.0)
			var nc := Color(nx * inv_len * 0.5 + 0.5, ny * inv_len * 0.5 + 0.5, inv_len * 0.5 + 0.5, 1.0)
			var noff := ((origin.y + y) * atlas_size + origin.x + x) * 4
			_write_rgba(normal_data, noff, nc)

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
