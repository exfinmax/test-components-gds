extends Node
class_name GlobalEventBus

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

func clear_event(event_name: StringName) -> void:
	_listeners.erase(event_name)

func clear_all() -> void:
	_listeners.clear()
