extends AnimatableBody2D

@export var move_distance := 100.0
@export var move_duration := 2.0

var start_x: float
var time_passed := 0.0


func _ready() -> void:
	start_x = global_position.x


func _physics_process(delta: float) -> void:
	time_passed += delta
	var t := time_passed / move_duration * TAU
	global_position.x = start_x + sin(t) * move_distance
