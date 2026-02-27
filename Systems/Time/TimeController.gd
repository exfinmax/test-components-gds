extends Node
## 全局时间控制器 - 控制时间流速，支持排除特定节点
##
## 用法:
##   TimeController.engine_time_scale = 0.5  # 引擎慢放（物理 + 渲染）
##   TimeController.audio_time_scale = 0.5   # 音频慢放（独立控制）
##   TimeController.set_all_time_scale(0.5)  # 同时设置两者（旧行为）
##   TimeController.exclude(player)          # player 不受影响
##   TimeController.include(player)          # player 重新受影响
##
## 被排除节点在 _process/_physics_process 中使用补偿 delta:
##   func _process(delta: float) -> void:
##       var real_delta = TimeController.get_real_delta(delta)

## 引擎时间缩放（影响 Engine.time_scale 和 physics_ticks_per_second）
var engine_time_scale: float = 1.0:
	set(v):
		if v < 0: return
		engine_time_scale = v
		Engine.time_scale = v
		_compensate_excluded_audio()

## 音频时间缩放（独立于引擎时间缩放）
var audio_time_scale: float = 1.0:
	set(v):
		if v < 0: return
		audio_time_scale = v
		AudioServer.playback_speed_scale = v
		_compensate_excluded_audio()

## 同时设置引擎和音频时间缩放（等同于旧版 global_time_scale 行为）
func set_all_time_scale(scale: float) -> void:
	if scale < 0: return
	# 先设置音频（不触发二次补偿），再设引擎（会触发一次补偿）
	audio_time_scale = scale
	engine_time_scale = scale

## 被排除的节点列表（不受时间缩放影响）
var _excluded_nodes: Array[Node] = []

#region 排除/包含 API

## 将节点加入排除列表，其 process delta 和子树中的音频不受全局时间缩放影响
func exclude(node: Node) -> void:
	if node in _excluded_nodes: return
	_excluded_nodes.append(node)
	node.tree_exiting.connect(_on_excluded_node_exiting.bind(node), CONNECT_ONE_SHOT)
	_compensate_audio_for_node(node)

## 将节点从排除列表移除，恢复受全局时间缩放影响
func include(node: Node) -> void:
	_excluded_nodes.erase(node)
	_restore_audio_for_node(node)

## 节点是否在排除列表中
func is_excluded(node: Node) -> bool:
	return node in _excluded_nodes

#endregion

#region Delta 补偿

## 获取真实（未缩放的）delta。被排除节点在 _process/_physics_process 中调用此方法
## 传入引擎给的 delta，返回补偿后的真实 delta
func get_real_delta(scaled_delta: float) -> float:
	if engine_time_scale <= 0.0: return 0.0
	return scaled_delta / engine_time_scale

## 获取当前补偿因子（1.0 / engine_time_scale）
func get_compensation_factor() -> float:
	if engine_time_scale <= 0.0: return 1.0
	return 1.0 / engine_time_scale

#endregion

func frame_freeze(time_scale: float, duration: float) -> void :
	engine_time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	engine_time_scale = 1

#region 音频补偿（内部）

func _compensate_excluded_audio() -> void:
	for node in _excluded_nodes:
		if is_instance_valid(node):
			_compensate_audio_for_node(node)

func _compensate_audio_for_node(node: Node) -> void:
	var factor := get_compensation_factor()
	for player in _find_audio_players(node):
		# 存储原始 pitch_scale（仅首次）
		if not player.has_meta("_original_pitch_scale"):
			player.set_meta("_original_pitch_scale", player.pitch_scale)
		var original: float = player.get_meta("_original_pitch_scale")
		player.pitch_scale = original * factor

func _restore_audio_for_node(node: Node) -> void:
	for player in _find_audio_players(node):
		if player.has_meta("_original_pitch_scale"):
			player.pitch_scale = player.get_meta("_original_pitch_scale")
			player.remove_meta("_original_pitch_scale")

func _find_audio_players(node: Node) -> Array:
	var result: Array = []
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_audio_players(child))
	return result

func _on_excluded_node_exiting(node: Node) -> void:
	_excluded_nodes.erase(node)

#endregion

func get_component_data() -> Dictionary:
	var excluded_names: Array[String] = []
	for node in _excluded_nodes:
		if is_instance_valid(node):
			excluded_names.append(node.name)
	return {
		"engine_time_scale": engine_time_scale,
		"audio_time_scale": audio_time_scale,
		"excluded_count": _excluded_nodes.size(),
		"excluded_nodes": excluded_names,
		"engine_time_scale_actual": Engine.time_scale,
		"audio_playback_speed": AudioServer.playback_speed_scale,
		"physics_ticks": Engine.physics_ticks_per_second,
	}
