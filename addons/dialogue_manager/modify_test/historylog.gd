class_name DialogueHistoryLog
extends Control
## ════════════════════════════════════════════════════════════════
##  DialogueHistoryLog — 对话历史记录面板
## ════════════════════════════════════════════════════════════════
##
## 使用 RichTextLabel + BBCode 记录对话历史，支持：
##   • 角色台词（带彩色角色名）
##   • 玩家选项（带前缀符号）
##   • 系统消息（斜体、灰色）
##   • 章节分隔线
##
## 使用方式：
##   history_log.add_dialogue_line("Nathan", "你好，这是台词。")
##   history_log.add_player_response("我选第一个")
##   history_log.add_system_message("【第一章 开始】")
##   history_log.add_chapter_divider("第二章：转折")
## ════════════════════════════════════════════════════════════════

## 面板可见性发生变化时触发（用于动画等）
signal visibility_toggled(is_visible: bool)

# ──────────────────────────────────────────────
# 配置
# ──────────────────────────────────────────────

## 默认角色名颜色
@export var character_name_color: Color = Color(0.4, 0.8, 1.0)

## 玩家选项颜色
@export var player_response_color: Color = Color(0.6, 1.0, 0.6)

## 系统消息颜色
@export var system_message_color: Color = Color(0.7, 0.7, 0.7)

## 章节标题颜色
@export var chapter_title_color: Color = Color(1.0, 0.85, 0.4)

## 是否在底部显示最新内容（自动滚动到底部）
@export var auto_scroll_to_bottom: bool = true

## 最大保存的历史条数（0 = 无限制）
@export var max_entries: int = 200

# ──────────────────────────────────────────────
# 内部状态
# ──────────────────────────────────────────────

var _entries: Array[String] = []

## 角色名 → 颜色的自定义映射（未设置时使用 character_name_color）
var _character_colors: Dictionary = {}

@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _rich_label: RichTextLabel = %RichLabel
@onready var _close_button: Button = %CloseButton

# ──────────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────────

func _ready() -> void:
	if is_instance_valid(_close_button):
		_close_button.pressed.connect(hide_log)
	hide()

# ──────────────────────────────────────────────
# 公共 API
# ──────────────────────────────────────────────

## 添加角色台词（character 为空时不显示角色名）
func add_dialogue_line(character: String, text: String) -> void:
	var color := _character_colors.get(character, character_name_color)
	var hex := color.to_html(false)
	var entry: String
	if character.is_empty():
		entry = "[color=#aaaaaa]%s[/color]" % _escape(text)
	else:
		entry = "[color=#%s][b]%s[/b][/color]  %s" % [hex, _escape(character), _escape(text)]
	_add_entry(entry)

## 添加玩家选项
func add_player_response(text: String) -> void:
	var hex := player_response_color.to_html(false)
	var entry := "[color=#%s]▶ %s[/color]" % [hex, _escape(text)]
	_add_entry(entry)

## 添加系统消息（斜体灰色）
func add_system_message(text: String) -> void:
	var hex := system_message_color.to_html(false)
	var entry := "[color=#%s][i]%s[/i][/color]" % [hex, _escape(text)]
	_add_entry(entry)

## 添加章节分隔线（带标题）
func add_chapter_divider(title: String = "") -> void:
	var hex := chapter_title_color.to_html(false)
	var entry: String
	if title.is_empty():
		entry = "[color=#555555]────────────────────────[/color]"
	else:
		entry = "[center][color=#%s][b]── %s ──[/b][/color][/center]" % [hex, _escape(title)]
	_add_entry(entry)

## 为指定角色设置专属颜色
func set_character_color(character: String, color: Color) -> void:
	_character_colors[character] = color

## 清空所有历史
func clear_history() -> void:
	_entries.clear()
	if is_instance_valid(_rich_label):
		_rich_label.text = ""

## 显示历史面板
func show_log() -> void:
	show()
	visibility_toggled.emit(true)
	if auto_scroll_to_bottom:
		await get_tree().process_frame
		_scroll_to_bottom()

## 隐藏历史面板
func hide_log() -> void:
	hide()
	visibility_toggled.emit(false)

## 切换历史面板的显示状态
func toggle_log() -> void:
	if visible:
		hide_log()
	else:
		show_log()

## 获取所有历史记录（BBCode 格式）
func get_history() -> Array[String]:
	return _entries.duplicate()

# ──────────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────────

func _add_entry(bbcode_line: String) -> void:
	_entries.append(bbcode_line)
	if max_entries > 0 and _entries.size() > max_entries:
		_entries = _entries.slice(_entries.size() - max_entries)
		_rebuild_text()
	else:
		if is_instance_valid(_rich_label):
			_rich_label.text += bbcode_line + "\n"
	if auto_scroll_to_bottom and visible:
		await get_tree().process_frame
		_scroll_to_bottom()

func _rebuild_text() -> void:
	if not is_instance_valid(_rich_label):
		return
	_rich_label.text = "\n".join(_entries) + "\n"

func _scroll_to_bottom() -> void:
	if is_instance_valid(_scroll_container):
		_scroll_container.scroll_vertical = _scroll_container.get_v_scroll_bar().max_value

## 转义 BBCode 特殊字符（防止文本被意外解析为标签）
func _escape(text: String) -> String:
	return text.replace("[", "[[")
