class_name ResponseModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## ResponseModule — 响应选项模块
## ════════════════════════════════════════════════════════════════
##
## 持有 DialogueResponsesMenu，处理响应选项的显示与玩家选择。
## 玩家选择后通过事件总线广播 response_selected 事件。
## ════════════════════════════════════════════════════════════════

## 玩家选择响应时发出
signal response_selected(response: DialogueResponse)

## 响应菜单节点引用（由场景配置）
var responses_menu: DialogueResponsesMenu
## 对话标签节点引用（用于在打字结束后显示选项）
var dialogue_label: DialogueLabel

# ════════════════════════════════════════════════════════════════
# 生命周期
# ════════════════════════════════════════════════════════════════

func setup(balloon: BaseBalloon) -> void:
	super.setup(balloon)
	# 连接响应菜单信号
	if is_instance_valid(responses_menu):
		if not responses_menu.response_selected.is_connected(_on_response_selected):
			responses_menu.response_selected.connect(_on_response_selected)

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "response"

func on_dialogue_line_changed(line: DialogueLine) -> void:
	if not is_instance_valid(responses_menu):
		return
	
	if line.responses.size() > 0:
		responses_menu.hide()
		responses_menu.responses = line.responses
		if is_instance_valid(dialogue_label) and not line.text.is_empty():
			await dialogue_label.finished_typing
		if not is_instance_valid(_balloon) or _balloon.get_current_line() != line:
			return
		responses_menu.show()
		responses_menu.configure_focus()
	else:
		responses_menu.hide()

func on_dialogue_ended() -> void:
	if is_instance_valid(responses_menu):
		responses_menu.hide()

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

func _on_response_selected(response: DialogueResponse) -> void:
	# 推进对话
	if is_instance_valid(_balloon):
		_balloon.next(response.next_id)
	
	# 发出本模块信号
	response_selected.emit(response)
	
	# 通过事件总线广播（供 HistoryModule 等监听）
	if is_instance_valid(_balloon):
		_balloon.emit_module_event("response_selected", {"response": response})
