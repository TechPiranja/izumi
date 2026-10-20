## One slot of the wing display in the HUD: an empty frame, with a wing on top if filled.
class_name WingSlot
extends TextureRect

@onready var wing: TextureRect = $Wing

var filled := false


## Pops the slot when a wing arrives, and shrinks it a little when one is used up.
func set_filled(is_filled: bool) -> void:
	wing.visible = is_filled
	if is_filled != filled and is_node_ready():
		_pop(1.35 if is_filled else 0.8)
	filled = is_filled


func _pop(peak: float) -> void:
	# Scale around the middle of the slot instead of its top left corner.
	pivot_offset = size * 0.5
	scale = Vector2(peak, peak)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
