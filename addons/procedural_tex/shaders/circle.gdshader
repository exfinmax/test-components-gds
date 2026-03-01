shader_type canvas_item;
render_mode blend_add;

uniform float radius = 0.44;
uniform float step_pos = 0.05;
uniform float smooth_edge = 0.02;

// https://iquilezles.org/articles/distfunctions2d
float circle(vec2 p, float r) {
	return length(p) - r;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv - 0.5;
	float c = circle(p, radius);
	float a = smoothstep(smooth_edge + step_pos, step_pos, c);
	vec4 col = vec4(1.0, 1.0, 1.0, a);
	COLOR = col;
}
