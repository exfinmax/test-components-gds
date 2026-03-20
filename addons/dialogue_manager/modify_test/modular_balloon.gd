class_name ModularBalloon
extends BaseBalloon

@export_group("Dialogue")
@export var dialogue_resource: DialogueResource
@export var start_from_title: String = ""
@export var auto_start: bool = false
@export var will_block_other_input: bool = true

@export_group("Flow")
@export var next_action: StringName = &"ui_accept"
@export var skip_action: StringName = &"ui_cancel"
@export var fast_forward_action: StringName = &"ui_page_down"
@export var slow_motion_action: StringName = &"ui_page_up"
@export var auto_advance: bool = false
@export_range(0.5, 5.0, 0.1) var auto_advance_delay: float = 1.5
@export_enum("fixed", "text_length") var auto_advance_mode: String = "text_length"
@export_range(0.01, 0.1, 0.005) var auto_advance_text_multiplier: float = 0.03
@export_range(2.0, 20.0, 0.5) var fast_forward_speed: float = 5.0
@export_range(0.1, 0.8, 0.05) var slow_motion_speed: float = 0.3
@export_range(0.01, 0.1, 0.005) var base_typing_speed: float = 0.02

@export_group("History")
@export var history_enabled: bool = true
@export_range(0, 500, 10) var max_history_entries: int = 200
@export var history_action: StringName = &"ui_text_submit"

@export_group("Save")
@export var auto_save_progress: bool = true
@export var chapter_name: String = ""

@export_group("Animation")
@export var enable_enter_animation: bool = true
@export var enable_exit_animation: bool = true
@export_enum("scale", "fade", "pop", "slide_up", "slide_down", "none") var enter_animation_type: String = "scale"
@export_enum("scale", "fade", "pop", "slide_up", "slide_down", "none") var exit_animation_type: String = "scale"
@export_range(0.1, 1.0, 0.05) var animation_duration: float = 0.25
@export_range(0.0, 0.2, 0.01) var response_animation_delay: float = 0.05

@export_group("Character UI")
@export_enum("left", "right", "auto") var balloon_direction: String = "auto"

@export_group("Typing Sound")
@export var typing_sound_enabled: bool = true
@export_range(0.5, 2.0, 0.1) var default_pitch: float = 1.0
@export_range(0.0, 0.3, 0.05) var pitch_variance: float = 0.1
@export_range(1, 8, 1) var sound_interval: int = 2
@export var typing_sound: AudioStream

@onready var _balloon_control: Control = %Balloon
@onready var _dialogue_label: DialogueLabel = %DialogueLabel
@onready var _responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var _character_label: RichTextLabel = %CharacterLabel
@onready var _portrait_texture: TextureRect = %PortraitTexture
@onready var _head_texture: TextureRect = %HeadTexture
@onready var _name_texture: TextureRect = %NameTexture
@onready var _bg_texture: TextureRect = %BGTexture
@onready var _history_log: DialogueHistoryLog = %HistoryLog
@onready var _auto_advance_indicator: Label = %AutoAdvanceIndicator
@onready var _speed_indicator: Label = %SpeedIndicator
@onready var _progress_indicator: Polygon2D = %Progress
@onready var _voice_player: AudioStreamPlayer = %VoicePlayer
@onready var _auto_advance_button: Button = %AutoAdvanceButton
@onready var _history_button: Button = %HistoryButton
@onready var _left_illustration: HumanTexture = %LeftIllustration
@onready var _right_illustration: HumanTexture = %RightIllustration
@onready var _center_illustration: HumanTexture = %CenterIllustration
@onready var _illustration_manager: IllustrationManager = $IllustrationManager
@onready var _flow_module: FlowControlModule = $FlowControlModule
@onready var _animation_module: AnimationModule = $AnimationModule
@onready var _typing_sound_module: TypingSoundModule = $TypingSoundModule
@onready var _history_module: HistoryModule = $HistoryModule
@onready var _save_module: SaveModule = $SaveModule
@onready var _illustration_module: IllustrationModule = $IllustrationModule
@onready var _character_ui_module: CharacterUIModule = $CharacterUIModule
@onready var _response_module: ResponseModule = $ResponseModule
@onready var _indicator_module: IndicatorModule = $IndicatorModule

var _character_manager: CharacterManager = CharacterManager.new()
var _ui_renderer: BalloonUIRenderer = BalloonUIRenderer.new()

