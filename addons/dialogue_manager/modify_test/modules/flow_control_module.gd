class_name FlowControlModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## FlowControlModule — 对话流程控制模块
## ════════════════════════════════════════════════════════════════
##
## 负责：
##   • 推进对话（按键/点击）
##   • 跳过打字动画
##   • 自动推进（固定延迟 / 文本长度计算）
##   • 快进 / 慢放速度控制
##   • voice 标签自动播放并推进
##   • time 标签定时推进
## ════════════════════════════════════════════════════════════════

@export_group("输入控制")
## 推进对话的输入动作
@export var next_action: StringName = &"ui_accept"
## 跳过打字的输入动作
@export var skip_action: StringName = &"ui_cancel"

@export_group("自动推进")
## 是否启用自动推进
@export var auto_advance: bool = false
## 自动推进基础延迟（秒）
@export_range(0.5, 5.0, 0.1) var auto_advance_delay: float = 1.5
## 延迟计算方式：fixed = 固定时间，text_length = 根据文本长度计算
@export_enum("fixed", "text_length") var auto_advance_mode: String = "text_length"
## 文本长度系数（text_length 模式下使用）
@export_range(0.01, 0.1, 0.005) var auto_advance_text_multiplier: float = 0.03

@export_group("速度控制")
## 快进速度倍率
@export_range(2.0, 20.0, 0.5) var fast_forward_speed: float = 5.0
## 慢放速度倍率
@export_range(0.1, 0.8, 0.05) var slow_motion_speed: float = 0.3
## 基础打字速度（秒/字符）
@export_range(0.01, 0.1, 0.005) var base_typing_speed: float = 0.02
## 快进输入动作
@export var fast_forward_action: StringName = &"ui_page_down"
## 慢放输入动作
@export var slow_motion_action: StringName = &"ui_page_up"

## 当前速度倍率（只读，供其他模块查询）
var current_speed_multiplier: float = 1.0

## 对话标签节点引用（由场景配置）
var dialogue_label: DialogueLabel

## 语音播放器节点引用（由场景配置）
var voice_player: AudioStreamPlayer

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

var _is_auto_advancing: bool = false
var _auto_advance_timer: float = 0.0
var _is_waiting_for_input: bool = false
var _current_line: DialogueLine = null

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "flow_control"

func on_dialogue_started(_resource: DialogueResource, _title: String) -> void:
	_is_auto_advancing = false
	_auto_advance_timer = 0.0
	_is_waiting_for_input = false
	_current_line = null
	current_speed_multiplier = 1.0

func on_dialogue_line_changed(line: DialogueLine) -> void:
	_current_line = line
	_is_auto_advancing = false
	_auto_advance_timer = 0.0
	_is_waiting_for_input = false
	
	# 重置打字速度
	if is_instance_valid(dialogue_label):
		dialogue_label.seconds_per_step = base_typing_speed / current_speed_multiplier
	
	# 等待打字完成后决定是否自动推进
	if not is_instance_valid(dialogue_label) or line.text.is_empty():
		_on_typing_finished(line)
		return
	await dialogue_label.finished_typing
	if _current_line != line:
		return
	_on_typing_finished(line)

func on_dialogue_ended() -> void:
	_is_auto_advancing = false
	_is_waiting_for_input = false
	_current_line = null

func on_input(event: InputEvent) -> bool:
	if _current_line == null:
		return false
	
	# 跳过打字动画
	if is_instance_valid(dialogue_label) and dialogue_label.is_typing:
		var skip_pressed := event.is_action_pressed(skip_action)
		var mouse_clicked :bool= (event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.is_pressed())
		if skip_pressed or mouse_clicked:
			dialogue_label.skip_typing()
			return true
	
	# 推进对话（等待输入时）
	if _is_waiting_for_input and _current_line.responses.size() == 0:
		if event.is_action_pressed(next_action):
			_is_waiting_for_input = false
			_balloon.next(_current_line.next_id)
			return true
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			_is_waiting_for_input = false
			_balloon.next(_current_line.next_id)
			return true
	
	return false

# ════════════════════════════════════════════════════════════════
# 公共 API
# ════════════════════════════════════════════════════════════════

## 切换自动推进开关
func toggle_auto_advance() -> void:
	auto_advance = not auto_advance
	_balloon.emit_module_event("auto_advance_changed", {"enabled": auto_advance})

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not is_enabled:
		return
	
	# 速度控制（持续检测按键）
	var target_multiplier := 1.0
	if Input.is_action_pressed(fast_forward_action):
		target_multiplier = fast_forward_speed
	elif Input.is_action_pressed(slow_motion_action):
		target_multiplier = slow_motion_speed
	
	if target_multiplier != current_speed_multiplier:
		current_speed_multiplier = target_multiplier
		if is_instance_valid(dialogue_label):
			dialogue_label.seconds_per_step = base_typing_speed / current_speed_multiplier
		_balloon.emit_module_event("speed_changed", {"multiplier": current_speed_multiplier})
	
	# 自动推进计时
	if _is_auto_advancing:
		_auto_advance_timer -= delta
		if _auto_advance_timer <= 0.0:
			_is_auto_advancing = false
			if is_instance_valid(_balloon) and _current_line != null:
				_balloon.next(_current_line.next_id)

## 打字完成后的处理逻辑
func _on_typing_finished(line: DialogueLine) -> void:
	if _current_line != line:
		return

	if line.responses.size() > 0:
		# 有响应选项，等待玩家选择
		return

	if line.has_tag("voice"):
		_handle_voice_tag(line)
		return

	if line.time != "":
		_handle_time_tag(line)
		return
	
	if auto_advance:
		# 启动自动推进计时
		_is_auto_advancing = true
		if auto_advance_mode == "text_length":
			_auto_advance_timer = max(auto_advance_delay, line.text.length() * auto_advance_text_multiplier)
		else:
			_auto_advance_timer = auto_advance_delay
		_balloon.emit_module_event("auto_advance_changed", {"enabled": true})
	else:
		_is_waiting_for_input = true

## 处理 voice 标签
func _handle_voice_tag(line: DialogueLine) -> void:
	if is_instance_valid(voice_player):
		var voice_path := line.get_tag_value("voice")
		if not voice_path.is_empty():
			voice_player.stream = load(voice_path)
			voice_player.play()
			await voice_player.finished
	_balloon.next(line.next_id)

## 处理 time 标签
func _handle_time_tag(line: DialogueLine) -> void:
	var time: float
	if line.time == "auto":
		time = line.text.length() * base_typing_speed
	else:
		time = line.time.to_float()
	await get_tree().create_timer(time).timeout
	if is_instance_valid(_balloon) and _current_line == line:
		_balloon.next(line.next_id)
