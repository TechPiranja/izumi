## Autoload "Sfx": plays the small sound effects from res://audio/ (made by tools/gen_sfx.gd).
## Usage: Sfx.play("jump")
extends Node

const POOL_SIZE := 8
const NAMES := ["jump", "air_jump", "land", "orb", "tick", "milestone", "toast", "dark", "cure", "ping", "game_over"]

var streams := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0


func _ready() -> void:
	# Sounds keep playing while the game is paused behind the game over screen.
	process_mode = Node.PROCESS_MODE_ALWAYS

	for sfx_name in NAMES:
		var path := "res://audio/%s.wav" % sfx_name
		if ResourceLoader.exists(path):
			streams[sfx_name] = load(path)

	# A few players, so overlapping sounds don't cut each other off.
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)


## `pitch_jitter` varies the pitch a little each time, so repeats don't sound robotic.
## `pitch` plays the sound higher (above 1) or lower (below 1), e.g. to play notes with one sample.
func play(sfx_name: String, volume_db := 0.0, pitch_jitter := 0.06, pitch := 1.0) -> void:
	if not streams.has(sfx_name):
		return

	var player := players[next_player]
	next_player = (next_player + 1) % POOL_SIZE
	player.stream = streams[sfx_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	player.play()
