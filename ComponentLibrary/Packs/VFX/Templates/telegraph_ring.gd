extends Node2D
class_name TelegraphRing
## 预警环 VFX 模板
## 目标：在机关触发前播放一段“圈缩 + 透明衰减”的预警效果。

@export var color: Color = Color(1.0, 0.35, 0.2, 0.9)
@export var line_width: float = 4.0
@export var start_radius: float = 56.0
@export var end_radius: float = 12.0

var _radius: float = 56.0:
	set(v):
		_radius = v
		queue_redraw()
var _alpha: float = 1.0

func _ready() -> void:
	_radius = start_radius
	_alpha = color.a
	play()

func play(duration: float = 0.55) -> void:
	_radius = start_radius
	_alpha = color.a
	queue_redraw()
	var tw := create_tween()
	tw.tween_property(self, "_radius", end_radius, duration)
	tw.parallel().tween_property(self, "_alpha", 0.0, duration)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var c := color
	c.a = _alpha
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, c, line_width)
