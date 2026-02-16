extends Node
## 全局事件总线 - 解耦跨场景通信
##
## 使用方式（Autoload）：
##   1. 在 project.godot 中注册为 Autoload: EventBus
##   2. 发送事件：EventBus.emit_event("player_died", {"position": pos})
##   3. 监听事件：EventBus.subscribe("player_died", _on_player_died)
##   4. 取消监听：EventBus.unsubscribe("player_died", _on_player_died)
##
## 也提供常用的预定义信号，直接 connect 即可：
##   EventBus.player_died.connect(_on_player_died)
##
## 设计原则：
##   - 用于跨场景/跨系统的全局事件
##   - 同一场景内的组件间通信应使用直接信号
##   - 避免滥用：仅用于真正需要全局广播的事件

#region 预定义信号（高频使用的全局事件）

## 玩家相关
signal player_died(data: Dictionary)
signal player_respawned(data: Dictionary)
signal player_checkpoint_reached(data: Dictionary)

## 时间控制相关（核心玩法）
signal time_scale_changed(new_scale: float)
signal time_freeze_started(duration: float)
signal time_freeze_ended
signal time_rewind_started
signal time_rewind_ended

## 游戏流程
signal level_started(level_name: String)
signal level_completed(level_name: String)
signal game_paused
signal game_resumed

## 战斗相关
signal entity_damaged(target: Node, amount: float, source: Node)
signal entity_died(entity: Node)
signal entity_healed(target: Node, amount: float)

## UI
signal ui_notification(message: String, type: String)
signal score_changed(new_score: int)

#endregion

#region 动态事件系统（自定义事件名）

## 存储动态事件的回调 {event_name: Array[Callable]}
var _listeners: Dictionary = {}

## 订阅动态事件
func subscribe(event_name: StringName, callback: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	var list: Array = _listeners[event_name]
	if callback not in list:
		list.append(callback)

## 取消订阅动态事件
func unsubscribe(event_name: StringName, callback: Callable) -> void:
	if not _listeners.has(event_name): return
	var list: Array = _listeners[event_name]
	list.erase(callback)
	if list.is_empty():
		_listeners.erase(event_name)

## 发送动态事件
func emit_event(event_name: StringName, data: Dictionary = {}) -> void:
	if not _listeners.has(event_name): return
	# 复制列表防止迭代中修改
	var list: Array = _listeners[event_name].duplicate()
	for callback: Callable in list:
		if callback.is_valid():
			callback.call(data)

## 清除某个事件的所有监听
func clear_event(event_name: StringName) -> void:
	_listeners.erase(event_name)

## 清除所有动态事件监听
func clear_all() -> void:
	_listeners.clear()

#endregion

#region 便捷方法 - 一次性监听（触发后自动取消）

func subscribe_once(event_name: StringName, callback: Callable) -> void:
	var wrapper: Callable
	wrapper = func(data: Dictionary) -> void:
		callback.call(data)
		unsubscribe(event_name, wrapper)
	subscribe(event_name, wrapper)

#endregion

#region 调试

func get_component_data() -> Dictionary:
	var event_counts := {}
	for event_name in _listeners:
		event_counts[event_name] = _listeners[event_name].size()
	return {
		"type": "EventBus",
		"dynamic_events": _listeners.size(),
		"event_listener_counts": event_counts,
	}

#endregion
