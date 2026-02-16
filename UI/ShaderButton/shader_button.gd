extends Button

const ButtonShader := preload("uid://b3o26w6ijhf1i")

@export var h_expend:float = 10
@export var v_expend:float = 5
@export var panel_style_box:StyleBox

@onready var text_label: Label = $Label
@onready var panel: Panel = $Panel


var _exit_tween: Tween  # 退出动画的补间动画引用
var _is_mouse_over = false  # 标记鼠标是否悬停在按钮上
var _original_brightness = {}  # 存储子节点原始亮度值的字典
var _center1 = Vector2(0.5, 0.5)  # 点击效果的中心点坐标
var _center2 = Vector2(0.5, 0.5)  # 鼠标悬停效果的中心点坐标

func _ready():
	if panel_style_box != null:
		panel.add_theme_stylebox_override("panel",panel_style_box)
	text_label.text = text
	text_label.add_theme_font_size_override("font_size",get_theme_font_size("font_size"))
	text = ""
	material = ButtonShader.duplicate()

	material.set("shader_parameter/size", size); material.set("shader_parameter/time1", 1.0); material.set("shader_parameter/time2", 0.0)  # 初始化着色器参数
	pressed.connect(_on_pressed); mouse_exited.connect(_on_mouse_exited); mouse_entered.connect(_on_mouse_entered)  # 连接按钮信号到处理函数
	material.set("shader_parameter/center1", _center1); material.set("shader_parameter/center2", _center2)  # 设置中心点参数

	# 检查样式盒是否存在且为StyleBoxFlat类型，若存在，则计算圆角参数
	var normal_style = get_theme_stylebox("normal")  # 获取正常状态的样式盒
	if normal_style and normal_style is StyleBoxFlat: material.set("shader_parameter/corner_radius", normal_style.corner_radius_top_left / size.y * 2)
	var text_color = modulate if modulate != Color(1,1,1,1) else Color(1,1,1,1)  # 获取按钮颜色或使用默认白色
	material.set("shader_parameter/color", text_color)  # 设置着色器颜色参数
	await get_tree().create_timer(.5).timeout
	text_label.position.x = (size.x/2. - text_label.size.x/2.)

func _process(_delta):
	if text_label.text != text && text != "":
		text_label.text = text
	if !disabled:
		var local_mouse = (get_global_transform().affine_inverse() * get_global_mouse_position()) / size  # 转换鼠标位置到局部坐标
		if _is_mouse_over: _center2 = local_mouse; material.set("shader_parameter/center2", _center2)  # 鼠标悬停时更新悬停中心点
		material.set("shader_parameter/center1", _center1)  # 更新点击中心点
	else:
		modulate.a = .5

func _on_pressed():
	$PressAudio.play()
	_center1 = (get_global_transform().affine_inverse() * get_global_mouse_position()) / size  # 设置点击位置为中心点
	create_tween().tween_property(material, "shader_parameter/time1", 1.0, 0.5).from(0.0)  # 创建点击动画

func _on_mouse_entered():
	if !disabled:
		$SelectAudio.play()
		_is_mouse_over = true  # 标记鼠标悬停
		if _exit_tween: _exit_tween.kill()  # 停止退出动画
		create_tween().tween_property(material, "shader_parameter/glow", 2.0, 0.2)  # 使用补间动画设置辉光强度为2
		for node in _get_all_children(self):  # 遍历所有子节点
			if node is Label or node is RichTextLabel:  # 检查是否为文本节点
				var path = node.get_path()  # 获取节点路径
				if not _original_brightness.has(path): _original_brightness[path] = node.modulate  # 存储原始亮度
				node.modulate = _original_brightness[path] * 2  # 提高文本亮度
		set_process(true)  # 启用_process函数
		create_tween().tween_property(material, "shader_parameter/time2", 0.35, 0.2)  # 创建悬停进入动画

func _on_mouse_exited():
	if !disabled:
		_is_mouse_over = false  # 标记鼠标离开
		var center = Vector2(0.5, 0.5)  # 中心点坐标
		var exit_target = center + (_center2 - center).normalized() * 2.0  # 计算退出目标位置
		_exit_tween = create_tween()  # 创建退出动画
		_exit_tween.parallel().tween_property(self, "_center2", exit_target, 0.3)  # 移动中心点
		_exit_tween.parallel().tween_property(material, "shader_parameter/time2", 0.0, 0.3)  # 重置时间参数
		_exit_tween.parallel().tween_property(material, "shader_parameter/glow", 0.0, 0.2)  # 使用补间动画设置辉光强度为0
		_exit_tween.tween_callback(func(): _center2 = Vector2(0.5, 0.5); set_process(false))  # 动画完成后重置中心点
		for node in _get_all_children(self):  # 遍历所有子节点
			if (node is Label or node is RichTextLabel) and _original_brightness.has(node.get_path()):  # 检查是否为文本节点且已存储亮度
				node.modulate = _original_brightness[node.get_path()]  # 恢复原始亮度

func _get_all_children(node: Node) -> Array:
	var children = []  # 子节点数组
	for child in node.get_children(): children.append(child); children.append_array(_get_all_children(child))  # 递归获取所有子节点
	return children  # 返回子节点数组


func _on_label_resized() -> void:
	if text_label != null:
		text_label.position += Vector2(h_expend,v_expend)
		position -= Vector2(h_expend,v_expend)
