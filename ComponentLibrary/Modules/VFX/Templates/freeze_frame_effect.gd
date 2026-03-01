extends Node
class_name FreezeFrameEffect

@export var default_duration: float = 0.05
@export var min_scale: float = 0.01

func play(duration: float = -1.0) -> void:
	var freeze_duration := default_duration if duration <= 0.0 else duration
	if freeze_duration <= 0.0:
		return

	var controller := get_node_or_null("/root/TimeController")
	if controller != null and controller.has_method("frame_freeze"):
		controller.call("frame_freeze", min_scale, freeze_duration)
		return

	# 回退路径：没有全局 TimeController 时直接改 Engine.time_scale
	var old_scale := Engine.time_scale
	Engine.time_scale = maxf(min_scale, 0.0)
	var timer := get_tree().create_timer(freeze_duration, true, false, true)
	var restore_callable := func() -> void:
		Engine.time_scale = old_scale
	timer.timeout.connect(restore_callable, CONNECT_ONE_SHOT)
