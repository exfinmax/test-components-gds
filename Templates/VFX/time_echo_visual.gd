extends Node2D
class_name TimeEchoVisual
## 回声拖影 VFX 模板
## 目标：给目标 Sprite2D 生成可控频率的残影，作为“回溯/回声”视觉反馈。

@export var target_path: NodePath
@export var echo_interval: float = 0.08
@export var echo_lifetime: float = 0.45
@export var echo_color: Color = Color(0.6, 0.95, 1.0, 0.55)

var _timer: float = 0.0
var _active: bool = false
var _target: Sprite2D

func _ready() -> void:
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as Sprite2D

func set_active(v: bool) -> void:
	_active = v
	_timer = 0.0

func _process(delta: float) -> void:
	if not _active:
		return
	if not _target:
		return
	_timer += delta
	if _timer >= echo_interval:
		_timer = 0.0
		_spawn_echo()

func _spawn_echo() -> void:
	var echo := Sprite2D.new()
	echo.texture = _target.texture
	echo.hframes = _target.hframes
	echo.vframes = _target.vframes
	echo.frame = _target.frame
	echo.flip_h = _target.flip_h
	echo.flip_v = _target.flip_v
	echo.global_position = _target.global_position
	echo.global_rotation = _target.global_rotation
	echo.scale = _target.global_scale
	echo.modulate = echo_color
	get_tree().current_scene.add_child(echo)

	var tw := create_tween()
	tw.tween_property(echo, "modulate:a", 0.0, echo_lifetime)
	tw.finished.connect(func():
		if is_instance_valid(echo):
			echo.queue_free()
	)
