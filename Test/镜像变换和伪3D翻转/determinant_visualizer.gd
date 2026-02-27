# determinant_visualizer.gd
# 行列式符号变化可视化工具（简化版）
# 作者：学习搭子
# 日期：2026-02-22
#
# 功能：
# 1. 滑块控制行列式值（-1 到 +1）
# 2. 实时显示变换矩阵和手性状态
# 3. 可视化基向量变化
# 4. 简单形状变换对比

extends Control

# 导出参数
@export var initial_determinant : float = 1.0

# 节点引用（通过编辑器拖放赋值）
#@onready var slider :HSlider= $VBoxContainer/HSlider  # 已删除
@onready var matrix_text: RichTextLabel = %MatrixText
@onready var value_label: Label = %ValueLabel
@onready var handedness_label: Label = %HandednessLabel

# 新增控制节点引用
@onready var scale_x_spin: SpinBox = $VBoxContainer/ScaleXHBox/ScaleXSpin
@onready var scale_y_spin: SpinBox = $VBoxContainer/ScaleYHBox/ScaleYSpin
@onready var rotate_angle_spin: SpinBox = $VBoxContainer/RotateHBox/AngleSpin
@onready var rotate_axis_option: OptionButton = $VBoxContainer/RotateHBox/AxisOption
@onready var skew_x_spin: SpinBox = $VBoxContainer/SkewXHBox/SkewXSpin
@onready var skew_y_spin: SpinBox = $VBoxContainer/SkewYHBox/SkewYSpin
# @onready var skew_axis_option: OptionButton = $VBoxContainer/SkewAxisHBox/AxisOption  # 已移除 
@onready var pivot_x_spin: SpinBox = $VBoxContainer/PivotHBox/PivotXSpin
@onready var pivot_y_spin: SpinBox = $VBoxContainer/PivotHBox/PivotYSpin
@onready var order_option: OptionButton = $VBoxContainer/OrderHBox/OrderOption

# 变换状态
var current_transform := Transform2D.IDENTITY
var center := Vector2(700, 150)  # 绘制中心
var scale_factor := 150.0         # 绘制比例
var origin:Vector2 = Vector2.ZERO

# 颜色定义
const COLOR_AXIS_X := Color(1.0, 0.3, 0.3)
const COLOR_AXIS_Y := Color(0.3, 1.0, 0.3)
const COLOR_ORIGINAL := Color(0.3, 0.5, 0.8, 0.6)
const COLOR_TRANSFORMED := Color(0.8, 0.3, 0.3, 0.7)
const COLOR_TEXT := Color(0.9, 0.9, 0.9)

func _ready():
	# 配置缩放输入
	scale_x_spin.min_value = -10
	scale_x_spin.max_value = 10
	scale_x_spin.step = 0.01
	scale_x_spin.value = 1.0
	scale_x_spin.value_changed.connect(_on_param_changed)

	scale_y_spin.min_value = -10
	scale_y_spin.max_value = 10
	scale_y_spin.step = 0.01
	scale_y_spin.value = 1.0
	scale_y_spin.value_changed.connect(_on_param_changed)

	# 配置旋转输入
	rotate_angle_spin.min_value = 0
	rotate_angle_spin.max_value = 360
	rotate_angle_spin.step = 1
	rotate_angle_spin.value = 0
	rotate_angle_spin.value_changed.connect(_on_param_changed)
	rotate_axis_option.add_item("X", 0)
	rotate_axis_option.add_item("Y", 1)
	rotate_axis_option.connect("item_selected", Callable(self, "_on_param_changed"))

	# 配置倾斜输入
	skew_x_spin.min_value = -5
	skew_x_spin.max_value = 5
	skew_x_spin.step = 0.01
	skew_x_spin.value = 0
	skew_x_spin.value_changed.connect(_on_param_changed)

	skew_y_spin.min_value = -5
	skew_y_spin.max_value = 5
	skew_y_spin.step = 0.01
	skew_y_spin.value = 0
	skew_y_spin.value_changed.connect(_on_param_changed)

	# 配置枢轴
	pivot_x_spin.min_value = -1000
	pivot_x_spin.max_value = 1000
	pivot_x_spin.step = 1
	pivot_x_spin.value = 0
	pivot_x_spin.value_changed.connect(_on_param_changed)

	pivot_y_spin.min_value = -1000
	pivot_y_spin.max_value = 1000
	pivot_y_spin.step = 1
	pivot_y_spin.value = 0
	pivot_y_spin.value_changed.connect(_on_param_changed)

	# 配置顺序选项
	order_option.add_item("Scale→Rotate→Skew", 0)
	order_option.add_item("Scale→Skew→Rotate", 1)
	order_option.add_item("Rotate→Scale→Skew", 2)
	order_option.add_item("Rotate→Skew→Scale", 3)
	order_option.add_item("Skew→Rotate→Scale", 4)
	order_option.connect("item_selected", Callable(self, "_on_param_changed"))

	# 初始更新
	_on_param_changed(0)
	
	# 设置背景色
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15)
	add_theme_stylebox_override("panel", bg_style)

