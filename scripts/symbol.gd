## Small drawn pictures for the tutorial, so it needs no words: arrow, up, check, blocks.
class_name Symbol
extends Control

const COLOR := Color("fff4dc")
const GOLD := Color("ffd35e")
const GREEN := Color("7be0b5")

var kind := "arrow"


func _init(symbol_kind := "arrow") -> void:
	kind = symbol_kind
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	match kind:
		"arrow":
			custom_minimum_size = Vector2(56.0, 40.0)
		"up":
			custom_minimum_size = Vector2(40.0, 56.0)
		"check":
			custom_minimum_size = Vector2(56.0, 56.0)
		"blocks":
			custom_minimum_size = Vector2(28.0, 72.0)


func _draw() -> void:
	match kind:
		"arrow":
			draw_line(Vector2(4.0, 20.0), Vector2(36.0, 20.0), COLOR, 7.0)
			draw_colored_polygon(PackedVector2Array([Vector2(34.0, 4.0), Vector2(54.0, 20.0), Vector2(34.0, 36.0)]), COLOR)
		"up":
			draw_line(Vector2(20.0, 52.0), Vector2(20.0, 20.0), COLOR, 7.0)
			draw_colored_polygon(PackedVector2Array([Vector2(4.0, 22.0), Vector2(20.0, 2.0), Vector2(36.0, 22.0)]), COLOR)
		"check":
			draw_polyline(PackedVector2Array([Vector2(8.0, 30.0), Vector2(22.0, 44.0), Vector2(48.0, 10.0)]), GREEN, 9.0)
		"blocks":
			# Three blocks like the progress column; the bottom one is filled.
			for i in 3:
				var rect := Rect2(Vector2(4.0, 4.0 + i * 24.0), Vector2(20.0, 20.0))
				if i == 2:
					draw_rect(rect, GOLD)
				else:
					draw_rect(rect, COLOR, false, 3.0)
