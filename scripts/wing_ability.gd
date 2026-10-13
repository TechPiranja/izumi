## Double jump ability of the player. Lives as a child node of the player.
class_name WingAbility
extends Node2D

signal charges_changed(charges: int)

const MAX_CHARGES := 3

## Set to false to lock the ability, e.g. until the player picks it up.
@export var unlocked := true

var charges := MAX_CHARGES

@onready var burst: CPUParticles2D = $WingBurst


## Uses one charge and returns true if an air jump is allowed right now.
func try_air_jump() -> bool:
	if not unlocked or charges <= 0:
		return false

	charges -= 1
	burst.restart()
	charges_changed.emit(charges)
	return true


## Adds one charge if there is room. Returns true if a charge was added.
func add_charge() -> bool:
	if charges >= MAX_CHARGES:
		return false

	charges += 1
	charges_changed.emit(charges)
	return true


## Connected to the restart pad.
func refill() -> void:
	charges = MAX_CHARGES
	charges_changed.emit(charges)
