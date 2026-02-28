extends Node
class_name SequenceSwitchComponent
## 时序开关组件（Gameplay/Common 层）
## 作用：要求玩家按指定顺序触发开关，常用于解谜门禁。

signal sequence_progress(index: int, total: int)
signal sequence_completed
signal sequence_failed

@export var sequence: Array[StringName] = []
@export var reset_on_fail: bool = true

var _index: int = 0

func input_step(step: StringName) -> bool:
	if sequence.is_empty():
		return false
	if step == sequence[_index]:
		_index += 1
		sequence_progress.emit(_index, sequence.size())
		if _index >= sequence.size():
			sequence_completed.emit()
			_index = 0
		return true
	sequence_failed.emit()
	if reset_on_fail:
		_index = 0
	return false

func reset_sequence() -> void:
	_index = 0

func get_component_data() -> Dictionary:
	return {
		"index": _index,
		"total": sequence.size(),
		"reset_on_fail": reset_on_fail,
	}
