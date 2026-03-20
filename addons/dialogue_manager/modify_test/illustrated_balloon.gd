class_name IllustratedBalloon
extends CanvasLayer
## ════════════════════════════════════════════════════════════════
## 立绘气球组件
## ════════════════════════════════════════════════════════════════
## 使用组合模式，整合各功能组件

## 信号
signal dialogue_line_changed(dialogue_line: DialogueLine)
signal dialogue_ended()
signal character_changed(character: String)

## 子节点引用
@onready var balloon: Control = $Balloon
@onready var dialogue_label: DialogueLabel = $Balloon/Margin/Panel/VBox/DialogueLabel
@onready var character_label: RichTextLabel = $Balloon/Margin/Panel/VBox/CharacterLabel
@onready var responses_menu: DialogueResponsesMenu = $Balloon/ResponsesMenu
@onready var history_log: DialogueHistoryLog = $Balloon/HistoryLog
@onready var auto_advance_button: Button = $Balloon/Margin/Panel/Toolbar/AutoAdvanceButton
@onready var history_button: Button = $Balloon/Margin/Panel/Toolbar/HistoryButton
@onready var auto_advance_indicator: Label = $Balloon/Margin/Panel/Toolbar/AutoAdvanceIndicator
@onready var speed_indicator: Label = $Balloon/Margin/Panel/Toolbar/SpeedIndicator
@onready var left_illustration: HumanTexture = $Illustrations/LeftIllustration
@onready var right_illustration: HumanTexture = $Illustrations/RightIllustration
@onready var talk_sound: AudioStreamPlayer = $TalkSound

## 导出变量 - 对话设置
@export_group("对话设置")
@export var base_typing_speed: float = 0.02
@export var auto_advance: bool = false
@export var auto_advance_delay: float = 1.5

## 导出变量 - 动画设置
@export_group("动画设置")
@export var enable_enter_animation: bool = true
@export var enable_exit_animation: bool = true
@export var enter_animation_type: String = "fade"
@export var exit_animation_type: String = "scale"
@export var animation_duration: float = 0.25
@export var response_animation_delay: float = 0.05

## 导出变量 - 速度控制
@export_group("速度控制")
@export var fast_forward_speed: float = 5.0
@export var slow_motion_speed: float = 0.3

## 导出变量 - 历史记录设置
@export_group("历史记录设置")
@export var history_enabled: bool = true
@export var chapter_name: String = ""

## 导出变量 - 自动推进设置
@export_group("自动推进设置")
@export var auto_save_progress: bool = true

## 组件
var character_manager: CharacterManager
var flow_controller: DialogueFlowController
var animator: BalloonAnimator

## 内部状态
var _is_dialogue_active: bool = false
var current_dialogue_line: DialogueLine
var _is_history_open: bool = false
var _speed_multiplier: float = 1.0
var _is_auto_advancing: bool = false
var _auto_advance_timer_value: float = 0.0

func _ready() -> void:
	_setup_components()
	_connect_signals()
	# Enable processing so _process and _input are called (for auto-advance, speed controls, and input handling)
	set_process(true)
	set_process_input(true)
	# Capture mouse clicks over the balloon area so it can advance dialogue.
	# Also listen globally via viewport to ensure we catch clicks even when UI eats the event.
	if balloon:
		balloon.mouse_filter = Control.MOUSE_FILTER_PASS
		balloon.connect("gui_input", Callable(self, "_on_balloon_gui_input"))
	# Hide the response template so it doesn't show up as a real option
	var template := responses_menu.get_node_or_null("ResponseTemplate")
	responses_menu.hide()
	if template:
		template.hide()

func _setup_components() -> void:
	character_manager = CharacterManager.new()
	
	flow_controller = DialogueFlowController.new()
	flow_controller.auto_advance = auto_advance
	flow_controller.auto_advance_delay = auto_advance_delay
	
	animator = BalloonAnimator.new()
	animator.animation_completed.connect(_on_animation_completed)

func _connect_signals() -> void:
	if dialogue_label:
		dialogue_label.finished_typing.connect(_on_finished_typing)
		dialogue_label.spoke.connect(_on_dialogue_label_spoke)
	
	#if responses_menu:
		#responses_menu.response_selected.connect(_on_response_selected)
	#
	#if auto_advance_button:
		#auto_advance_button.toggled.connect(_on_auto_advance_toggled)
	#
	#if history_button:
		#history_button.pressed.connect(_on_history_pressed)
	
	flow_controller.dialogue_line_changed.connect(_on_flow_line_changed)
	flow_controller.dialogue_ended.connect(_on_flow_ended)
	flow_controller.character_changed.connect(_on_flow_character_changed)

func start(dialogue_resource: DialogueResource, key: String = "", extra_game_states: Array = []) -> void:
	if dialogue_resource == null:
		push_error("IllustratedBalloon: 对话资源为空")
		return
	
	# Ensure the balloon is visible when starting (even if the whole node was hidden earlier)
	show()
	_is_dialogue_active = true
	balloon.show()
	
	if enable_enter_animation:
		_play_enter_animation()
	
	flow_controller.start(dialogue_resource, key, extra_game_states)

