shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float percent : hint_range(0.0, 1.0, 0.01);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 origin_color = texture(TEXTURE,UV);
	vec4 final_color = origin_color;
	vec4 noise_color = texture(noise_texture,UV);
	
	if(percent >= noise_color.r){
		final_color.a = .0;
	}
	
	COLOR = final_color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
