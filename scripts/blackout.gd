## Autoload "Blackout": remembers whether the platforms are currently hidden.
## The black orbs switch it; platforms and the HUD listen to `changed`.
##
## A "vision" is the short effect where the screen turns black and only outlines are shown,
## while a wave grows outwards and shows the platforms. It starts when a black orb makes it dark,
## and the player can trigger it once more with the ping button.
extends Node

## `instant` skips the blinking, e.g. when a run is reset.
signal changed(blind: bool, instant: bool)
## `radius` is how far the wave grows (px), `duration` how long the platforms stay visible (s).
signal vision_started(origin: Vector2, radius: float, duration: float)

const OVERLAY_SHADER := preload("res://shaders/vision.gdshader")
## How fast the wave travels (px/s): farther platforms show up a little later.
const VISION_SPEED := 700.0
## The screen is black for a moment before the outlines are drawn.
const VISION_START_DELAY := 0.3
## How long everything stays visible after the wave has reached its end.
const VISION_HOLD := 1.0
const MIN_RADIUS := 500.0
const MAX_RADIUS := 1800.0
## Used if there is no other black orb to reach.
const DEFAULT_RADIUS := 800.0
## The wave grows a bit past the next black orb.
const TARGET_MARGIN := 150.0

var is_blind := false
## How many more visions the ping button can trigger. Refilled to 1 when it gets dark.
var ping_charges := 0
var vision_active := false
var vision_id := 0
var overlay_material: ShaderMaterial
var overlay_tween: Tween


func _ready() -> void:
	_build_overlay()


func set_blind(value: bool, instant := false) -> void:
	if value == is_blind and not instant:
		return

	is_blind = value
	ping_charges = 1 if value else 0
	if not value:
		_end_vision()
	changed.emit(value, instant)


## Starts the black-and-outlines effect around `origin` (a world position).
func start_vision(origin: Vector2) -> void:
	var radius := _vision_radius(origin)
	var duration := radius / VISION_SPEED + VISION_START_DELAY + VISION_HOLD
	vision_active = true
	vision_id += 1

	vision_started.emit(origin, radius, duration)
	Sfx.play("ping", 0.0, 0.0)
	_animate_overlay(duration)

	# The ring and the end of the vision are timed with the id, so an early end cancels them.
	var id := vision_id
	await get_tree().create_timer(VISION_START_DELAY).timeout
	if id == vision_id:
		SonarRing.spawn(self, origin, radius, radius / VISION_SPEED)
	await get_tree().create_timer(duration - VISION_START_DELAY).timeout
	if id == vision_id:
		vision_active = false


## The ping button: one more vision, if it is dark and there is a charge left.
func try_ping(origin: Vector2) -> bool:
	if not is_blind or ping_charges <= 0 or vision_active:
		return false

	ping_charges -= 1
	start_vision(origin)
	return true


## Stops a running vision at once, e.g. when the platforms come back.
func _end_vision() -> void:
	vision_id += 1
	vision_active = false
	if overlay_tween:
		overlay_tween.kill()
	overlay_tween = create_tween()
	var current = overlay_material.get_shader_parameter("amount")
	_tween_param(overlay_tween, "amount", current if current != null else 0.0, 0.0, 0.2)


## Distance to the nearest black orb above the player, so the wave grows until it reaches it.
func _vision_radius(origin: Vector2) -> float:
	var nearest := INF
	for orb in get_tree().get_nodes_in_group("dark_orbs"):
		if orb.global_position.y < origin.y - 20.0:
			nearest = minf(nearest, origin.distance_to(orb.global_position))

	if nearest == INF:
		return DEFAULT_RADIUS
	return clampf(nearest + TARGET_MARGIN, MIN_RADIUS, MAX_RADIUS)


## Black first, then the outlines are drawn in, and at the end the normal picture fades back.
func _animate_overlay(duration: float) -> void:
	if overlay_tween:
		overlay_tween.kill()

	overlay_material.set_shader_parameter("lines", 0.0)
	overlay_tween = create_tween()
	_tween_param(overlay_tween, "amount", 0.0, 1.0, 0.08)
	overlay_tween.tween_interval(VISION_START_DELAY - 0.08)
	_tween_param(overlay_tween, "lines", 0.0, 1.0, 0.25)
	overlay_tween.tween_interval(maxf(duration - VISION_START_DELAY - 0.25 - 0.5, 0.1))
	_tween_param(overlay_tween, "amount", 1.0, 0.0, 0.5)


## Tweens a shader uniform of the overlay from one value to another.
func _tween_param(tween: Tween, param: String, from: float, to: float, time: float) -> void:
	tween.tween_method(func(value: float) -> void: overlay_material.set_shader_parameter(param, value), from, to, time)


## A full-screen rectangle above the game but below the HUD (HUD layer is 2).
func _build_overlay() -> void:
	overlay_material = ShaderMaterial.new()
	overlay_material.shader = OVERLAY_SHADER

	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)

	var rect := ColorRect.new()
	rect.material = overlay_material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
