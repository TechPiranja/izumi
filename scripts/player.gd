extends CharacterBody2D

signal wing_charges_changed(charges: int)

const SPEED = 300.0
const JUMP_VELOCITY = -550.0
const AIR_JUMP_VELOCITY = -500.0
const MAX_WING_CHARGES := 3

var wing_charges := MAX_WING_CHARGES


func _ready() -> void:
	$AnimatedSprite2D.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("move_up"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif wing_charges > 0:
			_air_jump()

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		$AnimatedSprite2D.play("run")
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		$AnimatedSprite2D.play("idle")

	move_and_slide()


func _air_jump() -> void:
	wing_charges -= 1
	velocity.y = AIR_JUMP_VELOCITY
	$WingBurst.restart()
	wing_charges_changed.emit(wing_charges)


func refill_wings() -> void:
	wing_charges = MAX_WING_CHARGES
	wing_charges_changed.emit(wing_charges)
