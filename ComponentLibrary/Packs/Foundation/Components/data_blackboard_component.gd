extends Node
class_name DataBlackboardComponent
## 数据黑板（Foundation 层）
## 作用：提供 key-value 共享上下文，减少组件之间直接依赖。

signal value_changed(key: StringName, value: Variant)
signal value_removed(key: StringName)

var _data: Dictionary = {}

func set_value(key: StringName, value: Variant) -> void:
	if key == StringName():
		return
	_data[key] = value
	value_changed.emit(key, value)

func get_value(key: StringName, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)

func has_value(key: StringName) -> bool:
	return _data.has(key)

func remove_value(key: StringName) -> void:
	if not _data.has(key):
		return
	_data.erase(key)
	value_removed.emit(key)

func clear_all() -> void:
	for key in _data.keys():
		value_removed.emit(key)
	_data.clear()

