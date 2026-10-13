## Builds an endless ladder of platforms upwards and removes the ones far below the player.
extends Node2D

## How much higher the next platform is placed.
const MIN_RISE := 60.0
const MAX_RISE := 130.0
## How far to the left or right the next platform may be shifted.
const MAX_HORIZONTAL_STEP := 250.0
## Minimum distance between the centers of two platforms.
const MIN_DISTANCE := 120.0
## How many platforms are built when a run starts.
const INITIAL_PLATFORMS := 15
## How many random positions are tried before taking the best one found.
const MAX_PLACEMENT_ATTEMPTS := 20

const WING_ORB_SCENE := preload("res://scenes/collectibles/wing_orb.tscn")
## Where an orb floats, relative to the platform it belongs to: centered, just above its top edge.
## Keep it low: the next platform can be only MIN_RISE above and would cover a higher orb.
const ORB_OFFSET := Vector2(0.0, -50.0)

@export var player: Player
## The platform the ladder starts from.
@export var start_platform: Node2D
## The kinds of platforms that can spawn, each with a weight.
@export var platform_types: Array[PlatformType]
## Chance (0 to 1) that a new platform gets a wing orb above it.
@export_range(0.0, 1.0) var orb_chance := 0.15

## Height and x position of the most recently placed platform.
var highest_y: float
var last_x: float


func _ready() -> void:
	assert(not platform_types.is_empty(), "PlatformSpawner needs at least one entry in platform_types")
	reset()


## Removes all platforms and builds a fresh ladder. Connected to the restart pad.
func reset() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	highest_y = start_platform.global_position.y
	last_x = start_platform.global_position.x

	for i in INITIAL_PLATFORMS:
		_spawn_platform()


func _process(_delta: float) -> void:
	var viewport_height := get_viewport_rect().size.y
	# Always keep platforms ready up to one screen height above the player.
	while highest_y > player.global_position.y - viewport_height:
		_spawn_platform()

	_cleanup_platforms(viewport_height)


func _spawn_platform() -> void:
	var platform: Platform = _pick_scene().instantiate()
	var pos := _find_position(platform.get_extra_width())

	last_x = pos.x
	highest_y = pos.y

	platform.spawn_center = pos
	platform.position = to_local(pos)

	if randf() < orb_chance:
		# Child of the platform: it moves with it and is removed together with it.
		var orb := WING_ORB_SCENE.instantiate()
		orb.position = ORB_OFFSET
		platform.add_child(orb)

	add_child(platform)


## Finds a spot above the previous platform that keeps enough distance to all others.
func _find_position(extra: float) -> Vector2:
	var prev_pos := Vector2(last_x, highest_y)
	var best_pos := prev_pos
	var best_clearance := -INF

	for attempt in MAX_PLACEMENT_ATTEMPTS:
		var rise := randf_range(MIN_RISE, MAX_RISE)
		var step := randf_range(-MAX_HORIZONTAL_STEP, MAX_HORIZONTAL_STEP)
		var pos := prev_pos + Vector2(step, -rise)

		var clearance := _clearance(pos, extra)
		if clearance >= 0.0:
			return pos
		if clearance > best_clearance:
			best_clearance = clearance
			best_pos = pos

	# No spot had enough room (swinging platforms ask for a lot): take the roomiest one.
	# Going higher instead would leave gaps the player can't jump.
	return best_pos


## Weighted random pick: roll a number up to the total weight, then subtract
## the weights one by one until the roll is used up.
func _pick_scene() -> PackedScene:
	var total := 0.0
	for type in platform_types:
		total += type.weight

	var roll := randf() * total
	for type in platform_types:
		roll -= type.weight
		if roll <= 0.0:
			return type.scene

	return platform_types[0].scene


## How much room `pos` has to the closest platform, beyond the required distance.
## Negative means it is too close.
func _clearance(pos: Vector2, extra: float) -> float:
	var smallest := INF
	for child in get_children():
		var other := child as Platform
		var min_dist := MIN_DISTANCE + extra + other.get_extra_width()
		smallest = minf(smallest, pos.distance_to(other.spawn_center) - min_dist)

	return smallest


func _cleanup_platforms(viewport_height: float) -> void:
	for child in get_children():
		if child.global_position.y > player.global_position.y + viewport_height:
			child.queue_free()
