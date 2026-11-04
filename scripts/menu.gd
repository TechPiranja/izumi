## The main menu: izumi, and three cards for tutorial, infinity mode and dark mode.
## Left/right (A/D) to choose, jump or enter to start. Or just click a card.
extends Control

const FONT := preload("res://fonts/PixelifySans-Bold.ttf")
const IZUMI_TEXTURE := preload("res://sprites/izumi.png")
const CLOUD_SCENE := preload("res://scenes/environment/cloud.tscn")
const SKY_COLOR := Color(0.326, 0.553, 0.587)
const CLOUD_COUNT := 9
const CARD_GAP := 22.0
const SELECTED_SCALE := 1.12
## Where the title label ends (14 px from the top, 140 px tall).
const TITLE_BOTTOM := 154.0
const CHARACTER_SCALE := 2.4
const CHARACTER_MAX_SCALE := 5.0
## The sprite frames are 100 px square.
const CHARACTER_FRAME := 100.0
## How much of the free height between title and cards she may fill.
const CHARACTER_FILL := 0.75

const KINDS := ["tutorial", "infinity", "dark"]

## Modes in the order of the cards.
var modes := [GameMode.Mode.TUTORIAL, GameMode.Mode.INFINITY, GameMode.Mode.DARK]
var cards: Array[MenuCard] = []
var selected := 1
var clouds: Node2D
var starting := false
var title: Label
var character: AnimatedSprite2D
## The screen size the menu was last laid out for.
var laid_out_size := Vector2.ZERO


func _ready() -> void:
	RenderingServer.set_default_clear_color(SKY_COLOR)
	_build_clouds()
	_build_title()
	_build_character()
	_build_cards()
	_select(selected, false)

	laid_out_size = get_viewport_rect().size
	get_viewport().size_changed.connect(_layout)


## Puts everything back in the middle when the window is resized.
func _layout() -> void:
	var screen := get_viewport_rect().size
	if laid_out_size.x > 0.0:
		# The clouds spread over the new width instead of staying in the old area.
		for cloud in clouds.get_children():
			cloud.position.x *= screen.x / laid_out_size.x
			cloud.position.y *= screen.y / laid_out_size.y
	laid_out_size = screen

	title.position.x = screen.x * 0.5 - 250.0
	_place_cards()
	_place_character()


## izumi sits in the middle, between the bottom of the title and the top of the cards.
func _place_character() -> void:
	var screen := get_viewport_rect().size
	var cards_top := screen.y - MenuCard.CARD_SIZE.y - 40.0
	character.position = Vector2(screen.x * 0.5, (TITLE_BOTTOM + cards_top) * 0.5)

	# With lots of room in between she grows, but never gets smaller than the normal size.
	var free_height := cards_top - TITLE_BOTTOM
	var grown := free_height * CHARACTER_FILL / CHARACTER_FRAME
	character.scale = Vector2.ONE * clampf(grown, CHARACTER_SCALE, CHARACTER_MAX_SCALE)


func _process(_delta: float) -> void:
	var width := get_viewport_rect().size.x
	for cloud in clouds.get_children():
		# Clouds that drift off to the right come back from the left.
		if cloud.position.x > width + 250.0:
			cloud.position.x = -250.0


func _input(event: InputEvent) -> void:
	if starting:
		return

	if event.is_action_pressed("move_left"):
		_select(maxi(selected - 1, 0))
	elif event.is_action_pressed("move_right"):
		_select(mini(selected + 1, cards.size() - 1))
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_accept"):
		_start(selected)


func _build_clouds() -> void:
	clouds = Node2D.new()
	add_child(clouds)
	var screen := get_viewport_rect().size
	for i in CLOUD_COUNT:
		var cloud: Cloud = CLOUD_SCENE.instantiate()
		clouds.add_child(cloud)
		cloud.randomize_look()
		# All clouds stay behind the character and the cards.
		cloud.z_index = -5
		cloud.position = Vector2(randf() * screen.x, randf() * screen.y)


func _build_title() -> void:
	title = Label.new()
	title.text = "izumi"
	title.custom_minimum_size = Vector2(500.0, 0.0)
	title.size = Vector2(500.0, 140.0)
	title.position = Vector2(get_viewport_rect().size.x * 0.5 - 250.0, 14.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", Color("fff4dc"))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.25, 0.8))
	title.add_theme_constant_override("outline_size", 14)
	add_child(title)

	# The title floats up and down a little.
	var tween := title.create_tween().set_loops()
	tween.tween_property(title, "position:y", 32.0, 1.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "position:y", 14.0, 1.4).set_trans(Tween.TRANS_SINE)


## izumi, standing and breathing between title and cards.
func _build_character() -> void:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 5.0)
	for i in 7:
		var atlas := AtlasTexture.new()
		atlas.atlas = IZUMI_TEXTURE
		atlas.region = Rect2(i * 100.0, 0.0, 100.0, 100.0)
		frames.add_frame("default", atlas)

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * CHARACTER_SCALE
	add_child(sprite)
	sprite.play("default")
	character = sprite
	_place_character()


func _build_cards() -> void:
	for i in KINDS.size():
		var card := MenuCard.new(KINDS[i])
		card.mouse_entered.connect(_select.bind(i))
		card.gui_input.connect(_on_card_input.bind(i))
		add_child(card)
		cards.append(card)
	_place_cards()


## The cards sit in a row, centered at the bottom.
func _place_cards() -> void:
	var screen := get_viewport_rect().size
	var total_width := MenuCard.CARD_SIZE.x * KINDS.size() + CARD_GAP * (KINDS.size() - 1)
	var left := (screen.x - total_width) * 0.5
	var top := screen.y - MenuCard.CARD_SIZE.y - 40.0

	for i in cards.size():
		cards[i].position = Vector2(left + i * (MenuCard.CARD_SIZE.x + CARD_GAP), top)


func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start(index)


func _select(index: int, with_sound := true) -> void:
	if with_sound and index != selected:
		Sfx.play("tick", -4.0)
	selected = index

	for i in cards.size():
		var card := cards[i]
		card.selected = i == selected
		var target := Vector2.ONE * (SELECTED_SCALE if i == selected else 1.0)
		card.create_tween().tween_property(card, "scale", target, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _start(index: int) -> void:
	starting = true
	Sfx.play("milestone", -4.0, 0.0)
	var card := cards[index]
	var tween := card.create_tween()
	tween.tween_property(card, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_callback(GameMode.start.bind(modes[index]))
