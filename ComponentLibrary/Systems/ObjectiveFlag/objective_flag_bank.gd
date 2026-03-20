extends Node
class_name ObjectiveFlagBank

signal flag_changed(flag_name: String, value: Variant)
signal objective_changed(objective_id: String, state: Dictionary)

var _flags: Dictionary = {}
var _objectives: Dictionary = {}

func set_flag(flag_name: String, value: Variant = true) -> void:
	_flags[flag_name] = value
	flag_changed.emit(flag_name, value)

func get_flag(flag_name: String, default_value: Variant = false) -> Variant:
	return _flags.get(flag_name, default_value)

func has_flag(flag_name: String, expected: Variant = true) -> bool:
	return _flags.get(flag_name, null) == expected

func set_objective_state(objective_id: String, state: Dictionary) -> void:
	_objectives[objective_id] = state.duplicate(true)
	objective_changed.emit(objective_id, _objectives[objective_id])

func get_objective_state(objective_id: String) -> Dictionary:
	return (_objectives.get(objective_id, {}) as Dictionary).duplicate(true)

func export_data() -> Dictionary:
	return {
		"flags": _flags.duplicate(true),
		"objectives": _objectives.duplicate(true),
	}