# 通用参数变化回调
func _on_param_changed(_value) -> void:
	# 更新变换矩阵 (determinant now not driven by slider)
	# 我们不再计算特定行列式，使用 skew values 直接传入
	update_transform_from_determinant()
	
	# 更新UI
	# value_label 用于显示当前 skew 值之一 (x, y)
	value_label.text = "Skew = (%.2f, %.2f)" % [skew_x_spin.value, skew_y_spin.value]
	update_matrix_display()
	
	# 触发重绘
	queue_redraw()

func update_transform_from_determinant():
	# 根据 UI 参数构建变换矩阵（缩放、旋转、倾斜、枢轴、顺序可调）

	# 缩放矩阵
	var scale_vec = Vector2(scale_x_spin.value, scale_y_spin.value)
	var scale_mat = Transform2D.IDENTITY.scaled(scale_vec)

	# 旋转矩阵
	var angle_rad = deg_to_rad(rotate_angle_spin.value)
	var rotate_mat = Transform2D.IDENTITY.rotated(angle_rad)
	# 旋转轴选项目前未改变 2D 旋转效果，但保留以便以后扩展

	# 倾斜矩阵（分别设置 x 与 y）
	var skew_mat = Transform2D(Vector2(1, skew_x_spin.value), Vector2(skew_y_spin.value, 1), Vector2.ZERO)

	# 枢轴位移（允许用户输入中心点）
	var base_offset = Vector2(0, 0)
	var pivot = Vector2(pivot_x_spin.value, pivot_y_spin.value)
	var origin_mat = Transform2D(Vector2(1,0), Vector2(0,1), base_offset - pivot)
	var inv_origin_mat = Transform2D(Vector2(1,0), Vector2(0,1), -base_offset + pivot)

	# 组合顺序控制
	match order_option.get_selected_id():
		0:
			current_transform = inv_origin_mat * scale_mat * rotate_mat * skew_mat * origin_mat
		1:
			current_transform = inv_origin_mat * scale_mat * skew_mat * rotate_mat * origin_mat
		2:
			current_transform = inv_origin_mat * rotate_mat * scale_mat * skew_mat * origin_mat
		3:
			current_transform = inv_origin_mat * rotate_mat * skew_mat * scale_mat * origin_mat
		_:
			current_transform = inv_origin_mat * skew_mat * rotate_mat * scale_mat * origin_mat

	# 输出当前行列式便于调试观察
	var actual_det = current_transform.determinant()
	print("当前行列式: %.2f" % actual_det)

func update_matrix_display():
	var det = current_transform.determinant()
	var handedness = "右手系" if det > 0 else "左手系" if det < 0 else "降维"
	
	# 计算基向量信息
	var i_len = current_transform.x.length()
	var j_len = current_transform.y.length()
	var angle_deg = rad_to_deg(current_transform.x.angle_to(current_transform.y))
	
	# 更新矩阵显示
	var matrix_str = "[b]变换矩阵:[/b]\n"
	matrix_str += "[code]"
	matrix_str += "| %6.2f  %6.2f |\n" % [current_transform.x.x, current_transform.y.x]
	matrix_str += "| %6.2f  %6.2f |\n" % [current_transform.x.y, current_transform.y.y]
	matrix_str += "[/code]\n\n"
	
	matrix_str += "[b]基向量分析:[/b]\n"
	matrix_str += "• i向量: (%.2f, %.2f)\n" % [current_transform.x.x, current_transform.x.y]
	matrix_str += "• j向量: (%.2f, %.2f)\n" % [current_transform.y.x, current_transform.y.y]
	matrix_str += "• i长度: %.2f, j长度: %.2f\n" % [i_len, j_len]
	matrix_str += "• i·j夹角: %.1f°\n" % angle_deg
	
	# 显示当前参数设置
	matrix_str += "\n[b]参数设置:[/b]\n"	
	matrix_str += "Scale = (%.2f, %.2f)\n" % [scale_x_spin.value, scale_y_spin.value]
	matrix_str += "Rotate = %.1f° around %s axis\n" % [rotate_angle_spin.value, rotate_axis_option.get_item_text(rotate_axis_option.selected)]
	matrix_str += "Skew = (%.2f, %.2f)\n" % [skew_x_spin.value, skew_y_spin.value]
	matrix_str += "Pivot = (%.1f, %.1f)\n" % [pivot_x_spin.value, pivot_y_spin.value]
	matrix_str += "Order = %s\n" % order_option.get_item_text(order_option.selected)

	matrix_text.text = matrix_str
	handedness_label.text = handedness

