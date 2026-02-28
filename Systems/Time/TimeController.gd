extends Node

signal frame_freeze_started(time_scale: float, duration: float)
signal frame_freeze_ended

## 引擎时间缩放（影响 Engine.time_scale）
var engine_time_scale: float = 1.0:
	set(v):
		if v < 0.0:
			return
		engine_time_scale = v
		Engine.time_scale = v
		_compensate_excluded_audio()

## 音频时间缩放（独立于引擎时间）
var audio_time_scale: float = 1.0:
	set(v):
		if v < 0.0:
			return
		audio_time_scale = v
		AudioServer.playback_speed_scale = v
		_compensate_excluded_audio()

## 不受全局时间影响的节点
var _excluded_nodes: Array[Node] = []

## 冻结帧并发计数
var _freeze_stack_count: int = 0
var _freeze_restore_scale: float = 1.0

func set_all_time_scale(scale: float) -> void:
	if scale < 0.0:
		return
	audio_time_scale = scale
	engine_time_scale = scale

func exclude(node: Node) -> void:
	if node == null or node in _excluded_nodes:
		return
	_excluded_nodes.append(node)
	node.tree_exiting.connect(_on_excluded_node_exiting.bind(node), CONNECT_ONE_SHOT)
	_compensate_audio_for_node(node)

func include(node: Node) -> void:
	if node == null:
		return
	_excluded_nodes.erase(node)
	_restore_audio_for_node(node)

func is_excluded(node: Node) -> bool:
	return node in _excluded_nodes

func get_real_delta(scaled_delta: float) -> float:
	if engine_time_scale <= 0.0:
		return 0.0
	return scaled_delta / engine_time_scale

func get_compensation_factor() -> float:
	if engine_time_scale <= 0.0:
		return 1.0
	return 1.0 / engine_time_scale

## 全局冻结帧入口（并发安全）
func frame_freeze(time_scale: float = 0.01, duration: float = 0.05) -> void:
	var safe_scale := maxf(time_scale, 0.0)
	var safe_duration := maxf(duration, 0.0)

	if _freeze_stack_count == 0:
		_freeze_restore_scale = engine_time_scale
	_freeze_stack_count += 1
	engine_time_scale = safe_scale
	frame_freeze_started.emit(safe_scale, safe_duration)

	if safe_duration <= 0.0:
		return

	var timer := get_tree().create_timer(safe_duration, true, false, true)
	timer.timeout.connect(_on_frame_freeze_timeout, CONNECT_ONE_SHOT)

func cancel_frame_freeze() -> void:
	if _freeze_stack_count <= 0:
		return
	_freeze_stack_count = 0
	engine_time_scale = _freeze_restore_scale
	frame_freeze_ended.emit()

func is_frame_freeze_active() -> bool:
	return _freeze_stack_count > 0

func _on_frame_freeze_timeout() -> void:
	_freeze_stack_count = maxi(_freeze_stack_count - 1, 0)
	if _freeze_stack_count == 0:
		engine_time_scale = _freeze_restore_scale
		frame_freeze_ended.emit()

func _compensate_excluded_audio() -> void:
	for node in _excluded_nodes:
		if is_instance_valid(node):
			_compensate_audio_for_node(node)

func _compensate_audio_for_node(node: Node) -> void:
	var factor := get_compensation_factor()
	for player in _find_audio_players(node):
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
		"freeze_active": is_frame_freeze_active(),
		"freeze_stack_count": _freeze_stack_count,
	}
