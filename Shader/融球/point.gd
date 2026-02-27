@tool
class_name Point
extends Control

# 相对半径 (0.0 - 0.5)，相对于父容器大小
@export_range(0.0, 0.5, 0.001) var radius: float = 0.05
# 颜色
@export var color: Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _draw() -> void:
	if Engine.is_editor_hint():
		# 为了在编辑器中看清位置，绘制一个圆圈
		# 因为 radius 是相对值 (UV空间)，这里乘以一个较大数值用于可视化辅助
		# 实际显示大小取决于父容器尺寸
		draw_arc(Vector2.ZERO, radius * 500.0, 0, TAU, 32, color, 2.0)
		draw_circle(Vector2.ZERO, radius * 500.0, Color(color.r, color.g, color.b, 0.2))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
