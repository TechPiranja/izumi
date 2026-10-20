## Small helpers for one-shot effects: particle bursts and floating text.
## They are added to the current scene, so they survive the node that triggered them.
class_name Fx
extends RefCounted

const FONT := preload("res://fonts/PixelifySans-Bold.ttf")


## A burst of `amount` square particles at `pos` (world position) that frees itself afterwards.
static func burst(from: Node, pos: Vector2, color: Color, amount := 14, speed := 160.0, size := 4.0) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.55
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, 220.0)
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.scale_amount_min = size * 0.6
	particles.scale_amount_max = size
	particles.color = color
	particles.color_ramp = _fade_out()
	particles.z_index = 5
	particles.finished.connect(particles.queue_free)

	from.get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	particles.restart()
	particles.emitting = true


## Text that floats up from `pos` (world position) and fades away.
static func float_text(from: Node, pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(160.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.2, 0.8))
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 10

	from.get_tree().current_scene.add_child(label)
	label.global_position = pos - Vector2(80.0, 20.0)

	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


static func _fade_out() -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	return gradient
