extends Node2D
class_name TimelineSwitchComponent
## 时间线开关组件（Gameplay/Time 层）
## 作用：把“时间状态”映射为机关开关，用于时间谜题。
## 示例：只有在慢放/倒流状态时才激活门、平台、激光。

signal switched(active: bool, state: StringName)

@export var enabled: bool = true
@export var watch_state: StringName = &"slow_time"
@export var invert: bool = false

var active: bool = false

## 外部可调用：传入当前时间状态名称，组件自动判定开关。
func apply_time_state(state: StringName) -> void:
	if not enabled:
		return
	var next := (state == watch_state)
	if invert:
		next = not next
	if next == active:
		return
	active = next
	switched.emit(active, state)

func force_set(value: bool) -> void:
	if active == value:
		return
	active = value
	switched.emit(active, watch_state)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"watch_state": watch_state,
		"invert": invert,
		"active": active,
	}
