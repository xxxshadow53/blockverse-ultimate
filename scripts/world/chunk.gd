class_name Chunk
extends StaticBody3D

var cx: int
var cz: int
var voxels: PackedByteArray
var biomes: PackedByteArray
var heights: PackedByteArray
var edits: Dictionary = {}
var triangle_count := 0

var _solid_mesh: MeshInstance3D
var _water_mesh: MeshInstance3D
var _cut_mesh: MeshInstance3D
var _collision: CollisionShape3D

func setup(chunk_x: int, chunk_z: int, data: Dictionary) -> void:
	cx = chunk_x
	cz = chunk_z
	voxels = data.get("voxels", PackedByteArray())
	biomes = data.get("biomes", PackedByteArray())
	heights = data.get("heights", PackedByteArray())
	name = "Chunk_%d_%d" % [cx, cz]
	position = Vector3(cx * VoxelUtil.CS, 0, cz * VoxelUtil.CS)
	collision_layer = 1
	collision_mask = 0
	_collision = CollisionShape3D.new()
	add_child(_collision)
	_solid_mesh = MeshInstance3D.new()
	_solid_mesh.name = "Solid"
	add_child(_solid_mesh)
	_water_mesh = MeshInstance3D.new()
	_water_mesh.name = "Water"
	add_child(_water_mesh)
	_cut_mesh = MeshInstance3D.new()
	_cut_mesh.name = "Foliage"
	add_child(_cut_mesh)

func apply_edits(saved: Dictionary) -> void:
	for key in saved.keys():
		var i := int(key)
		if i >= 0 and i < voxels.size():
			voxels[i] = int(saved[key])
			edits[i] = int(saved[key])

func rebuild() -> void:
	var built := ChunkMeshBuilder.build(voxels)
	triangle_count = int(built.get("triangles", 0))
	_set_mesh(_solid_mesh, built.get("solid", []), TextureFactory.solid_material)
	_set_mesh(_water_mesh, built.get("water", []), TextureFactory.water_material)
	_set_mesh(_cut_mesh, built.get("cutout", []), TextureFactory.foliage_material)
	var faces: PackedVector3Array = built.get("collision", PackedVector3Array())
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	_collision.shape = shape

func _set_mesh(node: MeshInstance3D, arrays: Array, material: Material) -> void:
	if arrays.size() < Mesh.ARRAY_MAX or arrays[Mesh.ARRAY_VERTEX] == null or (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
		node.mesh = null
		return
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material:
		mesh.surface_set_material(0, material)
	node.mesh = mesh

func get_block(x: int, y: int, z: int) -> int:
	if not VoxelUtil.in_chunk(x, y, z):
		return BlockDefs.AIR
	return voxels[VoxelUtil.idx(x, y, z)]

func set_block(x: int, y: int, z: int, id: int) -> void:
	if not VoxelUtil.in_chunk(x, y, z):
		return
	var i := VoxelUtil.idx(x, y, z)
	if voxels[i] == id:
		return
	voxels[i] = id
	edits[i] = id

func biome_at(x: int, z: int) -> int:
	if x < 0 or x >= VoxelUtil.CS or z < 0 or z >= VoxelUtil.CS or biomes.size() == 0:
		return 0
	return biomes[z * VoxelUtil.CS + x]

func surface_at(x: int, z: int) -> int:
	if x < 0 or x >= VoxelUtil.CS or z < 0 or z >= VoxelUtil.CS or heights.size() == 0:
		return 0
	return heights[z * VoxelUtil.CS + x]

func save(seed: int) -> void:
	SaveSystem.save_chunk(seed, cx, cz, edits)

func free_chunk() -> void:
	queue_free()
