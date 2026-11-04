## On-screen controls for touch devices: left and right at the bottom left, jump at the bottom right
## (plus ping while the platforms are hidden), and a small menu button at the top.
## They send the same input actions as the keys, so the player, menu and tutorial can't tell the difference.
class_name TouchControls
extends CanvasLayer

const FILL := Color(1.0, 0.957, 0.863, 0.5)
const FILL_PRESSED := Color(1.0, 0.827, 0.369, 0.85)
const BORDER := Color(0.76, 0.627, 0.416, 0.9)
const GLYPH_COLOR := Color("6b4a2e")
const MARGIN := 24.0
const GAP := 20.0
const SIDE_SIZE := 150.0
const JUMP_SIZE := 190.0
const PING_SIZE := 120.0
const MENU_SIZE := 80.0
## Tilting steers, when the phone has a sensor. Sideways tilt as a share of gravity (about the sine of
## the angle): nothing happens below the dead zone, and the full speed is reached at the other value.
const TILT_DEADZONE := 0.08
const TILT_FULL := 0.4
## How quickly the steering follows the phone (higher is snappier, lower is calmer).
const TILT_SMOOTHING := 15.0
## The input actions ignore weak values, so a tilt past the dead zone starts at this strength.
const TILT_MIN_STRENGTH := 0.3
## A finger may be this much outside a button and still hit it.
const TOUCH_PADDING := 10.0
## Sliding a finger from left to right (or back) switches the direction without lifting it.
const SLIDE_ACTIONS := [&"move_left", &"move_right"]

var buttons: Array[Dictionary] = []
## Which button each finger holds: touch index -> index in `buttons`.
var held := {}
var pad: Control
## True once the sensor gave a usable pose. From then on tilting replaces the left and right buttons.
var tilt_ready := false
## The sideways direction of the screen in sensor coordinates, found from the pose at the start.
var tilt_axis := Vector3.ZERO
## The length of the gravity vector (m/s² or g, depending on the platform).
var tilt_scale := 1.0
var tilt := 0.0
var sent_strength := {&"move_left": 0.0, &"move_right": 0.0}
var style_up: StyleBoxFlat
var style_down: StyleBoxFlat


## True on phones and tablets. While testing on a computer, the project setting
## "izumi/force_touch_ui" (and "Emulate Touch From Mouse") shows the controls anyway.
static func wanted() -> bool:
	return DisplayServer.is_touchscreen_available() \
		or OS.has_feature("mobile") \
		or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") \
		or ProjectSettings.get_setting("izumi/force_touch_ui", false)


## How far the notch and the rounded corners cut into the screen: x on the left, y on the right.
## In viewport units, so it can be added to the margins directly. Zero on computers.
static func safe_insets(viewport: Viewport) -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO

	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	if window.x <= 0 or safe.size.x <= 0:
		return Vector2.ZERO

	var to_viewport := viewport.get_visible_rect().size.x / window.x
	return Vector2(maxf(safe.position.x, 0.0), maxf(window.x - safe.end.x, 0.0)) * to_viewport


func _ready() -> void:
	# Above the HUD (2), below the game over screen (5).
	layer = 3

	pad = Control.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.draw.connect(_draw_pad)
	add_child(pad)

	style_up = _make_style(FILL)
	style_down = _make_style(FILL_PRESSED)

	_layout()
	get_viewport().size_changed.connect(_layout)
	Blackout.changed.connect(_on_blackout_changed)


func _exit_tree() -> void:
	# A held button must not stay pressed in the next scene.
	for index in held.values():
		_send(buttons[index].action, false)
	for action in sent_strength:
		_set_strength(action, 0.0)


func _process(delta: float) -> void:
	var gravity := Input.get_gravity()
	if not tilt_ready:
		_try_calibrate(gravity)
		return

	# Gravity along the screen's sideways direction: tilting the right edge down gives a positive value.
	# The direction was taken from the start pose, so it works in both landscape directions.
	var raw := -gravity.dot(tilt_axis) / tilt_scale
	if ProjectSettings.get_setting("izumi/tilt_invert", false):
		raw = -raw
	tilt = lerpf(tilt, raw, minf(delta * TILT_SMOOTHING, 1.0))

	var amount := clampf((absf(tilt) - TILT_DEADZONE) / (TILT_FULL - TILT_DEADZONE), 0.0, 1.0)
	var strength := 0.0
	if amount > 0.0:
		strength = lerpf(TILT_MIN_STRENGTH, 1.0, amount)
	_set_strength(&"move_right", strength if tilt > 0.0 else 0.0)
	_set_strength(&"move_left", strength if tilt < 0.0 else 0.0)


## Takes the way the phone is held right now as "straight". Waits while there is no sensor
## (a computer) or while the phone lies flat, because then there is no clear sideways direction.
func _try_calibrate(gravity: Vector3) -> void:
	var length := gravity.length()
	if length < 0.5 or Vector2(gravity.x, gravity.y).length() < length * 0.3:
		return

	# Sideways = perpendicular to gravity and to the screen's front (z).
	tilt_axis = gravity.cross(Vector3(0.0, 0.0, 1.0)).normalized()
	tilt_scale = length
	tilt = 0.0
	tilt_ready = true

	# The left and right buttons are not needed anymore.
	for index in held.values():
		if _slides(index):
			_send(buttons[index].action, false)
	for finger in held.keys():
		if _slides(held[finger]):
			held.erase(finger)
	pad.queue_redraw()


