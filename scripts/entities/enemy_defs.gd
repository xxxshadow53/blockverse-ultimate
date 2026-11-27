class_name EnemyDefs
extends RefCounted

## Genişletilebilir AI yaratık kayıtları. demo=true olanlar ilk sürümde gerçektenSpawn edilir.
const TYPES: Array = [
	{"id": "zombie", "name": "Zombi", "hp": 60, "speed": 2.4, "damage": 10, "range": 1.7, "detect": 16, "xp": 8, "armor": Color(0.28, 0.38, 0.26), "trim": Color(0.42, 0.22, 0.18), "glow": Color(0.55, 0.85, 0.30), "weapon": "pickaxe", "hair_style": "none", "demo": true},
	{"id": "skeleton", "name": "İskelet Savaşçı", "hp": 48, "speed": 3.0, "damage": 9, "range": 1.8, "detect": 18, "xp": 10, "armor": Color(0.78, 0.76, 0.68), "trim": Color(0.35, 0.28, 0.20), "glow": Color(0.95, 0.75, 0.25), "weapon": "bow", "hair_style": "none", "demo": true},
	{"id": "wolf", "name": "Kurt", "hp": 36, "speed": 4.8, "damage": 8, "range": 1.5, "detect": 20, "xp": 6, "armor": Color(0.32, 0.30, 0.28), "trim": Color(0.20, 0.18, 0.17), "glow": Color(1.0, 0.25, 0.20), "weapon": "daggers", "hair_style": "hood", "demo": true},
	{"id": "golem", "name": "Taş Golem", "hp": 150, "speed": 1.7, "damage": 22, "range": 2.4, "detect": 14, "xp": 25, "armor": Color(0.42, 0.44, 0.45), "trim": Color(0.28, 0.62, 0.48), "glow": Color(0.35, 0.95, 0.70), "weapon": "hammer", "hair_style": "helm", "demo": true},
	{"id": "fireling", "name": "Ateş Yaratığı", "hp": 75, "speed": 3.4, "damage": 14, "range": 2.0, "detect": 18, "xp": 16, "armor": Color(0.42, 0.12, 0.06), "trim": Color(0.95, 0.35, 0.05), "glow": Color(1.0, 0.45, 0.08), "weapon": "sword", "hair_style": "spikes", "demo": false},
	{"id": "dragon", "name": "Ejderha", "hp": 600, "speed": 5.0, "damage": 40, "range": 4.0, "detect": 35, "xp": 200, "armor": Color(0.35, 0.08, 0.10), "trim": Color(0.85, 0.20, 0.10), "glow": Color(1.0, 0.6, 0.1), "weapon": "hammer", "hair_style": "spikes", "demo": false},
	{"id": "villager", "name": "Köylü", "hp": 40, "speed": 2.5, "damage": 0, "range": 0, "detect": 5, "xp": 4, "armor": Color(0.52, 0.40, 0.26), "trim": Color(0.70, 0.50, 0.25), "glow": Color(1, 1, 1), "weapon": "pickaxe", "hair_style": "cap", "demo": false},
	{"id": "animal", "name": "Orman Hayvanı", "hp": 25, "speed": 3.2, "damage": 0, "range": 0, "detect": 9, "xp": 3, "armor": Color(0.58, 0.45, 0.32), "trim": Color(0.36, 0.28, 0.20), "glow": Color(1, 1, 1), "weapon": "daggers", "hair_style": "none", "demo": false},
	{"id": "boss", "name": "Bölüm Sonu Canavarı", "hp": 900, "speed": 2.8, "damage": 55, "range": 4.5, "detect": 28, "xp": 500, "armor": Color(0.14, 0.10, 0.22), "trim": Color(0.65, 0.15, 0.85), "glow": Color(0.85, 0.25, 1.0), "weapon": "hammer", "hair_style": "helm", "demo": false},
	{"id": "spider", "name": "Örümcek", "hp": 42, "speed": 4.0, "damage": 11, "range": 1.6, "detect": 15, "xp": 9, "armor": Color(0.16, 0.12, 0.18), "trim": Color(0.40, 0.10, 0.20), "glow": Color(1, 0.1, 0.2), "weapon": "daggers", "hair_style": "hood", "demo": false}
]

static func get_type(index: int) -> Dictionary:
	return TYPES[clampi(index, 0, TYPES.size() - 1)]

static func demo_indices() -> Array[int]:
	var out: Array[int] = []
	for i in range(TYPES.size()):
		if bool(TYPES[i].get("demo", false)):
			out.append(i)
	return out
