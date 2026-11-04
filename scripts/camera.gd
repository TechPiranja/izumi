extends Camera2D

## The node the camera follows.
@export var player: Player
## At the start the camera looks this share of the screen height above the player, so the player
## stands low on the screen and the sky is visible instead of just the ground.
@export var start_lift := 0.22
## Climbing this far (in pixels) brings the camera back to the player's height.
@export var lift_distance := 250.0
## How quickly the camera follows when the lift changes (higher is snappier).
@export var lift_smoothing := 6.0
## On touch devices the camera is zoomed in, which makes the player and the platforms bigger.
@export var touch_zoom := 1.3

var shake_strength := 0.0
var shake_time := 0.0
var shake_duration := 0.0
var start_y := 0.0
## How many pixels the camera currently looks above the player.
var lift := 0.0


func _ready() -> void:
	if TouchControls.wanted():
		zoom = Vector2.ONE * touch_zoom
	start_y = player.global_position.y
	lift = _target_lift()
	global_position = player.global_position + Vector2(0.0, -lift)


func _process(delta: float) -> void:
	lift = lerpf(lift, _target_lift(), minf(delta * lift_smoothing, 1.0))
	# global_position, because the camera's parent is itself offset in the world.
	global_position = player.global_position + Vector2(0.0, -lift)

	if shake_time > 0.0:
		shake_time -= delta
		# The shake fades out towards the end.
		var strength := shake_strength * clampf(shake_time / shake_duration, 0.0, 1.0)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	else:
		offset = Vector2.ZERO


## The full lift at the start, fading to nothing the higher the player climbs.
func _target_lift() -> float:
	var climbed := clampf(start_y - player.global_position.y, 0.0, lift_distance)
	# The height of the world that is visible, which is less when zoomed in.
	var screen_height := get_viewport_rect().size.y / zoom.y
	return screen_height * start_lift * (1.0 - climbed / lift_distance)


## Shakes the screen for a moment. Strength is in pixels.
func shake(strength: float, duration := 0.3) -> void:
	shake_strength = strength
	shake_duration = duration
	shake_time = duration


## Connected to the HUD's milestone signal.
func on_milestone(_meters: int) -> void:
	shake(6.0, 0.35)
