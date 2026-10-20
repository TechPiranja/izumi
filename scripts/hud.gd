extends CanvasLayer

## Emitted every time the player reaches the next milestone, e.g. 100, 200, 300 m.
signal milestone_reached(meters: int)

const WING_SLOT_SCENE := preload("res://scenes/ui/wing_slot.tscn")
const NUMBER_FONT := preload("res://fonts/PixelifySans-Bold.ttf")
## Where the ping pie sits, right of the wing slots.
const PING_PIE_POSITION := Vector2(236.0, 16.0)
## Falling this far below the start (in meters) ends the run.
const FALL_LIMIT_METERS := 2.0
const SEGMENT_SIZE := Vector2(18.0, 18.0)
## The wing icon above the column is dimmed at first and gets brighter the closer the player is.
const GOAL_MIN_ALPHA := 0.45
## How long the full row of segments stays visible after a milestone.
const FULL_ROW_TIME := 0.7
## Notes of a pentatonic scale in semitones: the segments "play" a little melody while filling.
const TICK_STEPS := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]

@export var player: Player
@export var wings: WingAbility
@export var pixels_per_meter := 100.0
## A toast with confetti and a free wing every this many meters.
@export var milestone_meters := 100
## One segment fills, with a small tick, every this many meters.
@export var tick_meters := 10

@onready var label: Label = $HeightLabel
@onready var segments: VBoxContainer = $MilestoneSegments
@onready var goal_icon: TextureRect = $GoalIcon
@onready var toast: MilestoneToast = $MilestoneToast
@onready var wing_slots: HBoxContainer = $WingSlots

## The player's y position at the start, used as height 0.
var start_y: float
var best_height := 0.0
var shown_meters := 0
var next_milestone := 1
## How many segments are filled right now.
var filled_count := 0
## True while the full row is shown after a milestone.
var holding_full_row := false
var label_tween: Tween
var game_over_started := false
## Shows how many pings are left, next to the wings, while the platforms are hidden.
var ping_pie: PingPie
var empty_style: StyleBoxFlat
var filled_style: StyleBoxFlat


func _ready() -> void:
	start_y = player.global_position.y

	# One slot per possible wing charge.
	for i in WingAbility.MAX_CHARGES:
		wing_slots.add_child(WING_SLOT_SCENE.instantiate())

	wings.charges_changed.connect(_on_wing_charges_changed)
	_on_wing_charges_changed(wings.charges)
	_build_segments()
	goal_icon.modulate.a = GOAL_MIN_ALPHA
	_build_ping_pie()


func _process(_delta: float) -> void:
	# y grows downwards in Godot, so height is start_y minus the current y.
	var height := (start_y - player.global_position.y) / pixels_per_meter
	best_height = maxf(best_height, height)

	if height < -FALL_LIMIT_METERS and not game_over_started:
		_start_game_over()
		return

	var meters := int(best_height)
	if meters != shown_meters:
		shown_meters = meters
		label.text = "%d m" % meters
		if meters % 10 == 0:
			_punch_label(1.25)
		_check_milestones(meters)
		_update_segments()


## Connected to the restart pad: forget the best height of the last run.
func reset() -> void:
	best_height = 0.0
	shown_meters = 0
	next_milestone = 1
	filled_count = 0
	holding_full_row = false
	label.text = "0 m"
	_update_segments()


## Pauses the game and shows the result. A key press there reloads the scene.
func _start_game_over() -> void:
	game_over_started = true
	# Stops a running vision and shows the platforms again for the next run.
	Blackout.set_blind(false, true)

	var screen := GameOver.new()
	add_child(screen)
	get_tree().paused = true
	screen.show_result(int(best_height))


## Shows a wing in the first `charges` slots, the rest stay empty.
func _on_wing_charges_changed(charges: int) -> void:
	for i in wing_slots.get_child_count():
		var slot: WingSlot = wing_slots.get_child(i)
		slot.set_filled(i < charges)


func _check_milestones(meters: int) -> void:
	while meters >= next_milestone * milestone_meters:
		var reached := next_milestone * milestone_meters
		next_milestone += 1
		_celebrate(reached)


