extends CanvasLayer

const WING_SLOT_SCENE := preload("res://scenes/ui/wing_slot.tscn")

@export var player: Player
@export var wings: WingAbility
@export var pixels_per_meter := 100.0

@onready var label: Label = $HeightLabel
@onready var wing_slots: HBoxContainer = $WingSlots

## The player's y position at the start, used as height 0.
var start_y: float
var best_height := 0.0


func _ready() -> void:
	start_y = player.global_position.y

	# One slot per possible wing charge.
	for i in WingAbility.MAX_CHARGES:
		wing_slots.add_child(WING_SLOT_SCENE.instantiate())

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


## Shows a wing in the first `charges` slots, the rest stay empty.
func _on_wing_charges_changed(charges: int) -> void:
	for i in wing_slots.get_child_count():
		var slot: WingSlot = wing_slots.get_child(i)
		slot.set_filled(i < charges)
