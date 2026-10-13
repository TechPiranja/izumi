class_name Cloud
extends Node2D

const MIN_SPEED := 15.0
const MAX_SPEED := 45.0
const MIN_SCALE := 0.6
const MAX_SCALE := 1.2
## From this depth on, the cloud is drawn in front of the player (z_index 3;
## layers: back clouds -3 to -1, platforms 0, wing orb 1, player 2).
const FRONT_DEPTH := 0.85

var speed: float


func _process(delta: float) -> void:
	position.x += speed * delta


## Rolls a new depth: far away = slow, small, far behind; close = fast, big, possibly in front.
func randomize_look() -> void:
	var depth := randf()
	speed = lerpf(MIN_SPEED, MAX_SPEED, depth)
	scale = Vector2.ONE * lerpf(MIN_SCALE, MAX_SCALE, depth)

	if depth > FRONT_DEPTH:
		z_index = 3
	else:
		# Spread the remaining clouds over the layers -3 to -1 (behind platforms, which are at 0).
		z_index = roundi(lerpf(-3.0, -1.0, depth / FRONT_DEPTH))
