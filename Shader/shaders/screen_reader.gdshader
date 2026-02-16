shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 origin_color = texture(screen_texture,SCREEN_UV);
	float greyscale = (origin_color.r+origin_color.g+origin_color.b)/3. * COLOR.a;

	COLOR = vec4(vec3(greyscale),COLOR.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
