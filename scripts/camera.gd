extends Camera2D

## The node the camera follows.
@export var player: Player


func _process(_delta: float) -> void:
	# global_position, because the camera's parent is itself offset in the world.
	global_position = player.global_position
