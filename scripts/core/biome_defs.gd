class_name BiomeDefs
extends RefCounted

## 12 biyom tanımı. Demo tümünü üretimde kullanır; yapı/bitki çeşitliliği genişletilebilir.
const OCEAN := 4
const CRYSTAL := 6

const BIOMES: Array = [
	{"n": "Yeşil Orman", "map": Color(0.27, 0.52, 0.22), "surface": BlockDefs.GRASS, "sub": BlockDefs.DIRT, "tree": 0.075, "deco": "oak", "structure": "village"},
	{"n": "Karlı Dağlar", "map": Color(0.83, 0.88, 0.94), "surface": BlockDefs.SNOW, "sub": BlockDefs.STONE, "tree": 0.02, "deco": "pine", "structure": "temple"},
	{"n": "Çöl", "map": Color(0.84, 0.72, 0.42), "surface": BlockDefs.SAND, "sub": BlockDefs.SANDSTONE, "tree": 0.0, "deco": "cactus", "structure": "temple"},
	{"n": "Tropikal Adalar", "map": Color(0.20, 0.62, 0.48), "surface": BlockDefs.SAND, "sub": BlockDefs.DIRT, "tree": 0.11, "deco": "palm", "structure": "bridge"},
	{"n": "Okyanus", "map": Color(0.13, 0.35, 0.58), "surface": BlockDefs.GRAVEL, "sub": BlockDefs.STONE, "tree": 0.0, "deco": "none", "structure": "ruin"},
	{"n": "Volkanik Bölge", "map": Color(0.42, 0.16, 0.12), "surface": BlockDefs.BASALT, "sub": BlockDefs.BASALT, "tree": 0.0, "deco": "lava", "structure": "ruin"},
	{"n": "Kristal Mağaraları", "map": Color(0.36, 0.58, 0.86), "surface": BlockDefs.STONE, "sub": BlockDefs.CRYSTAL_ORE, "tree": 0.0, "deco": "crystal", "structure": "vault"},
	{"n": "Bataklık", "map": Color(0.30, 0.40, 0.25), "surface": BlockDefs.MOSS_STONE, "sub": BlockDefs.DIRT, "tree": 0.035, "deco": "mushroom", "structure": "ruin"},
	{"n": "Bambu Ormanı", "map": Color(0.56, 0.70, 0.30), "surface": BlockDefs.GRASS, "sub": BlockDefs.DIRT, "tree": 0.13, "deco": "bamboo", "structure": "bridge"},
	{"n": "Büyülü Orman", "map": Color(0.28, 0.72, 0.62), "surface": BlockDefs.MAGIC_GRASS, "sub": BlockDefs.DIRT, "tree": 0.09, "deco": "magic", "structure": "temple"},
	{"n": "Çayırlar", "map": Color(0.48, 0.66, 0.30), "surface": BlockDefs.GRASS, "sub": BlockDefs.DIRT, "tree": 0.008, "deco": "flowers", "structure": "village"},
	{"n": "Karanlık Orman", "map": Color(0.18, 0.22, 0.20), "surface": BlockDefs.MOSS_STONE, "sub": BlockDefs.DIRT, "tree": 0.10, "deco": "dark", "structure": "vault"}
]

static func def(id: int) -> Dictionary:
	return BIOMES[clampi(id, 0, BIOMES.size() - 1)]

static func name_of(id: int) -> String:
	return String(def(id).get("n", "?"))

static func map_color(id: int) -> Color:
	return def(id).get("map", Color.WHITE)

static func surface(id: int) -> int:
	return int(def(id).get("surface", BlockDefs.STONE))

static func subsurface(id: int) -> int:
	return int(def(id).get("sub", BlockDefs.STONE))

static func tree_density(id: int) -> float:
	return float(def(id).get("tree", 0.0))

static func deco(id: int) -> String:
	return String(def(id).get("deco", "none"))

static func structure(id: int) -> String:
	return String(def(id).get("structure", "none"))

## continental: -1..1, temp/hum/special: 0..1, altitude: blok yüksekliği
static func pick(continental: float, temp: float, hum: float, special: float, altitude: float, sea_level: int) -> int:
	if continental < -0.35 or altitude < sea_level - 3:
		return OCEAN
	if special > 0.68 and hum > 0.5:
		return 9  # Büyülü orman
	if special < 0.30 and temp < 0.44:
		return 11  # Karanlık orman
	if temp > 0.80 and special > 0.55:
		return 5  # Volkanik
	if temp > 0.70 and hum < 0.38:
		return 2  # Çöl
	if temp > 0.66 and hum > 0.52:
		return 8  # Bambu / tropikal ayrımı irtifayla
	if hum > 0.74 and altitude < sea_level + 3:
		return 7  # Bataklık
	if temp < 0.24 or altitude > 68:
		return 1  # Karlı dağlar
	if hum < 0.42 and temp > 0.42:
		return 10  # Çayırlar
	return 0  # Yeşil orman

static func is_tropical(temp: float, hum: float, altitude: float, sea_level: int) -> bool:
	return temp > 0.66 and hum > 0.52 and altitude <= sea_level + 4
