class_name BlockDefs
extends RefCounted

## Blok kimlikleri ve özellikleri. Dünya verisi bu kimlikleri kullanır.
const AIR := 0
const GRASS := 1
const DIRT := 2
const STONE := 3
const COBBLESTONE := 4
const SAND := 5
const SNOW := 6
const ICE := 7
const WATER := 8
const LOG := 9
const LEAVES := 10
const PLANK := 11
const COAL_ORE := 12
const IRON_ORE := 13
const GOLD_ORE := 14
const DIAMOND_ORE := 15
const CRYSTAL_ORE := 16
const LAVA := 17
const BASALT := 18
const OBSIDIAN := 19
const GRAVEL := 20
const CACTUS := 21
const BAMBOO := 22
const MAGIC_GRASS := 23
const DARK_LOG := 24
const MOSS_STONE := 25
const BRICK := 26
const GLASS := 27
const TORCH := 28
const CHEST := 29
const SANDSTONE := 30
const SNOW_BLOCK := 31
const ICE_BLOCK := 32
const ASH := 33
const FLOWER := 34
const TALL_GRASS := 35
const MUSHROOM := 36
const FIRESTONE := 37
const STAR_ORE := 38
const PATH_STONE := 39

const COUNT := 40
const F_TOP := 0
const F_SIDE := 1
const F_BOTTOM := 2

