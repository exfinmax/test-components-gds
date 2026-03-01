extends Node
## 全局时间控制器
## 管理游戏时间缩放和局部时间域

signal time_scale_changed(new_scale: float)
signal time_paused
signal time_resumed

## 全局时间缩放（1.0 = 正常速度）
var time_scale: float = 1.0:
	set(value):
		time_scale = clampf(value, 0.0, 10.0)
		Engine.time_scale = time_scale
		time_scale_changed.emit(time_scale)

## 是否暂停
var is_paused: bool = false:
	set(value):
		if is_paused == value:
			return
		is_paused = value
		if is_paused:
			pause()
		else:
			resume()

## 排除列表：不受时间缩放影响的节点路径
var _excluded_nodes: Array[NodePath] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 设置时间缩放
func set_time_scale(scale: float, duration: float = 0.0) -> void:
	if duration <= 0.0:
		time_scale = scale
	else:
		var tween = create_tween()
		tween.tween_property(self, "time_scale", scale, duration)

## 暂停游戏
func pause() -> void:
	get_tree().paused = true
	time_paused.emit()

## 恢复游戏
func resume() -> void:
	get_tree().paused = false
	time_resumed.emit()

## 添加排除节点（不受时间缩放影响）
func exclude_node(node_path: NodePath) -> void:
	if node_path not in _excluded_nodes:
		_excluded_nodes.append(node_path)

## 移除排除节点
func include_node(node_path: NodePath) -> void:
	_excluded_nodes.erase(node_path)

## 检查节点是否被排除
func is_node_excluded(node_path: NodePath) -> bool:
	return node_path in _excluded_nodes

## 子弹时间效果
func bullet_time(scale: float = 0.3, duration: float = 1.0) -> void:
	set_time_scale(scale, 0.1)
	await get_tree().create_timer(duration).timeout
	set_time_scale(1.0, 0.2)

## 时间停止效果
func freeze_time(duration: float) -> void:
	time_scale = 0.0
	await get_tree().create_timer(duration).timeout
	time_scale = 1.0
