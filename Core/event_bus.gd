extends Node

## 动态事件监听表: { event_name: Array[Callable] }
var _listeners: Dictionary = {}

func subscribe(event_name: StringName, callback: Callable) -> void:
	if event_name == StringName() or not callback.is_valid():
		return
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	var list: Array = _listeners[event_name]
	if callback not in list:
		list.append(callback)

func unsubscribe(event_name: StringName, callback: Callable) -> void:
	if not _listeners.has(event_name):
		return
	var list: Array = _listeners[event_name]
	list.erase(callback)
	if list.is_empty():
		_listeners.erase(event_name)

func emit_event(event_name: StringName, ...args: Array) -> void:
	if not _listeners.has(event_name):
		return

	var list: Array = _listeners[event_name].duplicate()
	for callback: Callable in list:
		if not callback.is_valid():
			continue
		if args.is_empty():
			callback.call()
		else:
			callback.callv(args)

func subscribe_once(event_name: StringName, callback: Callable) -> void:
	var wrapper: Callable
	wrapper = func(payload = null) -> void:
		if payload == null:
			callback.call()
		else:
			callback.call(payload)
		unsubscribe(event_name, wrapper)
	subscribe(event_name, wrapper)

func has_subscribers(event_name: StringName) -> bool:
	return _listeners.has(event_name) and not (_listeners[event_name] as Array).is_empty()

func clear_event(event_name: StringName) -> void:
	_listeners.erase(event_name)

func clear_all() -> void:
	_listeners.clear()

func get_component_data() -> Dictionary:
	var event_counts := {}
	for event_name in _listeners:
		event_counts[event_name] = (_listeners[event_name] as Array).size()
	return {
		"type": "EventBus",
		"dynamic_events": _listeners.size(),
		"event_listener_counts": event_counts,
	}
