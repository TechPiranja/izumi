## A small pie chart that shows how often the ping button can be used while it is dark.
## Every slice is one ping; the next slice fills up while the player climbs towards it.
class_name PingPie
extends Control

const ORB_TEXTURE := preload("res://sprites/wing_orb.png")
## Which picture of the orb sprite sheet is drawn in the middle (each is 15x15 px).
const ORB_FRAME := Rect2(30.0, 0.0, 15.0, 15.0)
const FILLED_COLOR := Color("9d6bff")
const NEXT_COLOR := Color(0.62, 0.42, 1.0, 0.4)
const EMPTY_COLOR := Color(0.1, 0.04, 0.2, 0.55)
const LINE_COLOR := Color("fff4dc")
const SEGMENTS_PER_SLICE := 14

var orb_texture: AtlasTexture


func _ready() -> void:
	custom_minimum_size = Vector2(64.0, 64.0)
	size = custom_minimum_size
	orb_texture = AtlasTexture.new()
	orb_texture.atlas = ORB_TEXTURE
	orb_texture.region = ORB_FRAME


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 3.0
	var slices := Blackout.max_ping_charges
	var charges := Blackout.ping_charges
	var slice_angle := TAU / slices

	for i in slices:
		var start := -PI * 0.5 + i * slice_angle
		if i < charges:
			_draw_slice(center, radius, start, slice_angle, FILLED_COLOR)
		else:
			_draw_slice(center, radius, start, slice_angle, EMPTY_COLOR)
			# The next slice slowly fills as the player climbs towards the next charge.
			if i == charges:
				_draw_slice(center, radius, start, slice_angle * Blackout.charge_progress(), NEXT_COLOR)

	# Lines between the slices and an outer ring.
	for i in slices:
		var angle := -PI * 0.5 + i * slice_angle
		draw_line(center, center + Vector2.from_angle(angle) * radius, LINE_COLOR, 3.0)
	draw_arc(center, radius, 0.0, TAU, 48, LINE_COLOR, 3.0)

	# The black orb in the middle shows what the pie belongs to.
	var orb_size := Vector2(30.0, 30.0)
	draw_circle(center, 14.0, Color(0.1, 0.04, 0.2))
	draw_texture_rect(orb_texture, Rect2(center - orb_size * 0.5, orb_size), false, Color(0.5, 0.25, 0.8))


func _draw_slice(center: Vector2, radius: float, start: float, sweep: float, color: Color) -> void:
	if sweep <= 0.001:
		return
	# A single slice is the whole pie (a polygon with a closed circle can't be filled).
	if sweep >= TAU - 0.001:
		draw_circle(center, radius, color)
		return
	var points := PackedVector2Array([center])
	for step in SEGMENTS_PER_SLICE + 1:
		var angle := start + sweep * float(step) / SEGMENTS_PER_SLICE
		points.append(center + Vector2.from_angle(angle) * radius)
	draw_colored_polygon(points, color)
