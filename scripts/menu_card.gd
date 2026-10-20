## One mode in the menu: a card with a big picture. No words, the picture says what it is.
class_name MenuCard
extends Control

const FONT := preload("res://fonts/PixelifySans-Bold.ttf")
const ORB_TEXTURE := preload("res://sprites/wing_orb.png")
## Everything inside the card is drawn relative to this, so the card can be made bigger or smaller.
const UI_SCALE := 0.6
const CARD_SIZE := Vector2(200.0, 220.0) * UI_SCALE
const COLOR_CREAM := Color("fff4dc")
const COLOR_GOLD := Color("ffd35e")
const COLOR_DARK := Color(0.35, 0.15, 0.6)

## "tutorial", "infinity" or "dark".
var kind := "infinity"
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var orb_texture: AtlasTexture


func _init(card_kind := "infinity") -> void:
	kind = card_kind
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	orb_texture = AtlasTexture.new()
	orb_texture.atlas = ORB_TEXTURE
	orb_texture.region = Rect2(30.0, 0.0, 15.0, 15.0)


func _draw() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.96, 0.86, 0.95) if selected else Color(0.1, 0.07, 0.2, 0.88)
	style.border_color = COLOR_GOLD if selected else Color(1.0, 0.96, 0.86, 0.4)
	style.set_border_width_all(4 if selected else 2)
	style.set_corner_radius_all(12)
	draw_style_box(style, Rect2(Vector2.ZERO, CARD_SIZE))

	var center := CARD_SIZE * 0.5
	var ink := Color("6b4a2e") if selected else COLOR_CREAM
	match kind:
		"tutorial":
			_draw_centered_text("?", center, roundi(130.0 * UI_SCALE), ink)
		"infinity":
			_draw_infinity(center, ink)
		"dark":
			_draw_dark_orb(center)


func _draw_centered_text(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var text_size := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ascent := FONT.get_ascent(font_size)
	var pos := Vector2(center.x - text_size.x * 0.5, center.y + ascent * 0.5 - font_size * 0.08)
	draw_string(FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## The lemniscate: a sideways 8, the sign for infinity.
func _draw_infinity(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var steps := 64
	for i in steps + 1:
		var t := TAU * float(i) / steps
		var denominator := 1.0 + sin(t) * sin(t)
		points.append(center + Vector2(cos(t), sin(t) * cos(t)) * 70.0 * UI_SCALE / denominator * Vector2(1.0, 1.4))
	draw_polyline(points, color, 12.0 * UI_SCALE, true)


func _draw_dark_orb(center: Vector2) -> void:
	# Two soft rings around the black orb, like a sound wave.
	draw_arc(center, 78.0 * UI_SCALE, 0.0, TAU, 48, Color(COLOR_DARK, 0.35), 4.0)
	draw_arc(center, 58.0 * UI_SCALE, 0.0, TAU, 48, Color(COLOR_DARK, 0.6), 4.0)
	var orb_size := Vector2(84.0, 84.0) * UI_SCALE
	draw_texture_rect(orb_texture, Rect2(center - orb_size * 0.5, orb_size), false, Color(0.4, 0.15, 0.65))
