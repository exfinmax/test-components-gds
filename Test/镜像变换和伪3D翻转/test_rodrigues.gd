extends Sprite2D

# 导出变量，方便在编辑器中调整
@export_range(0.0, 360.0) var rotate_speed: float = 30.0  # 每秒旋转角度（度）
@export var light_orbit_speed: float = 15.0  # 光源绕Y轴旋转速度（度/秒）
@export var use_mouse_control: bool = true  # 是否启用鼠标控制

# 内部变量
var rotation_accum: float = 0.0
var light_angle: float = 0.0
var target_tr_x: float = 0.0
var target_tr_y: float = 0.0

func _ready():
	# 确保shader已正确加载
	#var shader = load("res://FFTHelper/镜像变换和伪3D翻转/rodrigues_rotation.gdshader")
	#if shader:
		#material = ShaderMaterial.new()
		#material.shader = shader
	#else:
		#print("警告：无法加载shader文件")
	
	# 初始化shader参数
	update_shader_params()

func _process(delta):
	# 累计旋转角度
	rotation_accum += rotate_speed * delta
	while rotation_accum >= 360.0:
		rotation_accum -= 360.0
	
	# 光源绕Y轴旋转
	light_angle += light_orbit_speed * delta
	while light_angle >= 360.0:
		light_angle -= 360.0
	
	# 鼠标控制平移（旋转中心）
	if use_mouse_control:
		var viewport_center = get_viewport().size / 2
		var mouse_pos = get_viewport().get_mouse_position()
		target_tr_x = (mouse_pos.x - viewport_center.x) / viewport_center.x
		target_tr_y = (mouse_pos.y - viewport_center.y) / viewport_center.y
	
	# 更新shader参数
	update_shader_params()

func update_shader_params():
	if material:
		# 设置旋转角度（弧度）
		var theta_rad = deg_to_rad(rotation_accum)
		material.set_shader_parameter("theta", theta_rad)
		
		# 设置旋转轴（这里可以动态调整，示例使用固定轴）
		# 例如：绕倾斜轴 (0.5, 0.5, 0.707) 旋转
		var axis = Vector3(1, 0, 0).normalized()
		material.set_shader_parameter("u", axis)
		
		# 设置平移（旋转中心）
		material.set_shader_parameter("tr_x", target_tr_x)
		material.set_shader_parameter("tr_y", target_tr_y)
		
		# 设置光源方向（基于light_angle计算）
		var light_dir = Vector3(
			sin(deg_to_rad(light_angle)),
			0.5,  # 固定Y分量
			cos(deg_to_rad(light_angle))
		).normalized()
		material.set_shader_parameter("light_dir", light_dir)
		
		# 设置环境光强度（可随正弦变化，示例）
		var ambient_value = 0.2 + 0.1 * sin(deg_to_rad(rotation_accum) * 2.0)
		material.set_shader_parameter("ambient", ambient_value)

# 键盘控制示例
func _input(event):
	if event is InputEventKey:
		# 方向键控制平移
		var speed = 0.05
		if event.keycode == KEY_LEFT:
			target_tr_x -= speed
		elif event.keycode == KEY_RIGHT:
			target_tr_x += speed
		elif event.keycode == KEY_UP:
			target_tr_y -= speed
		elif event.keycode == KEY_DOWN:
			target_tr_y += speed
		
		# 重置旋转中心
		if event.keycode == KEY_SPACE:
			target_tr_x = 0.0
			target_tr_y = 0.0

# 简单UI控件（如果存在Control节点）
func setup_ui():
	# 这里可以添加实际的UI控件代码
	# 例如：Slider控制旋转速度，旋钮控制光源方向等
	pass