var dialogue_line: DialogueLine:
	get:
		return get_current_line()

func _ready() -> void:
	super._ready()
	_wire_modules()
	_apply_configuration()
	_connect_ui()
	hide()
	_balloon_control.hide()
	_responses_menu.hide()
	_history_log.hide()
	if is_instance_valid(_center_illustration):
		_center_illustration.hide()
	if auto_start and dialogue_resource != null:
		start(dialogue_resource, start_from_title)

func _process(_delta: float) -> void:
	var line := get_current_line()
	if not is_instance_valid(_progress_indicator):
		return
	_progress_indicator.visible = (
		line != null
		and is_instance_valid(_dialogue_label)
		and not _dialogue_label.is_typing
		and line.responses.is_empty()
		and not line.has_tag("voice")
	)

func _unhandled_input(event: InputEvent) -> void:
	if forward_input(event):
		get_viewport().set_input_as_handled()
		return
	if will_block_other_input and get_current_line() != null:
		get_viewport().set_input_as_handled()

func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_states: Array = []) -> void:
	if with_dialogue_resource != null:
		dialogue_resource = with_dialogue_resource
	if title != "":
		start_from_title = title
	if dialogue_resource == null:
		push_error("ModularBalloon: dialogue_resource is required")
		return
	_apply_configuration()
	show()
	super.start(dialogue_resource, start_from_title, extra_states)

func toggle_auto_advance() -> void:
	if is_instance_valid(_flow_module):
		_flow_module.toggle_auto_advance()
		_sync_toolbar()

func toggle_history() -> void:
	if is_instance_valid(_history_log):
		_history_log.toggle_log()

func register_character(name: String, config: Dictionary = {}) -> void:
	_character_manager.register_character(name, config)

func set_expression(expression: String) -> void:
	if is_instance_valid(_character_ui_module):
		_character_ui_module.set_expression(expression)

func set_character_pitch(character: String, pitch: float) -> void:
	_character_manager.set_pitch(character, pitch)

func set_character_direction(character: String, direction: String) -> void:
	_character_manager.set_direction(character, direction)

func set_character_color(character: String, color: Color) -> void:
	_character_manager.set_color(character, color)

func set_character_texture(character: String, expression: String, texture: Texture2D) -> void:
	_character_manager.set_texture(character, expression, texture)

func set_character_bg_texture(character: String, bg_type: String, texture: Texture2D) -> void:
	_character_manager.set_bg_texture(character, bg_type, texture)

func switch_illustration(position: int, resource: LiHui, default_key: String = "ax") -> void:
	if is_instance_valid(_illustration_module):
		_illustration_module.switch_illustration(position, resource, default_key)

func show_illustration(position: int, animate: bool = true) -> void:
	if is_instance_valid(_illustration_module):
		_illustration_module.show_illustration(position, animate)

func hide_illustration(position: int, animate: bool = true) -> void:
	if is_instance_valid(_illustration_module):
		_illustration_module.hide_illustration(position, animate)

func setup_test_characters() -> void:
	register_character("主角", {
		"pitch": 1.2,
		"direction": "left",
		"color": Color(0.3, 0.7, 1.0),
	})
	register_character("NPC", {
		"pitch": 0.9,
		"direction": "right",
		"color": Color(1.0, 0.6, 0.8),
	})

func _wire_modules() -> void:
	_ui_renderer.setup(_balloon_control, _character_label, _dialogue_label, _responses_menu, _portrait_texture)
	_illustration_manager.left_illustration = _left_illustration
	_illustration_manager.right_illustration = _right_illustration
	_illustration_manager.center_illustration = _center_illustration
	_illustration_manager._setup_illustration_map()

	_flow_module.dialogue_label = _dialogue_label
	_flow_module.voice_player = _voice_player

	_animation_module.balloon_control = _balloon_control
	_animation_module.responses_menu = _responses_menu

	_typing_sound_module.dialogue_label = _dialogue_label
	_typing_sound_module.character_manager = _character_manager

	_history_module.history_log = _history_log
	_history_module.character_manager = _character_manager

	_illustration_module.illustration_manager = _illustration_manager

	_character_ui_module.character_manager = _character_manager
	_character_ui_module.ui_renderer = _ui_renderer
	_character_ui_module.character_label = _character_label
	_character_ui_module.portrait_texture = _portrait_texture
	_character_ui_module.head_texture = _head_texture
	_character_ui_module.name_texture = _name_texture
	_character_ui_module.bg_texture = _bg_texture

	_response_module.responses_menu = _responses_menu
	_response_module.dialogue_label = _dialogue_label

	_indicator_module.auto_advance_indicator = _auto_advance_indicator
	_indicator_module.speed_indicator = _speed_indicator

	for child in get_children():
		if child is BalloonModule:
			child.setup(self)

