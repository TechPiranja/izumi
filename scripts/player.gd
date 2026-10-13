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

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wings: WingAbility = $WingAbility

## Counts down while in the air; above 0 means a normal jump is still possible.
var coyote_timer := 0.0


func _ready() -> void:
	sprite.play("idle")


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
		elif wings.try_air_jump():
			# The ability only checks and uses a charge; the jump itself stays with the player.
			velocity.y = AIR_JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	_update_animation(direction)


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
