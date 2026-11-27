class_name VoxelWorld
extends Node3D

## Chunk streaming: arka planda üretim, ana iş parçacığında mesh oluşturma,
## uzak chunk'ların bellekten atılması ve değişikliklerin kalıcı kaydı.
signal chunk_loaded(cx: int, cz: int)

var seed: int
var render_distance: int = 3
var chunks: Dictionary = {}
var pending: Dictionary = {}
var player: Node3D
var loaded_triangles := 0
var _update_timer := 0.0
var _generator_cache: WorldGenerator
var _mutex := Mutex.new()
var _dirty: Dictionary = {}

func setup(world_seed: int, distance: int) -> void:
	seed = world_seed
	render_distance = clampi(distance, 1, 6)
	_generator_cache = WorldGenerator.new(seed)

func _process(delta: float) -> void:
	_update_timer -= delta
	if _update_timer > 0.0:
		return
	_update_timer = 0.35
	# Kare başına en fazla bir chunk bitirilir; dokunma/input kuyruğu bloke olmaz.
	_collect_tasks()
	_process_dirty()
	if player:
		_stream()

func _stream() -> void:
	var p := player.global_position
	var ccx := VoxelUtil.world_to_chunk(int(floor(p.x)))
	var ccz := VoxelUtil.world_to_chunk(int(floor(p.z)))
	var desired: Dictionary = {}
	var pending_keys: Dictionary = {}
	for info in pending.values():
		pending_keys[String(info["key"])] = true
	var missing: Array = []
	for dz in range(-render_distance, render_distance + 1):
		for dx in range(-render_distance, render_distance + 1):
			if dx * dx + dz * dz > render_distance * render_distance + render_distance:
				continue
			var key := VoxelUtil.chunk_key(ccx + dx, ccz + dz)
			desired[key] = true
			if chunks.has(key) or pending_keys.has(key):
				continue
			missing.append([dx * dx + dz * dz, ccx + dx, ccz + dz, key])
	# Önce oyuncuya en yakın chunk'lar üretilir; arka planda en fazla 2 iş bekler.
	missing.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	for item in missing:
		if pending.size() >= 2:
			break
		_start_task(int(item[1]), int(item[2]), String(item[3]))
	for key in chunks.keys():
		if not desired.has(key):
			var c: Chunk = chunks[key]
			c.save(seed)
			chunks.erase(key)
			_dirty.erase(key)
			c.free_chunk()
			loaded_triangles = 0
			for ch in chunks.values():
				loaded_triangles += (ch as Chunk).triangle_count

func _start_task(cx: int, cz: int, key: String) -> void:
	var holder: Array = [null]
	var task := WorkerThreadPool.add_task(Callable(self, "_thread_generate").bind(cx, cz, holder))
	pending[task] = {"key": key, "cx": cx, "cz": cz, "holder": holder}

func _thread_generate(cx: int, cz: int, holder: Array) -> void:
	var gen := WorldGenerator.new(seed)
	var data := gen.generate(cx, cz)
	_mutex.lock()
	holder[0] = data
	_mutex.unlock()

func _collect_tasks() -> void:
	for task in pending.keys():
		if not WorkerThreadPool.is_task_completed(task):
			continue
		var info: Dictionary = pending[task]
		pending.erase(task)
		_mutex.lock()
		var data: Variant = (info["holder"] as Array)[0]
		_mutex.unlock()
		if data is Dictionary:
			var key := String(info["key"])
			if chunks.has(key):
				continue
			var p := player.global_position if player else Vector3.ZERO
			var ccx := VoxelUtil.world_to_chunk(int(floor(p.x)))
			var ccz := VoxelUtil.world_to_chunk(int(floor(p.z)))
			if absi(int(info["cx"]) - ccx) > render_distance + 1 or absi(int(info["cz"]) - ccz) > render_distance + 1:
				continue
			_finish_chunk(int(info["cx"]), int(info["cz"]), data)
		# Tek çağrıda tek chunk: mesh + collision ana thread'i uzun süre tutmaz.
		return

func _finish_chunk(cx: int, cz: int, data: Dictionary, defer_mesh: bool = false) -> void:
	var key := VoxelUtil.chunk_key(cx, cz)
	var chunk := Chunk.new()
	chunk.setup(cx, cz, data)
	chunk.apply_edits(SaveSystem.load_chunk(seed, cx, cz))
	add_child(chunk)
	chunks[key] = chunk
	if defer_mesh:
		_dirty[key] = true
	else:
		chunk.rebuild()
		loaded_triangles += chunk.triangle_count
	chunk_loaded.emit(cx, cz)

func _process_dirty() -> void:
	if _dirty.is_empty():
		return
	var key: String = String(_dirty.keys()[0])
	_dirty.erase(key)
	var c: Chunk = chunks.get(key, null) as Chunk
	if c == null:
		return
	c.rebuild()
	loaded_triangles += c.triangle_count

