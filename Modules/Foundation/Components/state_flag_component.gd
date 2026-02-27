extends ComponentBase
class_name StateFlagComponent
## 状态标记组件（Foundation 层）
## 作用：统一管理“布尔状态位”，用于跨组件解耦协作。
## 典型用法：把“is_dead / in_dialog / puzzle_locked”等状态放在这里，其他组件只读不写。

signal flag_changed(flag: StringName, value: bool)
signal flags_cleared

var _flags: Dictionary = {}

func set_flag(flag: StringName, value: bool) -> void:
	if not enabled:
		return
	var old :bool= _flags.get(flag, false)
	if old == value:
		return
	_flags[flag] = value
	flag_changed.emit(flag, value)

func get_flag(flag: StringName, default_value: bool = false) -> bool:
	return _flags.get(flag, default_value)

func remove_flag(flag: StringName) -> void:
	if _flags.erase(flag):
		flag_changed.emit(flag, false)

func clear_flags() -> void:
	if _flags.is_empty():
		return
	_flags.clear()
	flags_cleared.emit()

func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)

func get_all_flags() -> Dictionary:
	return _flags.duplicate(true)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"count": _flags.size(),
		"flags": _flags.duplicate(true),
	}
