class_name Minimap
extends TextureRect

## Gerçek chunk verisinden üretilen mini harita (biyom + yükseklik + su).
## Görüntü ve dokuyu yeniden kullanır; GPU'ya her saniye yeni texture yüklemez.
var update_timer := 0.0
var player: Player
var world: VoxelWorld
const SIZE := 64

var _img: Image
var _tex: ImageTexture

func setup(player_ref: Player, world_ref: VoxelWorld) -> void:
	player = player_ref
	world = world_ref
	custom_minimum_size = Vector2(SIZE, SIZE)
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _img == null:
		_img = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		_tex = ImageTexture.create_from_image(_img)
		texture = _tex

func tick(delta: float) -> void:
	update_timer -= delta
	if update_timer > 0.0 or player == null or world == null:
		return
	update_timer = clampf(float(GameSettings.p("minimap_interval", 1.0)), 0.5, 3.0)
	_refresh()

func _refresh() -> void:
	var px := int(floor(player.global_position.x))
	var pz := int(floor(player.global_position.z))
	var half := SIZE / 2
	for y in range(SIZE):
		for x in range(SIZE):
			var gx := px + x - half
			var gz := pz + y - half
			var chunk := world.get_chunk(gx, gz)
			if chunk == null:
				_img.set_pixel(x, y, Color(0.05, 0.07, 0.11, 1))
				continue
			var biome := chunk.biome_at(VoxelUtil.local(gx), VoxelUtil.local(gz))
			var col := BiomeDefs.map_color(biome)
			var surface := chunk.surface_at(VoxelUtil.local(gx), VoxelUtil.local(gz))
			var light := clampf(0.65 + float(surface) / 180.0, 0.65, 1.25)
			col = Color(col.r * light, col.g * light, col.b * light, 1)
			if surface < VoxelUtil.SEA_LEVEL:
				col = col.lerp(Color(0.10, 0.32, 0.55), 0.55)
			_img.set_pixel(x, y, col)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if dx * dx + dy * dy <= 4:
				_img.set_pixel(half + dx, half + dy, Color(1, 0.95, 0.5, 1))
	_tex.update(_img)
