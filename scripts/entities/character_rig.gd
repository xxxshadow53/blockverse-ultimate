class_name CharacterRig
extends Node3D

## Gerçek Skeleton3D + kemik bağlantılı zırh/silah parçaları ve prosedürel iskelet animasyonu.
var skeleton: Skeleton3D
var bones: Dictionary = {}
var definition: Dictionary
var state: String = "idle"
var anim_time: float = 0.0
var move_speed: float = 0.0
var flash: float = 0.0
var _glow_materials: Array[StandardMaterial3D] = []
var _all_materials: Array[StandardMaterial3D] = []

func _init(def_data: Dictionary, detail: float = 1.0) -> void:
	definition = def_data
	_build(detail)

func _ready() -> void:
	set_process(true)

func _mat(color: Color, metallic: float = 0.35, roughness: float = 0.4, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
		_glow_materials.append(m)
	_all_materials.append(m)
	return m

func _bone(bone_name: String, parent: int, offset: Vector3) -> int:
	var i := skeleton.add_bone(bone_name)
	if parent >= 0:
		skeleton.set_bone_parent(i, parent)
	var t := Transform3D(Basis(), offset)
	skeleton.set_bone_rest(i, t)
	bones[bone_name] = i
	return i

func _attach(bone_name: String, node: Node3D, offset: Vector3) -> void:
	var a := BoneAttachment3D.new()
	a.bone_name = bone_name
	skeleton.add_child(a)
	a.position = offset
	a.add_child(node)

func _piece(mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scale
	return mi

func _box(size: Vector3, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _piece(m, mat, pos, rot)

func _capsule(radius: float, height: float, mat: Material, pos: Vector3) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	return _piece(m, mat, pos)

func _sphere(radius: float, mat: Material, pos: Vector3, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	return _piece(m, mat, pos, Vector3.ZERO, scale)

func _cone(radius: float, height: float, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = radius
	m.height = height
	return _piece(m, mat, pos, rot)

func _cyl(radius: float, height: float, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	return _piece(m, mat, pos, rot)

func _build(detail: float) -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "BattleSkeleton"
	add_child(skeleton)
	var hips := _bone("hips", -1, Vector3(0, 0.95, 0))
	var spine := _bone("spine", hips, Vector3(0, 0.28, 0))
	var chest := _bone("chest", spine, Vector3(0, 0.32, 0))
	var head := _bone("head", chest, Vector3(0, 0.42, 0))
	var au_l := _bone("arm_upper_L", chest, Vector3(0.30, 0.24, 0))
	var al_l := _bone("arm_lower_L", au_l, Vector3(0, -0.38, 0))
	var au_r := _bone("arm_upper_R", chest, Vector3(-0.30, 0.24, 0))
	var al_r := _bone("arm_lower_R", au_r, Vector3(0, -0.38, 0))
	var lu_l := _bone("leg_upper_L", hips, Vector3(0.15, -0.04, 0))
	var ll_l := _bone("leg_lower_L", lu_l, Vector3(0, -0.44, 0))
	var lu_r := _bone("leg_upper_R", hips, Vector3(-0.15, -0.04, 0))
	var ll_r := _bone("leg_lower_R", lu_r, Vector3(0, -0.44, 0))

	var armor := _mat(definition.get("armor", Color.GRAY), 0.55, 0.38)
	var trim := _mat(definition.get("trim", Color.WHITE), 0.65, 0.28, 0.35)
	var glow := _mat(definition.get("glow", Color.WHITE), 0.2, 0.3, 2.2)
	var skin := _mat(definition.get("skin", Color.WHITE), 0.05, 0.75)
	var dark := _mat(Color(0.06, 0.06, 0.08), 0.3, 0.5)

	_attach("hips", _box(Vector3(0.52, 0.26, 0.34), armor, Vector3.ZERO), Vector3.ZERO)
	_attach("chest", _box(Vector3(0.62, 0.68, 0.38), armor, Vector3(0, 0.06, 0)), Vector3.ZERO)
	_attach("chest", _box(Vector3(0.28, 0.40, 0.045), trim, Vector3(0, 0.10, -0.215)), Vector3.ZERO)
	_attach("chest", _box(Vector3(0.16, 0.16, 0.05), glow, Vector3(0, 0.12, -0.24)), Vector3.ZERO)
	_attach("head", _sphere(0.21, skin, Vector3.ZERO), Vector3(0, 0.14, 0))
	_attach("head", _sphere(0.032, glow, Vector3(-0.08, 0.17, -0.195)), Vector3(0, 0.14, 0))
	_attach("head", _sphere(0.032, glow, Vector3(0.08, 0.17, -0.195)), Vector3(0, 0.14, 0))
	_build_hair(dark, trim, glow)

	for side in ["L", "R"]:
		var au: int = bones["arm_upper_" + side]
		var al: int = bones["arm_lower_" + side]
		var sign := 1.0 if side == "L" else -1.0
		_attach("arm_upper_" + side, _box(Vector3(0.24, 0.20, 0.34), armor, Vector3(0, -0.02, 0)), Vector3.ZERO)
		_attach("arm_upper_" + side, _capsule(0.105, 0.36, armor, Vector3(0, -0.18, 0)), Vector3.ZERO)
		_attach("arm_lower_" + side, _capsule(0.09, 0.34, skin, Vector3(0, -0.16, 0)), Vector3.ZERO)
		_attach("arm_lower_" + side, _box(Vector3(0.19, 0.20, 0.20), trim, Vector3(0, -0.32, 0)), Vector3.ZERO)
		_attach("leg_upper_" + side, _capsule(0.13, 0.44, armor, Vector3(0, -0.20, 0)), Vector3.ZERO)
		_attach("leg_lower_" + side, _capsule(0.11, 0.42, dark, Vector3(0, -0.20, 0)), Vector3.ZERO)
		_attach("leg_lower_" + side, _box(Vector3(0.24, 0.16, 0.34), armor, Vector3(0, -0.42, -0.05)), Vector3.ZERO)
		_attach("leg_lower_" + side, _box(Vector3(0.26, 0.045, 0.36), trim, Vector3(0, -0.50, -0.05)), Vector3.ZERO)
		_attach("arm_upper_" + side, _sphere(0.05, glow, Vector3(sign * 0.13, -0.03, 0)), Vector3.ZERO)

	_build_weapon(armor, trim, glow, dark)
	if detail > 0.7:
		var style := String(definition.get("hair_style", ""))
		if style == "hood" or style == "ponytail":
			var cape := _box(Vector3(0.58, 0.78, 0.05), armor, Vector3(0, -0.1, 0.24))
			_attach("chest", cape, Vector3.ZERO)

func _build_hair(dark: Material, trim: Material, glow: Material) -> void:
	var style := String(definition.get("hair_style", ""))
	var hair := _mat(definition.get("hair", Color.BLACK), 0.25, 0.55)
	match style:
		"spikes":
			for i in range(7):
				var a := float(i) / 7.0 * TAU
				var spike := _cone(0.09, 0.30, hair, Vector3(cos(a) * 0.15, 0.30, sin(a) * 0.15), Vector3(0.5 * sin(a), 0, -0.5 * cos(a)))
				_attach("head", spike, Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.48, 0.07, 0.40), trim, Vector3(0, 0.26, 0)), Vector3(0, 0.14, 0))
			_attach("head", _cyl(0.10, 0.06, dark, Vector3(-0.21, 0.14, 0), Vector3(0, 0, PI * 0.5)), Vector3(0, 0.14, 0))
			_attach("head", _cyl(0.10, 0.06, dark, Vector3(0.21, 0.14, 0), Vector3(0, 0, PI * 0.5)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.42, 0.04, 0.06), glow, Vector3(0, 0.16, 0.21)), Vector3(0, 0.14, 0))
		"braid":
			_attach("head", _sphere(0.23, hair, Vector3(0, 0.07, 0.03), Vector3(1, 0.6, 1)), Vector3(0, 0.14, 0))
			for i in range(4):
				_attach("head", _cyl(0.065, 0.14, hair, Vector3(0, -0.10 - float(i) * 0.12, 0.19)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.44, 0.08, 0.08), trim, Vector3(0, 0.12, -0.20)), Vector3(0, 0.14, 0))
		"hood":
			_attach("head", _cone(0.29, 0.46, dark, Vector3(0, 0.12, 0.04)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.36, 0.16, 0.06), dark, Vector3(0, 0.02, -0.2)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.32, 0.035, 0.04), trim, Vector3(0, 0.09, -0.23)), Vector3(0, 0.14, 0))
		"helm":
			_attach("head", _box(Vector3(0.48, 0.30, 0.46), dark, Vector3(0, 0.22, 0)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.10, 0.34, 0.30), dark, Vector3(-0.25, 0.06, 0)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.10, 0.34, 0.30), dark, Vector3(0.25, 0.06, 0)), Vector3(0, 0.14, 0))
			_attach("head", _cone(0.09, 0.22, trim, Vector3(0, 0.44, 0)), Vector3(0, 0.14, 0))
		"ponytail":
			_attach("head", _box(Vector3(0.44, 0.18, 0.42), hair, Vector3(0, 0.24, 0)), Vector3(0, 0.14, 0))
			_attach("head", _capsule(0.08, 0.5, hair, Vector3(0, -0.12, 0.24)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.50, 0.05, 0.30), trim, Vector3(0, 0.20, -0.18)), Vector3(0, 0.14, 0))
		"cap":
			_attach("head", _cyl(0.24, 0.16, hair, Vector3(0, 0.28, 0)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.40, 0.04, 0.28), hair, Vector3(0, 0.22, -0.22)), Vector3(0, 0.14, 0))
			_attach("head", _box(Vector3(0.30, 0.06, 0.06), trim, Vector3(0, 0.28, -0.23)), Vector3(0, 0.14, 0))
		_:
			_attach("head", _sphere(0.22, hair, Vector3(0, 0.08, 0.02), Vector3(1, 0.7, 1)), Vector3(0, 0.14, 0))

