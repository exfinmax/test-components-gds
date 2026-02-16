shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 origin_color = texture(TEXTURE,UV);
	
	COLOR = vec4((origin_color.r+origin_color.g+origin_color.b)/3.) * COLOR.a;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
