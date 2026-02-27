extends Node
class_name FreezeFrameEffect
## 冻结帧模板（VFX/反馈）
## 目标：给关键事件（受击、机关触发、回溯释放）制造短暂“停顿感”。

@export var default_duration: float = 0.05
@export var min_scale: float = 0.01

func play(duration: float = -1.0) -> void:
	var d := default_duration if duration <= 0.0 else duration
	var old_scale := Engine.time_scale
	Engine.time_scale = min_scale
	get_tree().create_timer(d, true, false, true).timeout.connect(func():
		Engine.time_scale = old_scale
	)

