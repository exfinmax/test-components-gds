extends Node
class_name TriggerRouterComponent
## 触发路由器（Gameplay/Common 层）
## 作用：将关卡触发事件按规则分发到目标组件，减少场景手工连线复杂度。

signal route_hit(route_id: StringName, payload: Dictionary)
signal route_miss(route_id: StringName, payload: Dictionary)

@export var routes: Dictionary = {}

func dispatch(route_id: StringName, payload: Dictionary = {}) -> bool:
	if not routes.has(route_id):
		route_miss.emit(route_id, payload)
		return false

	var config = routes[route_id]
	if not (config is Dictionary):
		route_miss.emit(route_id, payload)
		return false

	var target_path: NodePath = config.get("target", NodePath())
	var method_name: StringName = config.get("method", &"")
	var target := get_node_or_null(target_path)
	if target == null or method_name == StringName() or not target.has_method(method_name):
		route_miss.emit(route_id, payload)
		return false

	target.call(method_name, payload)
	route_hit.emit(route_id, payload)
	return true

