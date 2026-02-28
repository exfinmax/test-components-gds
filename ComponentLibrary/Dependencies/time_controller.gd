extends Node
class_name GlobalTimeController

signal frame_freeze_started(time_scale: float, duration: float)
signal frame_freeze_ended

var engine_time_scale: float = 1.0:
	set(v):
		if v < 0.0:
			return
		engine_time_scale = v
		Engine.time_scale = v

var _freeze_stack_count: int = 0
var _freeze_restore_scale: float = 1.0

func set_time_scale(scale: float) -> void:
	engine_time_scale = scale

func frame_freeze(time_scale: float = 0.01, duration: float = 0.05) -> void:
	var safe_scale := maxf(time_scale, 0.0)
	var safe_duration := maxf(duration, 0.0)

	if _freeze_stack_count == 0:
		_freeze_restore_scale = engine_time_scale
	_freeze_stack_count += 1
	engine_time_scale = safe_scale
	frame_freeze_started.emit(safe_scale, safe_duration)

	if safe_duration <= 0.0:
		return

	var timer := get_tree().create_timer(safe_duration, true, false, true)
	timer.timeout.connect(_on_frame_freeze_timeout, CONNECT_ONE_SHOT)

func cancel_frame_freeze() -> void:
	if _freeze_stack_count <= 0:
		return
	_freeze_stack_count = 0
	engine_time_scale = _freeze_restore_scale
	frame_freeze_ended.emit()

func _on_frame_freeze_timeout() -> void:
	_freeze_stack_count = maxi(_freeze_stack_count - 1, 0)
	if _freeze_stack_count == 0:
		engine_time_scale = _freeze_restore_scale
		frame_freeze_ended.emit()
