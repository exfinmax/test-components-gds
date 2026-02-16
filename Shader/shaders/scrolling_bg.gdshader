shader_type canvas_item;

uniform vec2 tiling = vec2(1.0);
uniform vec2 offset;

void vertex() {
	UV = UV * tiling + offset * TIME;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
