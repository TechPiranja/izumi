class_name Platform
extends StaticBody2D

## Position where the spawner placed this platform (moving platforms change
## global_position, this value stays the same).
var spawn_center: Vector2


## Extra space the spawner has to keep free around this platform.
func get_extra_width() -> float:
	return 0.0
