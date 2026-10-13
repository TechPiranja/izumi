## Collectible that gives the player one wing charge.
extends Area2D

## Layer order: platforms 0, orb 1, player 2
const Z_INDEX := 1

## Size of one art pixel on screen (the sprite is scaled by this).
const PIXEL_SIZE := 4.0
## "Bobbing" = floating gently up and down. How far the orb bobs (in screen pixels).
const BOB_HEIGHT := 5.0
const BOB_SPEED := 2.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

## The y position the orb bobs around (where the spawner placed it).
var center_y: float
## Runs up over time and drives the bobbing.
var bob_time := 0.0


func _ready() -> void:
	z_index = Z_INDEX
	center_y = position.y
	# Random start so neighbouring orbs don't move in sync.
	bob_time = randf() * TAU
	var frame_count := sprite.sprite_frames.get_frame_count("pulse")
	sprite.set_frame_and_progress(randi() % frame_count, 0.0)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	bob_time += delta * BOB_SPEED
	var offset := sin(bob_time) * BOB_HEIGHT
	# Round to whole pixels so it moves in steps like the rest of the art.
	position.y = center_y + roundf(offset / PIXEL_SIZE) * PIXEL_SIZE


func _on_body_entered(body: Node2D) -> void:
	# If the player is already at max charges the orb stays, so it can be picked up later.
	if body is Player and body.wings.add_charge():
		queue_free()
