extends Node2D

const CLOUD_SCENE := preload("res://scenes/cloud.tscn")
const BAND_HEIGHT := 250.0
const BANDS_ABOVE := 5
const BANDS_BELOW := 4
const Y_JITTER := 0.3
const BEHIND_CHANCE := 0.8
const MIN_SPEED := 15.0
const MAX_SPEED := 35.0

@export var player_path: NodePath = ^"../Player"

var player: CharacterBody2D
var clouds := {}


func _ready() -> void:
	player = get_node(player_path)
	_update_clouds(true)


func _process(_delta: float) -> void:
	_update_clouds(false)


func _update_clouds(fill_visible: bool) -> void:
	var center_band := int(floor(player.global_position.y / BAND_HEIGHT))
	var first_band := center_band - BANDS_ABOVE
	var last_band := center_band + BANDS_BELOW

	for band in clouds.keys():
		var cloud: Node2D = clouds[band]
		if band < first_band or band > last_band or _too_far_sideways(cloud):
			cloud.queue_free()
			clouds.erase(band)

	for band in range(first_band, last_band + 1):
		if not clouds.has(band):
			clouds[band] = _spawn_cloud(band, fill_visible)


func _spawn_cloud(band: int, anywhere: bool) -> Node2D:
	var view := get_viewport_rect().size
	var y := (band + 0.5 + randf_range(-Y_JITTER, Y_JITTER)) * BAND_HEIGHT
	var on_screen := absf(y - player.global_position.y) < view.y / 2.0 + 100.0

	var x := player.global_position.x
	if on_screen and not anywhere:
		x -= view.x / 2.0 + 150.0
	else:
		x += randf_range(-view.x, view.x)

	var cloud: Node2D = CLOUD_SCENE.instantiate()
	cloud.position = to_local(Vector2(x, y))
	cloud.z_index = -1 if randf() < BEHIND_CHANCE else 1
	cloud.speed = randf_range(MIN_SPEED, MAX_SPEED)
	add_child(cloud)
	return cloud


func _too_far_sideways(cloud: Node2D) -> bool:
	return absf(cloud.global_position.x - player.global_position.x) > get_viewport_rect().size.x * 1.25
