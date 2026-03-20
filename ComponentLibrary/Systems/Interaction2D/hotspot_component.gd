extends Area2D
class_name HotspotComponent

signal enabled_changed(is_enabled: bool)
signal focus_changed(is_focused: bool, interactor: Node)
signal triggered(interactor: Node)

@export var prompt_text: String = "交互"
@export var interaction_action: StringName = &"interact"
@export var click_to_trigger: bool = false

var enabled: bool = true:
	set(value):
		if enabled == value:
			return
		enabled = value
		monitoring = value
		monitorable = value
		enabled_changed.emit(value)

var _focused_by: Node = null

func set_focus(is_focused: bool, interactor: Node) -> void:
	if not enabled:
		return
	if is_focused:
		_focused_by = interactor
	elif _focused_by == interactor:
		_focused_by = null
	focus_changed.emit(is_focused, interactor)

func try_trigger(interactor: Node) -> bool:
	if not enabled:
		return false
	triggered.emit(interactor)
	return true

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"prompt_text": prompt_text,
		"interaction_action": String(interaction_action),
		"focused": _focused_by != null,
	}
