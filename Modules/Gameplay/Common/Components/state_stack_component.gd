extends Node
class_name StateStackComponent

signal state_pushed(state_id: StringName)
signal state_popped(state_id: StringName)
signal state_changed(current_state: StringName)

@export var initial_state: StringName = &"idle"
@export var allow_duplicate_top: bool = false

var _stack: Array[StringName] = []

func _ready() -> void:
	if initial_state != StringName():
		push_state(initial_state)

func current_state() -> StringName:
	if _stack.is_empty():
		return StringName()
	return _stack[_stack.size() - 1]

func depth() -> int:
	return _stack.size()

func get_stack_snapshot() -> Array[StringName]:
	return _stack.duplicate()

func push_state(state_id: StringName) -> void:
	if state_id == StringName():
		return
	if not allow_duplicate_top and current_state() == state_id:
		return
	_stack.append(state_id)
	state_pushed.emit(state_id)
	state_changed.emit(state_id)

func pop_state() -> StringName:
	if _stack.is_empty():
		return StringName()
	var old: StringName = _stack.pop_back()
	state_popped.emit(old)
	state_changed.emit(current_state())
	return old

func replace_state(state_id: StringName) -> void:
	if state_id == StringName():
		return
	if _stack.is_empty():
		push_state(state_id)
		return
	if current_state() == state_id:
		return
	_stack[_stack.size() - 1] = state_id
	state_changed.emit(state_id)

func clear_to_initial() -> void:
	_stack.clear()
	if initial_state != StringName():
		_stack.append(initial_state)
	state_changed.emit(current_state())

func clear_states() -> void:
	_stack.clear()
	state_changed.emit(StringName())

func has_state(state_id: StringName) -> bool:
	return _stack.has(state_id)

func get_component_data() -> Dictionary:
	var stack_strings := PackedStringArray()
	for state in _stack:
		stack_strings.append(String(state))
	return {
		"initial_state": String(initial_state),
		"allow_duplicate_top": allow_duplicate_top,
		"depth": depth(),
		"current_state": String(current_state()),
		"stack": stack_strings,
	}
