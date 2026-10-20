## The tutorial: a card at the top shows pictures (keys and symbols, no words) for one thing at a time.
## When the player has done it, the card jumps to the next step. The tutorial places the orbs itself.
class_name Tutorial
extends Node

const FONT := preload("res://fonts/PixelifySans-Bold.ttf")
const WING_TEXTURE := preload("res://sprites/wing.png")
const ORB_TEXTURE := preload("res://sprites/wing_orb.png")
const PLATFORM_TEXTURE := preload("res://sprites/platform.png")
const WING_ORB_SCENE := preload("res://scenes/collectibles/wing_orb.tscn")
const DARK_ORB_SCENE := preload("res://scenes/collectibles/dark_orb.tscn")
## Where an orb floats above its platform (same as in the spawner).
const ORB_OFFSET := Vector2(0.0, -50.0)
const DONE_COLOR := Color("ffd35e")
## Seconds between doing something and the success chime of the card.
const SUCCESS_DELAY := 0.45

## What each step shows, left to right. "key:A" is a key, the others are symbols or pictures.
const STEPS := [
	# 0: walk
	["key:A", "key:D"],
	# 1: jump
	["key:W"],
	# 2: climb up the platforms
	["platform", "up"],
	# 3: double jump with a wing
	["key:W", "key:W", "wing"],
	# 4: pick up a wing orb
	["orb_wing", "arrow", "wing", "text:+1"],
	# 5: the blocks show the way to the next 100 m, which gives a wing
	["blocks", "arrow", "text:100 m", "arrow", "wing"],
	# 6: the black orb hides the platforms
	["orb_dark", "arrow", "platform_hidden"],
	# 7: space shows them again, once
	["key:SPACE", "arrow", "pie"],
	# 8: the second black orb ends the darkness
	["orb_dark", "arrow", "platform"],
	# 9: done
	["check", "key:ESC"],
]

var player: Player
var spawner: Node2D

var card: PanelContainer
var row: HBoxContainer
var dots: HBoxContainer
var step := 0
var finished := false
var advancing := false

var start_x := 0.0
var start_y := 0.0
var charges_at_entry := 0
var vision_count := 0
var vision_count_at_entry := 0
var was_blind := false


func _ready() -> void:
	start_x = player.global_position.x
	start_y = player.global_position.y
	Blackout.vision_started.connect(func(_origin: Vector2, _radius: float, _duration: float) -> void: vision_count += 1)
	_build_card()
	_enter_step(0)


func _process(_delta: float) -> void:
	if finished or advancing:
		return
	if _step_done():
		_next_step()


func _meters() -> float:
	return (start_y - player.global_position.y) / 100.0


## True when the player has done what the current step shows.
func _step_done() -> bool:
	match step:
		0:
			return absf(player.global_position.x - start_x) > 250.0
		1:
			# Moving upwards fast means a jump.
			return player.velocity.y < Player.JUMP_VELOCITY * 0.8
		2:
			return _meters() >= 3.0
		3:
			return player.wings.charges < WingAbility.MAX_CHARGES
		4:
			return player.wings.charges > charges_at_entry
		5:
			return _meters() >= 12.0
		6:
			return Blackout.is_blind
		7:
			return vision_count > vision_count_at_entry
		8:
			return not Blackout.is_blind
	return false


func _next_step() -> void:
	advancing = true
	# Wait a moment, so the sound of what the player just did (a jump, a pickup) is not
	# played at the same time as the success chime.
	await get_tree().create_timer(SUCCESS_DELAY).timeout
	Sfx.play("orb", -4.0)
	# The card flashes gold, then shows the next step.
	var style: StyleBoxFlat = card.get_theme_stylebox("panel")
	style.border_color = DONE_COLOR
	_pop_card()
	await get_tree().create_timer(0.5).timeout
	style.border_color = Color("fff4dc")
	_enter_step(step + 1)
	advancing = false


