shader_type canvas_item;

// 旋转参数
// 旋转轴（单位向量）。
// 使用 (1,0,0) 或 (0,1,0) 可以做绕水平/垂直轴的伪 3D 翻转；
// (0,0,1) 仍为平面内旋转，不产生深度感。
uniform vec3 u = vec3(1.0, 0.0, 0.0);
uniform float theta = 0.0;             // 旋转角度（弧度）

// 平移参数（绕任意点旋转）
uniform float tr_x = 0.0;
uniform float tr_y = 0.0;
uniform float tr_z = 1.0;


// 光照参数
uniform vec3 light_dir = vec3(0.0, 0.0, 1.0);  // 光源方向（归一化）
uniform float ambient = 0.2;                   // 环境光强度 [0,1]

// 透视参数（可选）
uniform float fov = 90.0;                      // 视场角（度）
uniform bool cull_back = true;                 // 背面剔除

// 顶点着色器输出
varying flat vec2 o;
varying vec3 p;
varying vec3 normal;  // 用于光照的法线

// 罗德里格斯旋转矩阵构造
mat3 rodrigues_rotation(vec3 k, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    float one_minus_c = 1.0 - c;
    
    // 叉乘矩阵 K
    mat3 K = mat3(
        vec3(0.0,    -k.z,     k.y),
        vec3(k.z,     0.0,    -k.x),
        vec3(-k.y,     k.x,     0.0)
    );
    
    // 外积矩阵 kk^T
    mat3 kkT = mat3(
        vec3(k.x * k.x, k.x * k.y, k.x * k.z),
        vec3(k.y * k.x, k.y * k.y, k.y * k.z),
        vec3(k.z * k.x, k.z * k.y, k.z * k.z)
    );
    
    // 罗德里格斯公式
    return c * mat3(1.0) + one_minus_c * kkT + s * K;
}

void vertex() {
    // 归一化旋转轴
    vec3 k = normalize(u);
    
    // 构造旋转矩阵
    mat3 R = rodrigues_rotation(k, theta);
    
    // 平移矩阵（绕任意点旋转）
    mat3 T = mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, 1.0, 0.0),
        vec3(tr_x, tr_y, tr_z)
    );
    mat3 inv_T = mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, 1.0, 0.0),
        vec3(-tr_x, -tr_y, -tr_z)
    );
    
    // 透视投影参数
    float t = tan(fov / 360.0 * PI);
    
    // 完整的变换矩阵：先平移回原点，再旋转，再平移回枢轴
    // 注意顺序必须是 T(pivot) * R * T(-pivot)
    mat3 final_mat = T * R * inv_T;
    
    // 变换纹理坐标（局部空间 -> 旋转后空间）
    p = final_mat * vec3((UV - 0.5), 0.5 / t);
    
    // 计算法线（假设初始法线为 (0,0,1)，经过旋转矩阵变换）
    // 注意：法线变换需要用逆转置矩阵，但对于纯旋转矩阵，逆矩阵 = 转置，所以直接使用 R 即可
    normal = R * vec3(0.0, 0.0, 1.0);
    
    // 透视修正
    float v = (0.5 / t) + 0.5;
    p.xy *= v * final_mat[2].z;
    o = v * final_mat[2].xy;
    
    // 调整顶点位置（防止裁剪）
    VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * t;
}

void fragment() {
    // 背面剔除（可切换为双面）
    if ( cull_back && p.z <= 0.0) {
        discard;
    }
    
    // 透视除法得到最终的纹理坐标
    vec2 uv = (p.xy / p.z).xy - o;
    
    // 采样纹理
    vec4 tex_color = texture(TEXTURE, uv + 0.5);
    

    vec3 L = normalize(light_dir);
    // 归一化法线
    vec3 N = normalize(normal);
    
    // 计算漫反射强度：max(0, N·L)
    float diffuse = max(0.0, dot(N, L));
    
    // 最终光照：环境光 + 漫反射
    float lighting = ambient + (1.0 - ambient) * diffuse;
    

    COLOR = tex_color * lighting;
	COLOR.a *= step(max(abs(uv.x), abs(uv.y)), .5);
    
}