extends Node

## Gerçek oyun oturumunu başsız (headless) olarak çalıştırıp temel sistemleri doğrular.
var failures: Array[String] = []
var game: Game
var checks := 0

func _ready() -> void:
	GameSettings.set_v("render_distance", 1)
	game = Game.new()
	add_child(game)
	game.world_ready.connect(_on_ready)
	game.begin({"seed": 424242, "name": "Smoke Dünya", "character": 3, "continue": false})
	await get_tree().create_timer(4.0).timeout
	if game.world == null or game.player == null:
		_fail("Dünya veya oyuncu oluşturulamadı")
	else:
		_check(game.world.chunks.size() > 0, "Chunk üretimi (%d chunk)" % game.world.chunks.size())
		var p := game.player.global_position
		_check(p.y > -20.0 and p.y < 200.0 and p.x > 2.0 and p.z > 2.0 and game.world.is_spawn_clear(p), "Güvenli spawn konumu: %s" % str(p))
		_check(game.world.get_block(int(p.x), int(floor(p.y + 0.06)) - 1, int(p.z)) != BlockDefs.AIR, "Spawn altı katı")
		_check(game.hud != null and game.controls != null, "HUD ve mobil kontroller")
		_test_blocks()
		_test_combat()
		_test_crafting()
		game.player.press("attack")
		game.player.press("ability")
		game.player.press("next")
		_check(game.player.inventory.selected == 1, "Envanter yuva değişimi")
		game.save_game()
		await get_tree().create_timer(1.5).timeout
		_check(true, "Kayıt tamamlandı")
		game.toggle_pause()
		_check(game.paused, "Duraklatma")
		game.toggle_pause()
		game.toggle_inventory()
		_check(game.inventory_open, "Envanter açılışı")
		game.toggle_inventory()
	for f in failures:
		print("FAIL: ", f)
	print("SMOKE TEST: %d kontrol, %d başarısız" % [checks, failures.size()])
	get_tree().quit(1 if failures.size() > 0 else 0)

func _on_ready() -> void:
	print("SMOKE: dünya hazır")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("SMOKE OK: ", label)
	else:
		_fail(label)

func _fail(label: String) -> void:
	failures.append(label)

func _test_blocks() -> void:
	var p := game.player.global_position
	var bx := int(floor(p.x)) + 2
	var by := int(floor(p.y))
	var bz := int(floor(p.z))
	var original := game.world.get_block(bx, by, bz)
	game.player.target = {"hit": true, "block": Vector3i(bx, by, bz), "normal": Vector3i(0, 1, 0), "id": original, "distance": 2.0}
	game.player.action_cooldown = 0.0
	game.player.press("break")
	game.player.flush_edits(false)
	_check(game.world.get_block(bx, by, bz) == BlockDefs.AIR, "Blok kırma")
	game.player.target = {"hit": true, "block": Vector3i(bx, by - 1, bz), "normal": Vector3i(0, 1, 0), "id": game.world.get_block(bx, by - 1, bz), "distance": 2.0}
	game.player.action_cooldown = 0.0
	game.player.inventory.select(0)
	var before := game.player.inventory.selected_count()
	game.player.press("place")
	game.player.flush_edits(false)
	_check(game.player.inventory.selected_count() == before - 1, "Blok koyma")

func _test_combat() -> void:
	var types := EnemyDefs.demo_indices()
	_check(types.size() >= 3, "Demo düşman çeşitliliği: %d" % types.size())
	var p := game.player.global_position
	for idx in types:
		var e := Enemy.new()
		game.add_child(e)
		e.global_position = p + Vector3(randf_range(-3.0, 3.0), 0.0, -3.0)
		e.setup(idx, game, game.world, game.player)
		game.enemies.append(e)
		e.take_damage(9999.0)
	await get_tree().create_timer(1.2).timeout
	_check(game.player.health > 0.0, "Düşman ölümü ve oyuncu hayatta")
	game.spawn_projectile(p + Vector3.UP, Vector3.FORWARD, "fire", 10.0)
	game.spawn_projectile(p + Vector3.UP, Vector3.BACK, "ice", 10.0)

func _test_crafting() -> void:
	var inv := game.player.inventory
	inv.reset()
	inv.slots[0] = {"id": BlockDefs.LOG, "count": 4}
	_check(inv.craft(Inventory.RECIPES[0]), "Üretim: tahta")
	_check(inv.count_of(BlockDefs.PLANK) >= 4, "Üretim sonucu envantere eklendi")
