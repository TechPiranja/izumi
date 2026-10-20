## Builds an endless ladder of platforms upwards and removes the ones far below the player.
extends Node2D

## How much higher the next platform is placed.
const MIN_RISE := 60.0
const MAX_RISE := 130.0
## How far to the left or right the next platform may be shifted.
const MAX_HORIZONTAL_STEP := 250.0
## A "big gap" is higher than a single jump reaches (about 137 px), so it needs a wing.
const BIG_MIN_RISE := 150.0
const BIG_MAX_RISE := 200.0
## Big gaps are kept narrow sideways: the double jump has to reach them reliably.
const BIG_MAX_HORIZONTAL_STEP := 160.0
## Height (in px above the start) at which the chance of big gaps stops growing.
const DIFFICULTY_RAMP_HEIGHT := 30000.0
## Wings are meant to be rare: the free wing every 100 m is the main source.
const MAX_BIG_GAP_CHANCE := 0.1
const MAX_ORB_CHANCE := 0.08
## Minimum distance between the centers of two platforms.
const MIN_DISTANCE := 120.0
## How many platforms are built when a run starts.
const INITIAL_PLATFORMS := 15
## How many random positions are tried before taking the best one found.
const MAX_PLACEMENT_ATTEMPTS := 20

const WING_ORB_SCENE := preload("res://scenes/collectibles/wing_orb.tscn")
const DARK_ORB_SCENE := preload("res://scenes/collectibles/dark_orb.tscn")
## Chance that a platform gets the black orb that hides all platforms.
const DARK_ORB_CHANCE := 0.1
## No black orbs in the first stretch of a run (px above the start).
const DARK_ORB_MIN_HEIGHT := 2000.0
## At the latest after this much climbing (px, 50 m) the next black orb is placed.
const DARK_ORB_MAX_GAP := 5000.0
## The black orb that brings the platforms back sits this many platforms higher.
## It starts at the minimum and grows with the height up to the maximum.
const MIN_CURE_DISTANCE := 4
const MAX_CURE_DISTANCE := 10
## After the orb that ends the darkness, this many platforms get no black orb at all.
const DARK_ORB_PAUSE := 10
## Where an orb floats, relative to the platform it belongs to: centered, just above its top edge.
## Keep it low: the next platform can be only MIN_RISE above and would cover a higher orb.
const ORB_OFFSET := Vector2(0.0, -50.0)

@export var player: Player
## The platform the ladder starts from.
@export var start_platform: Node2D
## The kinds of platforms that can spawn, each with a weight.
@export var platform_types: Array[PlatformType]
## Chance (0 to 1) that a new platform gets a wing orb above it.
@export_range(0.0, 1.0) var orb_chance := 0.04

## Height and x position of the most recently placed platform.
var highest_y: float
var last_x: float
## The most recently placed platform and whether it already carries an orb.
var last_platform: Platform
var last_has_orb := false
## True if the last platform carries a black orb (no big gap right after it).
var last_has_dark_orb := false
## Counts down the platforms until the curing black orb is placed. 0 means none is waiting.
var cure_countdown := 0
## The curing orb that was placed last, to notice when the player has left it behind.
var cure_orb: DarkOrb
## How many platforms were built in this run (the next one gets this number).
var platform_counter := 1
## How high (px above the start) the last hiding black orb was placed.
var last_dark_climbed := 0.0
## Counts down the platforms without any black orb after the end orb. 0 means black orbs may spawn.
var dark_pause := 0


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
	last_platform = null
	last_has_orb = false
	last_has_dark_orb = false
	cure_countdown = 0
	cure_orb = null
	platform_counter = 1
	last_dark_climbed = 0.0
	dark_pause = 0
	# A new run always starts with visible platforms and counts platforms from zero.
	Blackout.reset_run()

	for i in INITIAL_PLATFORMS:
		_spawn_platform()

	# Dark mode starts like a black orb: a short look at what is around.
	if GameMode.is_dark_mode():
		Blackout.start_vision(player.global_position)


func _process(_delta: float) -> void:
	var viewport_height := get_viewport_rect().size.y
	# Always keep platforms ready up to one screen height above the player.
	while highest_y > player.global_position.y - viewport_height:
		_spawn_platform()

	_cleanup_platforms(viewport_height)


