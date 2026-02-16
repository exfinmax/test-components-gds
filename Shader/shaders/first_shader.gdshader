shader_type canvas_item;

uniform vec2 mouse_distance;

void vertex() {
	if (mouse_distance.x < .0 && mouse_distance.y > .0){
		if(VERTEX.y > .0 && VERTEX.x < .0){
			VERTEX += mouse_distance + vec2(64,-64);
		};
	}
	else if (mouse_distance.x < .0 && mouse_distance.y < .0){
		if(VERTEX.y < .0 && VERTEX.x < .0){
			VERTEX += mouse_distance + vec2(64,64);
		};
	}
	else if (mouse_distance.x > .0 && mouse_distance.y > .0){
		if(VERTEX.y > .0 && VERTEX.x > .0){
			VERTEX += mouse_distance + vec2(-64,-64);
		};
	}
	else if (mouse_distance.x > .0 && mouse_distance.y < .0){
		if(VERTEX.y < .0 && VERTEX.x > .0){
			VERTEX += mouse_distance + vec2(-64,64);
		};
	}
}

void fragment() {
	vec4 origin_color = texture(TEXTURE,UV);
	
	vec4 color1 = vec4(1.0,.0,.0,1.0);
	vec4 color2 = vec4(.0,1.0,.0,1.0);
	
	float mix_percent = (sin(TIME)+1.0)/2.;
	
	COLOR = mix(color1*origin_color,color2*origin_color,mix_percent);
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
