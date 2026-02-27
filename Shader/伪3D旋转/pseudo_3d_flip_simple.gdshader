// Hey this is Hei! This shader "fakes" a 3D-camera perspective on CanvasItems.
// License: MIT

shader_type canvas_item;

// Camera FOV
uniform float fov : hint_range(1, 179) = 90;
uniform bool cull_back = true;
uniform float y_rot : hint_range(-180, 180) = 0.0;
uniform float x_rot : hint_range(-180, 180) = 0.0;
uniform float rotate_degree : hint_range(-180, 180) = 0.0;
uniform float tr_x;
uniform float tr_y;
uniform float y_speed;
uniform float x_speed;

// At 0, the image retains its size when unrotated.
// At 1, the image is resized so that it can do a full
// rotation without clipping inside its rect.
uniform float inset : hint_range(0, 1) = 0.0;
// Consider changing this to a uniform and changing it from code

varying flat vec2 o;
varying vec3 p;


// Creates rotation matrix
void vertex(){
	float sin_b = sin((y_rot + TIME * y_speed) / 180.0 * PI);
	float cos_b = cos((y_rot + TIME * y_speed) / 180.0 * PI);
	float sin_c = sin((x_rot + TIME * x_speed)/ 180.0 * PI);
	float cos_c = cos((x_rot + TIME * x_speed)/ 180.0 * PI);
	
	mat3 inv_rot_mat;
	inv_rot_mat[0][0] = cos_b;
	inv_rot_mat[0][1] = 0.0;
	inv_rot_mat[0][2] = -sin_b;
	
	inv_rot_mat[1][0] = sin_b * sin_c;
	inv_rot_mat[1][1] = cos_c;
	inv_rot_mat[1][2] = cos_b * sin_c;
	
	inv_rot_mat[2][0] = sin_b * cos_c;
	inv_rot_mat[2][1] = -sin_c;
	inv_rot_mat[2][2] = cos_b * cos_c;
	
	mat3 transform_mat = mat3(
		vec3(1.,0.,0.),
		vec3(0,1.,0),
		vec3(tr_x,tr_y,1)
	);
	
	mat3 inv_transform_mat = mat3(
		vec3(1.,0.,0.),
		vec3(0,1.,0),
		vec3(-tr_x,-tr_y,1)
	);
	
	mat3 rotate_mat = mat3(
		vec3(cos(-rotate_degree/ 180.0 * PI),sin(-rotate_degree/ 180.0 * PI),0.),
		vec3(-sin(-rotate_degree/ 180.0 * PI),cos(-rotate_degree/ 180.0 * PI),0.),
		vec3(0.,0.,1.)
	);
	
	mat3 inv_rotate_mat = inverse(rotate_mat);
	
	float t = tan(fov / 360.0 * PI);
	mat3 finnal_mat = transform_mat * rotate_mat * inv_rot_mat * inv_rotate_mat * inv_transform_mat;  
	p =  finnal_mat 
	 * vec3((UV - 0.5), 0.5 / t);
	float v = (0.5 / t) + 0.5;
	p.xy *= v * finnal_mat[2].z;
	o = v * finnal_mat[2].xy;

	VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * t * (1.0 - inset);
}

void fragment(){
	if (cull_back && p.z <= 0.0) discard;
	vec2 uv = (p.xy / p.z).xy - o;
    COLOR = texture(TEXTURE, uv + .5);
	COLOR.a *= step(max(abs(uv.x), abs(uv.y)), .5);
}