func next(key: String = "") -> void:
	if not _is_dialogue_active:
		return
	# If no key is specified, advance using the current line's next_id (normal conversation flow).
	if key == "" and current_dialogue_line != null:
		key = current_dialogue_line.next_id
	flow_controller.next(key)

func _on_flow_line_changed(dialogue_line: DialogueLine) -> void:
	current_dialogue_line = dialogue_line
	_apply_dialogue_line(dialogue_line)
	dialogue_line_changed.emit(dialogue_line)

func _on_flow_ended() -> void:
	_end_dialogue()

func _on_flow_character_changed(character_name: String) -> void:
	character_changed.emit(character_name)

func _apply_dialogue_line(dialogue_line: DialogueLine) -> void:
	var character := dialogue_line.character
	
	_update_character_display(character)
	_update_dialogue_display(dialogue_line)
	_update_illustrations(dialogue_line)
	_record_history(dialogue_line)
	
	_handle_post_dialogue(dialogue_line)

func _update_character_display(character: String) -> void:
	if character_label:
		character_label.visible = not character.is_empty()
		character_label.text = tr(character, "dialogue")
		
		if not character.is_empty():
			var color := character_manager.get_color(character)
			character_label.modulate = color

func _update_dialogue_display(dialogue_line: DialogueLine) -> void:
	if dialogue_label:
		dialogue_label.dialogue_line = dialogue_line
		dialogue_label.text = dialogue_line.text
		dialogue_label.type_out()

func _normalize_tag(tag: String) -> String:
	# Tags can come in with leading/trailing whitespace or a leading '#'
	return tag.strip_edges().lstrip("#")

func _update_illustrations(dialogue_line: DialogueLine) -> void:
	var character := dialogue_line.character
	
	if not character.is_empty():
		character_manager.set_current_character(character)
		_apply_speaker_focus(character)
	
	for tag in dialogue_line.tags:
		var normalized_tag := _normalize_tag(tag)
		if normalized_tag.begins_with("expression:"):
			var parts := normalized_tag.split(":" )
			if parts.size() >= 2:
				var expression := parts[1]
				var position := _get_position_from_tags(dialogue_line.tags)
				_switch_expression(position, expression)

func _get_position_from_tags(tags: Array) -> int:
	for tag in tags:
		var normalized_tag := _normalize_tag(tag)
		if normalized_tag.begins_with("position:"):
			var parts :Array = normalized_tag.split(":")
			if parts.size() >= 2:
				match parts[1].to_lower():
					"right": return 1
					"center": return 2
	return 0

func _apply_speaker_focus(character_name: String) -> void:
	var direction := character_manager.get_direction(character_name)
	
	if left_illustration and left_illustration.get_character_name() == character_name:
		_apply_focus(left_illustration, true)
		_apply_focus(right_illustration, false)
	elif right_illustration and right_illustration.get_character_name() == character_name:
		_apply_focus(left_illustration, false)
		_apply_focus(right_illustration, true)
	else:
		_apply_focus(left_illustration, false)
		_apply_focus(right_illustration, false)

func _apply_focus(illustration: HumanTexture, is_speaking: bool) -> void:
	if illustration == null:
		return
	
	var target_scale := 1.0 if is_speaking else 0.85
	var target_alpha := 1.0 if is_speaking else 0.7
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(illustration, "scale", Vector2.ONE * target_scale, 0.3)
	tween.tween_property(illustration, "modulate:a", target_alpha, 0.3)
	illustration.z_index = 100 if is_speaking else 0

func _switch_expression(position: int, expression: String) -> void:
	var illustration: HumanTexture
	match position:
		0: illustration = left_illustration
		1: illustration = right_illustration
	
	if illustration:
		illustration.switch_lihui(expression)
		illustration.show()

func _record_history(dialogue_line: DialogueLine) -> void:
	if not history_enabled or not history_log:
		return
	
	var character := dialogue_line.character
	if character.is_empty():
		history_log.add_dialogue_line("", dialogue_line.text)
	else:
		history_log.set_character_color(character, character_manager.get_color(character))
		history_log.add_dialogue_line(character, dialogue_line.text)

func _handle_post_dialogue(dialogue_line: DialogueLine) -> void:
	if dialogue_line.responses.size() > 0:
		responses_menu.responses = dialogue_line.responses
		responses_menu.show()
		_play_responses_animation()
	elif auto_advance:
		_start_auto_advance()
	else:
		_is_auto_advancing = false

func _start_auto_advance() -> void:
	_is_auto_advancing = true
	_auto_advance_timer_value = auto_advance_delay
	_update_indicators()

func _process(delta: float) -> void:
	if not _is_dialogue_active or current_dialogue_line == null:
		return
	
	_handle_speed_control()
	
	if _is_auto_advancing:
		_auto_advance_timer_value -= delta
		if _auto_advance_timer_value <= 0.0:
			_is_auto_advancing = false
			_update_indicators()
			next()

