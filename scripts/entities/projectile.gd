class_name Projectile
extends Node3D

## Ateş topu, buz kristali, ok ve iskelet oku. Voksel çarpışması ve hedef hasarı.
var direction := Vector3.FORWARD
var speed := 18.0
var damage := 20.0
var kind := "fire"
var hostile := false
var life := 3.0
var game: Node
var world: VoxelWorld
var traveled := 0.0

func setup(game_ref: Node, world_ref: VoxelWorld, origin: Vector3, dir: Vector3, proj_kind: String, dmg: float, is_hostile: bool = false) -> void:
	game = game_ref
	world = world_ref
	global_position = origin
	direction = dir.normalized()
	kind = proj_kind
	damage = dmg
	hostile = is_hostile
	var color := Color(1, 0.35, 0.08)
	var mesh: Mesh
	match kind:
		"ice":
			color = Color(0.45, 0.85, 1.0)
			var c := CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = 0.16
			c.height = 0.55
			mesh = c
		"arrow", "bone":
			color = Color(0.92, 0.88, 0.72) if kind == "bone" else Color(0.62, 0.86, 0.35)
			var c := CylinderMesh.new()
			c.top_radius = 0.045
			c.bottom_radius = 0.045
			c.height = 0.7
			mesh = c
		_:
			var s := SphereMesh.new()
			s.radius = 0.2
			s.height = 0.4
			mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.5
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if kind == "arrow" or kind == "bone":
		mi.rotation = Vector3(PI * 0.5, 0, 0)
	add_child(mi)
	# Işık yerine emissive materyal kullanılır; mermi başına dinamik ışık pahalıdır.
	look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	if game == null:
		return
	var step := direction * speed * delta
	global_position += step
	traveled += step.length()
	life -= delta
	var b := world.get_block(int(floor(global_position.x)), int(floor(global_position.y)), int(floor(global_position.z)))
	if BlockDefs.is_solid(b) or life <= 0.0 or traveled > 80.0:
		_explode()
		return
	if hostile:
		if game.player and global_position.distance_to(game.player.global_position + Vector3(0, 1.0, 0)) < 0.95:
			game.player.take_damage(damage, kind)
			_explode()
	else:
		game.check_projectile_hit(self)

func _explode() -> void:
	var color := Color(1, 0.4, 0.1)
	if kind == "ice":
		color = Color(0.5, 0.9, 1)
	game.spawn_pickup(global_position, BlockDefs.FLOWER, color, 8)
	queue_free()
