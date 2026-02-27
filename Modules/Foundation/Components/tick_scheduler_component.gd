extends Node
class_name TickSchedulerComponent
## 帧调度器（Foundation 层）
## 作用：按 key 注册轻量任务，统一调度更新频率，降低大量组件逐帧更新压力。

signal task_registered(task_id: StringName)
signal task_unregistered(task_id: StringName)

@export var default_interval: float = 0.1

var _tasks: Dictionary = {}

func register_task(task_id: StringName, callback: Callable, interval: float = -1.0) -> void:
	if task_id == StringName():
		return
	var safe_interval := interval if interval > 0.0 else default_interval
	_tasks[task_id] = {
		"callback": callback,
		"interval": maxf(0.001, safe_interval),
		"elapsed": 0.0
	}
	task_registered.emit(task_id)

func unregister_task(task_id: StringName) -> void:
	if not _tasks.has(task_id):
		return
	_tasks.erase(task_id)
	task_unregistered.emit(task_id)

func clear_tasks() -> void:
	_tasks.clear()

func _process(delta: float) -> void:
	for task_id in _tasks.keys():
		var state: Dictionary = _tasks[task_id]
		state["elapsed"] = float(state.get("elapsed", 0.0)) + delta
		var interval: float = maxf(0.001, float(state.get("interval", default_interval)))
		if float(state["elapsed"]) >= interval:
			state["elapsed"] = 0.0
			var cb: Callable = state.get("callback", Callable())
			if cb.is_valid():
				cb.call()
		_tasks[task_id] = state

