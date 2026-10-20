## A round arrow ("try again"), drawn in code so it needs no picture and no words.
class_name RestartSymbol
extends Control

const COLOR := Color("fff4dc")
const LINE_WIDTH := 10.0
## How much of the circle is drawn, in radians (the rest is the gap the arrow points into).
const SWEEP := TAU * 0.78


func _ready() -> void:
	custom_minimum_size = Vector2(110.0, 110.0)
	pivot_offset = custom_minimum_size * 0.5
	# A gentle pulse, so it looks like something to press.
	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var start := -PI * 0.5 + 0.35
	var end := start + SWEEP
	draw_arc(center, radius, start, end, 40, COLOR, LINE_WIDTH)

	# Arrow head at the end of the arc.
	var tip := center + Vector2.from_angle(end) * radius
	var along := Vector2.from_angle(end + PI * 0.5)
	var outward := Vector2.from_angle(end)
	var head := PackedVector2Array([
		tip + along * 22.0,
		tip - outward * 18.0 - along * 2.0,
		tip + outward * 18.0 - along * 2.0,
	])
	draw_colored_polygon(head, COLOR)
