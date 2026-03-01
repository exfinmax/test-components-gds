extends Node
class_name ProductionQueueComponent

signal job_queued(job_id: StringName, queue_size: int)
signal job_started(job_id: StringName)
signal job_completed(job_id: StringName, payload: Dictionary)
signal queue_cleared

@export var auto_start_next: bool = true
@export var max_queue_size: int = 0

var _queue: Array[Dictionary] = []
var _current_job: Dictionary = {}
var _elapsed: float = 0.0

func enqueue_job(job_id: StringName, duration: float, payload: Dictionary = {}) -> bool:
	if job_id == StringName():
		return false
	if max_queue_size > 0 and _queue.size() >= max_queue_size:
		return false

	var job := {
		"id": job_id,
		"duration": maxf(duration, 0.0),
		"payload": payload.duplicate(true),
	}
	_queue.append(job)
	job_queued.emit(job_id, _queue.size())
	if auto_start_next and _current_job.is_empty():
		_start_next_job()
	return true

func cancel_job(job_id: StringName) -> bool:
	for i in range(_queue.size()):
		if _queue[i].get("id", StringName()) == job_id:
			_queue.remove_at(i)
			return true
	return false

func clear_queue() -> void:
	_queue.clear()
	_current_job.clear()
	_elapsed = 0.0
	queue_cleared.emit()

func is_busy() -> bool:
	return not _current_job.is_empty()

func get_queue_size() -> int:
	return _queue.size()

func get_current_job_id() -> StringName:
	return _current_job.get("id", StringName())

func _process(delta: float) -> void:
	_tick(delta)

func _local_time_process(delta: float) -> void:
	_tick(delta)

func _tick(delta: float) -> void:
	if _current_job.is_empty():
		if auto_start_next:
			_start_next_job()
		return

	_elapsed += maxf(delta, 0.0)
	var duration := float(_current_job.get("duration", 0.0))
	if _elapsed >= duration:
		_complete_current_job()

func _start_next_job() -> void:
	if _queue.is_empty():
		return
	_current_job = _queue.pop_front()
	_elapsed = 0.0
	job_started.emit(_current_job.get("id", StringName()))
	if float(_current_job.get("duration", 0.0)) <= 0.0:
		_complete_current_job()

func _complete_current_job() -> void:
	var id: StringName = _current_job.get("id", StringName())
	var payload: Dictionary = _current_job.get("payload", {})
	job_completed.emit(id, payload)
	_current_job.clear()
	_elapsed = 0.0
	if auto_start_next:
		_start_next_job()
