class_name WorldGenerator
extends RefCounted

## Seed tabanlı, deterministik voksel dünya üretimi. 12 biyom, mağaralar, cevherler,
## ağaçlar ve yapılar tek bir chunk verisi içinde üretilir.
var seed_value: int
var n_cont: FastNoiseLite
var n_temp: FastNoiseLite
var n_hum: FastNoiseLite
var n_special: FastNoiseLite
var n_ridge: FastNoiseLite
var n_cave: FastNoiseLite
var n_ore: FastNoiseLite

func _init(seed: int) -> void:
	seed_value = seed
	n_cont = _noise(11, 0.0032)
	n_temp = _noise(23, 0.0021)
	n_hum = _noise(37, 0.0027)
	n_special = _noise(53, 0.0041)
	n_ridge = _noise(71, 0.0055)
	n_cave = _noise(89, 0.043)
	n_ore = _noise(101, 0.09)

func _noise(offset: int, freq: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_value + offset
	n.frequency = freq
	n.fractal_octaves = 4
	n.fractal_gain = 0.5
	return n

func generate(cx: int, cz: int) -> Dictionary:
	var size := VoxelUtil.CS * VoxelUtil.CS * VoxelUtil.WORLD_H
	var voxels := PackedByteArray()
	voxels.resize(size)
	voxels.fill(BlockDefs.AIR)
	var biomes := PackedByteArray()
	biomes.resize(VoxelUtil.CS * VoxelUtil.CS)
	var heights := PackedByteArray()
	heights.resize(VoxelUtil.CS * VoxelUtil.CS)
	var ox := cx * VoxelUtil.CS
	var oz := cz * VoxelUtil.CS

	for z in range(VoxelUtil.CS):
		for x in range(VoxelUtil.CS):
			var gx := ox + x
			var gz := oz + z
			var cont := n_cont.get_noise_2d(float(gx), float(gz))
			var temp := clampf(0.5 + n_temp.get_noise_2d(float(gx), float(gz)) * 0.62, 0.0, 1.0)
			var hum := clampf(0.5 + n_hum.get_noise_2d(float(gx), float(gz)) * 0.62, 0.0, 1.0)
			var special := clampf(0.5 + n_special.get_noise_2d(float(gx), float(gz)) * 0.62, 0.0, 1.0)
			var ridge := 1.0 - absf(n_ridge.get_noise_2d(float(gx), float(gz)))
			var h := VoxelUtil.SEA_LEVEL + int(cont * 11.0 + pow(ridge, 2.2) * 30.0 - 5.0)
			h = clampi(h, 7, 150)
			var biome := BiomeDefs.pick(cont, temp, hum, special, h, VoxelUtil.SEA_LEVEL)
			if BiomeDefs.is_tropical(temp, hum, h, VoxelUtil.SEA_LEVEL):
				biome = 3
			if biome == 5:
				h = clampi(h + 5, 7, 150)
			biomes[z * VoxelUtil.CS + x] = biome
			heights[z * VoxelUtil.CS + x] = h
			_fill_column(voxels, x, z, h, biome, gx, gz, temp, special)
			_decorate_column(voxels, x, z, h, biome, gx, gz)

	_place_structure(voxels, cx, cz, biomes, heights)
	if VoxelUtil.hash2(cx, cz, seed_value + 313) < 0.09:
		_place_waterfall(voxels, heights, biomes)
	return {"voxels": voxels, "biomes": biomes, "heights": heights, "cx": cx, "cz": cz}

func _fill_column(v: PackedByteArray, x: int, z: int, h: int, biome: int, gx: int, gz: int, temp: float, special: float) -> void:
	var surface_block := BiomeDefs.surface(biome)
	var sub_block := BiomeDefs.subsurface(biome)
	if biome == 3 and h > VoxelUtil.SEA_LEVEL + 1:
		surface_block = BlockDefs.SAND
	for y in range(h + 1):
		var id := sub_block
		if y == h:
			id = surface_block
		elif y > h - 4:
			id = sub_block
		else:
			id = BlockDefs.STONE
			if biome == 5 and y > h - 12:
				id = BlockDefs.BASALT
		if y < h - 3 and y > 3:
			var cave := n_cave.get_noise_3d(float(gx), float(y) * 1.35, float(gz))
			if cave > 0.53 and (y < 72 or cave > 0.61):
				id = BlockDefs.AIR
				if y < 18 and VoxelUtil.hash3(gx, y, gz, seed_value) < 0.018:
					id = BlockDefs.LAVA
		if id == BlockDefs.STONE:
			var r := VoxelUtil.hash3(gx, y, gz, seed_value + 5)
			if y < 16 and r < 0.014:
				id = BlockDefs.DIAMOND_ORE
			elif y < 32 and r < 0.024:
				id = BlockDefs.GOLD_ORE
			elif y < 58 and r < 0.04:
				id = BlockDefs.IRON_ORE
			elif r < 0.07:
				id = BlockDefs.COAL_ORE
			if (biome == 6 or (special > 0.72 and y < 42)) and VoxelUtil.hash3(gx, y, gz, seed_value + 8) < 0.055:
				id = BlockDefs.CRYSTAL_ORE
		v[VoxelUtil.idx(x, y, z)] = id
	if biome == 5 and temp > 0.82 and VoxelUtil.hash2(gx, gz, seed_value + 12) < 0.06:
		v[VoxelUtil.idx(x, h, z)] = BlockDefs.LAVA
	elif h < VoxelUtil.SEA_LEVEL:
		for y in range(h + 1, VoxelUtil.SEA_LEVEL + 1):
			v[VoxelUtil.idx(x, y, z)] = BlockDefs.WATER

func _vset(v: PackedByteArray, x: int, y: int, z: int, id: int) -> void:
	if VoxelUtil.in_chunk(x, y, z):
		v[VoxelUtil.idx(x, y, z)] = id

func _vget(v: PackedByteArray, x: int, y: int, z: int) -> int:
	if not VoxelUtil.in_chunk(x, y, z):
		return BlockDefs.AIR
	return v[VoxelUtil.idx(x, y, z)]

func _decorate_column(v: PackedByteArray, x: int, z: int, h: int, biome: int, gx: int, gz: int) -> void:
	if h <= VoxelUtil.SEA_LEVEL:
		return
	var density := BiomeDefs.tree_density(biome)
	var r := VoxelUtil.hash2(gx, gz, seed_value + 91)
	if x > 2 and x < 13 and z > 2 and z < 13 and r < density:
		var deco := BiomeDefs.deco(biome)
		match deco:
			"pine": _tree_pine(v, x, h + 1, z)
			"palm": _tree_palm(v, x, h + 1, z)
			"bamboo": _bamboo(v, x, h + 1, z, 3 + int(r * 30) % 4)
			"cactus": _cactus(v, x, h + 1, z)
			"magic": _tree_magic(v, x, h + 1, z)
			"dark": _tree_dark(v, x, h + 1, z)
			"crystal": _crystal_cluster(v, x, h + 1, z)
			"mushroom": _mushroom(v, x, h + 1, z)
			"flowers": _flower(v, x, h + 1, z)
			"lava": _cactus(v, x, h + 1, z)
			_: _tree_oak(v, x, h + 1, z)
	else:
		var d := VoxelUtil.hash2(gx, gz, seed_value + 133)
		if d < 0.055 and _vget(v, x, h + 1, z) == BlockDefs.AIR:
			_vset(v, x, h + 1, z, BlockDefs.TALL_GRASS)
		elif d < 0.075 and _vget(v, x, h + 1, z) == BlockDefs.AIR:
			_vset(v, x, h + 1, z, BlockDefs.FLOWER)

func _tree_oak(v: PackedByteArray, x: int, y: int, z: int) -> void:
	var height := 4 + int(VoxelUtil.hash2(x + 100, z, seed_value) * 3.0)
	for i in range(height):
		_vset(v, x, y + i, z, BlockDefs.LOG)
	var top := y + height - 1
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			for dz in range(-2, 3):
				var d := dx * dx + dy * dy + dz * dz
				if d <= 5 and _vget(v, x + dx, top + dy, z + dz) == BlockDefs.AIR:
					_vset(v, x + dx, top + dy, z + dz, BlockDefs.LEAVES)

func _tree_pine(v: PackedByteArray, x: int, y: int, z: int) -> void:
	var height := 6 + int(VoxelUtil.hash2(x, z + 70, seed_value) * 3.0)
	for i in range(height):
		_vset(v, x, y + i, z, BlockDefs.LOG)
	for layer in range(3):
		var radius := 3 - layer
		var ly := y + height - 4 + layer * 2
		for dx in range(-radius, radius + 1):
			for dz in range(-radius, radius + 1):
				if abs(dx) + abs(dz) <= radius + 1 and _vget(v, x + dx, ly, z + dz) == BlockDefs.AIR:
					_vset(v, x + dx, ly, z + dz, BlockDefs.LEAVES)

func _tree_palm(v: PackedByteArray, x: int, y: int, z: int) -> void:
	var height := 5 + int(VoxelUtil.hash2(x + 9, z + 3, seed_value) * 3.0)
	for i in range(height):
		_vset(v, x + int(i / 3), y + i, z, BlockDefs.LOG)
	var tx := x + int(height / 3)
	var ty := y + height
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			if abs(dx) + abs(dz) <= 3:
				_vset(v, tx + dx, ty, z + dz, BlockDefs.LEAVES)

func _tree_magic(v: PackedByteArray, x: int, y: int, z: int) -> void:
	_tree_oak(v, x, y, z)
	var top := y + 5
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if abs(dx) + abs(dz) == 1:
				_vset(v, x + dx, top, z + dz, BlockDefs.MAGIC_GRASS)
	_vset(v, x, top + 1, z, BlockDefs.CRYSTAL_ORE)

func _tree_dark(v: PackedByteArray, x: int, y: int, z: int) -> void:
	var height := 5 + int(VoxelUtil.hash2(x + 31, z, seed_value) * 3.0)
	for i in range(height):
		_vset(v, x, y + i, z, BlockDefs.DARK_LOG)
	var top := y + height - 1
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			for dy in range(-1, 2):
				if dx * dx + dz * dz + dy * dy <= 5 and _vget(v, x + dx, top + dy, z + dz) == BlockDefs.AIR:
					_vset(v, x + dx, top + dy, z + dz, BlockDefs.LEAVES)

func _bamboo(v: PackedByteArray, x: int, y: int, z: int, height: int) -> void:
	for i in range(height):
		_vset(v, x, y + i, z, BlockDefs.BAMBOO)
	_vset(v, x, y + height, z, BlockDefs.LEAVES)

func _cactus(v: PackedByteArray, x: int, y: int, z: int) -> void:
	var height := 2 + int(VoxelUtil.hash2(x, z + 17, seed_value) * 3.0)
	for i in range(height):
		_vset(v, x, y + i, z, BlockDefs.CACTUS)

func _crystal_cluster(v: PackedByteArray, x: int, y: int, z: int) -> void:
	for i in range(3):
		_vset(v, x + (i % 2), y + i, z + (i / 2), BlockDefs.CRYSTAL_ORE)

func _mushroom(v: PackedByteArray, x: int, y: int, z: int) -> void:
	_vset(v, x, y, z, BlockDefs.MUSHROOM)
	_vset(v, x, y + 1, z, BlockDefs.MUSHROOM)

func _flower(v: PackedByteArray, x: int, y: int, z: int) -> void:
	_vset(v, x, y, z, BlockDefs.FLOWER)

func _place_structure(v: PackedByteArray, cx: int, cz: int, biomes: PackedByteArray, heights: PackedByteArray) -> void:
	if VoxelUtil.hash2(cx, cz, seed_value + 777) > 0.022:
		return
	var biome := int(biomes[8 * VoxelUtil.CS + 8])
	var kind := BiomeDefs.structure(biome)
	var base := int(heights[8 * VoxelUtil.CS + 8]) + 1
	match kind:
		"village": _house(v, base)
		"temple": _temple(v, base, biome)
		"bridge": _bridge(v, base)
		"vault": _vault(v, base)
		_: _ruin(v, base)

func _house(v: PackedByteArray, base: int) -> void:
	for x in range(4, 12):
		for z in range(4, 11):
			_vset(v, x, base - 1, z, BlockDefs.PATH_STONE)
	for y in range(base, base + 4):
		for x in range(4, 12):
			for z in range(4, 11):
				if x == 4 or x == 11 or z == 4 or z == 10:
					var is_door := x == 7 and z == 4 and y < base + 3
					var is_window := (x == 4 or x == 11) and y == base + 2 and z % 3 == 0
					if is_door:
						_vset(v, x, y, z, BlockDefs.AIR)
					elif is_window:
						_vset(v, x, y, z, BlockDefs.GLASS)
					else:
						_vset(v, x, y, z, BlockDefs.PLANK)
	for x in range(3, 13):
		for z in range(3, 12):
			if x == 3 or x == 12 or z == 3 or z == 11:
				_vset(v, x, base + 4, z, BlockDefs.BRICK)
			else:
				_vset(v, x, base + 4, z, BlockDefs.PLANK)
	_vset(v, 8, base, 8, BlockDefs.CHEST)
	_vset(v, 6, base + 2, 5, BlockDefs.TORCH)
	_vset(v, 10, base + 2, 9, BlockDefs.TORCH)

func _temple(v: PackedByteArray, base: int, biome: int) -> void:
	var blocks: Array[int] = [BlockDefs.STONE, BlockDefs.SANDSTONE, BlockDefs.MOSS_STONE]
	var mat: int = blocks[biome % blocks.size()]
	for layer in range(4):
		var r := 7 - layer
		for x in range(8 - r, 8 + r + 1):
			for z in range(8 - r, 8 + r + 1):
				if x < 1 or x > 14 or z < 1 or z > 14:
					continue
				if layer == 0 and x > 5 and x < 11 and z > 5 and z < 11:
					continue
				_vset(v, x, base + layer, z, mat)
	_vset(v, 8, base, 8, BlockDefs.CHEST)
	_vset(v, 8, base + 4, 8, BlockDefs.CRYSTAL_ORE)

func _bridge(v: PackedByteArray, base: int) -> void:
	var y := maxi(base, VoxelUtil.SEA_LEVEL + 1)
	for x in range(1, 15):
		_vset(v, x, y, 7, BlockDefs.PLANK)
		_vset(v, x, y, 8, BlockDefs.PLANK)
		if x % 3 == 0:
			_vset(v, x, y + 1, 6, BlockDefs.LOG)
			_vset(v, x, y + 1, 9, BlockDefs.LOG)

func _vault(v: PackedByteArray, base: int) -> void:
	for y in range(base, base + 4):
		for x in range(5, 11):
			for z in range(5, 11):
				if x == 5 or x == 10 or z == 5 or z == 10 or y == base + 3:
					_vset(v, x, y, z, BlockDefs.OBSIDIAN)
				else:
					_vset(v, x, y, z, BlockDefs.AIR)
	_vset(v, 8, base, 8, BlockDefs.CHEST)
	_vset(v, 6, base + 1, 7, BlockDefs.CRYSTAL_ORE)
	_vset(v, 9, base + 1, 9, BlockDefs.CRYSTAL_ORE)

func _ruin(v: PackedByteArray, base: int) -> void:
	for px in [4, 11]:
		for pz in [4, 11]:
			for y in range(base, base + 4 + int(VoxelUtil.hash2(px, pz, seed_value) * 3.0)):
				_vset(v, px, y, pz, BlockDefs.MOSS_STONE)
	_vset(v, 8, base, 8, BlockDefs.CHEST)
	for x in range(6, 10):
		_vset(v, x, base, 8, BlockDefs.PATH_STONE)

func _place_waterfall(v: PackedByteArray, heights: PackedByteArray, biomes: PackedByteArray) -> void:
	var x := 4 + int(VoxelUtil.hash2(0, 0, seed_value + 44) * 8.0)
	var z := 4 + int(VoxelUtil.hash2(0, 0, seed_value + 45) * 8.0)
	var h := int(heights[z * VoxelUtil.CS + x])
	var bottom := maxi(4, h - 18)
	for y in range(bottom, h + 2):
		_vset(v, x, y, z, BlockDefs.WATER)
		if x + 1 < VoxelUtil.CS:
			_vset(v, x + 1, y, z, BlockDefs.WATER)
	var b := int(biomes[z * VoxelUtil.CS + x])
	if b == 5:
		for y in range(bottom, h + 2):
			_vset(v, x, y, z, BlockDefs.LAVA)
