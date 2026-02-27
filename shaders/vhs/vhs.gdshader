shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float tape_wave_amount = 0.003;
uniform float tape_noise_amount = 0.05;
uniform float color_bleed_amount = 0.005;

void fragment() {
    vec2 uv = SCREEN_UV;

    float jitter = sin(uv.y * 15.0 + TIME * 20.0) * tape_wave_amount;
    float tracking = step(0.95, sin(uv.y * 4.0 - TIME * 3.0)) * 0.015;
    uv.x += jitter + tracking;

    float tape_noise = fract(sin(dot(vec2(uv.y, TIME), vec2(12.9898, 78.233))) * 43758.5453);
    float stripe = step(0.9, fract(uv.y * 8.0 + TIME * 0.5));

    float r = texture(screen_tex, uv + vec2(color_bleed_amount, 0.0)).r;
    float g = texture(screen_tex, uv).g;
    float b = texture(screen_tex, uv - vec2(color_bleed_amount, 0.0)).b;
    vec3 color = vec3(r, g, b);

    color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), 0.4);

    color += (tape_noise * stripe * tape_noise_amount);
    color *= 0.85 + 0.15 * sin(uv.y * 700.0);

    float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    color *= clamp(pow(16.0 * vignette, 0.25), 0.0, 1.0);

    COLOR = vec4(color,1);
}