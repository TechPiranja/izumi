class_name Player
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -550.0
const AIR_JUMP_VELOCITY = -500.0
## Seconds after leaving the ground in which a normal jump is still allowed
## (also covers single frames where the floor contact flickers).
const COYOTE_TIME := 0.1
## Frame of the "run" animation that is held while the player is in the air.
const AIR_FRAME := 3
## Local y of the feet. Squash and stretch scales the sprite around this point.
const FEET_Y := 37.0
## Landing faster than this (px/s) squashes the sprite and plays a sound.
const HARD_LANDING_SPEED := 250.0
const DUST_COLOR := Color(1.0, 1.0, 1.0, 0.7)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wings: WingAbility = $WingAbility

## Counts down while in the air; above 0 means a normal jump is still possible.
var coyote_timer := 0.0
var was_on_floor := false
## Vertical speed of the last frame, because move_and_slide() zeroes it on landing.
var last_fall_speed := 0.0
var squash_tween: Tween
var dust: CPUParticles2D


func _ready() -> void:
	sprite.play("idle")
	dust = _make_dust()
	add_child(dust)


func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("move_up"):
		if coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			# Used up, so the same ground contact can't give a second normal jump.
			coyote_timer = 0.0
			_on_jumped()
		elif wings.try_air_jump():
			# The ability only checks and uses a charge; the jump itself stays with the player.
			velocity.y = AIR_JUMP_VELOCITY
			_on_air_jumped()

	# Only works while the platforms are hidden (a black orb), and only once per darkness.
	if Input.is_action_just_pressed("ping"):
		Blackout.try_ping(global_position)

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	last_fall_speed = velocity.y
	move_and_slide()
	_update_animation(direction)

	if is_on_floor() and not was_on_floor and last_fall_speed > HARD_LANDING_SPEED:
		_on_landed()
	was_on_floor = is_on_floor()


func _update_animation(direction: float) -> void:
	if not is_on_floor():
		# In the air: stand still on one frame of the run animation.
		sprite.animation = "run"
		sprite.stop()
		sprite.frame = AIR_FRAME
	elif direction:
		sprite.play("run")
	else:
		sprite.play("idle")


func _on_jumped() -> void:
	Sfx.play("jump")
	_puff(8)
	_squash(Vector2(0.8, 1.25))


func _on_air_jumped() -> void:
	Sfx.play("air_jump")
	_squash(Vector2(0.75, 1.35))


func _on_landed() -> void:
	Sfx.play("land", -4.0)
	_puff(10)
	_squash(Vector2(1.3, 0.7))


## Squashes or stretches the sprite and lets it spring back. The feet stay on the ground.
func _squash(target: Vector2) -> void:
	if squash_tween:
		squash_tween.kill()
	_set_sprite_scale(target)
	squash_tween = create_tween()
	squash_tween.tween_method(_set_sprite_scale, target, Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _set_sprite_scale(value: Vector2) -> void:
	sprite.scale = value
	# Scaling happens around the sprite's center; this moves it so the feet don't lift off.
	sprite.position.y = FEET_Y * (1.0 - value.y)


func _puff(amount: int) -> void:
	dust.amount = amount
	dust.restart()
	dust.emitting = true


func _make_dust() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.position = Vector2(0.0, FEET_Y)
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.45
	particles.direction = Vector2.UP
	particles.spread = 80.0
	particles.gravity = Vector2(0.0, 60.0)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = DUST_COLOR
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = fade
	# Dust stays where it was made instead of following the player.
	particles.local_coords = false
	return particles
