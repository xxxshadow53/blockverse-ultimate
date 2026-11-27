class_name CharacterDefs
extends RefCounted

## Altı özgün, birbirinden farklı savaşçı. İsimler ve tasarımlar özgündür.
const CHARS: Array = [
	{
		"id": "INFERNO", "name": "INFERNO", "title": "Alevin Oğlu",
		"desc": "Kırmızı-siyah dikenli saçı, kulaklığı ve alev kılıcıyla öncü savaşçı. Yakıcı enerji patlatır.",
		"armor": Color(0.13, 0.12, 0.16), "trim": Color(0.95, 0.16, 0.20), "hair": Color(0.09, 0.07, 0.09),
		"skin": Color(0.80, 0.60, 0.48), "glow": Color(1.0, 0.25, 0.08), "accent": Color(0.96, 0.42, 0.12),
		"hp": 125.0, "energy": 100.0, "speed": 5.6, "damage": 24.0, "ability": "fire", "weapon": "sword", "hair_style": "spikes"
	},
	{
		"id": "FROST", "name": "FROST", "title": "Buzun Muhafızı",
		"desc": "Beyaz-mavi zırhı ve buz kılıcıyla düşmanları dondurur; buz kristali fırlatır.",
		"armor": Color(0.78, 0.88, 0.95), "trim": Color(0.22, 0.58, 0.92), "hair": Color(0.86, 0.94, 1.0),
		"skin": Color(0.75, 0.62, 0.55), "glow": Color(0.40, 0.82, 1.0), "accent": Color(0.62, 0.90, 1.0),
		"hp": 110.0, "energy": 110.0, "speed": 5.2, "damage": 21.0, "ability": "ice", "weapon": "icesword", "hair_style": "braid"
	},
	{
		"id": "SHADOW", "name": "SHADOW", "title": "Gecenin Gölgesi",
		"desc": "Siyah-mor ninja. Hızlı hareket eder, kısa süreliğine görünmez olur ve anında öldürür.",
		"armor": Color(0.10, 0.08, 0.17), "trim": Color(0.48, 0.24, 0.72), "hair": Color(0.06, 0.05, 0.10),
		"skin": Color(0.72, 0.58, 0.52), "glow": Color(0.62, 0.30, 1.0), "accent": Color(0.35, 0.18, 0.55),
		"hp": 95.0, "energy": 120.0, "speed": 6.6, "damage": 26.0, "ability": "stealth", "weapon": "daggers", "hair_style": "hood"
	},
	{
		"id": "TITAN", "name": "TITAN", "title": "Demir Yığını",
		"desc": "Ağır zırhı ve dev çekiciyle yıkıcı darbeler indirir; en yüksek dayanıklılığa sahiptir.",
		"armor": Color(0.30, 0.33, 0.36), "trim": Color(0.66, 0.52, 0.20), "hair": Color(0.20, 0.16, 0.12),
		"skin": Color(0.76, 0.56, 0.42), "glow": Color(1.0, 0.72, 0.20), "accent": Color(0.50, 0.50, 0.54),
		"hp": 190.0, "energy": 80.0, "speed": 4.2, "damage": 38.0, "ability": "shock", "weapon": "hammer", "hair_style": "helm"
	},
	{
		"id": "RANGER", "name": "RANGER", "title": "Ormanın Yayı",
		"desc": "Yeşil-kahverengi doğa savaşçısı. Uzak mesafeden ok atar ve avcı inner-görüsü kullanır.",
		"armor": Color(0.32, 0.42, 0.24), "trim": Color(0.58, 0.40, 0.20), "hair": Color(0.28, 0.18, 0.10),
		"skin": Color(0.78, 0.62, 0.48), "glow": Color(0.55, 0.90, 0.35), "accent": Color(0.44, 0.30, 0.16),
		"hp": 105.0, "energy": 105.0, "speed": 5.8, "damage": 22.0, "ability": "volley", "weapon": "bow", "hair_style": "ponytail"
	},
	{
		"id": "BUILDER", "name": "BUILDER", "title": "Usta İnşacı",
		"desc": "Kazma ve inşaat uzmanı. Blokları daha hızlı kırar, enerjisini onarım için kullanır.",
		"armor": Color(0.48, 0.36, 0.22), "trim": Color(0.86, 0.64, 0.24), "hair": Color(0.34, 0.20, 0.12),
		"skin": Color(0.82, 0.64, 0.50), "glow": Color(1.0, 0.78, 0.30), "accent": Color(0.60, 0.44, 0.26),
		"hp": 130.0, "energy": 100.0, "speed": 5.0, "damage": 18.0, "ability": "repair", "weapon": "pickaxe", "hair_style": "cap"
	}
]

static func get_def(index: int) -> Dictionary:
	return CHARS[clampi(index, 0, CHARS.size() - 1)]

static func count() -> int:
	return CHARS.size()

static func id_of(index: int) -> String:
	return String(get_def(index).get("id", "INFERNO"))
