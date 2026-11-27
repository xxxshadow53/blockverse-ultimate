class_name MobileControls
extends CanvasLayer

## Çoklu dokunmatik mobil kontroller: 360° analog joystick + sağ alan kamera + aksiyon tuşları.
class JoystickPad extends Control:
	var value := Vector2.ZERO
	var active_pointer := -1
	var center_local := Vector2.ZERO
	var radius := 110.0
	var changed := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, radius, Color(0.05, 0.07, 0.12, 0.34))
		draw_arc(c, radius, 0, TAU, 48, Color(0.55, 0.85, 1.0, 0.35), 3.0)
		draw_circle(c + value * (radius * 0.62), radius * 0.30, Color(0.42, 0.85, 1.0, 0.72))
		draw_arc(c + value * (radius * 0.62), radius * 0.30, 0, TAU, 24, Color(1, 1, 1, 0.65), 2.0)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var t := event as InputEventScreenTouch
			if t.pressed and active_pointer == -1:
				active_pointer = t.index
				center_local = t.position
				changed = true
			elif not t.pressed and t.index == active_pointer:
				active_pointer = -1
				value = Vector2.ZERO
				changed = true
			accept_event()
		elif event is InputEventScreenDrag:
			var d := event as InputEventScreenDrag
			if d.index == active_pointer:
				var delta := d.position - center_local
				value = delta.limit_length(radius * 0.82) / (radius * 0.82)
				changed = true
				accept_event()
		elif event is InputEventMouseButton:
			var m := event as InputEventMouseButton
			if m.button_index == MOUSE_BUTTON_LEFT:
				if m.pressed:
					active_pointer = 99
					center_local = m.position
				else:
					active_pointer = -1
					value = Vector2.ZERO
				changed = true
				accept_event()
		elif event is InputEventMouseMotion and active_pointer == 99:
			value = (event.position - center_local).limit_length(radius * 0.82) / (radius * 0.82)
			changed = true
			accept_event()
		if changed:
			queue_redraw()
			changed = false

class LookZone extends Control:
	var pointer := -1
	var last_pos := Vector2.ZERO
	var player: Node = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if player == null:
			return
		if event is InputEventScreenTouch:
			var t := event as InputEventScreenTouch
			if t.pressed and pointer == -1:
				pointer = t.index
				last_pos = t.position
			elif not t.pressed and t.index == pointer:
				pointer = -1
			accept_event()
		elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == pointer:
			var d := event as InputEventScreenDrag
			player.add_look(d.position - last_pos)
			last_pos = d.position
			accept_event()
		elif event is InputEventMouseButton:
			var m := event as InputEventMouseButton
			if m.button_index == MOUSE_BUTTON_LEFT:
				pointer = 99 if m.pressed else -1
				last_pos = m.position
				accept_event()
		elif event is InputEventMouseMotion and pointer == 99:
			player.add_look((event as InputEventMouseMotion).relative)
			accept_event()

var player: Player
var joystick: JoystickPad
var look_zone: LookZone
var root: Control
var _buttons: Dictionary = {}

func setup(player_ref: Player) -> void:
	player = player_ref
	if look_zone:
		look_zone.player = player_ref

func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	look_zone = LookZone.new()
	look_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	look_zone.anchor_left = 0.38
	look_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(look_zone)
	joystick = JoystickPad.new()
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.anchor_right = 0.0
	joystick.offset_left = 40
	joystick.offset_right = 260
	joystick.offset_bottom = -40
	joystick.offset_top = -260
	root.add_child(joystick)
	_build_buttons()

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(40)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	return sb

func _button(text: String, anchor: int, offset: Vector2, size: Vector2, action: String, hold: bool = false) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.set_anchors_preset(anchor)
	b.offset_left = offset.x
	b.offset_top = offset.y
	b.offset_right = offset.x + size.x
	b.offset_bottom = offset.y + size.y
	b.add_theme_stylebox_override("normal", _style(Color(0.06, 0.10, 0.18, 0.62), Color(0.45, 0.80, 1.0, 0.55)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.18, 0.48, 0.72, 0.85), Color(0.8, 0.95, 1, 0.9)))
	b.add_theme_font_size_override("font_size", 17)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	if hold:
		b.button_down.connect(func(): _press(action))
		b.button_up.connect(func(): _release(action))
	else:
		b.pressed.connect(func(): _press(action))
	root.add_child(b)
	_buttons[action] = b

func _build_buttons() -> void:
	_button("Zıpla", Control.PRESET_BOTTOM_RIGHT, Vector2(-210, -250), Vector2(90, 90), "jump", true)
	_button("Koş", Control.PRESET_BOTTOM_RIGHT, Vector2(-320, -170), Vector2(80, 80), "run", true)
	_button("Saldır", Control.PRESET_BOTTOM_RIGHT, Vector2(-110, -280), Vector2(96, 96), "attack")
	_button("Kır", Control.PRESET_BOTTOM_RIGHT, Vector2(-190, -150), Vector2(80, 70), "break")
	_button("Koy", Control.PRESET_BOTTOM_RIGHT, Vector2(-100, -155), Vector2(80, 70), "place")
	_button("Yetenek", Control.PRESET_BOTTOM_RIGHT, Vector2(-300, -80), Vector2(110, 68), "ability")
	_button("Kamera", Control.PRESET_BOTTOM_RIGHT, Vector2(-180, -70), Vector2(90, 60), "camera")
	_button("Envanter", Control.PRESET_BOTTOM_RIGHT, Vector2(-80, -70), Vector2(100, 60), "inventory")
	_button("Duraklat", Control.PRESET_TOP_RIGHT, Vector2(-170, 26), Vector2(130, 54), "pause")

func _press(action: String) -> void:
	if player:
		player.press(action)
	AudioLibrary.play_sfx("menu", 0.22)

func _release(action: String) -> void:
	if player:
		player.release(action)

func set_enabled(value: bool) -> void:
	root.visible = value
