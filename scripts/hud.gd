extends CanvasLayer

@export var player: Player
@export var wings: WingAbility
@export var pixels_per_meter := 100.0

@onready var label: Label = $HeightLabel
@onready var wing_label: Label = $WingLabel

## The player's y position at the start, used as height 0.
var start_y: float
var best_height := 0.0


func _ready() -> void:
	start_y = player.global_position.y
	wings.charges_changed.connect(_on_wing_charges_changed)
	_on_wing_charges_changed(wings.charges)


func _process(_delta: float) -> void:
	# y grows downwards in Godot, so height is start_y minus the current y.
	var height := (start_y - player.global_position.y) / pixels_per_meter
	best_height = maxf(best_height, height)
	label.text = "%d m" % int(best_height)


## Connected to the restart pad: forget the best height of the last run.
func reset() -> void:
	best_height = 0.0


func _on_wing_charges_changed(charges: int) -> void:
	wing_label.text = "Flügel: %d" % charges
