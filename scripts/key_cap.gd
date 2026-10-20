## A keyboard key as a picture, e.g. [A] or [SPACE], that gently "presses" itself.
class_name KeyCap
extends PanelContainer

const FONT := preload("res://fonts/PixelifySans-Bold.ttf")


func _init(key_text := "") -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff4dc")
	style.border_color = Color("c2a06a")
	style.set_border_width_all(3)
	# A thicker bottom edge makes it look like a real key.
	style.border_width_bottom = 9
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 4.0
	add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = key_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color("6b4a2e"))
	add_child(label)

	custom_minimum_size = Vector2(64.0, 64.0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resized.connect(func() -> void: pivot_offset = size * 0.5)


func _ready() -> void:
	# Press and release, over and over.
	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(0.88, 0.88), 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.7)