func _celebrate(meters: int) -> void:
	var got_wing := wings.add_charge()
	toast.show_toast("%d m" % meters, got_wing)
	Sfx.play("milestone", -2.0, 0.0)
	_punch_label(1.6)
	milestone_reached.emit(meters)

	# Show the column completely full for a moment, then start from empty.
	holding_full_row = true
	for i in segments.get_child_count():
		_set_segment(i, true, true)
	goal_icon.modulate.a = 1.0
	_pop_control(goal_icon, 2.0)
	await get_tree().create_timer(FULL_ROW_TIME).timeout
	holding_full_row = false
	filled_count = 0
	_update_segments()


## Makes the height number pop for a moment.
func _punch_label(strength: float) -> void:
	if label_tween:
		label_tween.kill()
	label.pivot_offset = Vector2(label.size.x, label.size.y * 0.5)
	label.scale = Vector2(strength, strength)
	label_tween = create_tween()
	label_tween.tween_property(label, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_ping_pie() -> void:
	ping_pie = PingPie.new()
	ping_pie.position = PING_PIE_POSITION
	ping_pie.visible = Blackout.is_blind
	add_child(ping_pie)

	Blackout.changed.connect(_on_blackout_changed)


func _on_blackout_changed(blind: bool, _instant: bool) -> void:
	ping_pie.visible = blind
	if blind:
		_pop_control(ping_pie, 1.6)


## A column of chunky square blocks, one for every `tick_meters` of the way to the next milestone.
## It fills from the bottom up, like the player climbs.
func _build_segments() -> void:
	empty_style = _make_segment_style(Color(0.0, 0.0, 0.0, 0.2), Color("fff4dc", 0.55))
	filled_style = _make_segment_style(Color("ffd35e"), Color("c2603a"))

	for i in milestone_meters / tick_meters:
		var segment := Panel.new()
		segment.custom_minimum_size = SEGMENT_SIZE
		segment.add_theme_stylebox_override("panel", empty_style)
		segments.add_child(segment)


func _make_segment_style(fill: Color, border: Color) -> StyleBoxFlat:
	# No rounded corners: sharp squares fit the pixel art.
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	return style


## Fills the segments up to the current progress, with a pop and a tick for each new one.
func _update_segments() -> void:
	if holding_full_row:
		return

	var into_milestone := best_height - float(next_milestone - 1) * milestone_meters
	var count := clampi(int(into_milestone / tick_meters), 0, segments.get_child_count())

	for i in segments.get_child_count():
		_set_segment(i, i < count, i >= filled_count and i < count)

	if count > filled_count:
		var step: int = TICK_STEPS[(count - 1) % TICK_STEPS.size()]
		Sfx.play("tick", -8.0, 0.0, 0.5 * pow(2.0, step / 12.0))
		# The newest block tells how far the player is.
		var reached := (next_milestone - 1) * milestone_meters + count * tick_meters
		_show_number(count - 1, reached)
	filled_count = count

	var progress := float(count) / segments.get_child_count()
	goal_icon.modulate.a = lerpf(GOAL_MIN_ALPHA, 1.0, progress)


## `index` 0 is the bottom block, which is the last child of the column.
func _set_segment(index: int, filled: bool, pop: bool) -> void:
	var segment: Panel = segments.get_child(segments.get_child_count() - 1 - index)
	segment.add_theme_stylebox_override("panel", filled_style if filled else empty_style)
	if pop:
		_pop_control(segment, 1.6)


## Scales a control up around its center and lets it spring back.
func _pop_control(control: Control, strength: float) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(strength, strength)
	control.create_tween().tween_property(control, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A small number appears left of a block and drifts away, e.g. "40".
func _show_number(index: int, meters: int) -> void:
	var segment: Panel = segments.get_child(segments.get_child_count() - 1 - index)
	var number := Label.new()
	number.text = str(meters)
	number.custom_minimum_size = Vector2(60.0, 0.0)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number.add_theme_font_override("font", NUMBER_FONT)
	number.add_theme_font_size_override("font_size", 28)
	number.add_theme_color_override("font_color", Color("fff4dc"))
	number.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.2, 0.7))
	number.add_theme_constant_override("outline_size", 5)
	add_child(number)
	number.global_position = segment.global_position + Vector2(-70.0, -8.0)

	var tween := number.create_tween().set_parallel(true)
	tween.tween_property(number, "position:x", number.position.x - 24.0, 1.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tween.chain().tween_callback(number.queue_free)
