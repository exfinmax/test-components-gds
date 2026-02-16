shader_type canvas_item;

uniform float lerp_percent : hint_range(0.0, 1.0);
uniform vec4 flash_color : source_color = vec4(1);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec4 final_color = mix(texture_color, flash_color, lerp_percent);
	COLOR = mix(COLOR,final_color,COLOR.a);
}
