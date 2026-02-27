shader_type canvas_item;

// Usage: 
// 1. Append a ColorRect (Full size)
// 2. Add this Shader to the ColorRect


const int PARTICLE_COUNT = 120;

uniform float   speed         : hint_range(20.0, 500.0)  = 120.0;
uniform float   sway_strength : hint_range(0.0,  200.0)  = 60.0;
uniform float   sway_speed    : hint_range(0.1,  5.0)    = 1.4;
uniform float   spin_speed    : hint_range(0.0,  10.0)   = 3.5;
uniform float   piece_size    : hint_range(2.0,  30.0)   = 10.0;
uniform float   aspect_ratio  : hint_range(0.2,  3.0)    = 2.0;
uniform vec2    resolution    = vec2(1920.0, 1080.0);

uniform vec4    col0 : source_color = vec4(1.00, 0.20, 0.20, 1.0);
uniform vec4    col1 : source_color = vec4(1.00, 0.75, 0.10, 1.0);
uniform vec4    col2 : source_color = vec4(0.10, 0.80, 0.30, 1.0);
uniform vec4    col3 : source_color = vec4(0.15, 0.55, 1.00, 1.0);
uniform vec4    col4 : source_color = vec4(0.85, 0.20, 1.00, 1.0);
uniform vec4    col5 : source_color = vec4(1.00, 0.40, 0.70, 1.0);
uniform vec4    col6 : source_color = vec4(0.10, 0.90, 0.95, 1.0);
uniform vec4    col7 : source_color = vec4(1.00, 1.00, 1.00, 1.0);

float rand(float seed) {
    return fract(sin(seed * 127.1 + 311.7) * 43758.5453);
}

vec4 palette_color(float t) {
    int idx = int(t * 8.0) % 8;
    if (idx == 0) return col0;
    if (idx == 1) return col1;
    if (idx == 2) return col2;
    if (idx == 3) return col3;
    if (idx == 4) return col4;
    if (idx == 5) return col5;
    if (idx == 6) return col6;
    return col7;
}

vec2 rotate2d(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * v.x - s * v.y,
                s * v.x + c * v.y);
}

void fragment() {
    vec2 px = UV * resolution;
    vec4 out_color = vec4(0.0);

    for (int i = 0; i < PARTICLE_COUNT; i++) {
        float fi = float(i);

        float start_x  = rand(fi * 1.234)  * resolution.x;
        float start_y  = -(rand(fi * 5.678) * resolution.y);
        float t_offset = rand(fi * 9.101)  * (resolution.y + piece_size * 2.0) / speed;

        float my_speed      = speed         * (0.5 + rand(fi * 2.222));
        float my_sway_str   = sway_strength * (0.3 + rand(fi * 3.333) * 1.4);
        float my_sway_spd   = sway_speed    * (0.5 + rand(fi * 4.444) * 1.5);
        float my_sway_phase = rand(fi * 6.666) * TAU;
        float my_spin       = spin_speed    * (0.5 + rand(fi * 7.777) * 1.5)
                              * (rand(fi * 8.888) > 0.5 ? 1.0 : -1.0);
        float my_size       = piece_size    * (0.5 + rand(fi * 0.123) * 1.0);
        float my_ar         = aspect_ratio  * (0.7 + rand(fi * 0.456) * 0.6);

        float t     = mod(TIME + t_offset, (resolution.y + my_size * 2.0) / my_speed);
        float cy    = start_y + t * my_speed;
        float cx    = start_x + my_sway_str * sin(t * my_sway_spd + my_sway_phase);
        float angle = t * my_spin;

        vec2 delta = px - vec2(cx, cy);
        delta = rotate2d(delta, -angle);
        vec2 local = delta / vec2(my_size * my_ar, my_size);

        float inside = step(max(abs(local.x), abs(local.y)), 1.0);

        if (inside > 0.5) {
            float shimmer = 0.5 + 0.5 * sin(t * my_spin * 2.0);
            vec4 base_col = palette_color(rand(fi * 0.321));
            vec4 lit_col  = mix(base_col * 0.5, base_col, shimmer);
            lit_col.a     = 1.0;
            out_color = mix(out_color, lit_col, inside);
        }
    }

    COLOR = out_color;
}
