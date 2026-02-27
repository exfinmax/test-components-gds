extends Node
class_name StateStackComponent
## 状态栈（Gameplay/Common 层）
## 作用：管理可嵌套状态（如普通->交互->过场->暂停），避免布尔状态爆炸。

signal state_pushed(state_id: StringName)
signal state_popped(state_id: StringName)
signal state_changed(current_state: StringName)

@export var initial_state: StringName = &"idle"

var _stack: Array[StringName] = []

func _ready() -> void:
	if initial_state != StringName():
		push_state(initial_state)

func current_state() -> StringName:
	if _stack.is_empty():
		return StringName()
	return _stack[_stack.size() - 1]

func push_state(state_id: StringName) -> void:
	if state_id == StringName():
		return
	_stack.append(state_id)
	state_pushed.emit(state_id)
	state_changed.emit(current_state())

func pop_state() -> StringName:
	if _stack.is_empty():
		return StringName()
	var old := _stack.pop_back()
	state_popped.emit(old)
	state_changed.emit(current_state())
	return old

func clear_states() -> void:
	while not _stack.is_empty():
		pop_state()

func has_state(state_id: StringName) -> bool:
	return _stack.has(state_id)

