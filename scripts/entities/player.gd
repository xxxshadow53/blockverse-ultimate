class_name Player
extends CharacterBody3D

## Oyuncu: CharacterBody3D fiziği, 1./3. şahıs kamera, iskelet animasyon, savaş ve inşaat.
var character_index: int = 0
var def: Dictionary
var rig: CharacterRig
var camera_pivot: Node3D
var spring: SpringArm3D
var camera: Camera3D
var world: VoxelWorld
var game: Node
var inventory: Inventory
var highlight: MeshInstance3D

var max_health := 100.0
var health := 100.0
var max_energy := 100.0
var energy := 100.0
var xp := 0.0
var level := 1
var active := false
var third_person := true
var yaw := 0.0
var pitch := -0.1
var move_axis := Vector2.ZERO
var kb_axis := Vector2.ZERO
var run_held := false
var jump_held := false
var target: Dictionary = {}
var _edit_queue: Array[String] = []
var _ray_timer := 0.0
var invuln := 0.0
var ability_cooldown := 0.0
var action_cooldown := 0.0
var stealth_time := 0.0
var swim_time := 0.0
var fall_speed := 0.0
var _stuck_timer := 0.0
var _step_timer := 0.0
var _rig_state := "idle"

func setup(game_ref: Node, world_ref: VoxelWorld, char_index: int) -> void:
	game = game_ref
	world = world_ref
	character_index = char_index
	def = CharacterDefs.get_def(char_index)
	max_health = float(def.get("hp", 100))
	health = max_health
	max_energy = float(def.get("energy", 100))
	energy = max_energy
	inventory = Inventory.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.75
	shape.shape = capsule
	shape.position = Vector3(0, 0.88, 0)
	add_child(shape)
	collision_layer = 2
	collision_mask = 1
	rig = CharacterRig.new(def, 1.0)
	add_child(rig)
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.55, 0)
	camera_pivot.rotation_order = EulerOrder.EULER_ORDER_YXZ
	add_child(camera_pivot)
	spring = SpringArm3D.new()
	spring.spring_length = 4.2
	spring.collision_mask = 1
	spring.margin = 0.25
	camera_pivot.add_child(spring)
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.fov = 68.0
	camera.near = 0.05
	camera.far = 280.0
	spring.add_child(camera)
	camera.make_current()
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.35, 0.92, 1.0, 0.22)
	hm.emission_enabled = true
	hm.emission = Color(0.3, 0.8, 1.0)
	hm.emission_energy_multiplier = 1.2
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.cull_mode = BaseMaterial3D.CULL_FRONT
	var box := BoxMesh.new()
	box.size = Vector3(1.03, 1.03, 1.03)
	highlight = MeshInstance3D.new()
	highlight.mesh = box
	highlight.material_override = hm
	highlight.visible = false
	get_parent().add_child(highlight)

func set_active(value: bool) -> void:
	active = value
	if not value:
		move_axis = Vector2.ZERO
		kb_axis = Vector2.ZERO
		run_held = false
		jump_held = false
		_edit_queue.clear()

func set_move_axis(value: Vector2) -> void:
	move_axis = value.limit_length(1.0)

func add_look(delta: Vector2) -> void:
	var sens := float(GameSettings.get_v("camera_sensitivity", 0.45)) * 0.0035
	yaw -= delta.x * sens
	var invert := -1.0 if bool(GameSettings.get_v("invert_y", false)) else 1.0
	pitch = clampf(pitch - delta.y * sens * invert, -1.25, 1.15)

func press(action: String) -> void:
	match action:
		"jump": jump_held = true
		"run": run_held = true
		"attack": _attack()
		# Kır/koyma dokunma olayında chunk yeniden meshlemez; sonraki kareye kuyruklanır.
		"break":
			if _edit_queue.size() < 2:
				_edit_queue.append("break")
		"place":
			if _edit_queue.size() < 2:
				_edit_queue.append("place")
		"ability": _ability()
		"camera": toggle_camera()
		"inventory": game.toggle_inventory()
		"pause": game.toggle_pause()
		"next": inventory.cycle(1)
		"prev": inventory.cycle(-1)