func _spawn_platform() -> void:
	var platform: Platform = _pick_scene().instantiate()
	var difficulty := _difficulty()
	# The tutorial hands out its orbs itself; big gaps would need wings it may not have given yet.
	var tutorial := GameMode.is_tutorial()
	var big_gap := randf() < difficulty * MAX_BIG_GAP_CHANCE and not last_has_dark_orb and not tutorial
	var pos := _find_position(platform.get_extra_width(), big_gap)

	last_x = pos.x
	highest_y = pos.y

	platform.spawn_center = pos
	platform.position = to_local(pos)
	platform.index = platform_counter
	platform_counter += 1

	# A big gap needs a wing, so the platform below it always carries an orb.
	# Otherwise the player could stand there with no wings and be stuck.
	if big_gap and last_platform and not last_has_orb:
		_add_orb(last_platform)
		last_has_orb = true

	var has_orb := not tutorial and randf() < lerpf(orb_chance, MAX_ORB_CHANCE, difficulty)
	var has_dark_orb := false
	var was_paused := dark_pause > 0
	# Dark mode is dark all the time already, so it has no black orbs.
	var dark_orbs_allowed := not tutorial and not GameMode.is_dark_mode()

	if not dark_orbs_allowed:
		pass
	elif cure_countdown > 0:
		cure_countdown -= 1
		if cure_countdown == 0:
			cure_orb = _add_dark_orb(platform)
			has_dark_orb = true
			dark_pause = DARK_ORB_PAUSE
	elif _needs_new_cure():
		# The player skipped the second orb while it is dark: give them another one.
		cure_orb = _add_dark_orb(platform)
		has_dark_orb = true
		dark_pause = DARK_ORB_PAUSE
	elif not Blackout.is_blind and not was_paused and _climbed() > DARK_ORB_MIN_HEIGHT and _dark_orb_due(has_orb):
		_add_dark_orb(platform)
		cure_countdown = _cure_distance()
		last_dark_climbed = _climbed()
		has_dark_orb = true

	if was_paused:
		dark_pause -= 1

	# One orb per platform.
	if has_dark_orb:
		has_orb = false
	elif has_orb:
		_add_orb(platform)

	last_platform = platform
	last_has_orb = has_orb
	last_has_dark_orb = has_dark_orb

	add_child(platform)


## True if this platform should get the black orb: always after 50 m without one,
## otherwise by chance (and only if the platform has no wing orb).
func _dark_orb_due(platform_has_wing_orb: bool) -> bool:
	if _climbed() - last_dark_climbed >= DARK_ORB_MAX_GAP:
		return true
	return not platform_has_wing_orb and randf() < DARK_ORB_CHANCE


## How many platforms the darkness lasts: 4 at the start, more the higher the player is.
func _cure_distance() -> int:
	return MIN_CURE_DISTANCE + roundi(_difficulty() * (MAX_CURE_DISTANCE - MIN_CURE_DISTANCE))


func _add_dark_orb(platform: Platform) -> DarkOrb:
	var orb: DarkOrb = DARK_ORB_SCENE.instantiate()
	orb.position = ORB_OFFSET
	platform.add_child(orb)
	return orb


## True while it is dark but no curing orb is waiting above the player anymore.
func _needs_new_cure() -> bool:
	if not Blackout.is_blind or cure_countdown > 0:
		return false
	return not (is_instance_valid(cure_orb) and cure_orb.global_position.y < player.global_position.y)


## How far above the start the newest platform is, in px.
func _climbed() -> float:
	return start_platform.global_position.y - highest_y


## Child of the platform: the orb moves with it and is removed together with it.
func _add_orb(platform: Platform) -> void:
	var orb := WING_ORB_SCENE.instantiate()
	orb.position = ORB_OFFSET
	platform.add_child(orb)


## 0 at the start of a run, 1 once the player is DIFFICULTY_RAMP_HEIGHT px up.
func _difficulty() -> float:
	return clampf((start_platform.global_position.y - highest_y) / DIFFICULTY_RAMP_HEIGHT, 0.0, 1.0)


## Finds a spot above the previous platform that keeps enough distance to all others.
func _find_position(extra: float, big_gap: bool) -> Vector2:
	var prev_pos := Vector2(last_x, highest_y)
	var best_pos := prev_pos
	var best_clearance := -INF

	for attempt in MAX_PLACEMENT_ATTEMPTS:
		var rise := randf_range(BIG_MIN_RISE, BIG_MAX_RISE) if big_gap else randf_range(MIN_RISE, MAX_RISE)
		var max_step := BIG_MAX_HORIZONTAL_STEP if big_gap else MAX_HORIZONTAL_STEP
		var step := randf_range(-max_step, max_step)
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