func _handle_speed_control() -> void:
	var target_multiplier := 1.0
	
	if Input.is_action_pressed("ui_page_down"):
		target_multiplier = fast_forward_speed
	elif Input.is_action_pressed("ui_page_up"):
		target_multiplier = slow_motion_speed
	
	if target_multiplier != _speed_multiplier:
		_speed_multiplier = target_multiplier
		if dialogue_label:
			dialogue_label.seconds_per_step = base_typing_speed / _speed_multiplier
		_update_indicators()

func _on_finished_typing() -> void:
	pass

func _on_dialogue_label_spoke(letter: String, letter_index: int, _speed: float) -> void:
	if not character_manager.typing_sound_enabled:
		return
	if not character_manager.should_play_sound(letter, letter_index, _speed_multiplier):
		return
	
	var pitch := character_manager.calculate_pitch(character_manager.get_current_character())
	if talk_sound:
		talk_sound.pitch_scale = pitch
		talk_sound.play()

func _play_responses_animation() -> void:
	if not is_instance_valid(animator) or not is_instance_valid(responses_menu):
		return
	
	var items: Array = []
	for child in responses_menu.get_children():
		if child.visible:
			items.append(child)
	
	if items.is_empty():
		return
	
	var config := BalloonAnimator.AnimConfig.new()
	config.anim_type = BalloonAnimator.AnimType.FADE
	config.duration = animation_duration * 0.8
	config.delay = response_animation_delay
	
	animator.create_show_animation(items, config)

func _on_auto_advance_toggled(is_pressed: bool) -> void:
	auto_advance = is_pressed
	flow_controller.auto_advance = is_pressed
	_update_indicators()

func _on_history_pressed() -> void:
	if history_log:
		history_log.show()
		_is_history_open = true

func _on_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

func _end_dialogue() -> void:
	current_dialogue_line = null
	_is_dialogue_active = false
	_is_auto_advancing = false
	
	# Hide the balloon and illustrations on end.
	if enable_exit_animation:
		_play_exit_animation()
		left_illustration.hide()
		right_illustration.hide()
	else:
		balloon.hide()
		left_illustration.hide()
		right_illustration.hide()

	
	dialogue_ended.emit()

func _play_enter_animation() -> void:
	if animator == null or balloon == null:
		return
	
	var config := BalloonAnimator.AnimConfig.new()
	config.anim_type = _get_animation_type(enter_animation_type)
	config.duration = animation_duration
	animator.create_show_animation([balloon], config)

func _play_exit_animation() -> void:
	if animator == null or balloon == null:
		return
	
	var config := BalloonAnimator.AnimConfig.new()
	config.anim_type = _get_animation_type(exit_animation_type)
	config.duration = animation_duration
	animator.create_hide_animation([balloon], config)

func _get_animation_type(anim_name: String) -> int:
	match anim_name.to_lower():
		"scale": return BalloonAnimator.AnimType.SCALE
		"fade": return BalloonAnimator.AnimType.FADE
		"pop": return BalloonAnimator.AnimType.POP
		"slide_up": return BalloonAnimator.AnimType.SLIDE_UP
		"slide_down": return BalloonAnimator.AnimType.SLIDE_DOWN
		"slide_left": return BalloonAnimator.AnimType.SLIDE_LEFT
		"slide_right": return BalloonAnimator.AnimType.SLIDE_RIGHT
		_: return BalloonAnimator.AnimType.NONE

func _on_animation_completed(_anim_type: int) -> void:
	pass

func _update_indicators() -> void:
	if not is_node_ready():
		return
	
	if auto_advance_indicator:
		auto_advance_indicator.visible = auto_advance
		auto_advance_indicator.text = "⟳ 自动" if auto_advance else ""
	
	if speed_indicator:
		if _speed_multiplier > 1.5:
			speed_indicator.text = "⏩ 快进 x%.1f" % _speed_multiplier
			speed_indicator.show()
		elif _speed_multiplier < 0.7:
			speed_indicator.text = "⏪ 慢放 x%.1f" % _speed_multiplier
			speed_indicator.show()
		else:
			speed_indicator.hide()

func _unhandled_input(event: InputEvent) -> void:
	# Support keyboard shortcuts for advancing / closing history
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if _is_history_open:
			history_log.hide()
			_is_history_open = false
		elif responses_menu and responses_menu.visible:
			pass
		elif _is_dialogue_active:
			next()

	elif event.is_action_pressed("ui_cancel"):
		if _is_history_open:
			history_log.hide()
			_is_history_open = false
	


func _on_balloon_gui_input(event: InputEvent) -> void:
	# Advance dialogue when clicking on the balloon area.
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if _is_dialogue_active and (not responses_menu or not responses_menu.visible):
			next()
			# Consume so it doesn't click through to other UI.



func get_character_manager() -> CharacterManager:
	return character_manager

func setup_test_characters() -> void:
	character_manager.register_character("主角", {
		"pitch": 1.2,
		"direction": "left",
		"color": Color(0.3, 0.7, 1.0)
	})
	character_manager.register_character("NPC", {
		"pitch": 0.9,
		"direction": "right",
		"color": Color(1.0, 0.6, 0.8)
	})
