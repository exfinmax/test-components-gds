shader_type canvas_item;

// 渐变两端颜色（你可以理解为：靠边缘用 edge_color，远离边缘用 far_color）
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 far_color  : source_color = vec4(0.0, 0.8, 1.0, 1.0);

// 外描边
uniform float outer_size : hint_range(0.0, 12.0, 0.1) = 3.0;
uniform float outer_strength : hint_range(0.0, 1.0, 0.01) = 1.0;

// 内描边
uniform float inner_size : hint_range(0.0, 12.0, 0.1) = 3.0;
uniform float inner_strength : hint_range(0.0, 1.0, 0.01) = 1.0;

// 呼吸
uniform float speed : hint_range(0.0, 20.0, 0.1) = 6.0;
uniform float breathe_amp : hint_range(0.0, 1.0, 0.01) = 0.5;

// alpha 判定阈值
uniform float alpha_threshold : hint_range(0.0, 1.0, 0.01) = 0.01;

// scale 缩放大小
uniform vec2 scale = vec2(1);

// 多圈采样的圈数（越大越平滑，越耗）
uniform int rings : hint_range(2, 8) = 5;

float inside_01(vec2 uv) {
	vec2 a = step(vec2(0.0), uv);
	vec2 b = step(uv, vec2(1.0));
	return a.x * a.y * b.x * b.y;
}

float sample_a_safe(sampler2D tex, vec2 uv) {
	float inside = inside_01(uv);
	vec2 uvc = clamp(uv, vec2(0.0), vec2(1.0));
	return texture(tex, uvc).a * inside;
}

// 检查某个半径 r（像素单位）的一圈 8 方向，返回：邻域最小 alpha（越小越接近透明）
float ring_min_alpha(sampler2D tex, vec2 uv, vec2 px) {
	float n1 = sample_a_safe(tex, uv + vec2(-px.x,  0.0));
	float n2 = sample_a_safe(tex, uv + vec2( px.x,  0.0));
	float n3 = sample_a_safe(tex, uv + vec2( 0.0, -px.y));
	float n4 = sample_a_safe(tex, uv + vec2( 0.0,  px.y));
	float n5 = sample_a_safe(tex, uv + vec2(-px.x, -px.y));
	float n6 = sample_a_safe(tex, uv + vec2( px.x, -px.y));
	float n7 = sample_a_safe(tex, uv + vec2(-px.x,  px.y));
	float n8 = sample_a_safe(tex, uv + vec2( px.x,  px.y));

	return min(min(min(n1, n2), min(n3, n4)),
			   min(min(n5, n6), min(n7, n8)));
}

// 用多圈采样近似“离边缘的距离”：返回 0..1 的 t
// t=0 很靠近边缘；t=1 更远离边缘（更往里/或更往外，看你用在哪）
float edge_t_from_inside(sampler2D tex, vec2 uv, float size_px, int rings_count, vec2 size) {
	// 默认认为离边缘很远（t=1）
	float best_t = 1.0;

	// 分 rings_count 圈，从近到远找“第一次接近透明”的圈
	for (int i = 1; i <= 8; i++) { // 上限写死 8，配合 uniform rings 使用
		if (i > rings_count) { break; }

		float r = float(i) / float(rings_count) * size_px;
		vec2 px = size * r;

		float min_a = ring_min_alpha(tex, uv, px);

		// 只要这一圈有透明（min_a < threshold），说明边界在这一圈附近
		float hit = 1.0 - step(alpha_threshold, min_a); // 透明→1，不透明→0

		// 这一圈对应的 t（越靠近边缘越小）
		float t_i = float(i - 1) / float(max(rings_count - 1, 1));

		// 只在第一次 hit 时更新 best_t（用 min 即可实现）
		best_t = min(best_t, mix(1.0, t_i, hit));
	}

	return best_t;
}

void fragment() {
	vec2 uv = (UV-0.5) * scale + vec2(.5);
	vec4 base = texture(TEXTURE, uv);
	float a = base.a;

	// 呼吸系数
	float breathe = 1.0 + breathe_amp * sin(TIME * speed);

	// ------- 外描边 mask（在透明区画：自己透明 & 附近有不透明）-------
	// 近似：看外扩 size 范围内，是否能碰到不透明
	float outer_t = edge_t_from_inside(TEXTURE, uv, outer_size * breathe, rings, TEXTURE_PIXEL_SIZE);
	// outer_t 越小越靠近边缘（在“外侧透明区域”里意义更强）
	// 外描边判定：自己透明
	float is_transparent = 1.0 - step(alpha_threshold, a);
	// 并且附近能碰到不透明：用邻域最大alpha来判定更直接
	// 这里偷个懒：用 ring_min_alpha 的反面不好做，我们再算一次 max（简单点：用 8方向在最大半径采样）
	vec2 pxo = TEXTURE_PIXEL_SIZE * (outer_size * breathe);
	float o1 = sample_a_safe(TEXTURE, uv + vec2(-pxo.x,  0.0));
	float o2 = sample_a_safe(TEXTURE, uv + vec2( pxo.x,  0.0));
	float o3 = sample_a_safe(TEXTURE, uv + vec2( 0.0, -pxo.y));
	float o4 = sample_a_safe(TEXTURE, uv + vec2( 0.0,  pxo.y));
	float o5 = sample_a_safe(TEXTURE, uv + vec2(-pxo.x, -pxo.y));
	float o6 = sample_a_safe(TEXTURE, uv + vec2( pxo.x, -pxo.y));
	float o7 = sample_a_safe(TEXTURE, uv + vec2(-pxo.x,  pxo.y));
	float o8 = sample_a_safe(TEXTURE, uv + vec2( pxo.x,  pxo.y));
	float neighbor_max_outer = max(max(max(o1,o2), max(o3,o4)), max(max(o5,o6), max(o7,o8)));
	float has_solid_near = step(alpha_threshold, neighbor_max_outer);

	float outer_mask = is_transparent * has_solid_near;

	// 外描边渐变色（t=0 边缘色，t=1 远色）
	vec3 outer_grad = mix(edge_color.rgb, far_color.rgb, outer_t);
	vec3 outer_rgb = outer_grad;
	float outer_alpha = outer_mask * outer_strength;

	// ------- 内描边 mask（在不透明区画：自己不透明 & 附近有透明）-------
	float is_solid = step(alpha_threshold, a);

	float inner_t = edge_t_from_inside(TEXTURE, uv, outer_size * breathe, rings, TEXTURE_PIXEL_SIZE);
	// “附近有透明”的判定：在最大半径圈上只要有透明就算靠边
	vec2 pxi = TEXTURE_PIXEL_SIZE * (inner_size * breathe);
	float mmin = ring_min_alpha(TEXTURE, uv, pxi);
	float has_transparent_near = 1.0 - step(alpha_threshold, mmin);

	float inner_mask = is_solid * has_transparent_near;

	vec3 inner_grad = mix(edge_color.rgb, far_color.rgb, inner_t);
	// 内描边我们一般不想覆盖原图太硬，用 mix 更自然
	vec3 inner_mixed = mix(base.rgb, inner_grad, inner_mask * inner_strength);

	// ------- 合成：先内描边作用在实体上，再把外描边画到透明区 -------
	vec3 rgb_after_inner = inner_mixed;

	// 外描边只在透明区：直接覆盖即可（也可以加法叠加，看你风格）
	vec3 final_rgb = mix(rgb_after_inner, outer_rgb, outer_alpha);

	// alpha：实体保持原 alpha；透明区外描边给 alpha
	float final_a = max(a, outer_alpha);

	COLOR = vec4(final_rgb, final_a);
}
