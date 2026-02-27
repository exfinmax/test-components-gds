shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    vec3 rgb = texture(screen_texture, SCREEN_UV).rgb;
    float lum = dot(rgb, vec3(0.2126, 0.7152, 0.0722));

    vec3 c;

    if (lum > 0.95)      c = vec3(1.0);                // white
    else if (lum > 0.90) c = vec3(1.0, 0.8, 0.8);      // light red
    else if (lum > 0.85) c = vec3(1.0, 0.0, 0.0);      // red
    else if (lum > 0.80) c = vec3(1.0, 0.5, 0.0);      // orange
    else if (lum > 0.75) c = vec3(1.0, 0.8, 0.0);      // yellow-orange
    else if (lum > 0.70) c = vec3(1.0, 1.0, 0.0);      // yellow
    else if (lum > 0.65) c = vec3(0.8, 1.0, 0.0);      // yellow-green
    else if (lum > 0.60) c = vec3(0.5, 1.0, 0.0);      // lime
    else if (lum > 0.55) c = vec3(0.2, 1.0, 0.2);      // green light
    else if (lum > 0.50) c = vec3(0.0, 1.0, 0.0);      // green
    else if (lum > 0.45) c = vec3(0.3);                // mid gray
    else if (lum > 0.40) c = vec3(0.2, 0.8, 0.8);      // cyan light
    else if (lum > 0.35) c = vec3(0.0, 0.8, 1.0);      // cyan
    else if (lum > 0.30) c = vec3(0.0, 0.5, 1.0);      // blue light
    else if (lum > 0.25) c = vec3(0.0, 0.2, 1.0);      // blue
    else if (lum > 0.20) c = vec3(0.0, 0.0, 1.0);      // deep blue
    else if (lum > 0.15) c = vec3(0.3, 0.0, 0.8);      // violet
    else if (lum > 0.10) c = vec3(0.5, 0.0, 0.6);      // purple
    else if (lum > 0.05) c = vec3(0.2, 0.0, 0.3);      // dark purple
    else                 c = vec3(0.05, 0.0, 0.1);     // near black

    COLOR = vec4(c, 1.0);
}