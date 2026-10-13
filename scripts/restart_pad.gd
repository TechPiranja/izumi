extends Area2D

## Emitted when the player touches the pad. The main scene connects it to the
## wing refill, the platform spawner reset and the HUD reset.
signal player_touched


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_touched.emit()
