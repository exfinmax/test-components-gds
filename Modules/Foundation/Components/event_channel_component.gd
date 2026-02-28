extends Node
class_name EventChannelComponent

signal event_emitted(event_id: StringName, payload: Dictionary)

@export var channel_name: StringName = &"global"
@export var forward_to_global_bus: bool = true
@export var emit_local_signal: bool = true

func emit_event(event_id: StringName, payload: Dictionary = {}) -> void:
	var data := payload.duplicate(true)

	if emit_local_signal:
		event_emitted.emit(event_id, data)

	if forward_to_global_bus:
		var bus := _get_event_bus()
		if bus != null:
			var full_event_id := _compose_event_id(event_id)
			bus.call("emit_event", full_event_id, data)

func listen(callable_ref: Callable) -> void:
	if not event_emitted.is_connected(callable_ref):
		event_emitted.connect(callable_ref)

func unlisten(callable_ref: Callable) -> void:
	if event_emitted.is_connected(callable_ref):
		event_emitted.disconnect(callable_ref)

func subscribe_global(event_id: StringName, callable_ref: Callable) -> bool:
	var bus := _get_event_bus()
	if bus == null:
		return false
	bus.call("subscribe", _compose_event_id(event_id), callable_ref)
	return true

func unsubscribe_global(event_id: StringName, callable_ref: Callable) -> bool:
	var bus := _get_event_bus()
	if bus == null:
		return false
	bus.call("unsubscribe", _compose_event_id(event_id), callable_ref)
	return true

func _compose_event_id(event_id: StringName) -> StringName:
	if channel_name == StringName():
		return event_id
	return StringName("%s.%s" % [channel_name, event_id])

func _get_event_bus() -> Node:
	var bus := get_node_or_null("/root/EventBus")
	if bus == null or not bus.has_method("emit_event"):
		return null
	return bus
