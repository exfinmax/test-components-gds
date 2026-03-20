class_name DialogueFlowController
extends RefCounted
## ════════════════════════════════════════════════════════════════
## 对话流程控制器
## ════════════════════════════════════════════════════════════════
## 负责对话的流程控制，包括开始、推进、跳转等操作

## 信号
signal dialogue_line_changed(dialogue_line: DialogueLine)
signal dialogue_ended()
signal character_changed(character_name: String)
signal response_selected(response: DialogueResponse)

## 当前状态
var current_dialogue: DialogueResource = null
var current_line: DialogueLine = null
var is_active: bool = false
var is_waiting_for_input: bool = false

## 配置
var auto_advance: bool = false
var auto_advance_delay: float = 1.0

## 开始对话
func start(dialogue_resource: DialogueResource, key: String = "", extra_game_states: Array = []) -> void:
	if dialogue_resource == null:
		push_error("DialogueFlowController: 对话资源为空")
		return
	
	current_dialogue = dialogue_resource
	is_active = true
	
	var line := await DialogueManager.get_next_dialogue_line(dialogue_resource, key, extra_game_states)
	if line == null:
		_end_dialogue()
		return
	
	current_line = line
	dialogue_line_changed.emit(line)

## 推进对话
func next(key: String = "") -> void:
	if not is_active or current_dialogue == null:
		return
	
	if current_line != null and current_line.responses.size() > 0:
		return
	
	var line := await DialogueManager.get_next_dialogue_line(current_dialogue, key)
	if line == null:
		_end_dialogue()
		return
	
	current_line = line
	dialogue_line_changed.emit(line)
	character_changed.emit(line.character)

## 选择响应
func select_response(response: DialogueResponse) -> void:
	if response == null:
		return
	
	response_selected.emit(response)
	next(response.next_id)

## 跳转到指定ID
func jump_to(id: String) -> void:
	if not is_active or current_dialogue == null:
		return
	
	var line := await DialogueManager.get_next_dialogue_line(current_dialogue, id)
	if line == null:
		_end_dialogue()
		return
	
	current_line = line
	dialogue_line_changed.emit(line)

## 结束对话
func _end_dialogue() -> void:
	current_line = null
	is_active = false
	is_waiting_for_input = false
	dialogue_ended.emit()

## 强制结束
func force_end() -> void:
	_end_dialogue()

## 获取当前角色名
func get_current_character() -> String:
	if current_line == null:
		return ""
	return current_line.character

## 获取当前对话文本
func get_current_text() -> String:
	if current_line == null:
		return ""
	return current_line.text

## 获取当前响应列表
func get_responses() -> Array:
	if current_line == null:
		return []
	return current_line.responses

## 是否有响应选项
func has_responses() -> bool:
	return current_line != null and current_line.responses.size() > 0
