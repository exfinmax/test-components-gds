extends Area2D
class_name InteractableComponent
## 交互组件（Gameplay/Common 层）
## 作用：抽象“可交互对象”，统一提示显示、交互触发和可用状态。

signal enabled_changed(is_enabled: bool)
signal focused_changed(focused: bool, interactor: Node)
signal interacted(interactor: Node)

var enabled: bool = true:
	set(v):
		if enabled == v:
			return
		enabled = v
		monitoring = v
		monitorable = v
		enabled_changed.emit(v)

@export var interaction_id: StringName = &""
@export var prompt_text: String = "交互"
@export var one_shot: bool = false

var _focused_by: Node = null

func set_focused(value: bool, interactor: Node) -> void:
	if not enabled:
		return
	if value:
		_focused_by = interactor
	else:
		if interactor == _focused_by:
			_focused_by = null
	focused_changed.emit(value, interactor)

func try_interact(interactor: Node) -> bool:
	if not enabled:
		return false
	interacted.emit(interactor)
	if one_shot:
		enabled = false
	return true

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"interaction_id": interaction_id,
		"prompt_text": prompt_text,
		"one_shot": one_shot,
		"focused": _focused_by != null,
	}
