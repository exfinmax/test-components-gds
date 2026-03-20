class_name HistoryModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## HistoryModule — 历史记录模块
## ════════════════════════════════════════════════════════════════
##
## 持有 DialogueHistoryLog 引用，记录对话历史。
## 监听 response_selected 模块事件，记录玩家选项。
## ════════════════════════════════════════════════════════════════

@export_group("历史记录设置")
## 是否启用历史记录
@export var history_enabled: bool = true
## 章节名（不为空时在对话开始时添加章节分隔）
@export var chapter_name: String = ""
## 最大历史条目数（0 = 无限制）
@export_range(0, 500, 10) var max_history_entries: int = 200
## 切换历史面板的输入动作
@export var history_action: StringName = &"ui_text_submit"

## DialogueHistoryLog 节点引用（由场景配置）
var history_log: DialogueHistoryLog

## CharacterManager 引用（由场景配置，用于读取角色颜色）
var character_manager: CharacterManager

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "history"

func on_dialogue_started(_resource: DialogueResource, _title: String) -> void:
	if not history_enabled or not is_instance_valid(history_log):
		return
	
	# 配置历史记录参数
	history_log.max_entries = max_history_entries
	
	# 清空历史记录
	history_log.clear_history()
	
	# 添加章节分隔
	if not chapter_name.is_empty():
		history_log.add_chapter_divider(chapter_name)

func on_dialogue_line_changed(line: DialogueLine) -> void:
	if not history_enabled or not is_instance_valid(history_log):
		return
	
	var character := line.character
	
	# 同步角色颜色
	if is_instance_valid(character_manager) and not character.is_empty():
		var color := character_manager.get_color(character)
		history_log.set_character_color(character, color)
	
	history_log.add_dialogue_line(character, line.text)

func on_dialogue_ended() -> void:
	pass

func on_input(event: InputEvent) -> bool:
	if not history_enabled or not is_instance_valid(history_log):
		return false
	
	if event.is_action_pressed(history_action):
		history_log.toggle_log()
		return true
	
	return false

func on_module_event(event_name: String, data: Dictionary) -> void:
	if event_name == "response_selected":
		if not history_enabled or not is_instance_valid(history_log):
			return
		var response: DialogueResponse = data.get("response")
		if response != null:
			history_log.add_player_response(response.text)
