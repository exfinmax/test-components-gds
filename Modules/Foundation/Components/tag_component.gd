extends Node
class_name TagComponent
## 标签组件（Foundation 层）
## 作用：为任意节点挂载运行时标签，替代硬编码 Group/Name 判断。

signal tag_added(tag: StringName)
signal tag_removed(tag: StringName)

@export var initial_tags: Array[StringName] = []

var _tags: Dictionary = {}

func _ready() -> void:
	for tag in initial_tags:
		_tags[tag] = true

func add_tag(tag: StringName) -> void:
	if _tags.has(tag):
		return
	_tags[tag] = true
	tag_added.emit(tag)

func remove_tag(tag: StringName) -> void:
	if _tags.erase(tag):
		tag_removed.emit(tag)

func has_tag(tag: StringName) -> bool:
	return _tags.has(tag)

func get_tags() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in _tags:
		result.append(key)
	return result

func clear_tags() -> void:
	for key in _tags.keys():
		tag_removed.emit(key)
	_tags.clear()

func get_component_data() -> Dictionary:
	return {
		"count": _tags.size(),
		"tags": get_tags(),
	}