func release(action: String) -> void:
	match action:
		"jump": jump_held = false
		"run": run_held = false

func toggle_camera() -> void:
	third_person = not third_person
	spring.spring_length = 4.2 if third_person else 0.0
	camera.position = Vector3(0, 0, 0) if third_person else Vector3(0, 0.08, 0)

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and not event.echo:
		var k := event as InputEventKey
		var pressed := k.pressed
		match k.keycode:
			KEY_W: kb_axis.y = 1.0 if pressed else 0.0
			KEY_S: kb_axis.y = -1.0 if pressed else 0.0
			KEY_A: kb_axis.x = -1.0 if pressed else 0.0
			KEY_D: kb_axis.x = 1.0 if pressed else 0.0
			KEY_SPACE:
				if pressed: jump_held = true
				else: jump_held = false
			KEY_SHIFT: run_held = pressed
			KEY_J: if pressed: _attack()
			KEY_K: if pressed: _break_block()
			KEY_L: if pressed: _place_block()
			KEY_E: if pressed: _ability()
			KEY_C: if pressed: toggle_camera()
			KEY_I: if pressed: game.toggle_inventory()
			KEY_ESCAPE: if pressed: game.toggle_pause()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				if pressed:
					inventory.select(k.keycode - KEY_1)
			KEY_Q: if pressed: inventory.cycle(-1)
			KEY_F: if pressed: inventory.cycle(1)
	if event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if not m.pressed:
			return
		if m.button_index == MOUSE_BUTTON_LEFT:
			_attack()
		elif m.button_index == MOUSE_BUTTON_RIGHT:
			_place_block()
		elif m.button_index == MOUSE_BUTTON_MIDDLE:
			_break_block()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		add_look((event as InputEventMouseMotion).relative)

