class_name ModifyBalloon
extends CanvasLayer
## ════════════════════════════════════════════════════════════════
##  ModifyBalloon — 增强版对话气泡框
## ════════════════════════════════════════════════════════════════
##
## 在 DialogueManagerExampleBalloon 基础上扩展以下功能：
##   • 自动推进（auto_advance）— 打字完成后自动进入下一行
##   • 快进（fast_forward）     — 加速打字动画
##   • 慢放（slow_motion）      — 减速打字动画
##   • 查看历史记录             — 切换 DialogueHistoryLog 面板
##   • 气泡指示箭头             — 可配置的方向箭头
##   • 对话进度自动保存          — 集成 DialogueSaveModule
##
## 使用方式：
##   $ModifyBalloon.start(dialogue_resource, "start", [self])
## ════════════════════════════════════════════════════════════════

## 对话资源
@export var dialogue_resource: DialogueResource

## 启动时自动从该标题开始
@export var start_from_title: String = ""

## 是否随节点进入场景时自动开始
@export var auto_start: bool = false

## 是否阻断其他输入
@export var will_block_other_input: bool = true

## 推进对话的输入动作
@export var next_action: StringName = &"ui_accept"

## 跳过打字的输入动作
@export var skip_action: StringName = &"ui_cancel"

## 查看历史记录的输入动作（默认 H 键）
@export var history_action: StringName = &"ui_text_submit"

# ── 新增功能配置 ───────────────────────────────

## 打字完成后自动推进（无需按键）
@export var auto_advance: bool = false

## 自动推进延迟（秒）
@export var auto_advance_delay: float = 1.5

## 快进速度倍率（按住时生效）
@export var fast_forward_speed: float = 5.0

## 慢放速度倍率（按住时生效）
@export var slow_motion_speed: float = 0.3

## 快进的输入动作
@export var fast_forward_action: StringName = &"ui_page_down"

## 慢放的输入动作
@export var slow_motion_action: StringName = &"ui_page_up"

## 是否集成 DialogueSaveModule 自动保存进度
@export var auto_save_progress: bool = true

## 存档章节名（显示在存档槽中）
@export var chapter_name: String = ""

# ──────────────────────────────────────────────
# 内部状态
# ──────────────────────────────────────────────

var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()
var _auto_advance_timer: float = 0.0
var _is_auto_advancing: bool = false
var _base_typing_speed: float = 0.02
var _current_speed_multiplier: float = 1.0

var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

var mutation_cooldown: Timer = Timer.new()

# ── 子节点 ──────────────────────────────────

@onready var balloon: Control            = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel  = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var progress: Polygon2D         = %Progress
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var history_log: DialogueHistoryLog = %HistoryLog
@onready var toolbar: HBoxContainer      = %Toolbar
@onready var auto_advance_indicator: Label = %AutoAdvanceIndicator
@onready var speed_indicator: Label      = %SpeedIndicator

# ──────────────────────────────────────────────
# 生命周期
# ──────────────────────────────────────────────

func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	_base_typing_speed = dialogue_label.seconds_per_step

	_update_indicators()

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, "ModifyBalloon: auto_start requires a valid dialogue_resource")
		start()


func _process(delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = (
			not dialogue_label.is_typing
			and dialogue_line.responses.size() == 0
			and not dialogue_line.has_tag("voice")
			and not is_auto_advancing
		)

	# 快进 / 慢放（持续按住时动态调整速度）
	var target_multiplier := 1.0
	if Input.is_action_pressed(fast_forward_action):
		target_multiplier = fast_forward_speed
	elif Input.is_action_pressed(slow_motion_action):
		target_multiplier = slow_motion_speed

	if target_multiplier != _current_speed_multiplier:
		_current_speed_multiplier = target_multiplier
		dialogue_label.seconds_per_step = _base_typing_speed / _current_speed_multiplier
		_update_indicators()

	# 自动推进倒计时
	if _is_auto_advancing:
		_auto_advance_timer -= delta
		if _auto_advance_timer <= 0.0:
			_is_auto_advancing = false
			_update_indicators()
			next(dialogue_line.next_id)


var is_auto_advancing: bool:
	get: return _is_auto_advancing

# ──────────────────────────────────────────────
# 输入处理
# ──────────────────────────────────────────────

func _unhandled_input(_event: InputEvent) -> void:
	if will_block_other_input:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()

# ──────────────────────────────────────────────
# 对话 API
# ──────────────────────────────────────────────

## 开始对话
func start(
		with_dialogue_resource: DialogueResource = null,
		title: String = "",
		extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	history_log.clear_history()
	if not chapter_name.is_empty():
		history_log.add_chapter_divider(chapter_name)
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


## 应用新的对话行到 UI
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	_is_auto_advancing = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# 记录到历史
	_record_to_history(dialogue_line)

	# 自动保存进度
	if auto_save_progress:
		_save_progress()

	# 后续行为
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = (
			dialogue_line.text.length() * 0.02
			if dialogue_line.time == "auto"
			else dialogue_line.time.to_float()
		)
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	elif auto_advance:
		_is_auto_advancing = true
		_auto_advance_timer = auto_advance_delay
		_update_indicators()
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

	_update_indicators()


## 进入下一行
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)

# ──────────────────────────────────────────────
# 功能 API
# ──────────────────────────────────────────────

## 切换自动推进功能
func toggle_auto_advance() -> void:
	auto_advance = not auto_advance
	_update_indicators()

## 快进（立即跳过打字动画到最终文本）
func fast_forward() -> void:
	if dialogue_label.is_typing:
		dialogue_label.skip_typing()

## 切换历史记录面板
func toggle_history() -> void:
	history_log.toggle_log()

# ──────────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────────

func _update_indicators() -> void:
	if not is_node_ready():
		return
	if is_instance_valid(auto_advance_indicator):
		auto_advance_indicator.text = "⟳ 自动" if auto_advance else ""
		auto_advance_indicator.visible = auto_advance
	if is_instance_valid(speed_indicator):
		if _current_speed_multiplier > 1.5:
			speed_indicator.text = "⏩ 快进"
			speed_indicator.show()
		elif _current_speed_multiplier < 0.7:
			speed_indicator.text = "⏪ 慢放"
			speed_indicator.show()
		else:
			speed_indicator.hide()

func _record_to_history(line: DialogueLine) -> void:
	if not is_instance_valid(history_log):
		return
	history_log.add_dialogue_line(line.character, line.text)

func _save_progress() -> void:
	if Engine.has_singleton("SaveSystem"):
		var sys: Node = Engine.get_singleton("SaveSystem")
		var module := sys.get_module("dialogue")
		if module is DialogueSaveModule:
			module.save_progress(
				dialogue_resource,
				dialogue_line.id,
				chapter_name,
				dialogue_line.character,
				dialogue_line.text
			)

# ──────────────────────────────────────────────
# 信号处理
# ──────────────────────────────────────────────

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	if not _mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# 查看历史记录
	if event.is_action_pressed(history_action):
		get_viewport().set_input_as_handled()
		toggle_history()
		return

	# 跳过打字
	if dialogue_label.is_typing:
		var mouse_clicked := event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_pressed  := event.is_action_pressed(skip_action)
		if mouse_clicked or skip_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	# 记录玩家选择
	if is_instance_valid(history_log):
		history_log.add_player_response(response.text)
	next(response.next_id)


func _on_auto_advance_button_toggled(toggled_on: bool) -> void:
	auto_advance = toggled_on
	_update_indicators()


func _on_history_button_pressed() -> void:
	toggle_history()