func _enter_step(index: int) -> void:
	step = index
	_rebuild_card()

	match step:
		4:
			# Make sure there is a free slot for the wing.
			if player.wings.charges >= WingAbility.MAX_CHARGES:
				player.wings.charges = WingAbility.MAX_CHARGES - 1
				player.wings.charges_changed.emit(player.wings.charges)
			charges_at_entry = player.wings.charges
			_place_orb(WING_ORB_SCENE, 1)
		6:
			# The black orb, and the one that ends the darkness four platforms higher.
			_place_orb(DARK_ORB_SCENE, 1)
			_place_orb(DARK_ORB_SCENE, 5)
		7:
			vision_count_at_entry = vision_count
		9:
			finished = true
			Sfx.play("milestone", -4.0, 0.0)


## Puts an orb on the platform that is `rank` platforms above the player (0 = the nearest one).
func _place_orb(scene: PackedScene, rank: int) -> void:
	var platforms: Array[Node2D] = []
	for child in spawner.get_children():
		if child is Platform and child.global_position.y < player.global_position.y - 60.0:
			platforms.append(child)
	if platforms.is_empty():
		return

	# Nearest first: platforms further down have bigger y.
	platforms.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.y > b.global_position.y)
	var platform := platforms[mini(rank, platforms.size() - 1)]
	var orb: Node2D = scene.instantiate()
	orb.position = ORB_OFFSET
	platform.add_child(orb)


func _build_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)

	card = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.2, 0.78)
	style.border_color = Color("fff4dc")
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 14.0
	card.add_theme_stylebox_override("panel", style)
	layer.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)

	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)

	dots = HBoxContainer.new()
	dots.add_theme_constant_override("separation", 6)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(dots)


## Shows the pictures of the current step and the progress dots, centered at the top.
func _rebuild_card() -> void:
	for child in row.get_children():
		child.queue_free()
	for child in dots.get_children():
		child.queue_free()

	for token in STEPS[step]:
		row.add_child(_make_token(token))

	for i in STEPS.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12.0, 12.0)
		dot.color = DONE_COLOR if i <= step else Color(1.0, 0.96, 0.86, 0.3)
		dots.add_child(dot)

	# The card has its new size one frame later.
	card.size = Vector2.ZERO
	await get_tree().process_frame
	var screen := get_viewport().get_visible_rect().size
	# Below the wings and the ping pie in the top left corner.
	card.position = Vector2((screen.x - card.size.x) * 0.5, 100.0)
	_pop_card()


func _pop_card() -> void:
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(1.08, 1.08)
	card.create_tween().tween_property(card, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _make_token(token: String) -> Control:
	if token.begins_with("key:"):
		return KeyCap.new(token.trim_prefix("key:"))
	if token.begins_with("text:"):
		return _make_label(token.trim_prefix("text:"))

	match token:
		"arrow", "up", "check", "blocks":
			return Symbol.new(token)
		"wing":
			return _make_picture(WING_TEXTURE, Vector2(56.0, 56.0), Color.WHITE)
		"orb_wing":
			return _make_picture(_orb_frame(), Vector2(60.0, 60.0), Color.WHITE)
		"orb_dark":
			return _make_picture(_orb_frame(), Vector2(60.0, 60.0), Color(0.5, 0.25, 0.8))
		"platform":
			return _make_picture(PLATFORM_TEXTURE, Vector2(120.0, 60.0), Color.WHITE)
		"platform_hidden":
			return _make_picture(PLATFORM_TEXTURE, Vector2(120.0, 60.0), Color(1.0, 1.0, 1.0, 0.25))
		"pie":
			var pie := PingPie.new()
			return pie
	return Control.new()


func _orb_frame() -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ORB_TEXTURE
	texture.region = Rect2(30.0, 0.0, 15.0, 15.0)
	return texture


func _make_picture(texture: Texture2D, picture_size: Vector2, tint: Color) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = picture_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = tint
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color("fff4dc"))
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label