func get_chunk(gx: int, gz: int) -> Chunk:
	var key := VoxelUtil.chunk_key(VoxelUtil.world_to_chunk(gx), VoxelUtil.world_to_chunk(gz))
	return chunks.get(key, null) as Chunk

## Spawn için yalnızca voksel verisini üretir; ağır mesh/collision işini sonraki kareye bırakır.
func ensure_spawn_chunk() -> void:
	if get_chunk(0, 0) != null:
		return
	var data := _generator_cache.generate(0, 0)
	if data is Dictionary:
		_finish_chunk(0, 0, data, true)

func get_block(gx: int, gy: int, gz: int) -> int:
	if gy < 0 or gy >= VoxelUtil.WORLD_H:
		return BlockDefs.AIR
	var c := get_chunk(gx, gz)
	if c == null:
		return BlockDefs.AIR
	return c.get_block(VoxelUtil.local(gx), gy, VoxelUtil.local(gz))

func set_block(gx: int, gy: int, gz: int, id: int) -> void:
	var c := get_chunk(gx, gz)
	if c == null:
		return
	c.set_block(VoxelUtil.local(gx), gy, VoxelUtil.local(gz), id)

func rebuild_at(gx: int, gz: int) -> void:
	var key := VoxelUtil.chunk_key(VoxelUtil.world_to_chunk(gx), VoxelUtil.world_to_chunk(gz))
	if chunks.has(key):
		_dirty[key] = true

func biome_at(gx: int, gz: int) -> int:
	var c := get_chunk(gx, gz)
	if c == null:
		return 0
	return c.biome_at(VoxelUtil.local(gx), VoxelUtil.local(gz))

func save_all() -> void:
	for c in chunks.values():
		(c as Chunk).save(seed)

func find_spawn() -> Vector3:
	var gx := 0
	var gz := 0
	for y in range(VoxelUtil.WORLD_H - 1, 0, -1):
		var id := get_block(gx, y, gz)
		if BlockDefs.is_solid(id) and get_block(gx, y + 1, gz) == BlockDefs.AIR and get_block(gx, y + 2, gz) == BlockDefs.AIR:
			if id != BlockDefs.WATER and id != BlockDefs.LAVA:
				return Vector3(float(gx) + 0.5, float(y + 1), float(gz) + 0.5)
	return Vector3(0.5, 70.0, 0.5)

## Voksel DDA ışın testi: blok koordinatı ve yüzey normali döndürür.
func raycast(origin: Vector3, direction: Vector3, max_distance: float) -> Dictionary:
	var dir := direction.normalized()
	var vx := int(floor(origin.x))
	var vy := int(floor(origin.y))
	var vz := int(floor(origin.z))
	var step_x := 1 if dir.x > 0.0 else -1
	var step_y := 1 if dir.y > 0.0 else -1
	var step_z := 1 if dir.z > 0.0 else -1
	var tdx := 1.0 / maxf(absf(dir.x), 0.00001)
	var tdy := 1.0 / maxf(absf(dir.y), 0.00001)
	var tdz := 1.0 / maxf(absf(dir.z), 0.00001)
	var boundary_x := float(vx) if dir.x < 0.0 else float(vx + 1)
	var boundary_y := float(vy) if dir.y < 0.0 else float(vy + 1)
	var boundary_z := float(vz) if dir.z < 0.0 else float(vz + 1)
	var tmx := (boundary_x - origin.x) / dir.x if absf(dir.x) > 0.00001 else 1e9
	var tmy := (boundary_y - origin.y) / dir.y if absf(dir.y) > 0.00001 else 1e9
	var tmz := (boundary_z - origin.z) / dir.z if absf(dir.z) > 0.00001 else 1e9
	var normal := Vector3i.ZERO
	var travelled := 0.0
	for i in range(64):
		var id := get_block(vx, vy, vz)
		if id != BlockDefs.AIR and id != BlockDefs.WATER:
			return {"hit": true, "block": Vector3i(vx, vy, vz), "normal": normal, "id": id, "distance": travelled}
		if id == BlockDefs.WATER:
			return {"hit": true, "block": Vector3i(vx, vy, vz), "normal": normal, "id": id, "distance": travelled}
		if tmx < tmy and tmx < tmz:
			vx += step_x
			travelled = tmx
			tmx += tdx
			normal = Vector3i(-step_x, 0, 0)
		elif tmy < tmz:
			vy += step_y
			travelled = tmy
			tmy += tdy
			normal = Vector3i(0, -step_y, 0)
		else:
			vz += step_z
			travelled = tmz
			tmz += tdz
			normal = Vector3i(0, 0, -step_z)
		if travelled > max_distance:
			break
	return {"hit": false, "block": Vector3i.ZERO, "normal": Vector3i.ZERO, "id": 0, "distance": max_distance}
