# manual_transform_2d.gd
# 手动实现2D变换矩阵计算的Godot脚本
# 作者：学习搭子
# 日期：2026-02-21
#
# 本脚本展示如何手动计算平移、旋转、缩放矩阵，并应用到Sprite2D节点上
# 与Godot内置的Transform2D进行对比验证

extends Node2D

# 导出变量，方便在编辑器中调整
@export var manual_translation := Vector3(100, 50,0)
@export var manual_rotation_degrees := 30.0
@export var manual_scale := Vector2(1.5, 0.8)
@export var x_rotate_degree := 30

# 引用场景中的节点
@onready var sprite_manual := $SpriteManual as Sprite2D
@onready var sprite_engine := $SpriteEngine as Sprite2D
@onready var label_info := $LabelInfo as Label

func _ready():
	# 初始应用变换
	apply_manual_transform()
	update_info_label()

func apply_manual_transform():
	# 1. 创建缩放矩阵
	# Godot的Transform2D构造方式：Transform2D(x_axis, y_axis, origin)
	# 缩放矩阵：对角线为缩放因子
	var scale_matrix := Basis(
		Vector3(manual_scale.x, 0,0),    # x轴缩放
		Vector3(0, manual_scale.y,0),    # y轴缩放
		Vector3.ZERO                   # 原点
	)
	
	# 2. 创建旋转矩阵
	var rotation_rad := deg_to_rad(manual_rotation_degrees)
	var cos_theta := cos(rotation_rad)
	var sin_theta := sin(rotation_rad)
	var rotation_matrix := Basis(
		Vector3(cos_theta, -sin_theta,0),   # 旋转后的x轴
		Vector3(sin_theta, cos_theta,0),    # 旋转后的y轴
		Vector3.ZERO                      # 原点
	)
	
	# 3. 创建平移矩阵
	var translation_matrix := Basis.IDENTITY
	translation_matrix.z = Vector3(manual_translation)
	
	var xred = deg_to_rad(x_rotate_degree)
	var x_rot_mat := Basis(
		Vector3(1,0,0),
		Vector3(0,cos(xred),-sin(xred)),
		Vector3(0,sin(xred),cos(xred))
	)
	
	# 4. 组合变换：通常顺序为 缩放 → 旋转 → 平移
	# 注意：矩阵乘法顺序与应用的顺序相反（从右往左）
	# 我们要先缩放，再旋转，再平移，所以：
	# final = translation * rotation * scale
	var final_transform := translation_matrix * x_rot_mat * rotation_matrix * scale_matrix
	
	# 5. 应用到手动控制的Sprite
	sprite_manual.transform = Transform2D(
		Vector2(final_transform.x.x,final_transform.x.y),
		Vector2(final_transform.y.x,final_transform.y.y),
		Vector2(final_transform.z.x,final_transform.z.y)
	)
	
	# 6. 使用Godot内置方法做对比
	# Godot的Transform2D提供了便捷构造方法
	var engine_transform := Transform2D.IDENTITY
	engine_transform = engine_transform.scaled(manual_scale)
	engine_transform = engine_transform.rotated(-rotation_rad)
	engine_transform = engine_transform.translated(Vector2(manual_translation.x,manual_translation.y))
	
	sprite_engine.transform = engine_transform
	
	# 验证两个变换是否相同（允许浮点误差）
	var is_same := sprite_manual.transform.is_equal_approx(engine_transform)
	if is_same:
		print("✓ 手动计算与引擎内置变换一致！")
	else:
		print("⚠ 手动计算与引擎内置变换存在差异")
		print("手动矩阵: ", final_transform)
		print("引擎矩阵: ", engine_transform)

func update_info_label():
	var info := ""
	info += "手动变换参数：\n"
	info += "  平移: (%.1f, %.1f)\n" % [manual_translation.x, manual_translation.y]
	info += "  旋转: %.1f°\n" % manual_rotation_degrees
	info += "  缩放: (%.1f, %.1f)\n" % [manual_scale.x, manual_scale.y]
	info += "\n"
	info += "操作说明：\n"
	info += "  1. 在检查器中调整参数实时查看效果\n"
	info += "  2. 按空格键重置变换\n"
	info += "  3. 按R键随机生成变换参数"
	
	label_info.text = info

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				# 重置变换
				manual_translation = Vector3(0,0,1)
				manual_rotation_degrees = 0.0
				manual_scale = Vector2.ONE
				apply_manual_transform()
				update_info_label()
				
			KEY_R:
				# 随机变换参数
				randomize()
				manual_translation = Vector3(
					randf_range(0, 1080),
					randf_range(0, 720),
					1
				)
				manual_rotation_degrees = randf_range(-180, 180)
				print(manual_rotation_degrees)
				manual_scale = Vector2(
					randf_range(0.5, 2.0),
					randf_range(0.5, 2.0)
				)
				print(sprite_manual.rotation_degrees)
				apply_manual_transform()
				print(sprite_manual.rotation_degrees)
				update_info_label()

# 如果需要在_process中持续更新（例如动画）
func _process(delta):
	# 示例：可以取消注释以下代码制作简单动画
	#manual_rotation_degrees += 60.0 * delta  # 每秒60度
	#apply_manual_transform()
	pass
	
