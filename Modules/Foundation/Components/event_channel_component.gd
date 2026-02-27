extends Node
class_name EventChannelComponent
## 事件通道（Foundation 层）
## 作用：提供解耦的轻量事件总线，避免模块之间直接硬引用。

signal event_emitted(event_id: StringName, payload: Dictionary)

@export var channel_name: StringName = &"global"

func emit_event(event_id: StringName, payload: Dictionary = {}) -> void:
	event_emitted.emit(event_id, payload)

func listen(callable_ref: Callable) -> void:
	if not event_emitted.is_connected(callable_ref):
		event_emitted.connect(callable_ref)

func unlisten(callable_ref: Callable) -> void:
	if event_emitted.is_connected(callable_ref):
		event_emitted.disconnect(callable_ref)

