class_name ChunkMeshBuilder
extends RefCounted

## Greedy meshing: aynı bloktan oluşan bitişik yüzeyler tek kuadorda birleştirilir.
## Görünmez yüzler atılır; çarpışma üçgenleri aynı kuadolardan üretilir.
const MAX_MERGE := 4

static func build(voxels: PackedByteArray) -> Dictionary:
	var solid_v := PackedVector3Array()
	var solid_n := PackedVector3Array()
	var solid_uv := PackedVector2Array()
	var solid_i := PackedInt32Array()
	var water_v := PackedVector3Array()
	var water_n := PackedVector3Array()
	var water_uv := PackedVector2Array()
	var water_i := PackedInt32Array()
	var cut_v := PackedVector3Array()
	var cut_n := PackedVector3Array()
	var cut_uv := PackedVector2Array()
	var cut_i := PackedInt32Array()
	var collision := PackedVector3Array()
	var CS := VoxelUtil.CS

	# --- Greedy meshing: katı bloklar (chunk 16 × 256 × 16) ---
	for d in range(3):
		var u := (d + 1) % 3
		var v := (d + 2) % 3
		var dim_u := VoxelUtil.WORLD_H if d == 0 else CS
		var dim_v := VoxelUtil.WORLD_H if d == 2 else CS
		var slices := VoxelUtil.WORLD_H if d == 1 else CS
		var x := [0, 0, 0]
		var mask := PackedInt32Array()
		mask.resize(dim_u * dim_v)
		for slice in range(-1, slices):
			mask.fill(0)
			for j in range(dim_u):
				for k in range(dim_v):
					x[u] = j
					x[v] = k
					x[d] = slice
					var a := _vget(voxels, x[0], x[1], x[2])
					x[d] = slice + 1
					var b := _vget(voxels, x[0], x[1], x[2])
					if _opaque(a) and not _opaque(b):
						mask[k * dim_u + j] = a
					elif _opaque(b) and not _opaque(a):
						mask[k * dim_u + j] = -b
			for j in range(dim_u):
				for k in range(dim_v):
					var id := mask[k * dim_u + j]
					if id == 0:
						continue
					var w := 1
					while j + w < dim_u and w < MAX_MERGE and mask[k * dim_u + j + w] == id:
						w += 1
					var h := 1
					while k + h < dim_v and h < MAX_MERGE and _row_same(mask, j, w, k + h, dim_u):
						h += 1
					for kk in range(k, k + h):
						for jj in range(j, j + w):
							mask[kk * dim_u + jj] = 0
					x[d] = slice + 1
					x[u] = j
					x[v] = k
					var du := [0, 0, 0]
					var dv := [0, 0, 0]
					du[u] = w
					dv[v] = h
					var n := Vector3.ZERO
					n[d] = 1.0 if id > 0 else -1.0
					var face := BlockDefs.F_SIDE
					if d == 1:
						face = BlockDefs.F_TOP if id > 0 else BlockDefs.F_BOTTOM
					_emit_quad(Vector3i(x[0], x[1], x[2]), Vector3i(du[0], du[1], du[2]), Vector3i(dv[0], dv[1], dv[2]), n, absi(id), face, solid_v, solid_n, solid_uv, solid_i, collision)

	# --- Su yüzeyleri ---
	var dirs: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
	for y in range(1, VoxelUtil.WORLD_H):
		for z in range(CS):
			for x in range(CS):
				if _vget(voxels, x, y, z) != BlockDefs.WATER:
					continue
				for dir in dirs:
					var nb := _vget(voxels, x + dir.x, y + dir.y, z + dir.z)
					if nb == BlockDefs.WATER or _opaque(nb):
						continue
					var n := Vector3(dir)
					var p := Vector3i(x, y, z) + dir
					var du := Vector3i(1, 0, 0)
					var dv := Vector3i(0, 0, 1)
					if absi(dir.y) == 1:
						du = Vector3i(1, 0, 0)
						dv = Vector3i(0, 0, 1)
					elif absi(dir.x) == 1:
						du = Vector3i(0, 0, 1)
						dv = Vector3i(0, 1, 0)
					else:
						du = Vector3i(1, 0, 0)
						dv = Vector3i(0, 1, 0)
					if dir.x < 0 or dir.z > 0:
						var tmp := du
						du = dv
						dv = tmp
					_emit_quad(p, du, dv, n, BlockDefs.WATER, BlockDefs.F_TOP, water_v, water_n, water_uv, water_i, PackedVector3Array())

	# --- Çapraz düzlem bitki örtüsü (rüzgâr shader'ı ile) ---
	for y in range(1, VoxelUtil.WORLD_H):
		for z in range(CS):
			for x in range(CS):
				var id := _vget(voxels, x, y, z)
				if not BlockDefs.is_cutout(id):
					continue
				var tile := BlockDefs.tile(id, BlockDefs.F_SIDE)
				_cross_quad(Vector3(x + 0.5, y, z + 0.5), tile, cut_v, cut_n, cut_uv, cut_i)

	return {
		"solid": _arrays(solid_v, solid_n, solid_uv, solid_i),
		"water": _arrays(water_v, water_n, water_uv, water_i),
		"cutout": _arrays(cut_v, cut_n, cut_uv, cut_i),
		"collision": collision,
		"triangles": solid_i.size() / 3
	}

