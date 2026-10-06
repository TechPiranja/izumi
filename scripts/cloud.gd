extends Node2D

@export var speed := 20.0


func _process(delta: float) -> void:
	position.x += speed * delta
