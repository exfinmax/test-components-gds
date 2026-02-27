shader_type canvas_item;

// 增加基础颜色，融合阈值，边缘柔化参数
// 注意：base_color 现在主要作为背景色或叠加色，球体颜色由 colors 数组决定
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float meta_threshold : hint_range(0.0, 2.0) = 1.0;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.02;

uniform vec2 bg_size;
const int MAX_SIZE = 20;

uniform float radius[MAX_SIZE];
uniform int now_size = 0;
uniform vec2 points[MAX_SIZE];
uniform vec4 colors[MAX_SIZE];

void fragment() {
	float field_strength_sum = 0.0;
	vec4 weighted_color_sum = vec4(0.0);
	
	// 计算元球场强和颜色混合
	for(int i = 0; i < now_size; i++){
		// 避免除以0
		float dist = length(UV - points[i]);
		if (dist > 0.0001) {
			// 这种衰减函数 (r/d) 是最基础的 Metaball 算法
			// 也可以尝试 (r*r)/(d*d) 获得更陡峭的融合效果
			float contribution = radius[i] / dist;
			
			field_strength_sum += contribution;
			
			// 根据贡献权重累加颜色
			weighted_color_sum += colors[i] * contribution;
		}
	}
	
	vec4 final_color = base_color;
	
	if (field_strength_sum > 0.0001) {
		// 归一化颜色
		final_color = weighted_color_sum / field_strength_sum;
	}
	
	// 使用 smoothstep 进行平滑边缘处理
	// alpha 从 0 过渡到 1，产生抗锯齿效果
	float alpha = smoothstep(meta_threshold - edge_softness, meta_threshold, field_strength_sum);
	
	COLOR = final_color;
	COLOR.a *= alpha;
}
