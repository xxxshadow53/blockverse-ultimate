extends Node

## Tamamen üretilmiş (prosedürel) sesler – harici lisanslı dosya gerekmez.
const RATE := 16000

var streams: Dictionary = {}
var music_player: AudioStreamPlayer
var wind_player: AudioStreamPlayer
var water_player: AudioStreamPlayer
var rain_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var _pool_index := 0
var _music_timer := 0.0

func _ready() -> void:
	_build_streams()
	music_player = _make_player(streams["music"], GameSettings.get_v("music_volume", 0.55))
	wind_player = _make_player(streams["wind"], 0.22)
	water_player = _make_player(streams["water"], 0.18)
	rain_player = _make_player(streams["rain"], 0.0)
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.volume_db = 0.0
		add_child(p)
		sfx_pool.append(p)

func _make_player(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = linear_to_db(clampf(volume, 0.0, 1.0))
	add_child(p)
	return p

func play_music() -> void:
	if music_player and not music_player.playing:
		music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func play_ambient(wind: bool, water: bool, rain: bool) -> void:
	if wind_player:
		wind_player.playing = wind
	if water_player:
		water_player.playing = water
	if rain_player:
		rain_player.playing = rain

func set_volumes() -> void:
	var master := float(GameSettings.get_v("master_volume", 0.8))
	var music := float(GameSettings.get_v("music_volume", 0.55)) * master
	var sfx := float(GameSettings.get_v("sfx_volume", 0.85)) * master
	if music_player:
		music_player.volume_db = linear_to_db(clampf(music, 0.0, 1.0))
	if wind_player:
		wind_player.volume_db = linear_to_db(clampf(sfx * 0.25, 0.0, 1.0))
	if water_player:
		water_player.volume_db = linear_to_db(clampf(sfx * 0.2, 0.0, 1.0))
	if rain_player:
		rain_player.volume_db = linear_to_db(clampf(sfx * 0.45, 0.0, 1.0))

func play_sfx(name: String, volume: float = 1.0, pitch: float = 1.0) -> void:
	if not streams.has(name) or sfx_pool.is_empty():
		return
	var p := sfx_pool[_pool_index % sfx_pool.size()]
	_pool_index += 1
	p.stream = streams[name]
	p.pitch_scale = clampf(pitch, 0.4, 2.2)
	var master := float(GameSettings.get_v("master_volume", 0.8))
	var sfx := float(GameSettings.get_v("sfx_volume", 0.85)) * master
	p.volume_db = linear_to_db(clampf(volume * sfx, 0.001, 1.0))
	p.play()

func _build_streams() -> void:
	streams["menu"] = _synth(0.18, "menu", false)
	streams["step"] = _synth(0.14, "step", false)
	streams["break"] = _synth(0.32, "break", false)
	streams["place"] = _synth(0.16, "place", false)
	streams["swing"] = _synth(0.22, "swing", false)
	streams["hit"] = _synth(0.26, "hit", false)
	streams["hurt"] = _synth(0.34, "hurt", false)
	streams["pickup"] = _synth(0.2, "pickup", false)
	streams["fire"] = _synth(0.5, "fire", false)
	streams["ice"] = _synth(0.55, "ice", false)
	streams["bow"] = _synth(0.24, "bow", false)
	streams["death"] = _synth(0.7, "death", false)
	streams["splash"] = _synth(0.4, "splash", false)
	streams["unlock"] = _synth(0.8, "unlock", false)
	streams["wind"] = _synth(2.0, "wind", true)
	streams["water"] = _synth(2.0, "water", true)
	streams["rain"] = _synth(2.0, "rain", true)
	streams["music"] = _synth(8.0, "music", true)

func _synth(duration: float, kind: String, looping: bool) -> AudioStreamWAV:
	var count := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = kind.hash()
	var smooth := 0.0
	var smooth2 := 0.0
	for i in range(count):
		var t := float(i) / float(RATE)
		var s := 0.0
		var env := 1.0
		match kind:
			"menu":
				env = exp(-t * 16.0)
				s = sin(TAU * (620.0 + t * 900.0) * t) * 0.5 + sin(TAU * 930.0 * t) * 0.2
			"step":
				env = exp(-t * 22.0)
				smooth = smooth * 0.72 + rng.randf_range(-1, 1) * 0.28
				s = smooth * 0.8 + sin(TAU * 95.0 * t) * 0.25
			"break":
				env = exp(-t * 9.0)
				smooth = smooth * 0.55 + rng.randf_range(-1, 1) * 0.45
				s = smooth * 0.9 + sin(TAU * (140.0 - t * 80.0) * t) * 0.3
			"place":
				env = exp(-t * 18.0)
				s = sin(TAU * 210.0 * t) * 0.6 + sin(TAU * 420.0 * t) * 0.2
			"swing":
				env = sin(PI * clampf(t / 0.22, 0, 1))
				smooth = smooth * 0.9 + rng.randf_range(-1, 1) * 0.1
				s = smooth * (0.4 + t * 2.0)
			"hit":
				env = exp(-t * 13.0)
				smooth = smooth * 0.6 + rng.randf_range(-1, 1) * 0.4
				s = sin(TAU * 78.0 * t) * 0.7 + smooth * 0.5
			"hurt":
				env = exp(-t * 7.0)
				s = sin(TAU * (340.0 - t * 180.0) * t) * 0.55 + rng.randf_range(-0.2, 0.2)
			"pickup":
				env = exp(-t * 6.0)
				s = sin(TAU * (540.0 if t < 0.08 else 810.0) * t) * 0.5
			"fire":
				env = exp(-t * 4.5) * clampf(t * 12.0, 0, 1)
				smooth = smooth * 0.7 + rng.randf_range(-1, 1) * 0.3
				s = sin(TAU * (110.0 + t * 260.0) * t) * 0.4 + smooth * 0.6
			"ice":
				env = exp(-t * 4.0)
				s = sin(TAU * 1180.0 * t) * 0.25 + sin(TAU * 1570.0 * t) * 0.2 + sin(TAU * 2350.0 * t) * 0.1
			"bow":
				env = exp(-t * 15.0)
				s = sin(TAU * (300.0 + t * 500.0) * t) * 0.6
			"death":
				env = exp(-t * 3.2)
				s = sin(TAU * (260.0 - t * 190.0) * t) * 0.5 + rng.randf_range(-0.15, 0.15)
			"splash":
				env = exp(-t * 7.0)
				smooth = smooth * 0.5 + rng.randf_range(-1, 1) * 0.5
				s = smooth * 0.85
			"unlock":
				env = clampf(t * 4.0, 0, 1) * exp(-max(0.0, t - 0.45) * 8.0)
				s = sin(TAU * (440.0 if t < 0.25 else 660.0) * t) * 0.35 + sin(TAU * 880.0 * t) * 0.15
			"wind":
				smooth = smooth * 0.985 + rng.randf_range(-1, 1) * 0.015
				env = 0.55 + 0.45 * sin(TAU * 0.23 * t)
				s = smooth * 1.8
			"water":
				smooth = smooth * 0.88 + rng.randf_range(-1, 1) * 0.12
				smooth2 = smooth2 * 0.6 + sin(TAU * (3.0 + sin(t) * 1.4) * t) * 0.4
				s = smooth * 0.7 + smooth2 * 0.18
			"rain":
				smooth = smooth * 0.35 + rng.randf_range(-1, 1) * 0.65
				s = smooth * 0.5
			"music":
				var chord_step := int(t / 2.0) % 4
				var roots: Array[float] = [110.0, 130.81, 146.83, 98.0]
				var ratios: Array[float] = [1.0, 1.25, 1.5, 2.0]
				var root: float = roots[chord_step]
				var pad := sin(TAU * root * t) * 0.16 + sin(TAU * root * 1.5 * t) * 0.1 + sin(TAU * root * 2.0 * t) * 0.07
				var beat := fmod(t, 0.5)
				var note: float = root * 4.0 * ratios[int(t / 0.5) % 4]
				var arp := sin(TAU * note * t) * exp(-beat * 9.0) * 0.16
				s = pad + arp
				env = 0.75 + 0.25 * sin(TAU * 0.08 * t)
			_:
				s = 0.0
		s = clampf(s * env, -1.0, 1.0)
		var v := int(s * 32767.0) & 0xFFFF
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if looping:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = count
	return wav