func _connect_ui() -> void:
	if not dialogue_started.is_connected(_on_dialogue_started):
		dialogue_started.connect(_on_dialogue_started)
	if not dialogue_line_changed.is_connected(_on_dialogue_line_changed):
		dialogue_line_changed.connect(_on_dialogue_line_changed)
	if not dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_ended.connect(_on_dialogue_ended)
	if not _dialogue_label.meta_clicked.is_connected(_on_meta_clicked):
		_dialogue_label.meta_clicked.connect(_on_meta_clicked)
	_sync_toolbar()

func _apply_configuration() -> void:
	_flow_module.next_action = next_action
	_flow_module.skip_action = skip_action
	_flow_module.auto_advance = auto_advance
	_flow_module.auto_advance_delay = auto_advance_delay
	_flow_module.auto_advance_mode = auto_advance_mode
	_flow_module.auto_advance_text_multiplier = auto_advance_text_multiplier
	_flow_module.fast_forward_speed = fast_forward_speed
	_flow_module.slow_motion_speed = slow_motion_speed
	_flow_module.base_typing_speed = base_typing_speed
	_flow_module.fast_forward_action = fast_forward_action
	_flow_module.slow_motion_action = slow_motion_action

	_animation_module.enable_enter_animation = enable_enter_animation
	_animation_module.enable_exit_animation = enable_exit_animation
	_animation_module.enter_animation_type = enter_animation_type
	_animation_module.exit_animation_type = exit_animation_type
	_animation_module.animation_duration = animation_duration
	_animation_module.response_animation_delay = response_animation_delay

	_history_module.history_enabled = history_enabled
	_history_module.chapter_name = chapter_name
	_history_module.max_history_entries = max_history_entries
	_history_module.history_action = history_action

	_save_module.auto_save_progress = auto_save_progress
	_save_module.chapter_name = chapter_name

	_character_ui_module.balloon_direction = balloon_direction

	_typing_sound_module.typing_sound_enabled = typing_sound_enabled
	_typing_sound_module.default_pitch = default_pitch
	_typing_sound_module.pitch_variance = pitch_variance
	_typing_sound_module.sound_interval = sound_interval
	_typing_sound_module.typing_sound = typing_sound

	_character_manager.typing_sound_enabled = typing_sound_enabled
	_character_manager.default_pitch = default_pitch
	_character_manager.pitch_variance = pitch_variance
	_character_manager.sound_interval = sound_interval
	
	_dialogue_label.seconds_per_step = base_typing_speed
	_responses_menu.next_action = next_action
	_sync_toolbar()

func _sync_toolbar() -> void:
	if is_instance_valid(_auto_advance_button):
		_auto_advance_button.set_pressed_no_signal(_flow_module.auto_advance)

func _on_dialogue_started(_resource: DialogueResource, _title: String) -> void:
	show()
	_balloon_control.show()
	_responses_menu.hide()
	_progress_indicator.hide()
	_sync_toolbar()

func _on_dialogue_line_changed(line: DialogueLine) -> void:
	_balloon_control.show()
	_balloon_control.focus_mode = Control.FOCUS_ALL
	_balloon_control.grab_focus()
	_dialogue_label.show()
	_dialogue_label.dialogue_line = line
	if line.text.is_empty():
		return
	_dialogue_label.type_out()

func _on_dialogue_ended() -> void:
	_responses_menu.hide()
	_progress_indicator.hide()
	_sync_toolbar()

func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

func _on_balloon_gui_input(event: InputEvent) -> void:
	if forward_input(event):
		get_viewport().set_input_as_handled()
		return
	if will_block_other_input and get_current_line() != null:
		get_viewport().set_input_as_handled()

func _on_auto_advance_button_toggled(_toggled_on: bool) -> void:
	toggle_auto_advance()

func _on_history_button_pressed() -> void:
	toggle_history()
