extends Node2D

const CLOUD_SCENE := preload("res://scenes/environment/cloud.tscn")
## Size of the cloud field around the player, in screen sizes.
const FIELD_WIDTH := 1.5
const FIELD_ABOVE := 2.0
const FIELD_BELOW := 0.75

@export var player: Player
## Fixed number of clouds. They are recycled, never freed.
@export var cloud_count := 30


func _ready() -> void:
	var field := _field()
	for i in cloud_count:
		var cloud: Cloud = CLOUD_SCENE.instantiate()
		add_child(cloud)
		# Start with a random spot somewhere inside the field.
		cloud.global_position = player.global_position + field.position + Vector2(
			randf_range(0.0, field.size.x),
			randf_range(0.0, field.size.y),
		)
		cloud.randomize_look()


## Clouds that leave the field re-enter on the opposite side.
func _process(_delta: float) -> void:
	var field := _field()
	for cloud: Cloud in get_children():
		var local := cloud.global_position - player.global_position - field.position
		# Modulo on x and y: a cloud that leaves the field on one side
		# comes back in on the other side.
		var wrapped := Vector2(fposmod(local.x, field.size.x), fposmod(local.y, field.size.y))
		if not wrapped.is_equal_approx(local):
			cloud.global_position = player.global_position + field.position + wrapped
			cloud.randomize_look()


## The field relative to the player: `position` is the top-left corner, plus `size`.
func _field() -> Rect2:
	var view := get_viewport_rect().size
	var size := Vector2(view.x * FIELD_WIDTH, view.y * (FIELD_ABOVE + FIELD_BELOW))
	return Rect2(Vector2(-size.x / 2.0, -view.y * FIELD_ABOVE), size)
