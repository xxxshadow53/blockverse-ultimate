class_name Enemy
extends CharacterBody3D

## Durum makinesi tabanlı AI: algılama, takip, saldırı, kaçma ve mesafeli atış.
var type_index: int
var type_def: Dictionary
var rig: CharacterRig
var game: Node
var world: VoxelWorld
var player: Player
var health: float
var state := "idle"
var attack_cd := 0.0
var state_time := 0.0
var dead := false
var wander_dir := Vector3.ZERO
var slow_time := 0.0
var burn_time := 0.0

func setup(index: int, game_ref: Node, world_ref: VoxelWorld, player_ref: Player) -> void:
	type_index = index
	type_def = EnemyDefs.get_type(index)
	game = game_ref
	world = world_ref
	player = player_ref
	health = float(type_def.get("hp", 50))
	var rig_def := {
		"armor": type_def.get("armor", Color.GRAY),
		"trim": type_def.get("trim", Color.WHITE),
		"hair": type_def.get("trim", Color.WHITE),
		"skin": type_def.get("armor", Color.GRAY),
		"glow": type_def.get("glow", Color.WHITE),
		"accent": type_def.get("trim", Color.WHITE),
		"hp": health, "energy": 100.0, "speed": type_def.get("speed", 3.0),
		"damage": type_def.get("damage", 8), "ability": "none",
		"weapon": type_def.get("weapon", "sword"), "hair_style": type_def.get("hair_style", "none")
	}
	rig = CharacterRig.new(rig_def, 0.45)
	add_child(rig)
	var id := String(type_def.get("id", "zombie"))
	if id == "wolf":
		rig.scale = Vector3(0.8, 0.72, 1.05)
	elif id == "golem":
		rig.scale = Vector3(1.35, 1.25, 1.35)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34 * rig.scale.x
	cap.height = 1.75 * rig.scale.y
	shape.shape = cap
	shape.position = Vector3(0, 0.88 * rig.scale.y, 0)
	add_child(shape)
	collision_layer = 4
	collision_mask = 1 | 2
	wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

func _physics_process(delta: float) -> void:
	if dead or player == null:
		return
	attack_cd = maxf(0.0, attack_cd - delta)
	state_time += delta
	slow_time = maxf(0.0, slow_time - delta)
	if burn_time > 0.0:
		burn_time -= delta
		health -= 7.0 * delta
		if health <= 0.0:
			_die()
			return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist > 45.0:
		# Uzak düşmanların AI'sı çalışmaz; yaklaşınca kaldığı yerden devam eder.
		return
	if dist > 75.0:
		queue_free()
		return
	var speed := float(type_def.get("speed", 3.0)) * (0.45 if slow_time > 0.0 else 1.0)
	var detect := float(type_def.get("detect", 16))
	var attack_range := float(type_def.get("range", 1.7))
	var next_state := state
	if dist < detect:
		if String(type_def.get("id", "")) == "skeleton" and dist > 5.0 and dist < 16.0:
			next_state = "ranged"
		elif dist <= attack_range:
			next_state = "attack"
		else:
			next_state = "chase"
	elif health < float(type_def.get("hp", 50)) * 0.3 and String(type_def.get("id", "")) == "wolf":
		next_state = "flee"
	else:
		next_state = "patrol"
	if next_state != state:
		state = next_state
		state_time = 0.0
	var wish := Vector3.ZERO
	match state:
		"chase":
			wish = to_player.normalized()
			if state_time > 3.0 and randf() < 0.02:
				wander_dir = Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		"patrol":
			if state_time > 3.0:
				wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				state_time = 0.0
			wish = wander_dir
		"flee":
			wish = -to_player.normalized()
			speed *= 1.35
		"attack":
			if attack_cd <= 0.0:
				attack_cd = 1.3
				rig.set_state("attack")
				player.take_damage(float(type_def.get("damage", 8)), String(type_def.get("id", "enemy")))
				AudioLibrary.play_sfx("hit", 0.5)
		"ranged":
			if attack_cd <= 0.0:
				attack_cd = 2.5
				rig.set_state("attack")
				var origin := global_position + Vector3(0, 1.2, 0)
				game.spawn_projectile(origin, to_player.normalized(), "bone", float(type_def.get("damage", 8)) * 0.8, true)
	if state == "chase" or state == "patrol" or state == "flee":
		var nx := global_position + wish * 0.8
		var ground := world.get_block(int(floor(nx.x)), int(floor(global_position.y - 0.2)), int(floor(nx.z)))
		if ground == BlockDefs.AIR or ground == BlockDefs.WATER:
			if is_on_floor():
				velocity.y = 5.5
		velocity.x = lerpf(velocity.x, wish.x * speed, 0.16)
		velocity.z = lerpf(velocity.z, wish.z * speed, 0.16)
		var anim := "run" if state == "chase" else "walk"
		rig.set_state(anim)
	else:
		velocity.x = lerpf(velocity.x, 0.0, 0.2)
		velocity.z = lerpf(velocity.z, 0.0, 0.2)
	velocity.y -= 19.0 * delta
	move_and_slide()

func take_damage(amount: float, status: String = "") -> void:
	if dead:
		return
	health -= amount
	rig.trigger_hurt()
	if status == "fire":
		burn_time = 3.0
	elif status == "ice":
		slow_time = 4.0
	AudioLibrary.play_sfx("hit", 0.5, randf_range(0.9, 1.1))
	if health <= 0.0:
		_die()

func _die() -> void:
	if dead:
		return
	dead = true
	rig.set_state("death")
	collision_layer = 0
	collision_mask = 0
	game.on_enemy_died(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.9)
	tween.tween_callback(queue_free)

func distance_to_player() -> float:
	if player == null:
		return 1e9
	return global_position.distance_to(player.global_position)
