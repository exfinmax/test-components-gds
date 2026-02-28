extends Node
class_name FreezeFrameEffect

@export var default_duration: float = 0.05
@export var min_scale: float = 0.01

var _active_freezes: int = 0
var _restore_scale: float = 1.0

func play(duration: float = -1.0) -> void:
	var freeze_duration := default_duration if duration <= 0.0 else duration
	if freeze_duration <= 0.0:
		return

	if _active_freezes == 0:
		_restore_scale = _get_current_scale()
	_set_time_scale(min_scale)
	_active_freezes += 1

	var timer := get_tree().create_timer(freeze_duration, true, false, true)
	timer.timeout.connect(_on_freeze_timeout, CONNECT_ONE_SHOT)

func cancel_all() -> void:
	if _active_freezes <= 0:
		return
	_active_freezes = 0
	_set_time_scale(_restore_scale)

func _exit_tree() -> void:
	cancel_all()

func _on_freeze_timeout() -> void:
	_active_freezes = max(_active_freezes - 1, 0)
	if _active_freezes == 0:
		_set_time_scale(_restore_scale)

func _get_current_scale() -> float:
	var controller := get_node_or_null("/root/TimeController")
	if controller:
		var value = controller.get("engine_time_scale")
		if value is float or value is int:
			return float(value)
	return Engine.time_scale

func _set_time_scale(scale: float) -> void:
	var safe_scale := max(scale, 0.0)
	var controller := get_node_or_null("/root/TimeController")
	if controller:
		controller.set("engine_time_scale", safe_scale)
		return
	Engine.time_scale = safe_scale
