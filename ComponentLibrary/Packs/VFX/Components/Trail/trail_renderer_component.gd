extends Line2D
class_name TrailRendererComponent
## 拖尾渲染组件 - 角色/物体运动时的轨迹线
##
## 有什么用？
##   想象冲刺时身后拖出一道蓝色光带，
##   或者子弹飞过留下一条白色尾迹——这就是 Trail（拖尾）。
##   
##   在时间操控跑酷中：
##     - 冲刺 → 蓝色高速拖尾
##     - 倒流 → 紫色逆向拖尾（方向反转）
##     - 正常跑步 → 淡淡的短拖尾
##     - 加速区域 → 金色长拖尾
##
##   拖尾让速度感变得"可见"，极大提升跑酷手感。
##
## 工作原理：
##   Line2D 本身就能渲染多段线。
##   每帧把角色位置加到线头，超过最大长度就删掉线尾。
##   就像贪吃蛇——头一直在长，尾一直在缩。
##
## 使用方式：
##   1. 作为角色子节点（注意：top_level = true 让它不随角色翻转）
##   2. 设置 trail_length, trail_color, trail_width
##   3. 设置 enabled = true / false 控制开关
##   
##   自动模式：
##     当角色速度 > min_speed_threshold 时自动显示
##   手动模式：
##     通过代码 trail.enabled = true/false 控制

signal trail_started
signal trail_ended

## --------- 外观设置 ---------

## 最大拖尾点数（越多越长，15-30 适中）
@export var trail_length: int = 20

## 拖尾颜色（支持渐变：头部亮→尾部淡）
@export var trail_color: Color = Color(0.3, 0.6, 1.0, 0.8)

## 尾部颜色（渐变终点）
@export var trail_end_color: Color = Color(0.3, 0.6, 1.0, 0.0)

## 拖尾宽度
@export var trail_width_start: float = 6.0
@export var trail_width_end: float = 1.0

## --------- 行为设置 ---------

## 是否启用（关闭后立即开始缩短拖尾）
@export var enabled: bool = true:
	set(v):
		if enabled == v: return
		enabled = v
		if enabled:
			trail_started.emit()
		else:
			trail_ended.emit()

## 自动模式：速度超过此阈值时自动显示拖尾
@export var auto_mode: bool = false
@export var min_speed_threshold: float = 200.0

## 每隔多少帧记录一个点（1 = 每帧，2 = 隔帧，降低密度）
@export var record_every_n_frames: int = 1

## 拖尾不随角色翻转（top_level）
@export var detach_from_parent: bool = true

## --------- 内部 ---------
var _target: Node2D
var _frame_counter: int = 0
var _is_fading: bool = false  # 正在消失（enabled=false 后逐渐缩短）

func _ready() -> void:
	# 脱离父级变换（防止跟着角色翻转/缩放）
	if detach_from_parent:
		top_level = true
	
	# 清空初始点
	clear_points()
	
	# 设置渐变
	_update_gradient()
	_update_width_curve()
	
	# 自动找目标
	if owner:
		_target = owner as Node2D
	elif get_parent() is Node2D:
		_target = get_parent() as Node2D

func _process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return
	
	# 自动模式：根据速度判断是否显示
	if auto_mode and _target is CharacterBody2D:
		var speed := (_target as CharacterBody2D).velocity.length()
		enabled = speed > min_speed_threshold
	
	if enabled:
		_frame_counter += 1
		if _frame_counter >= record_every_n_frames:
			_frame_counter = 0
			# 在头部添加新点
			add_point(_target.global_position, 0)
			# 保持最大长度
			while get_point_count() > trail_length:
				remove_point(get_point_count() - 1)
		_is_fading = false
	else:
		# 拖尾逐渐消失（每帧删一个尾部点）
		if get_point_count() > 0:
			remove_point(get_point_count() - 1)
			_is_fading = true
		else:
			_is_fading = false

#region 外观更新

func _update_gradient() -> void:
	var grad := Gradient.new()
	grad.set_color(0, trail_color)
	grad.add_point(1.0, trail_end_color)
	gradient = grad

func _update_width_curve() -> void:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, trail_width_start))
	curve.add_point(Vector2(1.0, trail_width_end))
	width_curve = curve
	width = 1.0  # width_curve 会乘以 width

#endregion

#region API

## 立即清除拖尾
func clear_trail() -> void:
	clear_points()

## 设置拖尾颜色（运行时切换，如冲刺时变色）
func set_trail_color(start_color: Color, end_color: Color = Color.TRANSPARENT) -> void:
	trail_color = start_color
	trail_end_color = end_color if end_color != Color.TRANSPARENT else Color(start_color.r, start_color.g, start_color.b, 0)
	_update_gradient()

## 设置拖尾宽度
func set_trail_width(start_w: float, end_w: float = 1.0) -> void:
	trail_width_start = start_w
	trail_width_end = end_w
	_update_width_curve()

## 预设：冲刺拖尾
func preset_dash() -> void:
	set_trail_color(Color(0.3, 0.6, 1.0, 0.9))
	set_trail_width(8.0, 2.0)
	trail_length = 25

## 预设：倒流拖尾
func preset_rewind() -> void:
	set_trail_color(Color(0.8, 0.3, 1.0, 0.7))
	set_trail_width(5.0, 1.0)
	trail_length = 30

## 预设：加速拖尾
func preset_speed_boost() -> void:
	set_trail_color(Color(1.0, 0.8, 0.2, 0.8))
	set_trail_width(6.0, 1.5)
	trail_length = 20

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"point_count": get_point_count(),
		"trail_length": trail_length,
		"auto_mode": auto_mode,
		"is_fading": _is_fading,
	}

#endregion
