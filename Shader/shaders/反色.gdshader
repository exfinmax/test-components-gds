shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec3 anti_color(vec3 ori_color){
	return vec3(1) - ori_color;
}

void fragment() {
	vec4 origin_color = texture(screen_texture,SCREEN_UV);
	COLOR = vec4(anti_color(origin_color.rgb),1);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
