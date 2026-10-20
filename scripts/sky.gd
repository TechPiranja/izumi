## Changes the background color with the player's height: day, sunset, night, space.
## It is a CanvasLayer behind the world, which also holds the twinkling stars.
extends CanvasLayer

## Sky color at a height in meters, from the ground up.
const SKY_STOPS := [
	[0.0, Color(0.326, 0.553, 0.587)],
	[100.0, Color(0.55, 0.72, 0.78)],
	[200.0, Color(0.93, 0.62, 0.55)],
	[300.0, Color(0.45, 0.33, 0.6)],
	[450.0, Color(0.1, 0.12, 0.28)],
	[600.0, Color(0.04, 0.04, 0.14)],
]
## Stars fade in between these two heights.
const STARS_FROM := 280.0
const STARS_FULL := 450.0

@export var player: Player
@export var pixels_per_meter := 100.0

var start_y: float
var current_color := Color.BLACK
var stars: StarField


func _ready() -> void:
	layer = -10
	start_y = player.global_position.y
	stars = StarField.new()
	add_child(stars)
	current_color = _sky_color(0.0)


func _process(delta: float) -> void:
	var meters := (start_y - player.global_position.y) / pixels_per_meter
	# Moves towards the target color, so a restart fades back instead of jumping.
	current_color = current_color.lerp(_sky_color(meters), minf(delta * 3.0, 1.0))
	RenderingServer.set_default_clear_color(current_color)
	stars.modulate.a = clampf(inverse_lerp(STARS_FROM, STARS_FULL, meters), 0.0, 1.0)


func _sky_color(meters: float) -> Color:
	for i in range(1, SKY_STOPS.size()):
		var upper: Array = SKY_STOPS[i]
		if meters <= upper[0]:
			var lower: Array = SKY_STOPS[i - 1]
			return lower[1].lerp(upper[1], inverse_lerp(lower[0], upper[0], meters))
	return SKY_STOPS[-1][1]
