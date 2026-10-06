extends Node2D

const PLATFORM_SCENE := preload("res://scenes/platform.tscn")
const MIN_GAP := 60.0
const MAX_GAP := 100.0
const SIDE_MARGIN := 60.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var highest_y: float


func _ready() -> void:
	pass


func _spawn_platform() -> void:
	highest_y -= randf_range(MIN_GAP, MAX_GAP)

	var viewport_width := get_viewport_rect().size.x
	var half_width := viewport_width / 2.0
	var x := camera.global_position.x + randf_range(-half_width + SIDE_MARGIN, half_width - SIDE_MARGIN)

	var platform := PLATFORM_SCENE.instantiate()
	add_child(platform)
	platform.global_position = Vector2(x, highest_y)


func _process(_delta: float) -> void:
	pass


func _cleanup_platforms(viewport_height: float) -> void:
	for child in get_children():
		if child is StaticBody2D and child.global_position.y > player.global_position.y + viewport_height:
			child.queue_free()
