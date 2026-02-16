shader_type canvas_item;

uniform float percentage : hint_range(-0, 1, 0.01) = 0.0; // 溶解进度
uniform vec2 direction = vec2(0.0, 1.0); // 溶解方向，默认向上
uniform float wave_amplitude : hint_range(0.0, 0.2, 0.01) = 0.05; // 波浪幅度
uniform float wave_frequency : hint_range(0.0, 20.0, 0.1) = 10.0; // 波浪频率
uniform float wave_speed : hint_range(0.0, 10.0, 0.1) = 2.0; // 波浪移动速度
uniform float edge_softness : hint_range(0.0, 0.1, 0.01) = 0.02; // 边缘柔和度

void fragment() {
    // 归一化方向向量
    vec2 dir = normalize(direction);
    // 垂直方向向量
    vec2 perp = vec2(-dir.y, dir.x);

    // 把 UV 坐标投影到新坐标系 (dir, perp)
    float pos = dot(UV, dir);       // 沿着溶解方向的坐标
    float wave_axis = dot(UV, perp); // 垂直方向坐标，用来生成波浪
	
	float max_proj = max(max(dot(vec2(0.0,0.0), dir),dot(vec2(1.0,0.0), dir)),
	 max(dot(vec2(0.0,1.0), dir), dot(vec2(1.0,1.0), dir))
	);
	
	pos /= max_proj; // 映射到 [0,1]

    // 波浪偏移
    float wave = sin(wave_axis * wave_frequency + TIME * wave_speed) * wave_amplitude;

    // 溶解边界：方向坐标 + 波浪
    float dissolve_edge = pos + wave;

    // 使用 smoothstep 让边缘柔和过渡
    float mask = smoothstep(percentage - edge_softness, percentage + edge_softness, dissolve_edge);

    // 根据 mask 丢弃像素
    if (mask < 0.5) {
        discard;
    } else {
        COLOR = texture(TEXTURE,UV);
    }
}