static func _arrays(v: PackedVector3Array, n: PackedVector3Array, uv: PackedVector2Array, idx: PackedInt32Array) -> Array:
	var a: Array = []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = v
	a[Mesh.ARRAY_NORMAL] = n
	a[Mesh.ARRAY_TEX_UV] = uv
	a[Mesh.ARRAY_INDEX] = idx
	return a

static func _vget(v: PackedByteArray, x: int, y: int, z: int) -> int:
	if not VoxelUtil.in_chunk(x, y, z):
		return BlockDefs.AIR
	return v[VoxelUtil.idx(x, y, z)]

static func _opaque(id: int) -> bool:
	return BlockDefs.is_solid(id) and not BlockDefs.is_cutout(id)

static func _row_same(mask: PackedInt32Array, j: int, w: int, k: int, dim_u: int) -> bool:
	var first := mask[k * dim_u + j]
	if first == 0:
		return false
	for jj in range(j, j + w):
		if mask[k * dim_u + jj] != first:
			return false
	return true

static func _uv(index: int, u: float, v: float) -> Vector2:
	var cols := 16.0
	var rows := 16.0
	var pad := 0.004
	var tx := float(index % 16) / cols
	var ty := float(index / 16) / rows
	var step := 1.0 / cols
	return Vector2(tx + pad + u * (step - pad * 2.0), ty + pad + v * (step - pad * 2.0))

static func _emit_quad(p: Vector3i, du: Vector3i, dv: Vector3i, normal: Vector3, id: int, face: int, v: PackedVector3Array, n: PackedVector3Array, uv: PackedVector2Array, idx: PackedInt32Array, collision: PackedVector3Array) -> void:
	var p0 := Vector3(p)
	var p1 := p0 + Vector3(du)
	var p2 := p1 + Vector3(dv)
	var p3 := p0 + Vector3(dv)
	var base := v.size()
	v.append(p0)
	v.append(p1)
	v.append(p2)
	v.append(p3)
	for i in range(4):
		n.append(normal)
	var tile := BlockDefs.tile(id, face)
	uv.append(_uv(tile, 0.0, 0.0))
	uv.append(_uv(tile, 1.0, 0.0))
	uv.append(_uv(tile, 1.0, 1.0))
	uv.append(_uv(tile, 0.0, 1.0))
	var cross_dir := (p1 - p0).cross(p3 - p0)
	if cross_dir.dot(normal) >= 0.0:
		idx.append(base)
		idx.append(base + 1)
		idx.append(base + 2)
		idx.append(base)
		idx.append(base + 2)
		idx.append(base + 3)
		collision.append(p0)
		collision.append(p1)
		collision.append(p2)
		collision.append(p0)
		collision.append(p2)
		collision.append(p3)
	else:
		idx.append(base)
		idx.append(base + 3)
		idx.append(base + 2)
		idx.append(base)
		idx.append(base + 2)
		idx.append(base + 1)
		collision.append(p0)
		collision.append(p3)
		collision.append(p2)
		collision.append(p0)
		collision.append(p2)
		collision.append(p1)

static func _cross_quad(center: Vector3, tile: int, v: PackedVector3Array, n: PackedVector3Array, uv: PackedVector2Array, idx: PackedInt32Array) -> void:
	var angles := [0.0, PI * 0.5]
	for a in angles:
		var side := Vector3(cos(a), 0.0, sin(a)) * 0.44
		var p0 := center - side + Vector3(0, 0.05, 0)
		var p1 := center + side + Vector3(0, 0.05, 0)
		var p2 := center + side + Vector3(0, 0.98, 0)
		var p3 := center - side + Vector3(0, 0.98, 0)
		var base := v.size()
		var points: Array[Vector3] = [p0, p1, p2, p3]
		for p in points:
			v.append(p)
			n.append(Vector3(0, 1, 0))
		uv.append(_uv(tile, 0.0, 0.0))
		uv.append(_uv(tile, 1.0, 0.0))
		uv.append(_uv(tile, 1.0, 1.0))
		uv.append(_uv(tile, 0.0, 1.0))
		idx.append(base)
		idx.append(base + 1)
		idx.append(base + 2)
		idx.append(base)
		idx.append(base + 2)
		idx.append(base + 3)
