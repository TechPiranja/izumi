// Full-screen effect: the picture turns black and only the outlines of everything are drawn.
// `amount` blends the effect in and out, `lines` draws the outlines on top of the black.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float lines : hint_range(0.0, 1.0) = 0.0;
uniform vec4 line_color : source_color = vec4(0.78, 0.94, 1.0, 1.0);
uniform vec4 background : source_color = vec4(0.02, 0.02, 0.07, 1.0);
// How different two neighbouring colors must be to count as an edge.
uniform float threshold = 0.12;

float difference(vec3 a, vec3 b) {
	vec3 d = abs(a - b);
	return max(d.r, max(d.g, d.b));
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * 2.0;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float edge = max(
		max(difference(c, texture(screen_tex, SCREEN_UV + vec2(px.x, 0.0)).rgb),
			difference(c, texture(screen_tex, SCREEN_UV - vec2(px.x, 0.0)).rgb)),
		max(difference(c, texture(screen_tex, SCREEN_UV + vec2(0.0, px.y)).rgb),
			difference(c, texture(screen_tex, SCREEN_UV - vec2(0.0, px.y)).rgb)));
	float line = step(threshold, edge) * lines;
	vec3 outlined = mix(background.rgb, line_color.rgb, line);
	COLOR = vec4(mix(c, outlined, amount), 1.0);
}
