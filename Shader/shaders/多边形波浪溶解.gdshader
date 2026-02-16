shader_type canvas_item;

// 溶解进度
uniform float percentage : hint_range(0.0, 1.0, 0.01) = 0.0;

// 溶解方向（例如 vec2(0,1) 表示自下而上）
uniform vec2 direction = vec2(0.0, 1.0);

// 多边形顶点在该方向上的最小/最大投影值（由脚本计算并传入）
uniform float min_proj = 0.0;
uniform float max_proj = 1.0;

// 波浪参数
uniform float wave_amplitude : hint_range(0.0, 0.2, 0.01) = 0.05;
uniform float wave_frequency : hint_range(0.0, 20.0, 0.1) = 10.0;
uniform float wave_speed : hint_range(0.0, 10.0, 0.1) = 2.0;

// 边缘柔和度
uniform float edge_softness : hint_range(0.0, 0.1, 0.01) = 0.02;

// 边缘颜色（可选，用来做渐变效果）
uniform vec4 edge_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);

void fragment() {
    // 归一化方向
    vec2 dir = normalize(direction);
    vec2 perp = vec2(-dir.y, dir.x);

    // 投影到新坐标系
    float pos = dot(VERTEX, dir);
    float wave_axis = dot(VERTEX, perp);

    // 归一化到 [0,1]
    pos = (pos - min_proj) / (max_proj - min_proj);

    // 波浪偏移
    float wave = sin(wave_axis * wave_frequency + TIME * wave_speed) * wave_amplitude;

    // 溶解边界
    float dissolve_edge = pos + wave;

    // 平滑过渡
    float mask = smoothstep(percentage - edge_softness, percentage + edge_softness, dissolve_edge);

    if (mask < 0.5) {
        discard;
    } else {
        vec4 base = texture(TEXTURE, UV);
        // 在边缘区域混合颜色（可选）
        float edge_factor = 1.0 - mask;
        COLOR = mix(base, edge_color, edge_factor * 0.5);
    }
}
