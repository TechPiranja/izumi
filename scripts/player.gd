class_name Player
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -550.0
const AIR_JUMP_VELOCITY = -500.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wings: WingAbility = $WingAbility


func _ready() -> void:
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("move_up"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif wings.try_air_jump():
			# The ability only checks and uses a charge; the jump itself stays with the player.
			velocity.y = AIR_JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.play("run")
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		sprite.play("idle")

	move_and_slide()
