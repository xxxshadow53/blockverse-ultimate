class_name Inventory
extends RefCounted

## 9 yuvalı sıcak çubuk + temel üretim tarifleri.
const SLOTS := 9

const RECIPES: Array = [
	{"id": "plank", "name": "Tahta", "need": {BlockDefs.LOG: 1}, "give": BlockDefs.PLANK, "count": 4},
	{"id": "path", "name": "Yol Taşı", "need": {BlockDefs.COBBLESTONE: 2}, "give": BlockDefs.PATH_STONE, "count": 4},
	{"id": "torch", "name": "Meşale", "need": {BlockDefs.PLANK: 1, BlockDefs.COAL_ORE: 1}, "give": BlockDefs.TORCH, "count": 4},
	{"id": "chest", "name": "Sandık", "need": {BlockDefs.PLANK: 4}, "give": BlockDefs.CHEST, "count": 1},
	{"id": "glass", "name": "Cam", "need": {BlockDefs.SAND: 2}, "give": BlockDefs.GLASS, "count": 2},
	{"id": "brick", "name": "Tuğla", "need": {BlockDefs.STONE: 2, BlockDefs.DIRT: 1}, "give": BlockDefs.BRICK, "count": 2}
]

var slots: Array[Dictionary] = []
var selected := 0

func _init() -> void:
	reset()

func reset() -> void:
	slots.clear()
	var starter := [BlockDefs.STONE, BlockDefs.DIRT, BlockDefs.COBBLESTONE, BlockDefs.PLANK, BlockDefs.TORCH, BlockDefs.GLASS, BlockDefs.SAND, BlockDefs.LEAVES, BlockDefs.CHEST]
	var amounts := [64, 64, 48, 32, 16, 16, 32, 32, 4]
	for i in range(SLOTS):
		slots.append({"id": starter[i], "count": amounts[i]})
	selected = 0

func add(id: int, count: int = 1) -> int:
	if id == BlockDefs.AIR:
		return count
	for s in slots:
		if int(s["id"]) == id and int(s["count"]) < 999:
			var add_count := mini(int(s["count"]) + count, 999) - int(s["count"])
			s["count"] = int(s["count"]) + add_count
			count -= add_count
			if count == 0:
				return 0
	for s in slots:
		if int(s["id"]) == BlockDefs.AIR:
			s["id"] = id
			s["count"] = count
			return 0
	return count

func remove(id: int, count: int = 1) -> bool:
	var needed := count
	for s in slots:
		if int(s["id"]) == id:
			var take := mini(int(s["count"]), needed)
			s["count"] = int(s["count"]) - take
			needed -= take
			if int(s["count"]) == 0:
				s["id"] = BlockDefs.AIR
			if needed == 0:
				return true
	return needed == 0

func count_of(id: int) -> int:
	var total := 0
	for s in slots:
		if int(s["id"]) == id:
			total += int(s["count"])
	return total

func select(index: int) -> void:
	selected = clampi(index, 0, SLOTS - 1)

func selected_id() -> int:
	if selected >= slots.size():
		return BlockDefs.STONE
	return int(slots[selected].get("id", BlockDefs.STONE))

func selected_count() -> int:
	if selected >= slots.size():
		return 0
	return int(slots[selected].get("count", 0))

func cycle(delta: int) -> void:
	select((selected + delta + SLOTS) % SLOTS)

func can_craft(recipe: Dictionary) -> bool:
	for id in recipe["need"].keys():
		if count_of(int(id)) < int(recipe["need"][id]):
			return false
	return true

func craft(recipe: Dictionary) -> bool:
	if not can_craft(recipe):
		return false
	for id in recipe["need"].keys():
		remove(int(id), int(recipe["need"][id]))
	add(int(recipe["give"]), int(recipe["count"]))
	return true

func to_dict() -> Array:
	var out: Array = []
	for s in slots:
		out.append({"id": int(s["id"]), "count": int(s["count"])})
	return out

func from_dict(data: Variant) -> void:
	reset()
	if not data is Array:
		return
	for i in range(mini(data.size(), SLOTS)):
		var entry: Variant = data[i]
		if entry is Dictionary:
			slots[i] = {"id": int(entry.get("id", BlockDefs.AIR)), "count": int(entry.get("count", 0))}
