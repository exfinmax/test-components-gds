
extends ComponentBase
class_name ConditionGateComponent
## 条件门组件（Foundation 层）
## 作用：根据 StateFlagComponent 的状态判断“是否允许执行”。
## 适用：剧情门禁、机关开关、UI 按钮可用性。

signal gate_changed(is_open: bool)

@export var state_flags: StateFlagComponent
@export var required_true_flags: Array[StringName] = []
@export var required_false_flags: Array[StringName] = []

var _is_open_cached: bool = true

func _component_ready() -> void:
	if not state_flags:
		state_flags = find_sibling(StateFlagComponent) as StateFlagComponent
	if state_flags:
		state_flags.flag_changed.connect(_on_flag_changed)
		state_flags.flags_cleared.connect(_on_flags_cleared)
	_update_gate(true)

func is_open() -> bool:
	if not enabled:
		return false
	if not state_flags:
		return true
	for key in required_true_flags:
		if not state_flags.get_flag(key, false):
			return false
	for key in required_false_flags:
		if state_flags.get_flag(key, false):
			return false
	return true

func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_update_gate(false)

func _on_flags_cleared() -> void:
	_update_gate(false)

func _update_gate(force_emit: bool) -> void:
	var now_open := is_open()
	if force_emit or now_open != _is_open_cached:
		_is_open_cached = now_open
		gate_changed.emit(now_open)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_open": is_open(),
		"required_true_flags": required_true_flags,
		"required_false_flags": required_false_flags,
		"has_state_flags": state_flags != null,
	}
