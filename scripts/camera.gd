extends Camera2D

@export var player_path: NodePath = ^"../Player"
var player: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node(player_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	global_position = player.global_position
