## The game over screen: how high the run got, and a round arrow to try again. No words.
class_name GameOver
extends CanvasLayer

const FONT := preload("res://fonts/PixelifySans-Bold.ttf")
const WING_TEXTURE := preload("res://sprites/wing.png")
## The screen ignores input for a moment, so a key that was already pressed doesn't skip it.
const INPUT_DELAY := 0.9
const NORMAL_COLOR := Color("fff4dc")
const RECORD_COLOR := Color("ffd35e")

## The best height in this session (it survives the restart, but is not saved to disk).
static var best_meters := 0

var can_restart := false
var number: Label


func _ready() -> void:
	layer = 5
	# The game is paused behind this screen; the screen itself keeps running.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Builds the screen for a run that reached `meters`.
func show_result(meters: int) -> void:
	var is_record := meters > best_meters
	best_meters = maxi(best_meters, meters)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.02, 0.1, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	if is_record:
		# A wing above the number marks a new best height.
		var wing := TextureRect.new()
		wing.texture = WING_TEXTURE
		wing.custom_minimum_size = Vector2(72.0, 72.0)
		wing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		column.add_child(wing)

	number = Label.new()
	number.text = "%d m" % meters
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_font_override("font", FONT)
	number.add_theme_font_size_override("font_size", 120)
	number.add_theme_color_override("font_color", RECORD_COLOR if is_record else NORMAL_COLOR)
	number.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2, 0.9))
	number.add_theme_constant_override("outline_size", 12)
	column.add_child(number)

	var symbol := RestartSymbol.new()
	symbol.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	symbol.modulate.a = 0.0
	column.add_child(symbol)

	# Fade in, pop the number, then show the arrow.
	number.pivot_offset = Vector2(number.size.x * 0.5, 60.0)
	number.scale = Vector2.ZERO
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dim, "color:a", 0.82, 0.5)
	tween.tween_property(number, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.15)
	tween.tween_property(symbol, "modulate:a", 1.0, 0.4).set_delay(INPUT_DELAY - 0.3)

	Sfx.play("game_over", 0.0, 0.0)
	await get_tree().create_timer(INPUT_DELAY).timeout
	can_restart = true


func _input(event: InputEvent) -> void:
	if not can_restart:
		return

	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton or event is InputEventJoypadButton:
		pressed = event.pressed
	if pressed:
		can_restart = false
		get_tree().paused = false
		get_tree().reload_current_scene()
