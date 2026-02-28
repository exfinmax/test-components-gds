extends Node2D
class_name TimedDoorComponent
## 计时门组件（Gameplay/Common 层）
## 作用：当输入保持激活足够时长后开门，可配置自动关闭。

signal opened
signal closed
signal progress_changed(value: float)

@export var required_seconds: float = 0.8
@export var auto_close: bool = false
@export var close_delay: float = 1.0
@export var collision_shape_path: NodePath = ^"CollisionShape2D"

var _active_input: bool = false
var _progress: float = 0.0
var _opened: bool = false
var _close_timer: float = 0.0

func _process(delta: float) -> void:
	if _opened:
		if auto_close:
			_close_timer -= delta
			if _close_timer <= 0.0:
				_close()
		return

	if _active_input:
		_progress = minf(required_seconds, _progress + delta)
	else:
		_progress = maxf(0.0, _progress - delta * 1.2)
	progress_changed.emit(_progress / maxf(required_seconds, 0.001))
	if _progress >= required_seconds:
		_open()

func set_input_active(active: bool) -> void:
	_active_input = active
	if _opened and auto_close and active:
		_close_timer = close_delay

func _open() -> void:
	if _opened:
		return
	_opened = true
	_set_collision_enabled(false)
	visible = false
	_close_timer = close_delay
	opened.emit()

func _close() -> void:
	if not _opened:
		return
	_opened = false
	_progress = 0.0
	_set_collision_enabled(true)
	visible = true
	closed.emit()

func _set_collision_enabled(v: bool) -> void:
	var shape := get_node_or_null(collision_shape_path) as CollisionShape2D
	if shape:
		shape.disabled = not v

func get_component_data() -> Dictionary:
	return {
		"opened": _opened,
		"progress": _progress,
		"required_seconds": required_seconds,
		"auto_close": auto_close,
	}
