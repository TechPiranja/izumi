extends CanvasLayer

@export var player_path: NodePath = ^"../Player"
@export var pixels_per_meter := 100.0

@onready var label: Label = $HeightLabel
@onready var wing_label: Label = $WingLabel

var player: CharacterBody2D
var start_y: float
var best_height := 0.0


func _ready() -> void:
	player = get_node(player_path)
	start_y = player.global_position.y
	player.wing_charges_changed.connect(_on_wing_charges_changed)
	_on_wing_charges_changed(player.wing_charges)


func _process(_delta: float) -> void:
	var height := (start_y - player.global_position.y) / pixels_per_meter
	best_height = maxf(best_height, height)
	label.text = "%d m" % int(best_height)


func reset() -> void:
	best_height = 0.0


func _on_wing_charges_changed(charges: int) -> void:
	wing_label.text = "Flügel: %d" % charges