func _build_weapon(armor: Material, trim: Material, glow: Material, dark: Material) -> void:
	var weapon := String(definition.get("weapon", "sword"))
	match weapon:
		"sword":
			_attach("arm_lower_R", _cyl(0.045, 0.28, dark, Vector3(0, -0.46, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _box(Vector3(0.34, 0.05, 0.09), trim, Vector3(0, -0.62, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _box(Vector3(0.09, 0.72, 0.045), glow, Vector3(0, -0.98, 0)), Vector3.ZERO)
		"icesword":
			_attach("arm_lower_R", _cyl(0.04, 0.26, dark, Vector3(0, -0.46, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _box(Vector3(0.30, 0.05, 0.08), trim, Vector3(0, -0.62, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _cone(0.11, 0.82, glow, Vector3(0, -1.00, 0), Vector3(PI, 0, 0)), Vector3.ZERO)
		"daggers":
			for side in ["L", "R"]:
				_attach("arm_lower_" + side, _cyl(0.035, 0.18, dark, Vector3(0, -0.44, 0)), Vector3.ZERO)
				_attach("arm_lower_" + side, _cone(0.055, 0.34, glow, Vector3(0, -0.66, 0), Vector3(PI, 0, 0)), Vector3.ZERO)
		"hammer":
			_attach("arm_lower_R", _cyl(0.055, 0.95, dark, Vector3(0, -0.72, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _box(Vector3(0.42, 0.30, 0.32), armor, Vector3(0, -1.18, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _box(Vector3(0.46, 0.06, 0.36), trim, Vector3(0, -1.18, -0.17)), Vector3.ZERO)
		"bow":
			for i in range(5):
				var yy := -0.42 - float(i) * 0.15
				var bend := sin(float(i) / 4.0 * PI) * 0.16
				_attach("arm_lower_L", _box(Vector3(0.05, 0.16, 0.05), trim, Vector3(-0.20 + bend, yy, 0), Vector3(0, 0, 0.3 - float(i) * 0.15)), Vector3.ZERO)
			_attach("arm_lower_L", _cyl(0.008, 0.72, glow, Vector3(-0.18, -0.75, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _box(Vector3(0.04, 0.04, 0.62), trim, Vector3(0, -0.55, -0.25)), Vector3.ZERO)
		"pickaxe":
			_attach("arm_lower_R", _cyl(0.045, 0.90, dark, Vector3(0, -0.70, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _box(Vector3(0.62, 0.08, 0.10), armor, Vector3(0, -1.15, 0)), Vector3.ZERO)
			_attach("arm_lower_R", _cone(0.09, 0.28, trim, Vector3(0.32, -1.15, 0), Vector3(0, 0, -PI * 0.5)), Vector3.ZERO)
			_attach("arm_lower_R", _cone(0.09, 0.28, trim, Vector3(-0.32, -1.15, 0), Vector3(0, 0, PI * 0.5)), Vector3.ZERO)

func set_state(new_state: String) -> void:
	if state != new_state:
		state = new_state
		anim_time = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	_apply_pose()

func _apply_pose() -> void:
	if skeleton == null:
		return
	for i in bones.values():
		skeleton.set_bone_pose_rotation(i, Quaternion.IDENTITY)
		skeleton.set_bone_pose_position(i, Vector3.ZERO)
		skeleton.set_bone_pose_scale(i, Vector3.ONE)
	var t := anim_time
	var hips: int = bones["hips"]
	var chest: int = bones["chest"]
	var head: int = bones["head"]
	var au_l: int = bones["arm_upper_L"]
	var au_r: int = bones["arm_upper_R"]
	var al_r: int = bones["arm_lower_R"]
	var lu_l: int = bones["leg_upper_L"]
	var lu_r: int = bones["leg_upper_R"]
	var ll_l: int = bones["leg_lower_L"]
	var ll_r: int = bones["leg_lower_R"]

	match state:
		"idle":
			skeleton.set_bone_pose_position(hips, Vector3(0, sin(t * 1.7) * 0.015, 0))
			_rot(chest, Vector3(sin(t * 1.1) * 0.025, 0, 0))
			_rot(au_l, Vector3(0.05 + sin(t * 1.1) * 0.03, 0, 0.08))
			_rot(au_r, Vector3(0.05 - sin(t * 1.1) * 0.03, 0, -0.08))
			_rot(head, Vector3(sin(t * 0.7) * 0.04, sin(t * 0.35) * 0.12, 0))
		"walk", "run":
			var speed := 7.0 if state == "run" else 4.6
			var phase := t * speed
			var amp := 0.75 if state == "run" else 0.48
			var s := sin(phase)
			_rot(lu_l, Vector3(s * amp, 0, 0))
			_rot(lu_r, Vector3(-s * amp, 0, 0))
			_rot(ll_l, Vector3(maxf(0.0, -s) * 0.75, 0, 0))
			_rot(ll_r, Vector3(maxf(0.0, s) * 0.75, 0, 0))
			_rot(au_l, Vector3(-s * amp * 0.75, 0, 0.06))
			_rot(au_r, Vector3(s * amp * 0.75, 0, -0.06))
			_rot(chest, Vector3(0.08 if state == "run" else 0.03, s * 0.05, 0))
			skeleton.set_bone_pose_position(hips, Vector3(0, absf(s) * (0.05 if state == "run" else 0.025), 0))
		"jump":
			_rot(lu_l, Vector3(-0.65, 0, 0.08))
			_rot(lu_r, Vector3(-0.35, 0, -0.08))
			_rot(ll_l, Vector3(0.9, 0, 0))
			_rot(ll_r, Vector3(0.55, 0, 0))
			_rot(au_l, Vector3(-1.5, 0, 0.2))
			_rot(au_r, Vector3(-1.5, 0, -0.2))
		"fall":
			_rot(lu_l, Vector3(0.35, 0, 0.15))
			_rot(lu_r, Vector3(0.25, 0, -0.15))
			_rot(au_l, Vector3(-0.4, 0, 0.85))
			_rot(au_r, Vector3(-0.4, 0, -0.85))
			_rot(chest, Vector3(-0.12, 0, 0))
		"swim":
			var phase := t * 5.0
			_rot(chest, Vector3(-0.95, 0, 0))
			_rot(au_l, Vector3(-1.2 + sin(phase) * 0.6, 0, 0.2))
			_rot(au_r, Vector3(-1.2 - sin(phase) * 0.6, 0, -0.2))
			_rot(lu_l, Vector3(sin(phase * 1.3) * 0.4, 0, 0))
			_rot(lu_r, Vector3(-sin(phase * 1.3) * 0.4, 0, 0))
			skeleton.set_bone_pose_position(hips, Vector3(0, 0.05 + sin(phase) * 0.03, 0))
		"climb":
			var phase := t * 5.0
			_rot(au_l, Vector3(-1.6 + sin(phase) * 0.9, 0, 0))
			_rot(au_r, Vector3(-1.6 - sin(phase) * 0.9, 0, 0))
			_rot(lu_l, Vector3(sin(phase) * 0.4, 0, 0))
			_rot(lu_r, Vector3(-sin(phase) * 0.4, 0, 0))
			_rot(chest, Vector3(0.12, 0, 0))
		"attack":
			var p := clampf(fmod(t, 0.5) / 0.5, 0.0, 1.0)
			var swing := -2.2 + p * 3.0
			_rot(au_r, Vector3(swing, 0, -0.25))
			_rot(al_r, Vector3(-0.6 + p * 0.5, 0, 0))
			_rot(chest, Vector3(0, -0.35 + p * 0.7, 0))
			_rot(au_l, Vector3(-0.5, 0, 0.2))
		"break":
			var p := clampf(fmod(t, 0.55) / 0.55, 0.0, 1.0)
			var chop := -1.6 + sin(p * PI) * 2.2
			_rot(au_r, Vector3(chop, 0, -0.1))
			_rot(au_l, Vector3(chop * 0.8, 0, 0.1))
			_rot(chest, Vector3(sin(p * PI) * 0.35, 0, 0))
		"hurt":
			_rot(chest, Vector3(-0.4, 0, 0.12))
			_rot(head, Vector3(-0.25, 0, 0))
			_rot(au_l, Vector3(-0.5, 0, 0.5))
			_rot(au_r, Vector3(-0.5, 0, -0.5))
		"ability":
			var pulse := sin(t * 9.0) * 0.25
			_rot(au_l, Vector3(-1.7 + pulse, 0, 0.35))
			_rot(au_r, Vector3(-1.7 + pulse, 0, -0.35))
			_rot(chest, Vector3(-0.15, 0, 0))
			for m in _glow_materials:
				m.emission_energy_multiplier = 2.2 + pulse * 3.0
		"death":
			_rot(hips, Vector3(-1.45, 0, 0))
			_rot(chest, Vector3(-0.2, 0, 0.2))
			_rot(au_l, Vector3(0.4, 0, 0.8))
			_rot(au_r, Vector3(0.4, 0, -0.8))
		_:
			pass
	if flash > 0.0:
		flash = maxf(0.0, flash - 0.06)
		for m in _all_materials:
			m.albedo_color = m.albedo_color.lerp(Color.WHITE, flash * 0.5)

func _rot(bone: int, euler: Vector3) -> void:
	skeleton.set_bone_pose_rotation(bone, Quaternion.from_euler(euler))

func trigger_attack() -> void:
	set_state("attack")

func trigger_hurt() -> void:
	set_state("hurt")
	flash = 1.0