func _draw():
	# 绘制原始坐标系（灰色）
	draw_axes(Transform2D.IDENTITY, false)
	
	# 绘制变换后坐标系（彩色）
	draw_axes(current_transform, true)
	
	# 绘制原始形状
	draw_square(Transform2D.IDENTITY, COLOR_ORIGINAL)
	
	# 绘制变换后形状
	draw_square(current_transform, COLOR_TRANSFORMED)
	
	# 绘制中心点
	draw_circle(center, 3, COLOR_TEXT)

func draw_axes(transform: Transform2D, is_transformed: bool):
	# 计算基向量在屏幕上的位置
	var i_vec = transform.x * scale_factor
	var j_vec = transform.y * scale_factor
	
	var color_i = COLOR_AXIS_X if is_transformed else Color(0.5, 0.5, 0.5)
	var color_j = COLOR_AXIS_Y if is_transformed else Color(0.5, 0.5, 0.5)
	var line_width = 3.0 if is_transformed else 1.0
	
	# 绘制x轴（i向量）
	draw_line(center, center + i_vec, color_i, line_width)
	
	# 绘制箭头
	draw_arrow_head(center + i_vec, i_vec.angle(), color_i)
	
	# 绘制y轴（j向量）
	draw_line(center, center + j_vec, color_j, line_width)
	draw_arrow_head(center + j_vec, j_vec.angle(), color_j)
	
	# 标签
	if is_transformed:
		draw_string(
			ThemeDB.fallback_font,
			center + i_vec * 1.1 + Vector2(-10, 10),
			"i'",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			color_i
		)
		draw_string(
			ThemeDB.fallback_font,
			center + j_vec * 1.1 + Vector2(-10, 10),
			"j'",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			color_j
		)

func draw_arrow_head(position: Vector2, angle: float, color: Color):
	var arrow_size = 8.0
	var arrow_angle = deg_to_rad(30)
	
	var dir = Vector2(cos(angle), sin(angle))
	var perp = Vector2(-dir.y, dir.x)
	
	var p1 = position
	var p2 = position - dir * arrow_size + perp * arrow_size * tan(arrow_angle * 0.5)
	var p3 = position - dir * arrow_size - perp * arrow_size * tan(arrow_angle * 0.5)
	
	draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([color, color, color]))

func draw_square(transform: Transform2D, color: Color):
	# 定义正方形顶点（相对坐标）
	var square_points = [
		Vector2(-0.5, -0.5),
		Vector2(0.5, -0.5),
		Vector2(0.5, 0.5),
		Vector2(-0.5, 0.5)
	]
	
	# 应用变换并转换到屏幕坐标
	var points = PackedVector2Array()
	for point in square_points:
		var transformed_point = transform * (point * scale_factor * 0.8)
		points.append(center + transformed_point)
	
	# 绘制填充
	if points.size() >= 3:
		draw_polygon(points, PackedColorArray([color]))
	
	# 绘制轮廓
	for i in range(points.size()):
		var next_idx = (i + 1) % points.size()
		draw_line(
			points[i],
			points[next_idx],
			color.darkened(0.3),
			2.0
		)

# 鼠标交互：点击拖动改变中心点
var dragging = false
var drag_start = Vector2.ZERO
var center_start = Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			dragging = mb.pressed
			if mb.pressed:
				drag_start = get_local_mouse_position()
				center_start = center
			else:
				queue_redraw()
	
	elif event is InputEventMouseMotion and dragging:
		var delta = get_local_mouse_position() - drag_start
		center = center_start + delta
		queue_redraw()

# 重置功能
func reset():
	center = Vector2(200, 150)
	# 恢复默认参数
	scale_x_spin.value = 1
	scale_y_spin.value = 1
	rotate_angle_spin.value = 0
	skew_x_spin.value = 0
	skew_y_spin.value = 0
	pivot_x_spin.value = 0
	pivot_y_spin.value = 0
	order_option.select(0)
	_on_param_changed(0)  # 强制刷新显示
	queue_redraw()

# 获取当前变换信息（供外部使用）
func get_transform_info() -> Dictionary:
	return {
		"matrix": current_transform,
		"determinant": current_transform.determinant(),
		"handedness": "右手系" if current_transform.determinant() > 0 else "左手系"
	}
