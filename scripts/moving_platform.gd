extends Platform

## How far the platform swings to each side.
@export var move_distance := 100.0
## Seconds for one full swing back and forth.
@export var move_duration := 2.0

var start_x: float
var time_passed := 0.0


func _ready() -> void:
	start_x = global_position.x


## Overrides Platform: the swing needs extra room so it doesn't hit its neighbours.
func get_extra_width() -> float:
	return move_distance


func _physics_process(delta: float) -> void:
	time_passed += delta
	# TAU is a full circle, so t goes through one sine period per move_duration.
	var t := time_passed / move_duration * TAU
	global_position.x = start_x + sin(t) * move_distance