## pattern: noise | speckle | grass | ore | glass | crystal | stripe | emblem | glow
const DEFS: Array = [
	{"n": "Hava", "solid": false, "liquid": false, "cut": false, "c": Color(0, 0, 0, 0), "p": "noise", "h": 0.0, "drop": 0},
	{"n": "Çimen", "solid": true, "liquid": false, "cut": false, "c": Color(0.31, 0.55, 0.20), "p": "grass", "h": 0.5, "drop": 2},
	{"n": "Toprak", "solid": true, "liquid": false, "cut": false, "c": Color(0.40, 0.29, 0.18), "p": "speckle", "h": 0.5, "drop": 2},
	{"n": "Taş", "solid": true, "liquid": false, "cut": false, "c": Color(0.44, 0.46, 0.48), "p": "noise", "h": 1.0, "drop": 4},
	{"n": "Kırık Taş", "solid": true, "liquid": false, "cut": false, "c": Color(0.36, 0.37, 0.39), "p": "speckle", "h": 1.0, "drop": 4},
	{"n": "Kum", "solid": true, "liquid": false, "cut": false, "c": Color(0.82, 0.72, 0.45), "p": "speckle", "h": 0.5, "drop": 5},
	{"n": "Kar", "solid": true, "liquid": false, "cut": false, "c": Color(0.90, 0.94, 0.98), "p": "speckle", "h": 0.3, "drop": 31},
	{"n": "Buz", "solid": true, "liquid": false, "cut": false, "c": Color(0.55, 0.78, 0.90), "p": "crystal", "h": 0.4, "drop": 32},
	{"n": "Su", "solid": false, "liquid": true, "cut": false, "c": Color(0.12, 0.42, 0.62), "p": "noise", "h": 0.0, "drop": 0},
	{"n": "Kütük", "solid": true, "liquid": false, "cut": false, "c": Color(0.36, 0.25, 0.14), "p": "stripe", "h": 0.8, "drop": 9},
	{"n": "Yaprak", "solid": true, "liquid": false, "cut": false, "c": Color(0.20, 0.45, 0.16), "p": "noise", "h": 0.2, "drop": 10},
	{"n": "Tahta", "solid": true, "liquid": false, "cut": false, "c": Color(0.62, 0.43, 0.24), "p": "stripe", "h": 0.7, "drop": 11},
	{"n": "Kömür Cevheri", "solid": true, "liquid": false, "cut": false, "c": Color(0.41, 0.42, 0.44), "p": "ore", "h": 1.2, "drop": 12},
	{"n": "Demir Cevheri", "solid": true, "liquid": false, "cut": false, "c": Color(0.48, 0.44, 0.40), "p": "ore", "h": 1.4, "drop": 13},
	{"n": "Altın Cevheri", "solid": true, "liquid": false, "cut": false, "c": Color(0.52, 0.48, 0.33), "p": "ore", "h": 1.5, "drop": 14},
	{"n": "Elmas Cevheri", "solid": true, "liquid": false, "cut": false, "c": Color(0.40, 0.48, 0.55), "p": "ore", "h": 1.8, "drop": 15},
	{"n": "Kristal Cevheri", "solid": true, "liquid": false, "cut": false, "c": Color(0.30, 0.55, 0.78), "p": "crystal", "h": 1.6, "drop": 16},
	{"n": "Lava", "solid": false, "liquid": true, "cut": false, "c": Color(0.95, 0.30, 0.06), "p": "glow", "h": 0.0, "drop": 0},
	{"n": "Bazalt", "solid": true, "liquid": false, "cut": false, "c": Color(0.17, 0.17, 0.19), "p": "noise", "h": 1.4, "drop": 18},
	{"n": "Obsidyen", "solid": true, "liquid": false, "cut": false, "c": Color(0.08, 0.07, 0.12), "p": "crystal", "h": 2.5, "drop": 19},
	{"n": "Çakıl", "solid": true, "liquid": false, "cut": false, "c": Color(0.48, 0.46, 0.43), "p": "speckle", "h": 0.6, "drop": 20},
	{"n": "Kaktüs", "solid": true, "liquid": false, "cut": false, "c": Color(0.18, 0.42, 0.22), "p": "stripe", "h": 0.5, "drop": 21},
	{"n": "Bambu", "solid": true, "liquid": false, "cut": false, "c": Color(0.55, 0.70, 0.27), "p": "stripe", "h": 0.3, "drop": 22},
	{"n": "Büyülü Çimen", "solid": true, "liquid": false, "cut": false, "c": Color(0.30, 0.66, 0.52), "p": "glow", "h": 0.4, "drop": 23},
	{"n": "Karanlık Kütük", "solid": true, "liquid": false, "cut": false, "c": Color(0.19, 0.15, 0.22), "p": "stripe", "h": 0.9, "drop": 24},
	{"n": "Yosunlu Taş", "solid": true, "liquid": false, "cut": false, "c": Color(0.32, 0.40, 0.28), "p": "speckle", "h": 1.0, "drop": 25},
	{"n": "Tuğla", "solid": true, "liquid": false, "cut": false, "c": Color(0.52, 0.25, 0.20), "p": "emblem", "h": 1.1, "drop": 26},
	{"n": "Cam", "solid": true, "liquid": false, "cut": false, "c": Color(0.62, 0.82, 0.90), "p": "glass", "h": 0.3, "drop": 27},
	{"n": "Meşale", "solid": false, "liquid": false, "cut": true, "c": Color(0.95, 0.68, 0.25), "p": "glow", "h": 0.1, "drop": 28},
	{"n": "Sandalık", "solid": true, "liquid": false, "cut": false, "c": Color(0.44, 0.28, 0.14), "p": "emblem", "h": 1.0, "drop": 29},
	{"n": "Kum Taşı", "solid": true, "liquid": false, "cut": false, "c": Color(0.76, 0.66, 0.43), "p": "stripe", "h": 0.9, "drop": 30},
	{"n": "Kar Bloku", "solid": true, "liquid": false, "cut": false, "c": Color(0.88, 0.93, 0.99), "p": "noise", "h": 0.3, "drop": 31},
	{"n": "Buz Bloku", "solid": true, "liquid": false, "cut": false, "c": Color(0.48, 0.73, 0.88), "p": "crystal", "h": 0.4, "drop": 32},
	{"n": "Kül", "solid": true, "liquid": false, "cut": false, "c": Color(0.22, 0.21, 0.22), "p": "speckle", "h": 0.5, "drop": 33},
	{"n": "Çiçek", "solid": false, "liquid": false, "cut": true, "c": Color(0.92, 0.32, 0.48), "p": "emblem", "h": 0.1, "drop": 34},
	{"n": "Uzun Çimen", "solid": false, "liquid": false, "cut": true, "c": Color(0.34, 0.62, 0.24), "p": "stripe", "h": 0.1, "drop": 35},
	{"n": "Mantar", "solid": false, "liquid": false, "cut": true, "c": Color(0.70, 0.30, 0.36), "p": "emblem", "h": 0.1, "drop": 36},
	{"n": "Ateş Taşı", "solid": true, "liquid": false, "cut": false, "c": Color(0.72, 0.20, 0.08), "p": "glow", "h": 1.2, "drop": 37},
	{"n": "Yıldız Cevheri", "solid": true, "liquid": false, "cut": false, "c": Color(0.38, 0.50, 0.82), "p": "glow", "h": 2.0, "drop": 38},
	{"n": "Yol Taşı", "solid": true, "liquid": false, "cut": false, "c": Color(0.42, 0.41, 0.38), "p": "speckle", "h": 0.6, "drop": 39}
]

static func def(id: int) -> Dictionary:
	if id < 0 or id >= DEFS.size():
		return DEFS[0]
	return DEFS[id]

static func name_of(id: int) -> String:
	return String(def(id).get("n", "?"))

static func is_solid(id: int) -> bool:
	return bool(def(id).get("solid", false))

static func is_liquid(id: int) -> bool:
	return bool(def(id).get("liquid", false))

static func is_cutout(id: int) -> bool:
	return bool(def(id).get("cut", false))

static func is_air(id: int) -> bool:
	return id == AIR

static func is_opaque(id: int) -> bool:
	return is_solid(id) and not is_cutout(id) and id != GLASS

static func tile(id: int, face: int) -> int:
	return clampi(id, 0, COUNT - 1) * 3 + clampi(face, 0, 2)

static func color_of(id: int) -> Color:
	return def(id).get("c", Color.WHITE)

static func hardness(id: int) -> float:
	return float(def(id).get("h", 0.5))

static func drop_of(id: int) -> int:
	return int(def(id).get("drop", 0))

static func pattern_of(id: int) -> String:
	return String(def(id).get("p", "noise"))

static func placeable() -> Array[int]:
	var out: Array[int] = []
	for i in range(1, COUNT):
		if i != WATER and i != LAVA:
			out.append(i)
	return out
