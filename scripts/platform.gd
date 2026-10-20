class_name Platform
extends StaticBody2D

## How visible the platform is while the black orb hides everything (0 = not at all).
const HIDDEN_ALPHA := 0.0
## How long each step of the blinking lasts, in seconds.
const BLINK_STEP := 0.1
const REVEAL_TIME := 0.1
const HIDE_TIME := 0.4

## Position where the spawner placed this platform (moving platforms change
## global_position, this value stays the same).
var spawn_center: Vector2
## Spawn number: the higher the platform, the bigger the number. Used to count climbed platforms.
var index := 0

var blink_tween: Tween


## Not `_ready()`: the platform types override that and would skip this.
func _enter_tree() -> void:
	Blackout.changed.connect(_on_blackout_changed)
	Blackout.vision_started.connect(_on_vision_started)
	# Platforms that appear while everything is hidden start hidden.
	if Blackout.is_blind:
		_set_alpha(HIDDEN_ALPHA)


## Extra space the spawner has to keep free around this platform.
func get_extra_width() -> float:
	return 0.0


func _on_blackout_changed(blind: bool, instant: bool) -> void:
	if blink_tween:
		blink_tween.kill()

	# Going dark is instant: the black-and-outlines effect covers it.
	if blind or instant:
		_set_alpha(HIDDEN_ALPHA if blind else 1.0)
		return

	# The platforms come back: flicker a few times, then stay visible.
	var steps: Array[float] = [0.1, 1.0, 0.4, 1.0]
	blink_tween = create_tween()
	var from := _current_alpha()
	for alpha in steps:
		blink_tween.tween_method(_set_alpha, from, alpha, BLINK_STEP)
		from = alpha


## The wave of a vision reaches this platform: it shows up, stays, and hides again at the end.
func _on_vision_started(origin: Vector2, radius: float, duration: float) -> void:
	if not Blackout.is_blind:
		return
	var distance := global_position.distance_to(origin)
	if distance > radius:
		return

	if blink_tween:
		blink_tween.kill()
	# Near platforms show up first, as the wave grows outwards.
	var delay := Blackout.VISION_START_DELAY + distance / Blackout.VISION_SPEED
	var visible_time := maxf(duration - delay - REVEAL_TIME - HIDE_TIME, 0.2)
	blink_tween = create_tween()
	blink_tween.tween_interval(delay)
	blink_tween.tween_method(_set_alpha, _current_alpha(), 1.0, REVEAL_TIME)
	blink_tween.tween_interval(visible_time)
	blink_tween.tween_method(_set_alpha, 1.0, HIDDEN_ALPHA, HIDE_TIME)


## The platform's own pictures. Orbs are Area2D children and are not included.
func _sprites() -> Array[CanvasItem]:
	var sprites: Array[CanvasItem] = []
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			sprites.append(child)
	return sprites


func _set_alpha(alpha: float) -> void:
	for sprite in _sprites():
		sprite.modulate.a = alpha


func _current_alpha() -> float:
	var sprites := _sprites()
	return sprites[0].modulate.a if not sprites.is_empty() else 1.0
