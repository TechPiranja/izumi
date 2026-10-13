extends Platform

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detect_area: Area2D = $DetectArea

var triggered := false


func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta: float) -> void:
	if triggered:
		return

	# Only crumble when the player stands on top, not when bumping into it from below.
	for body in detect_area.get_overlapping_bodies():
		if body is CharacterBody2D:
			var character := body as CharacterBody2D
			if character.is_on_floor() and character.global_position.y < global_position.y:
				triggered = true
				animated_sprite.play("crumble")
				return


func _on_animation_finished() -> void:
	queue_free()
