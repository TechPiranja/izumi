## A ring that grows outwards and fades, for the sonar ping.
class_name SonarRing
extends Node2D

const COLOR := Color(0.75, 0.92, 1.0)

var radius := 0.0
var max_radius := 500.0


## Spawns a ring at `pos` (world position) that grows to `to_radius` in `duration` seconds.
static func spawn(from: Node, pos: Vector2, to_radius: float, duration: float) -> void:
	var ring := SonarRing.new()
	ring.max_radius = to_radius
	ring.z_index = 4
	from.get_tree().current_scene.add_child(ring)
	ring.global_position = pos

	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "radius", to_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(ring.queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, COLOR, 4.0)
