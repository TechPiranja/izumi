extends Area2D

## Emitted when the player touches the pad. The main scene connects it to the
## wing refill, the platform spawner reset and the HUD reset.
signal player_touched

const GLOW_COLOR := Color(1.0, 0.96, 0.6)
## Where the pad's top edge is, which is where the beam starts.
const PAD_TOP := 0.0
## About as tall as izumi.
const BEAM_HEIGHT := 130.0
const SPARKLE_COLORS := [Color("fff4dc"), Color("ffd35e"), Color("ff9ccf"), Color("9fe8ff")]

var additive := CanvasItemMaterial.new()
var burst: CPUParticles2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# A wide soft beam with a narrower, brighter one inside, so it glows from the middle.
	_build_beam(52.0, 30.0, 0.4)
	_build_beam(20.0, 8.0, 0.65)
	_build_sparkles()
	_build_burst()
	_pulse_pad()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		burst.restart()
		burst.emitting = true
		player_touched.emit()


## A column of light that narrows and fades towards the top.
func _build_beam(half_bottom: float, half_top: float, alpha: float) -> void:
	var top := PAD_TOP - BEAM_HEIGHT
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([
		Vector2(-half_bottom, PAD_TOP), Vector2(half_bottom, PAD_TOP),
		Vector2(half_top, top), Vector2(-half_top, top),
	])
	var bright := Color(GLOW_COLOR, alpha)
	var faded := Color(GLOW_COLOR, 0.0)
	beam.vertex_colors = PackedColorArray([bright, bright, faded, faded])
	beam.material = additive
	# In front of the platforms, but behind the player.
	beam.z_index = 1
	add_child(beam)

	# It breathes slowly.
	var tween := beam.create_tween().set_loops()
	tween.tween_property(beam, "modulate:a", 0.55, 1.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(beam, "modulate:a", 1.0, 1.3).set_trans(Tween.TRANS_SINE)


## Little squares of light that rise up through the beam and fade out.
func _build_sparkles() -> void:
	var sparkles := _make_particles()
	sparkles.position = Vector2(0.0, PAD_TOP + 2.0)
	sparkles.amount = 28
	# Short enough that the sparkles fade out about where the beam ends.
	sparkles.lifetime = 1.6
	# Starts with the beam already full of sparkles.
	sparkles.preprocess = 1.6
	sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkles.emission_rect_extents = Vector2(46.0, 3.0)
	sparkles.spread = 10.0
	sparkles.gravity = Vector2.ZERO
	sparkles.initial_velocity_min = 30.0
	sparkles.initial_velocity_max = 80.0
	sparkles.scale_amount_min = 3.0
	sparkles.scale_amount_max = 6.0
	add_child(sparkles)


## A shower of sparkles, shot up when the player lands on the pad.
func _build_burst() -> void:
	burst = _make_particles()
	burst.position = Vector2(0.0, PAD_TOP)
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 36
	burst.lifetime = 1.0
	burst.spread = 55.0
	burst.gravity = Vector2(0.0, 260.0)
	burst.initial_velocity_min = 90.0
	burst.initial_velocity_max = 190.0
	burst.scale_amount_min = 3.0
	burst.scale_amount_max = 7.0
	add_child(burst)


## Particles that fly up, with sharp-edged squares in a few colors that fade out.
func _make_particles() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.direction = Vector2.UP
	particles.material = additive
	particles.z_index = 1

	# Every particle picks one of the colors for its whole life ...
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colors.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75])
	colors.colors = PackedColorArray(SPARKLE_COLORS)
	particles.color_initial_ramp = colors

	# ... and fades out at the end.
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	particles.color_ramp = fade
	return particles


## The pad itself glows a little brighter and dimmer.
func _pulse_pad() -> void:
	var rect: ColorRect = $ColorRect
	var tween := rect.create_tween().set_loops()
	tween.tween_property(rect, "modulate", Color(1.2, 1.2, 1.1), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(rect, "modulate", Color.WHITE, 1.0).set_trans(Tween.TRANS_SINE)
