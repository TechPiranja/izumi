## The game scene. In tutorial mode it adds the tutorial on top of the normal game.
extends Node2D


func _ready() -> void:
	if TouchControls.wanted():
		add_child(TouchControls.new())

	if GameMode.is_tutorial():
		var tutorial := Tutorial.new()
		tutorial.player = $Player
		tutorial.spawner = $PlatformSpawner
		add_child(tutorial)
