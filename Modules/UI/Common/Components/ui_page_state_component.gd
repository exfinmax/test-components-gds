extends Node
class_name UIPageStateComponent
## UI 页面状态组件（UI 通用层）
## 作用：统一“菜单/背包/地图/暂停”等页面状态切换，避免多处手写显示隐藏逻辑。

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: StringName = &"main"
@export var nodes_by_state: Dictionary = {}
@export var hide_unknown_nodes: bool = true

var _current_state: StringName = &""

func _ready() -> void:
	if initial_state != StringName():
		set_state(initial_state)

func get_state() -> StringName:
	return _current_state

func set_state(next_state: StringName) -> void:
	if _current_state == next_state:
		return
	var prev := _current_state
	_current_state = next_state
	_apply_state(next_state)
	state_changed.emit(prev, next_state)

func _apply_state(state_name: StringName) -> void:
	var visible_paths: Array[NodePath] = []
	if nodes_by_state.has(state_name):
		var arr = nodes_by_state[state_name]
		if arr is Array:
			for item in arr:
				if item is NodePath:
					visible_paths.append(item)

	if hide_unknown_nodes:
		for key in nodes_by_state.keys():
			var entries = nodes_by_state[key]
			if entries is Array:
				for p in entries:
					if p is NodePath:
						_set_visible_by_path(p, false)

	for path in visible_paths:
		_set_visible_by_path(path, true)

func _set_visible_by_path(path: NodePath, visible: bool) -> void:
	var node := get_node_or_null(path)
	if node == null:
		return
	if node is CanvasItem:
		node.visible = visible
	elif node.has_method("set_visible"):
		node.call("set_visible", visible)

