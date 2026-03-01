extends Node
class_name CameraShakeTemplate
## 相机震动模板（VFX/反馈）
## 目标：为 Camera2D 提供一套轻量震动接口，快速接入机关/受击反馈。

@export var camera_path: NodePath
@export var base_intensity: float = 8.0
@export var base_duration: float = 0.2

var _camera: Camera2D
var _timer: float = 0.0
var _duration: float = 0.0
var _intensity: float = 0.0
var _origin_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if camera_path != NodePath():
		_camera = get_node_or_null(camera_path) as Camera2D
	if _camera:
		_origin_offset = _camera.offset

func shake(intensity: float = -1.0, duration: float = -1.0) -> void:
	if not _camera:
		return
	_intensity = base_intensity if intensity < 0 else intensity
	_duration = base_duration if duration < 0 else duration
	_timer = _duration

func _process(delta: float) -> void:
	if not _camera:
		return
	if _timer <= 0.0:
		_camera.offset = _origin_offset
		return
	_timer -= delta
	var t := clampf(_timer / maxf(_duration, 0.001), 0.0, 1.0)
	var amp := _intensity * t
	_camera.offset = _origin_offset + Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
