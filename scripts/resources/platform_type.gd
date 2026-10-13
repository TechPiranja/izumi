## One entry in the platform spawner's list: which scene to spawn and how often.
class_name PlatformType
extends Resource

@export var scene: PackedScene
## Relative chance: weight 6 next to two entries with weight 2 means 60 % of all platforms.
@export var weight := 1.0
