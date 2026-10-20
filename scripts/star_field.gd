## Small square stars across the screen that twinkle. Fade it in and out with `modulate.a`.
class_name StarField
extends Node2D

const STAR_COUNT := 70
const STAR_SIZE := 4.0

var stars: Array[Vector3] = []
var time := 0.0


func _ready() -> void:
	# x and y are positions as a fraction of the screen, z is a random twinkle offset.
	for i in STAR_COUNT:
		stars.append(Vector3(randf(), randf(), randf() * TAU))


func _process(delta: float) -> void:
	time += delta
	# No need to draw anything while the stars are invisible.
	visible = modulate.a > 0.01
	if visible:
		queue_redraw()


func _draw() -> void:
	var screen := get_viewport_rect().size
	for star in stars:
		var twinkle := 0.55 + 0.45 * sin(time * 2.0 + star.z)
		var pos := Vector2(star.x * screen.x, star.y * screen.y).snappedf(STAR_SIZE)
		draw_rect(Rect2(pos, Vector2(STAR_SIZE, STAR_SIZE)), Color(1.0, 1.0, 0.9, twinkle))
