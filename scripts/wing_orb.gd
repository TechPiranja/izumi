## Collectible that gives the player one wing charge.
extends Area2D

const RADIUS := 12.0
const BOB_HEIGHT := 5.0
const BOB_SPEED := 2.5

var base_y: float
var time := 0.0


func _ready() -> void:
	base_y = position.y
	# Random start phase so neighbouring orbs don't bob in sync.
	time = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	time += delta * BOB_SPEED
	position.y = base_y + sin(time) * BOB_HEIGHT


# Placeholder look until there is a sprite: soft glow, filled circle, white outline.
func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS * 1.6, Color(1.0, 0.95, 0.6, 0.25))
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.95, 0.5))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, Color.WHITE, 2.0)


func _on_body_entered(body: Node2D) -> void:
	# If the player is already at max charges the orb stays, so it can be picked up later.
	if body is Player and body.wings.add_charge():
		queue_free()
