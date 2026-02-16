shader_type canvas_item;

uniform sampler2D mask_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 origin_color = texture(TEXTURE,UV);
	vec4 final_color = origin_color;
	vec4 mask_color = texture(mask_texture,UV);

	final_color.a = sign(mask_color.r);

	
	COLOR = final_color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
