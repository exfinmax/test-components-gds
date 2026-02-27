
# interactive_transform_tool.gd
# 交互式2D变换工具
# 作者：学习搭子
# 日期：2026-02-21
#
# 本脚本提供鼠标交互的2D变换工具：
# - 鼠标拖拽平移
# - 滚轮缩放
# - 键盘控制旋转
# 同时显示变换矩阵和坐标信息

extends Node2D

# 控制灵敏度
@export var translation_speed := 1.0
@export var rotation_speed := 90.0  # 度/秒
@export var zoom_speed := 0.1

# 当前变换状态
var current_transform := Transform2D.IDENTITY
var is_dragging := false
var drag_start_position := Vector2.ZERO
var transform_start := Transform2D.IDENTITY

# 斜切状态
var is_skewing := false
var skew_start_position := Vector2.ZERO
var transform_before_skew := Transform2D.IDENTITY

# 节点引用
@onready var target_sprite := $TargetSprite as Sprite2D
@onready var coordinate_system := $CoordinateSystem as Node2D
@onready var matrix_display: RichTextLabel = %MatrixDisplay
@onready var coord_display: RichTextLabel = %CoordDisplay


func _ready():
	update_displays()

# helper to draw dashed line between two points


func _draw():
	# 坐标轴受 current_transform 影响
	# 原点为变换中的平移分量
	var origin := Vector2.ZERO
	var axis_width := 2

	# 先绘制网格线（本地坐标每72单位）
	var rect = get_viewport_rect()
	var inv = Transform2D.IDENTITY
	if current_transform.determinant():
		inv = current_transform.affine_inverse()
	
	# compute local bounds from viewport corners
	var corners = [
		inv.basis_xform(rect.position - Vector2(rect.size.x/2, 0)),
		inv.basis_xform(rect.position + Vector2(rect.size.x/2, 0)),
		inv.basis_xform(rect.position - Vector2(0, rect.size.y/2)),
		inv.basis_xform(rect.position + rect.size/2)
	]
	var min_x = corners[0].x
	var max_x = corners[0].x
	var min_y = corners[0].y
	var max_y = corners[0].y
	for c in corners:
		min_x = min(min_x, c.x)
		max_x = max(max_x, c.x)
		min_y = min(min_y, c.y)
		max_y = max(max_y, c.y)
	# vertical grid lines
	var gx = floor(min_x / 72.0) * 72
	while gx <= max_x:
		var w1 = current_transform.basis_xform(Vector2(gx, min_y))
		var w2 = current_transform.basis_xform(Vector2(gx, max_y))
		draw_dashed_line(w1, w2, Color(1,1,1,0.5), 1, 10, 10)
		gx += 72
	# horizontal grid lines
	var gy = floor(min_y / 72.0) * 72
	while gy <= max_y:
		var w1 = current_transform.basis_xform(Vector2(min_x, gy))
		var w2 = current_transform.basis_xform(Vector2(max_x, gy))
		draw_dashed_line(w1, w2, Color(1,1,1,0.5), 1, 10, 10)
		gy += 72

	# 计算轴端点通过变换作用
	var x_pos = current_transform.basis_xform(Vector2(max_x, 0))
	var x_neg = current_transform.basis_xform(Vector2(-max_x, 0))
	var y_pos = current_transform.basis_xform(Vector2(0, max_y))
	var y_neg = current_transform.basis_xform(Vector2(0, -max_y))
	# X轴 红色
	draw_line(origin, x_pos, Color.RED, axis_width)
	draw_line(origin, x_neg, Color.RED, axis_width)
	# Y轴 绿色
	draw_line(origin, y_pos, Color.GREEN, axis_width)
	draw_line(origin, y_neg, Color.GREEN, axis_width)
	# 原点
	draw_circle(origin, 5, Color.WHITE)

func _process(delta):
	# 键盘旋转控制
	var rotation_input := 0.0
	if Input.is_key_pressed(KEY_Q):
		rotation_input -= 1.0
	if Input.is_key_pressed(KEY_E):
		rotation_input += 1.0
	
	if rotation_input != 0.0:
		var rotation_rad := deg_to_rad(rotation_speed * delta * rotation_input)
		#var origin = current_transform.get_origin()
		#current_transform = current_transform.translated(-origin)
		current_transform = current_transform.rotated(rotation_rad)
		#current_transform = current_transform.translated(origin)
		apply_transform()

func _input(event):
	# 鼠标拖拽平移
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 开始拖拽
				is_dragging = true
				drag_start_position = get_global_mouse_position()
				transform_start = current_transform
			else:
				# 结束拖拽
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				# 开始斜切
				is_skewing = true
				skew_start_position = get_global_mouse_position()
				transform_before_skew = current_transform
			else:
				# 结束斜切
				is_skewing = false
		# 滚轮缩放
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# 放大
			var scale_factor := 1.0 + zoom_speed
			#var origin = current_transform.get_origin()
			#current_transform = current_transform.translated(-origin)
			current_transform = current_transform.scaled(Vector2(scale_factor, scale_factor))
			#current_transform = current_transform.translated(origin)
			apply_transform()
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# 缩小
			var scale_factor := 1.0 / (1.0 + zoom_speed)
			#var origin = current_transform.get_origin()
			#current_transform = current_transform.translated(-origin)
			current_transform = current_transform.scaled(Vector2(scale_factor, scale_factor))
			#current_transform = current_transform.translated(origin)
			apply_transform()
	
	# 鼠标移动拖拽
	elif event is InputEventMouseMotion and is_dragging:
		var current_pos := get_global_mouse_position()
		var delta_pos := current_pos - drag_start_position
		
		# 应用平移（在全局空间中进行）
		current_transform = transform_start
		current_transform.origin += delta_pos * translation_speed
		apply_transform()
	# 斜切拖动
	elif event is InputEventMouseMotion and is_skewing:
		var current_pos := get_global_mouse_position()
		var delta := current_pos - skew_start_position
		# 根据水平/垂直移动计算shear值
		var factor := 0.005
		var shx := delta.x * factor
		var shy := delta.y * factor
		var shear = Transform2D(Vector2(1, shx),Vector2(shy, 1), Vector2.ZERO)
		current_transform = transform_before_skew * shear
		apply_transform()
	
	# 键盘快捷键
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				# 重置变换
				current_transform = Transform2D.IDENTITY
				apply_transform()
			KEY_T:
				# 打印当前变换详情
				print_transform_details()
			KEY_H:
				# 显示帮助
				show_help()

