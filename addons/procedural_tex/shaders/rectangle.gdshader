shader_type canvas_item;
render_mode blend_add;

uniform float size = 0.5;
uniform float step_pos = 0.0;
uniform float smooth_edge = 0.0;

// https://iquilezles.org/articles/distfunctions2d
float box(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv - 0.5;
	float b = box(p, vec2(size));
	float a = smoothstep(smooth_edge + step_pos, step_pos, b);
	vec4 col = vec4(1.0, 1.0, 1.0, a);
	COLOR = col;
}
