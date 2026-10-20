## A cute box that slides in at the bottom right with confetti, e.g. for every 100 m.
## It builds its own children, so it can simply be added to the HUD.
class_name MilestoneToast
extends PanelContainer

const TITLE_FONT := preload("res://fonts/PixelifySans-Bold.ttf")
const WING_TEXTURE := preload("res://sprites/wing.png")

const MARGIN := 24.0
const SLIDE_TIME := 0.45
const STAY_TIME := 2.6
const CONFETTI_COLORS := [
	Color("ff7aa8"), Color("ffd35e"), Color("7be0b5"), Color("8fb8ff"), Color("c59bff"), Color("ffffff"),
]

var title_label: Label
## The wing and "+1" that are shown when the milestone gave a wing.
var bonus: HBoxContainer
var confetti: CPUParticles2D
var queue: Array[Array] = []
var showing := false


func _ready() -> void:
	# Starts off screen; the slide-in moves it into view.
	position = Vector2(-1000.0, -1000.0)
	z_index = 20
	_build()


## Shows the toast now, or after the current one if one is still visible.
## Only numbers and symbols, no words: `title` is e.g. "100 m", `got_wing` adds a wing and "+1".
func show_toast(title: String, got_wing: bool) -> void:
	queue.append([title, got_wing])
	if not showing:
		_show_next()


func _build() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff4dc")
	style.border_color = Color("e0a458")
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16.0
	style.content_margin_right = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	add_child(row)

	title_label = _make_label(TITLE_FONT, 40, Color("c2603a"))
	row.add_child(title_label)

	bonus = HBoxContainer.new()
	bonus.add_theme_constant_override("separation", 6)
	row.add_child(bonus)

	var icon := TextureRect.new()
	icon.texture = WING_TEXTURE
	icon.custom_minimum_size = Vector2(44.0, 44.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bonus.add_child(icon)
	bonus.add_child(_make_label(TITLE_FONT, 32, Color("6b5b4e"), "+1"))

	confetti = _make_confetti()
	add_child(confetti)


func _make_label(font: Font, font_size: int, color: Color, text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_confetti() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 90
	particles.lifetime = 1.8
	particles.direction = Vector2(-0.3, -1.0)
	particles.spread = 60.0
	particles.gravity = Vector2(0.0, 560.0)
	particles.initial_velocity_min = 300.0
	particles.initial_velocity_max = 640.0
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 11.0
	var colors := Gradient.new()
	var offsets := PackedFloat32Array()
	for i in CONFETTI_COLORS.size():
		offsets.append(float(i) / (CONFETTI_COLORS.size() - 1))
	colors.offsets = offsets
	colors.colors = PackedColorArray(CONFETTI_COLORS)
	# Every piece picks a random color from this ramp at the start.
	particles.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	particles.color_ramp = fade
	particles.show_behind_parent = false
	return particles


func _show_next() -> void:
	if queue.is_empty():
		showing = false
		return

	showing = true
	var entry: Array = queue.pop_front()
	title_label.text = entry[0]
	bonus.visible = entry[1]

	# One frame, so the panel has its new size before it is placed.
	size = Vector2.ZERO
	await get_tree().process_frame

	var screen := get_viewport_rect().size
	var target := Vector2(screen.x - size.x - MARGIN, screen.y - size.y - MARGIN)
	position = Vector2(screen.x + 20.0, target.y)
	scale = Vector2.ONE
	pivot_offset = size * 0.5

	Sfx.play("toast", -2.0, 0.02)
	confetti.position = Vector2(size.x * 0.5, 0.0)
	confetti.restart()
	confetti.emitting = true

	var tween := create_tween()
	tween.tween_property(self, "position:x", target.x, SLIDE_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(STAY_TIME)
	tween.tween_property(self, "position:x", screen.x + 20.0, SLIDE_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(_show_next)