func apply_transform():
	# 应用到目标Sprite
	target_sprite.transform = current_transform

	# 更新坐标系统可视化
	coordinate_system.transform = current_transform
	queue_redraw()  # 触发_draw()更新坐标轴显示

	# 更新显示
	update_displays()

func update_displays():
	# 更新矩阵显示
	var matrix_text := "[b]当前变换矩阵:[/b]\n"
	matrix_text += "[code]"
	matrix_text += "| %6.2f  %6.2f |\n" % [current_transform.x.x, current_transform.y.x]
	matrix_text += "| %6.2f  %6.2f |\n" % [current_transform.x.y, current_transform.y.y]
	matrix_text += "[/code]\n"
	matrix_text += "原点: (%.1f, %.1f)\n" % [current_transform.origin.x, current_transform.origin.y]
	
	# 计算行列式（判断是否包含镜像）
	var det := current_transform.x.x * current_transform.y.y - current_transform.x.y * current_transform.y.x
	matrix_text += "行列式: %.3f " % det
	if abs(det - 1.0) < 0.01:
		matrix_text += "(纯旋转/平移)"
	elif det < 0:
		matrix_text += "(包含镜像)"
	
	# 近似显示斜切数值
	var shx := current_transform.y.x
	var shy := current_transform.x.y
	matrix_text += "\n斜切: (shx=%.3f, shy=%.3f)" % [shx, shy]
	
	matrix_display.text = matrix_text
	
	# 更新坐标显示
	var local_pos := Vector2(50, 50)  # 假设的局部坐标
	var world_pos := current_transform * local_pos
	var mouse_pos := get_global_mouse_position()
	var local_mouse_pos := current_transform.affine_inverse() * mouse_pos
	
	var coord_text := "[b]坐标转换:[/b]\n"
	coord_text += "局部点 (50,50) → 世界: (%.1f, %.1f)\n" % [world_pos.x, world_pos.y]
	coord_text += "鼠标世界坐标: (%.1f, %.1f)\n" % [mouse_pos.x, mouse_pos.y]
	coord_text += "鼠标局部坐标: (%.1f, %.1f)" % [local_mouse_pos.x, local_mouse_pos.y]
	
	coord_display.text = coord_text

func print_transform_details():
	print("=== 当前变换详情 ===")
	print("变换矩阵:")
	print("  [%6.2f, %6.2f]" % [current_transform.x.x, current_transform.y.x])
	print("  [%6.2f, %6.2f]" % [current_transform.x.y, current_transform.y.y])
	print("原点: (%6.2f, %6.2f)" % [current_transform.origin.x, current_transform.origin.y])
	
	# 分解变换
	var rotation_rad := atan2(current_transform.x.y, current_transform.x.x)
	var scale_x := current_transform.x.length()
	var scale_y := current_transform.y.length()
	
	print("分解结果:")
	print("  旋转角度: %.1f°" % rad_to_deg(rotation_rad))
	print("  缩放: (%.2f, %.2f)" % [scale_x, scale_y])
	print("  平移: (%.1f, %.1f)" % [current_transform.origin.x, current_transform.origin.y])

func show_help():
	var help_text := """
	[b]交互式2D变换工具 - 操作指南[/b]
	
	[code]
	鼠标控制：
	  • 左键拖拽：平移
	  • 滚轮上下：缩放
	
	键盘控制：
	  • Q/E：逆时针/顺时针旋转
	  • R：重置变换
	  • T：打印变换详情到控制台
	  • H：显示此帮助
	
	显示信息：
	  • 左上角：当前变换矩阵
	  • 右上角：坐标转换示例
	[/code]
	
	学习要点：
	  1. 观察矩阵如何随交互变化
	  2. 理解局部坐标到世界坐标的转换
	  3. 验证矩阵乘法顺序的重要性
	"""
	
	# 可以创建一个临时弹窗显示帮助，这里简化处理
	print(help_text)

# 工具函数：创建变换矩阵
static func create_translation_matrix(offset: Vector2) -> Transform2D:
	return Transform2D.IDENTITY.translated(offset)

static func create_rotation_matrix(angle_degrees: float) -> Transform2D:
	return Transform2D.IDENTITY.rotated(deg_to_rad(angle_degrees))

static func create_scaling_matrix(scale: Vector2) -> Transform2D:
	return Transform2D.IDENTITY.scaled(scale)

static func create_transform_sequence() -> Transform2D:
	# 演示变换组合顺序
	var transform := Transform2D.IDENTITY
	transform = transform.scaled(Vector2(2.0, 1.5))      # 先缩放
	transform = transform.rotated(deg_to_rad(45.0))      # 再旋转
	transform = transform.translated(Vector2(100, 50))   # 最后平移
	return transform
