shader_type canvas_item;
render_mode blend_add;

uniform float size = 0.44;
uniform float smooth_edge = 0.02;

// https://iquilezles.org/articles/distfunctions2d
float triangle(vec2 p, float r) {
	const float k = sqrt(3.0);
	p.x = abs(p.x) - r;
	p.y = p.y + r / k;
	if (p.x + k * p.y > 0.0) {
		p = vec2(p.x - k * p.y, -k * p.x - p.y) * 0.5;
	}
	p.x -= clamp(p.x, -2.0 * r, 0.0);
	return -length(p) * sign(p.y);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv - 0.5;
	p.y *= -1.0;
	float t = triangle(p / size, 1.0);
	float a = smoothstep(t, t + smooth_edge, 0.0);
	vec4 col = vec4(1.0, 1.0, 1.0, a);
	COLOR = col;
}
