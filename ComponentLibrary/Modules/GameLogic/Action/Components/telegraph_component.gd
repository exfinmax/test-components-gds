extends ComponentBase
class_name TelegraphComponent
## 预警触发组件（Gameplay/Common 层）
## 作用：先发出预警，再延迟触发真正效果（激光、落石、陷阱等）。

signal telegraph_started(duration: float)
signal telegraph_triggered
signal telegraph_canceled

@export var telegraph_duration: float = 0.6

var _running: bool = false
var _remaining: float = 0.0


func _process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	if not enabled or not _running:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_running = false
		telegraph_triggered.emit()

func start(duration: float = -1.0) -> void:
	if duration > 0.0:
		telegraph_duration = duration
	_running = true
	_remaining = telegraph_duration
	telegraph_started.emit(telegraph_duration)

func cancel() -> void:
	if not _running:
		return
	_running = false
	_remaining = 0.0
	telegraph_canceled.emit()

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"running": _running,
		"remaining": _remaining,
		"telegraph_duration": telegraph_duration,
	}
