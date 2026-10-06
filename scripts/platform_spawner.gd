extends Node2D

const MIN_RISE := 60.0
const MAX_RISE := 130.0
const MAX_HORIZONTAL_STEP := 250.0
const MIN_DISTANCE := 120.0

const PLATFORM_TYPES := [
	{"scene": preload("res://scenes/platform.tscn"), "weight": 6.0},
	{"scene": preload("res://scenes/moving_platform.tscn"), "weight": 2.0},
	{"scene": preload("res://scenes/crumble_platform.tscn"), "weight": 2.0},
]

@export var player_path: NodePath = ^"../Player"
@export var start_platform_path: NodePath = ^"../Platform"

var player: CharacterBody2D
var start_platform: Node2D
var highest_y: float
var last_x: float


func _ready() -> void:
	player = get_node(player_path)
	start_platform = get_node(start_platform_path)
	reset()


func reset() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	highest_y = start_platform.global_position.y
	last_x = start_platform.global_position.x

	for i in range(15):
		_spawn_platform()


func _process(_delta: float) -> void:
	var viewport_height := get_viewport_rect().size.y
	while highest_y > player.global_position.y - viewport_height:
		_spawn_platform()

	_cleanup_platforms(viewport_height)


func _spawn_platform() -> void:
	var platform: Node2D = _pick_scene().instantiate()
	var extra := _extra_width(platform)

	var prev_pos := Vector2(last_x, highest_y)
	var pos := prev_pos

	for attempt in range(20):
		var rise := randf_range(MIN_RISE, MAX_RISE)
		var step := randf_range(-MAX_HORIZONTAL_STEP, MAX_HORIZONTAL_STEP)
		pos = prev_pos + Vector2(step, -rise)

		if not _too_close_to_any(pos, extra):
			break

	last_x = pos.x
	highest_y = pos.y

	platform.set_meta("center", pos)
	platform.set_meta("extra", extra)
	platform.position = to_local(pos)
	add_child(platform)


func _pick_scene() -> PackedScene:
	var total := 0.0
	for entry in PLATFORM_TYPES:
		total += entry["weight"]

	var roll := randf() * total
	for entry in PLATFORM_TYPES:
		roll -= entry["weight"]
		if roll <= 0.0:
			return entry["scene"]

	return PLATFORM_TYPES[0]["scene"]


func _extra_width(platform: Node) -> float:
	if "move_distance" in platform:
		return platform.move_distance

	return 0.0


func _too_close_to_any(pos: Vector2, extra: float) -> bool:
	for child in get_children():
		var min_dist: float = MIN_DISTANCE + extra + child.get_meta("extra")
		if pos.distance_to(child.get_meta("center")) < min_dist:
			return true

	return false


func _cleanup_platforms(viewport_height: float) -> void:
	for child in get_children():
		if child.global_position.y > player.global_position.y + viewport_height:
			child.queue_free()
