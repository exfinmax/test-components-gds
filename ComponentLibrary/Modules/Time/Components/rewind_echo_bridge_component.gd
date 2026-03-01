extends Node
class_name RewindEchoBridgeComponent
## 回溯-回声桥接组件（Gameplay/Time 层）
## 作用：把“回溯结束”转成“回声释放”事件，统一你想要的核心循环。
## 注意：该组件只做编排，不绑定具体实现；由外部连接真实的回溯/回声系统。

signal rewind_started
signal rewind_stopped
signal echo_release_requested(window_seconds: float)

@export var min_window_for_echo: float = 0.2

var _rewind_active: bool = false
var _rewind_elapsed: float = 0.0

func _process(delta: float) -> void:
	if _rewind_active:
		_rewind_elapsed += delta

func start_rewind() -> void:
	if _rewind_active:
		return
	_rewind_active = true
	_rewind_elapsed = 0.0
	rewind_started.emit()

func stop_rewind() -> void:
	if not _rewind_active:
		return
	_rewind_active = false
	rewind_stopped.emit()
	if _rewind_elapsed >= min_window_for_echo:
		echo_release_requested.emit(_rewind_elapsed)

func is_rewinding() -> bool:
	return _rewind_active

func get_component_data() -> Dictionary:
	return {
		"rewind_active": _rewind_active,
		"rewind_elapsed": _rewind_elapsed,
		"min_window_for_echo": min_window_for_echo,
	}
