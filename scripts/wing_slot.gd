## One slot of the wing display in the HUD: an empty frame, with a wing on top if filled.
class_name WingSlot
extends TextureRect

@onready var wing: TextureRect = $Wing


func set_filled(filled: bool) -> void:
	wing.visible = filled