func _physics_process(delta: float) -> void:
	if not active or world == null:
		return
	_unstuck_guard(delta)
	var axis := (move_axis + kb_axis).limit_length(1.0)
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var wish := fwd * axis.y + right * axis.x
	var speed := float(def.get("speed", 5.2))
	if run_held and energy > 1.0:
		speed *= 1.55
		energy = maxf(0.0, energy - 7.0 * delta)
	var head_block := world.get_block(int(floor(global_position.x)), int(floor(global_position.y + 1.2)), int(floor(global_position.z)))
	var in_water := head_block == BlockDefs.WATER
	if in_water:
		speed *= 0.62
		swim_time += delta
	else:
		swim_time = 0.0
	var accel := 12.0 if is_on_floor() else 4.0
	velocity.x = lerpf(velocity.x, wish.x * speed, clampf(accel * delta, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, wish.z * speed, clampf(accel * delta, 0.0, 1.0))
	if in_water:
		velocity.y -= 4.0 * delta
		velocity.y = maxf(velocity.y, -2.0)
		if jump_held:
			velocity.y = 3.2
	elif is_on_floor() and jump_held:
		velocity.y = 6.0
		jump_held = false
	if not is_on_floor():
		fall_speed = minf(fall_speed, velocity.y)
	velocity.y -= 19.0 * delta
	move_and_slide()
	if is_on_floor() and fall_speed < -17.0:
		take_damage((absf(fall_speed) - 17.0) * 2.5, "düşme")
	fall_speed = 0.0
	_update_rig_state(in_water, axis)

func _update_rig_state(in_water: bool, axis: Vector2) -> void:
	var new_state := "idle"
	if in_water:
		new_state = "swim"
	elif not is_on_floor():
		new_state = "jump" if velocity.y > 0.5 else "fall"
	elif axis.length() > 0.12:
		new_state = "run" if run_held else "walk"
	if _rig_state == "attack" and rig.anim_time < 0.5:
		return
	if _rig_state == "break" and rig.anim_time < 0.55:
		return
	if _rig_state == "hurt" and rig.anim_time < 0.35:
		return
	if _rig_state == "ability" and rig.anim_time < 0.6:
		return
	_rig_state = new_state
	rig.set_state(new_state)
	if is_on_floor() and axis.length() > 0.12 and _step_timer <= 0.0:
		_step_timer = 0.34 if run_held else 0.5
		AudioLibrary.play_sfx("step", 0.35, randf_range(0.9, 1.1))

func _process(delta: float) -> void:
	if not active:
		return
	camera_pivot.rotation = Vector3(pitch, yaw, 0)
	invuln = maxf(0.0, invuln - delta)
	ability_cooldown = maxf(0.0, ability_cooldown - delta)
	action_cooldown = maxf(0.0, action_cooldown - delta)
	_step_timer -= delta
	energy = minf(max_energy, energy + (3.5 if run_held else 7.0) * delta)
	if stealth_time > 0.0:
		stealth_time -= delta
		rig.visible = stealth_time <= 0.0 or fmod(stealth_time * 6.0, 1.0) > 0.35
	else:
		rig.visible = true
	_ray_timer -= delta
	if _ray_timer <= 0.0:
		_ray_timer = 0.15 if int(GameSettings.p("render", 3)) <= 2 else 0.08
		_refresh_target()
	flush_edits()

## Kuyruktaki kır/koyma işlemlerini işler. refresh=false testlerde hedefi korur.
func flush_edits(refresh: bool = true) -> void:
	while not _edit_queue.is_empty():
		var action: String = String(_edit_queue.pop_front())
		if refresh:
			_refresh_target()
		if action == "break":
			_break_block()
		elif action == "place":
			_place_block()

func _unstuck_guard(delta: float) -> void:
	var gx := int(floor(global_position.x))
	var gy := int(floor(global_position.y + 0.06))
	var gz := int(floor(global_position.z))
	var embedded := false
	for y in range(gy, gy + 3):
		if BlockDefs.is_solid(world.get_block(gx, y, gz)):
			embedded = true
			break
	if not embedded:
		_stuck_timer = 0.0
		return
	_stuck_timer += delta
	if _stuck_timer >= 0.4:
		global_position = world.find_spawn()
		velocity = Vector3.ZERO
		_stuck_timer = 0.0

func _refresh_target() -> void:
	var origin := camera.global_position
	var cx := int(floor(origin.x))
	var cy := int(floor(origin.y))
	var cz := int(floor(origin.z))
	if BlockDefs.is_solid(world.get_block(cx, cy, cz)):
		origin = global_position + Vector3(0, 1.2, 0)
	target = world.raycast(origin, -camera.global_transform.basis.z, 6.5)
	if target.get("hit", false):
		var b: Vector3i = target["block"]
		highlight.visible = true
		highlight.global_position = Vector3(b.x, b.y, b.z) + Vector3.ONE * 0.5
	else:
		highlight.visible = false

func _attack() -> void:
	if action_cooldown > 0.0 or not active:
		return
	action_cooldown = 0.42
	_rig_state = "attack"
	rig.set_state("attack")
	AudioLibrary.play_sfx("swing", 0.55, randf_range(0.92, 1.08))
	var dmg := float(def.get("damage", 20))
	if stealth_time > 0.0:
		dmg *= 2.2
		stealth_time = 0.0
	var dir := -camera.global_transform.basis.z
	game.melee_attack(global_position + Vector3(0, 1.1, 0), dir, 3.2, dmg)

func _break_block() -> void:
	if action_cooldown > 0.0 or not active or not target.get("hit", false):
		return
	action_cooldown = 0.22 if CharacterDefs.id_of(character_index) == "BUILDER" else 0.32
	var b: Vector3i = target["block"]
	var id := int(target.get("id", 0))
	if id == BlockDefs.AIR:
		return
	_rig_state = "break"
	rig.set_state("break")
	world.set_block(b.x, b.y, b.z, BlockDefs.AIR)
	world.rebuild_at(b.x, b.z)
	game.notify_block_mined()
	var drop := BlockDefs.drop_of(id)
	if drop != BlockDefs.AIR and inventory.add(drop, 1) == 0:
		game.spawn_pickup(Vector3(b.x, b.y, b.z) + Vector3.ONE * 0.5, drop)
	gain_xp(1.0)
	AudioLibrary.play_sfx("break", 0.6, randf_range(0.85, 1.15))

func _place_block() -> void:
	if action_cooldown > 0.0 or not active or not target.get("hit", false):
		return
	var id := inventory.selected_id()
	if id == BlockDefs.AIR or inventory.selected_count() <= 0:
		return
	var b: Vector3i = target["block"]
	var n: Vector3i = target["normal"]
	var p := b + n
	var center := Vector3(p.x, p.y, p.z) + Vector3.ONE * 0.5
	if center.distance_to(global_position) < 1.1:
		return
	if world.get_block(p.x, p.y, p.z) != BlockDefs.AIR:
		return
	world.set_block(p.x, p.y, p.z, id)
	world.rebuild_at(p.x, p.z)
	inventory.remove(id, 1)
	action_cooldown = 0.24
	AudioLibrary.play_sfx("place", 0.5, randf_range(0.9, 1.1))

func _ability() -> void:
	if ability_cooldown > 0.0 or not active:
		return
	var cost := 30.0
	if energy < cost:
		return
	energy -= cost
	ability_cooldown = 6.0
	_rig_state = "ability"
	rig.set_state("ability")
	var kind := String(def.get("ability", "fire"))
	var dir := -camera.global_transform.basis.z
	var origin := global_position + Vector3(0, 1.2, 0) + dir * 0.8
	match kind:
		"fire":
			game.spawn_projectile(origin, dir, "fire", 34.0)
			game.spawn_pickup(origin, BlockDefs.FLOWER, Color(1, 0.35, 0.1), 12)
		"ice":
			game.spawn_projectile(origin, dir, "ice", 28.0)
		"stealth":
			stealth_time = 5.0
			AudioLibrary.play_sfx("ice", 0.5, 0.8)
		"shock":
			game.radial_damage(global_position, 5.0, 42.0)
			game.spawn_pickup(global_position, BlockDefs.FLOWER, Color(1, 0.7, 0.2), 20)
		"volley":
			for i in range(3):
				var spread := dir.rotated(Vector3.UP, (i - 1) * 0.11)
				game.spawn_projectile(origin, spread, "arrow", 24.0)
		"repair":
			health = minf(max_health, health + 38.0)
			energy = minf(max_energy, energy + 20.0)
			game.spawn_pickup(global_position, BlockDefs.FLOWER, Color(0.4, 1, 0.5), 14)
	AudioLibrary.play_sfx("fire" if kind == "fire" else "ice", 0.65)

func gain_xp(amount: float) -> void:
	xp += amount
	if xp >= level * 40:
		xp -= level * 40
		level += 1
		max_health += 8.0
		health = minf(max_health, health + 18.0)
		AudioLibrary.play_sfx("unlock", 0.7)

func take_damage(amount: float, _source: String = "") -> void:
	if invuln > 0.0 or not active:
		return
	health -= amount
	invuln = 0.55
	_rig_state = "hurt"
	rig.trigger_hurt()
	AudioLibrary.play_sfx("hurt", 0.6)
	if health <= 0.0:
		health = 0.0
		game.player_died()

func to_dict() -> Dictionary:
	return {
		"pos": [global_position.x, global_position.y, global_position.z],
		"yaw": yaw, "pitch": pitch,
		"character": character_index,
		"health": health, "energy": energy, "xp": xp, "level": level,
		"inventory": inventory.to_dict(), "selected": inventory.selected
	}

func restore(data: Dictionary) -> void:
	if data.has("pos"):
		var p: Array = data["pos"]
		if p.size() == 3:
			global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	if data.has("yaw"):
		yaw = float(data["yaw"])
	if data.has("pitch"):
		pitch = float(data["pitch"])
	if data.has("health"):
		health = float(data["health"])
	if data.has("energy"):
		energy = float(data["energy"])
	if data.has("xp"):
		xp = float(data["xp"])
	if data.has("level"):
		level = int(data["level"])
	if data.has("inventory"):
		inventory.from_dict(data["inventory"])
	if data.has("selected"):
		inventory.select(int(data["selected"]))
