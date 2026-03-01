extends Node
class_name LapCheckpointComponent

signal checkpoint_passed(checkpoint_id: StringName, index: int, total: int)
signal lap_completed(lap: int)
signal wrong_checkpoint(expected: StringName, actual: StringName)

@export var checkpoint_order: Array[StringName] = [&"A", &"B", &"C"]
@export var loop_enabled: bool = true

var _next_index: int = 0
var _lap: int = 0

func set_checkpoint_order(order: Array[StringName]) -> void:
	checkpoint_order = order.duplicate()
	reset_progress()

func pass_checkpoint(checkpoint_id: StringName) -> bool:
	if checkpoint_order.is_empty():
		return false
	if _next_index >= checkpoint_order.size():
		return false

	var expected: StringName = checkpoint_order[_next_index]
	if checkpoint_id != expected:
		wrong_checkpoint.emit(expected, checkpoint_id)
		return false

	_next_index += 1
	checkpoint_passed.emit(checkpoint_id, _next_index, checkpoint_order.size())
	if _next_index >= checkpoint_order.size():
		_lap += 1
		lap_completed.emit(_lap)
		if loop_enabled:
			_next_index = 0
	return true

func get_lap() -> int:
	return _lap

func get_next_checkpoint() -> StringName:
	if checkpoint_order.is_empty() or _next_index >= checkpoint_order.size():
		return StringName()
	return checkpoint_order[_next_index]

func reset_progress() -> void:
	_next_index = 0
	_lap = 0
