## A black orb. Every black orb switches the platforms: visible -> hidden -> visible.
## It floats like the wing orb, only the pickup is different.
class_name DarkOrb
extends WingOrb

const DARK_COLOR := Color(0.35, 0.15, 0.6)


## The first orb's vision wave grows until it reaches the next black orb, so they need to be found.
func _enter_tree() -> void:
	add_to_group("dark_orbs")


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	if not Blackout.is_blind:
		# Dark at once; the vision shows the way for a moment.
		Blackout.set_blind(true, true)
		Blackout.start_vision(global_position)
		Sfx.play("dark", 0.0, 0.0)
		Fx.burst(self, global_position, DARK_COLOR, 22, 220.0, 5.0)
		_shake_camera(6.0)
	else:
		Blackout.set_blind(false)
		Sfx.play("cure", 0.0, 0.0)
		Fx.burst(self, global_position, Color(1.0, 0.95, 0.6), 22, 220.0, 5.0)

	queue_free()


func _shake_camera(strength: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(strength, 0.3)