## Sets how far left or right is pressed (0 to 1), sending an event only when it changes.
func _set_strength(action: StringName, strength: float) -> void:
	var before: float = sent_strength[action]
	if (strength > 0.0) == (before > 0.0) and absf(strength - before) < 0.03:
		return
	sent_strength[action] = strength
	_send(action, strength > 0.0, strength)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		var hit := _button_at(event.position)
		var current: int = held.get(event.index, -1)
		if hit == current:
			return
		if (current >= 0 and not _slides(current)) or (hit >= 0 and not _slides(hit)):
			return
		_release(event.index)
		_press(event.index, event.position)


func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var insets := safe_insets(get_viewport())
	var bottom := screen.y - MARGIN
	var left := insets.x + MARGIN
	var right := screen.x - insets.y - MARGIN

	buttons = [
		_button(&"move_left", "left", Rect2(left, bottom - SIDE_SIZE, SIDE_SIZE, SIDE_SIZE)),
		_button(&"move_right", "right", Rect2(left + SIDE_SIZE + GAP, bottom - SIDE_SIZE, SIDE_SIZE, SIDE_SIZE)),
		_button(&"move_up", "up", Rect2(right - JUMP_SIZE, bottom - JUMP_SIZE, JUMP_SIZE, JUMP_SIZE)),
		_button(&"ping", "ping", Rect2(right - JUMP_SIZE - GAP - PING_SIZE, bottom - PING_SIZE, PING_SIZE, PING_SIZE)),
		_button(&"ui_cancel", "menu", Rect2((screen.x - MENU_SIZE) * 0.5, 12.0, MENU_SIZE, MENU_SIZE)),
	]
	pad.queue_redraw()


func _button(action: StringName, glyph: String, rect: Rect2) -> Dictionary:
	return {"action": action, "glyph": glyph, "rect": rect}


func _make_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BORDER
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	return style


func _on_blackout_changed(_blind: bool, _instant: bool) -> void:
	pad.queue_redraw()


## Ping only does something while the platforms are hidden, so only then it is shown.
## Left and right are only buttons when there is nothing to tilt.
func _is_active(index: int) -> bool:
	if _slides(index):
		return not tilt_ready
	return buttons[index].action != &"ping" or Blackout.is_blind


func _slides(index: int) -> bool:
	return buttons[index].action in SLIDE_ACTIONS


func _button_at(position: Vector2) -> int:
	for i in buttons.size():
		if _is_active(i) and buttons[i].rect.grow(TOUCH_PADDING).has_point(position):
			return i
	return -1


func _press(finger: int, position: Vector2) -> void:
	var index := _button_at(position)
	if index < 0:
		return
	var already_held: bool = held.values().has(index)
	held[finger] = index
	if not already_held:
		_send(buttons[index].action, true)
	pad.queue_redraw()


func _release(finger: int) -> void:
	if not held.has(finger):
		return
	var index: int = held[finger]
	held.erase(finger)
	# Another finger may still hold the same button.
	if not held.values().has(index):
		_send(buttons[index].action, false)
	pad.queue_redraw()


## Sends an input action as an event, like a key would: is_action_just_pressed and _input both see it.
func _send(action: StringName, pressed: bool, strength := 1.0) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = strength if pressed else 0.0
	Input.parse_input_event(event)


func _draw_pad() -> void:
	for i in buttons.size():
		if not _is_active(i):
			continue
		var rect: Rect2 = buttons[i].rect
		pad.draw_style_box(style_down if held.values().has(i) else style_up, rect)
		draw_glyph(pad, buttons[i].glyph, rect.get_center(), rect.size.x * 0.22)


## Draws a button symbol ("left", "right", "up", "ping" or "menu") with the given half-size `s`.
## Static, so the tutorial can show the very same shapes on its key caps.
static func draw_glyph(canvas: CanvasItem, glyph: String, center: Vector2, s: float) -> void:
	match glyph:
		"left":
			_triangle(canvas, center, [Vector2(-s, 0.0), Vector2(s * 0.8, -s), Vector2(s * 0.8, s)])
		"right":
			_triangle(canvas, center, [Vector2(s, 0.0), Vector2(-s * 0.8, -s), Vector2(-s * 0.8, s)])
		"up":
			_triangle(canvas, center, [Vector2(0.0, -s), Vector2(-s, s * 0.8), Vector2(s, s * 0.8)])
		"ping":
			canvas.draw_arc(center, s, 0.0, TAU, 32, GLYPH_COLOR, maxf(s * 0.25, 3.0))
			canvas.draw_circle(center, s * 0.3, GLYPH_COLOR)
		"menu":
			# A little house.
			_triangle(canvas, center, [Vector2(0.0, -s), Vector2(-s, 0.0), Vector2(s, 0.0)])
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.7, 0.0), Vector2(s * 1.4, s * 0.9)), GLYPH_COLOR)


static func _triangle(canvas: CanvasItem, center: Vector2, corners: Array) -> void:
	var points := PackedVector2Array()
	for corner in corners:
		points.append(center + corner)
	canvas.draw_colored_polygon(points, GLYPH_COLOR)
