class_name Minimap
extends TextureRect

## Gerçek chunk verisinden üretilen mini harita (biyom + yükseklik + su).
var update_timer := 0.0
var player: Player
var world: VoxelWorld
const SIZE := 96

func setup(player_ref: Player, world_ref: VoxelWorld) -> void:
	player = player_ref
	world = world_ref
	custom_minimum_size = Vector2(SIZE, SIZE)
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func tick(delta: float) -> void:
	update_timer -= delta
	if update_timer > 0.0 or player == null or world == null:
		return
	update_timer = 0.35
	_refresh()

func _refresh() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var px := int(floor(player.global_position.x))
	var pz := int(floor(player.global_position.z))
	for y in range(SIZE):
		for x in range(SIZE):
			var gx := px + x - SIZE / 2
			var gz := pz + y - SIZE / 2
			var chunk := world.get_chunk(gx, gz)
			if chunk == null:
				img.set_pixel(x, y, Color(0.05, 0.07, 0.11, 1))
				continue
			var biome := chunk.biome_at(VoxelUtil.local(gx), VoxelUtil.local(gz))
			var col := BiomeDefs.map_color(biome)
			var surface := chunk.surface_at(VoxelUtil.local(gx), VoxelUtil.local(gz))
			var light := clampf(0.65 + float(surface) / 180.0, 0.65, 1.25)
			col = Color(col.r * light, col.g * light, col.b * light, 1)
			if surface < VoxelUtil.SEA_LEVEL:
				col = col.lerp(Color(0.10, 0.32, 0.55), 0.55)
			img.set_pixel(x, y, col)
	var c := SIZE / 2
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if dx * dx + dy * dy <= 4:
				img.set_pixel(c + dx, c + dy, Color(1, 0.95, 0.5, 1))
	var tex := ImageTexture.create_from_image(img)
	texture = tex
