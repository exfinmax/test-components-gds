extends Node
class_name TickSchedulerComponent

signal task_registered(task_id: StringName)
signal task_unregistered(task_id: StringName)

@export var default_interval: float = 0.1
@export var use_local_time_domain: bool = true
@export var local_time_domain_path: NodePath

var _tasks: Dictionary = {}
var _local_time_domain: LocalTimeDomain = null

func _ready() -> void:
	if use_local_time_domain:
		_local_time_domain = _resolve_local_time_domain()
		if _local_time_domain != null:
			_local_time_domain.register_participant(self)

func register_task(task_id: StringName, callback: Callable, interval: float = -1.0) -> void:
	if task_id == StringName():
		return
	var safe_interval := interval if interval > 0.0 else default_interval
	_tasks[task_id] = {
		"callback": callback,
		"interval": maxf(0.001, safe_interval),
		"elapsed": 0.0,
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
	_tick(delta)

func _local_time_process(delta: float) -> void:
	_tick(delta)

func _tick(delta: float) -> void:
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

func _resolve_local_time_domain() -> LocalTimeDomain:
	if local_time_domain_path != NodePath():
		return get_node_or_null(local_time_domain_path) as LocalTimeDomain

	var current := get_parent()
	while current != null:
		if current is LocalTimeDomain:
			return current as LocalTimeDomain
		current = current.get_parent()
	return null
