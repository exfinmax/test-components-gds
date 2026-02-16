shader_type canvas_item;

uniform sampler2D gradient_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 origin_color = texture(TEXTURE,UV);
	float greyscale = (origin_color.r+origin_color.g+origin_color.b)/3. * COLOR.a;
	
	vec4 gradient_color = texture(gradient_texture, vec2(greyscale));
	
	COLOR = vec4(gradient_color.rgb,origin_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
