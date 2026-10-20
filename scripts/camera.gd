extends Camera2D

## The node the camera follows.
@export var player: Player

var shake_strength := 0.0
var shake_time := 0.0
var shake_duration := 0.0


func _process(delta: float) -> void:
	# global_position, because the camera's parent is itself offset in the world.
	global_position = player.global_position

	if shake_time > 0.0:
		shake_time -= delta
		# The shake fades out towards the end.
		var strength := shake_strength * clampf(shake_time / shake_duration, 0.0, 1.0)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	else:
		offset = Vector2.ZERO


## Shakes the screen for a moment. Strength is in pixels.
func shake(strength: float, duration := 0.3) -> void:
	shake_strength = strength
	shake_duration = duration
	shake_time = duration


## Connected to the HUD's milestone signal.
func on_milestone(_meters: int) -> void:
	shake(6.0, 0.35)
