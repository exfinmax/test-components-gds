class_name EnhancedBalloon
extends CanvasLayer
## ════════════════════════════════════════════════════════════════
##  EnhancedBalloon — 增强版对话气泡框
## ════════════════════════════════════════════════════════════════
##
## 整合自 dialogue/balloon.gd 和 modify_test/modify_balloon.gd
## 
## 核心功能：
##   • 角色音效系统 — 不同角色有不同音调的打字音效
##   • 角色头像系统 — 支持动态头像、表情切换
##   • 气泡方向切换 — 左右布局自动切换
##   • 自动推进模式 — 打字完成后自动进入下一行
##   • 快进/慢放功能 — 动态调整打字速度
##   • 历史记录系统 — 记录所有对话内容
##   • 进度自动保存 — 集成存档系统
##   • 主题样式系统 — 可配置的视觉主题
##   • 标签解析系统 — 支持自定义标签（URL、颜色、抖动等）
##   • 入场/出场动画 — 中心缩放展开等动画效果
##
## 使用方式：
##   $EnhancedBalloon.start(dialogue_resource, "start", [self])
## ════════════════════════════════════════════════════════════════

## 对话行变化信号
signal dialogue_line_changed(line: DialogueLine)
## 对话开始信号
signal dialogue_started(resource: DialogueResource, title: String)
## 对话结束信号
signal dialogue_ended()
## 角色变化信号
signal character_changed(character: String)
## 表情变化信号
signal expression_changed(character: String, expression: String)

# ════════════════════════════════════════════════════════════════
# 导出参数
# ════════════════════════════════════════════════════════════════

@export_group("基础配置")
## 对话资源
@export var dialogue_resource: DialogueResource
## 启动时自动从该标题开始
@export var start_from_title: String = ""
## 是否随节点进入场景时自动开始
@export var auto_start: bool = false
## 是否阻断其他输入
@export var will_block_other_input: bool = true

@export_group("输入控制")
## 推进对话的输入动作
@export var next_action: StringName = &"ui_accept"
## 跳过打字的输入动作
@export var skip_action: StringName = &"ui_cancel"
## 查看历史记录的输入动作
@export var history_action: StringName = &"ui_text_submit"
## 快进的输入动作
@export var fast_forward_action: StringName = &"ui_page_down"
## 慢放的输入动作
@export var slow_motion_action: StringName = &"ui_page_up"

@export_group("自动推进")
## 打字完成后自动推进（无需按键）
@export var auto_advance: bool = false
## 自动推进延迟（秒）
@export_range(0.5, 5.0, 0.1) var auto_advance_delay: float = 1.5
## 自动推进延迟计算方式：fixed = 固定时间, text_length = 根据文本长度计算
@export_enum("fixed", "text_length") var auto_advance_mode: String = "text_length"
## 文本长度系数（当 auto_advance_mode = text_length 时使用）
@export_range(0.01, 0.1, 0.005) var auto_advance_text_multiplier: float = 0.03

@export_group("速度控制")
## 快进速度倍率（按住时生效）
@export_range(2.0, 20.0, 0.5) var fast_forward_speed: float = 5.0
## 慢放速度倍率（按住时生效）
@export_range(0.1, 0.8, 0.05) var slow_motion_speed: float = 0.3
## 基础打字速度（秒/字符）
@export_range(0.01, 0.1, 0.005) var base_typing_speed: float = 0.02

@export_group("音效设置")
## 是否启用打字音效
@export var typing_sound_enabled: bool = true
## 打字音效资源（默认使用内置）
@export var typing_sound: AudioStream
## 默认音效音调
@export_range(0.5, 2.0, 0.1) var default_pitch: float = 1.0
## 音调随机变化范围
@export_range(0.0, 0.3, 0.05) var pitch_variance: float = 0.1
## 每隔多少字符播放一次音效
@export_range(1, 8, 1) var sound_interval: int = 2

@export_group("历史记录")
## 是否启用历史记录
@export var history_enabled: bool = true
## 最大保存的历史条数（0 = 无限制）
@export_range(0, 500, 10) var max_history_entries: int = 200
## 历史记录是否自动滚动到底部
@export var history_auto_scroll: bool = true
## 默认角色名颜色
@export var character_name_color: Color = Color(0.4, 0.8, 1.0)
## 玩家选项颜色
@export var player_response_color: Color = Color(0.6, 1.0, 0.6)

@export_group("存档集成")
## 是否集成存档系统自动保存进度
@export var auto_save_progress: bool = true
## 存档章节名（显示在存档槽中）
@export var chapter_name: String = ""

@export_group("视觉样式")
## 默认气泡方向：left = 头像在左, right = 头像在右
@export_enum("left", "right", "auto") var balloon_direction: String = "auto"
## 气泡背景颜色
@export var balloon_bg_color: Color = Color(0.04, 0.04, 0.06, 0.97)
## 气泡边框颜色
@export var balloon_border_color: Color = Color(0.35, 0.35, 0.45, 1)
## 气泡圆角半径
@export_range(0, 20, 1) var balloon_corner_radius: int = 8
## 头像容器最小尺寸
@export var portrait_min_size: Vector2 = Vector2(150, 150)
## 是否显示进度指示器
@export var show_progress_indicator: bool = true

@export_group("动画设置")
## 是否启用入场动画
@export var enable_enter_animation: bool = true
## 是否启用出场动画
@export var enable_exit_animation: bool = true
## 入场动画类型
@export_enum("scale", "fade", "pop", "slide_up", "slide_down", "none") var enter_animation_type: String = "scale"
## 出场动画类型
@export_enum("scale", "fade", "pop", "slide_up", "slide_down", "none") var exit_animation_type: String = "scale"
## 动画持续时间（秒）
@export_range(0.1, 1.0, 0.05) var animation_duration: float = 0.25
## 选项动画延迟间隔（秒）
@export_range(0.0, 0.2, 0.01) var response_animation_delay: float = 0.05

@export_group("标签解析")
## 是否启用自定义标签解析
@export var enable_custom_tags: bool = true
## 是否启用颜色标签
@export var enable_color_tag: bool = true
## 是否启用抖动标签
@export var enable_shake_tag: bool = true

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()
var _auto_advance_timer: float = 0.0
var _is_auto_advancing: bool = false
var _current_speed_multiplier: float = 1.0
var _current_expression: String = ""
var _current_direction: String = "left"
var _is_first_show: bool = true
var _is_dialogue_active: bool = false

var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			_apply_dialogue_line()
		else:
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

var mutation_cooldown: Timer = Timer.new()

## 动画控制器
var _animator: BalloonAnimator = null

# ════════════════════════════════════════════════════════════════
# 角色配置字典（可在运行时动态修改）
# ════════════════════════════════════════════════════════════════

## 角色音调配置：角色名 → 音调值
var character_pitches: Dictionary = {}

## 角色头像位置偏移：角色名 → Vector2
var character_head_offsets: Dictionary = {}

## 角色名称位置偏移：角色名 → Vector2
var character_name_offsets: Dictionary = {}

## 角色名称缩放：角色名 → Vector2
var character_name_scales: Dictionary = {}

## 角色专属颜色：角色名 → Color
var character_colors: Dictionary = {}

## 角色头像纹理：角色名 → { 表情名 → Texture2D }
var character_textures: Dictionary = {}

## 角色背景纹理：角色名 → { BG/NAME/HEAD → Texture2D }
var character_bg_textures: Dictionary = {}

## 角色默认方向：角色名 → "left"/"right"
var character_directions: Dictionary = {}

# ════════════════════════════════════════════════════════════════
# 子节点引用
# ════════════════════════════════════════════════════════════════

@onready var balloon: Control = %Balloon
@onready var margin: MarginContainer = %Margin
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var portrait_container: Control = %PortraitContainer
@onready var portrait_texture: TextureRect = %PortraitTexture
@onready var head_texture: TextureRect = %HeadTexture
@onready var name_texture: TextureRect = %NameTexture
@onready var bg_texture: TextureRect = %BGTexture
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var talk_sound: AudioStreamPlayer = %TalkSound
@onready var history_log: DialogueHistoryLog = %HistoryLog
@onready var toolbar: HBoxContainer = %Toolbar
@onready var auto_advance_indicator: Label = %AutoAdvanceIndicator
@onready var speed_indicator: Label = %SpeedIndicator
@onready var progress: Polygon2D = %Progress

# ════════════════════════════════════════════════════════════════
# 生命周期
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	
	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)
	
	dialogue_label.meta_clicked.connect(OS.shell_open)
	dialogue_label.seconds_per_step = base_typing_speed
	
	if is_instance_valid(responses_menu):
		responses_menu.next_action = next_action
		responses_menu.response_selected.connect(_on_response_selected)
	
	_setup_animator()
	_setup_default_character_config()
	_update_indicators()
	
	if history_enabled and is_instance_valid(history_log):
		history_log.max_entries = max_history_entries
		history_log.auto_scroll_to_bottom = history_auto_scroll
		history_log.character_name_color = character_name_color
		history_log.player_response_color = player_response_color
	
	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, "EnhancedBalloon: auto_start requires a valid dialogue_resource")
		start()




	


func _setup_animator() -> void:
	_animator = BalloonAnimator.new()
	_animator.animation_completed.connect(_on_animation_completed)


func _on_tag_clicked(tag_name: String, meta_data: Dictionary) -> void:
	pass


func _on_animation_completed(_anim_type: int) -> void:
	pass


func _process(delta: float) -> void:
	if not is_instance_valid(dialogue_line):
		return
	
	if show_progress_indicator and is_instance_valid(progress):
		progress.visible = (
			not dialogue_label.is_typing
			and dialogue_line.responses.size() == 0
			and not dialogue_line.has_tag("voice")
			and not _is_auto_advancing
		)
	
	var target_multiplier := 1.0
	if Input.is_action_pressed(fast_forward_action):
		target_multiplier = fast_forward_speed
	elif Input.is_action_pressed(slow_motion_action):
		target_multiplier = slow_motion_speed
	
	if target_multiplier != _current_speed_multiplier:
		_current_speed_multiplier = target_multiplier
		dialogue_label.seconds_per_step = base_typing_speed / _current_speed_multiplier
		_update_indicators()
	
	if _is_auto_advancing:
		_auto_advance_timer -= delta
		if _auto_advance_timer <= 0.0:
			_is_auto_advancing = false
			_update_indicators()
			next(dialogue_line.next_id)


func _setup_default_character_config() -> void:
	character_pitches = {
		"旁白": 1.0,
		"Narrator": 1.0,
	}
	character_directions = {
		"旁白": "right",
		"Narrator": "right",
	}

# ════════════════════════════════════════════════════════════════
# 输入处理
# ════════════════════════════════════════════════════════════════

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

# ════════════════════════════════════════════════════════════════
# 对话 API
# ════════════════════════════════════════════════════════════════

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
	
	if history_enabled and is_instance_valid(history_log):
		history_log.clear_history()
		if not chapter_name.is_empty():
			history_log.add_chapter_divider(chapter_name)
	
	_is_dialogue_active = true
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	
	show()
	
	if enable_enter_animation:
		_play_enter_animation()
	
	dialogue_started.emit(dialogue_resource, start_from_title)


## 应用新的对话行到 UI
func _apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	
	progress.hide()
	is_waiting_for_input = false
	_is_auto_advancing = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()
	
	var character := dialogue_line.character
	character_label.visible = not character.is_empty()
	character_label.text = tr(character, "dialogue")
	
	_update_character_visuals(character)
	_update_balloon_direction(character)
	
	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line
	
	
	_setup_responses()
	
	balloon.show()
	will_hide_balloon = false
	
	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing
	
	_record_to_history(dialogue_line)
	
	if auto_save_progress:
		_save_progress()
	
	_handle_post_dialogue()
	
	dialogue_line_changed.emit(dialogue_line)
	character_changed.emit(character)





## 播放入场动画
func _play_enter_animation() -> void:
	if not is_instance_valid(_animator) or not is_instance_valid(balloon):
		return
	
	var config := BalloonAnimator.AnimConfig.new()
	config.anim_type = _get_animation_type(enter_animation_type)
	config.duration = animation_duration
	
	_animator.create_show_animation([balloon], config)
	await _animator.animation_completed


## 播放出出场动画
func _play_exit_animation() -> void:
	if not is_instance_valid(_animator) or not is_instance_valid(balloon):
		return
	
	var config := BalloonAnimator.AnimConfig.new()
	config.anim_type = _get_animation_type(exit_animation_type)
	config.duration = animation_duration
	
	_animator.create_hide_animation([balloon], config)
	await _animator.animation_completed


## 播放选项入场动画
func _play_responses_animation() -> void:
	if not is_instance_valid(_animator) or not is_instance_valid(responses_menu):
		return
	
	var items: Array = []
	for child in responses_menu.get_children():
		if child.visible:
			items.append(child)
	
	if items.is_empty():
		return
	
	# 选项动画只使用 FADE 类型，避免 scale 改变点击区域
	var config := BalloonAnimator.AnimConfig.new()
	config.anim_type = BalloonAnimator.AnimType.FADE
	config.duration = animation_duration * 0.8
	config.delay = response_animation_delay
	
	_animator.create_show_animation(items, config)


## 获取动画类型
func _get_animation_type(anim_name: String) -> int:
	match anim_name.to_lower():
		"scale":
			return BalloonAnimator.AnimType.SCALE
		"fade":
			return BalloonAnimator.AnimType.FADE
		"pop":
			return BalloonAnimator.AnimType.POP
		"slide_up":
			return BalloonAnimator.AnimType.SLIDE_UP
		"slide_down":
			return BalloonAnimator.AnimType.SLIDE_DOWN
		_:
			return BalloonAnimator.AnimType.NONE


## 设置响应选项
func _setup_responses() -> void:
	if not is_instance_valid(responses_menu):
		return
	
	responses_menu.hide()
	
	if dialogue_line.responses.size() > 0:
		responses_menu.responses = dialogue_line.responses
		responses_menu.show()
		responses_menu.configure_focus()
		_play_responses_animation()


## 更新角色视觉效果
func _update_character_visuals(character: String) -> void:
	if character.is_empty():
		if is_instance_valid(portrait_texture):
			portrait_texture.texture = null
		return
	
	var char_textures: Dictionary = character_textures.get(character, {})
	if char_textures.is_empty():
		if is_instance_valid(portrait_texture):
			portrait_texture.texture = null
	else:
		var texture_key := _current_expression if not _current_expression.is_empty() else "BS"
		var texture = char_textures.get(texture_key, char_textures.get("BS", null))
		if is_instance_valid(portrait_texture):
			portrait_texture.texture = texture
	
	var char_bg: Dictionary = character_bg_textures.get(character, {})
	if not char_bg.is_empty():
		if is_instance_valid(bg_texture):
			bg_texture.texture = char_bg.get("BG", null)
		if is_instance_valid(name_texture):
			name_texture.texture = char_bg.get("NAME", null)
		if is_instance_valid(head_texture):
			head_texture.texture = char_bg.get("HEAD", null)
	
	if is_instance_valid(head_texture):
		var offset: Vector2 = character_head_offsets.get(character, Vector2.ZERO)
		head_texture.position = offset
	
	if is_instance_valid(name_texture):
		var scale: Vector2 = character_name_scales.get(character, Vector2.ONE)
		name_texture.scale = scale
		var offset: Vector2 = character_name_offsets.get(character, Vector2.ZERO)
		name_texture.position = offset


## 更新气泡方向
func _update_balloon_direction(character: String) -> void:
	var target_direction := balloon_direction
	
	if balloon_direction == "auto":
		target_direction = character_directions.get(character, "left")
	
	if target_direction == _current_direction:
		return
	
	_current_direction = target_direction
	_apply_direction(target_direction)


## 应用方向布局
func _apply_direction(direction: String) -> void:
	var h_box: HBoxContainer = margin.get_child(0) as HBoxContainer
	if not is_instance_valid(h_box):
		return
	
	var portrait: Control = portrait_container
	var v_box: VBoxContainer = dialogue_label.get_parent() as VBoxContainer
	var temp: Control
	
	for child in h_box.get_children():
		if child.name == "Temp":
			temp = child
			break
	
	if direction == "right":
		margin.add_theme_constant_override("margin_left", 0)
		margin.add_theme_constant_override("margin_right", 40)
		if is_instance_valid(name_texture) and name_texture.scale.x < 0:
			name_texture.scale.x = -name_texture.scale.x
			name_texture.position.x += 150
		if portrait and portrait.get_parent() == h_box:
			v_box.reparent(temp)
			v_box.reparent(h_box, false)
	else:
		margin.add_theme_constant_override("margin_left", 40)
		margin.add_theme_constant_override("margin_right", 0)
		if is_instance_valid(name_texture) and name_texture.scale.x > 0:
			name_texture.scale.x = -name_texture.scale.x
			name_texture.position.x -= 150
		if portrait and portrait.get_parent() != h_box:
			portrait.reparent(temp)
			portrait.reparent(h_box, false)


## 处理对话完成后的行为
func _handle_post_dialogue() -> void:
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
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
		if auto_advance_mode == "text_length":
			_auto_advance_timer = max(auto_advance_delay, dialogue_line.text.length() * auto_advance_text_multiplier)
		else:
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

# ════════════════════════════════════════════════════════════════
# 功能 API
# ════════════════════════════════════════════════════════════════

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
	if is_instance_valid(history_log):
		history_log.toggle_log()


## 切换角色表情
func set_expression(expression: String) -> void:
	_current_expression = expression
	if is_instance_valid(dialogue_line) and not dialogue_line.character.is_empty():
		_update_character_visuals(dialogue_line.character)
		expression_changed.emit(dialogue_line.character, expression)


## 设置角色音调
func set_character_pitch(character: String, pitch: float) -> void:
	character_pitches[character] = pitch


## 设置角色方向
func set_character_direction(character: String, direction: String) -> void:
	character_directions[character] = direction


## 设置角色颜色
func set_character_color(character: String, color: Color) -> void:
	character_colors[character] = color
	if is_instance_valid(history_log):
		history_log.set_character_color(character, color)


## 设置角色头像纹理
func set_character_texture(character: String, expression: String, texture: Texture2D) -> void:
	if not character_textures.has(character):
		character_textures[character] = {}
	character_textures[character][expression] = texture

# ════════════════════════════════════════════════════════════════
# 内部辅助
# ════════════════════════════════════════════════════════════════

func _update_indicators() -> void:
	if not is_node_ready():
		return
	
	if is_instance_valid(auto_advance_indicator):
		auto_advance_indicator.text = "⟳ 自动" if auto_advance else ""
		auto_advance_indicator.visible = auto_advance
	
	if is_instance_valid(speed_indicator):
		if _current_speed_multiplier > 1.5:
			speed_indicator.text = "⏩ 快进 x%.1f" % _current_speed_multiplier
			speed_indicator.show()
		elif _current_speed_multiplier < 0.7:
			speed_indicator.text = "⏪ 慢放 x%.1f" % _current_speed_multiplier
			speed_indicator.show()
		else:
			speed_indicator.hide()


func _record_to_history(line: DialogueLine) -> void:
	if not history_enabled or not is_instance_valid(history_log):
		return
	
	var character := line.character
	var text := line.text
	
	if character.is_empty():
		history_log.add_dialogue_line("", text)
	else:
		if character_colors.has(character):
			history_log.set_character_color(character, character_colors[character])
		history_log.add_dialogue_line(character, text)


func _save_progress() -> void:
	if Engine.has_singleton("SaveSystem"):
		var sys: Node = Engine.get_singleton("SaveSystem")
		var module = sys.get_module("dialogue")
		if module and module.has_method("save_progress"):
			module.call("save_progress",
				dialogue_resource,
				dialogue_line.id,
				chapter_name,
				dialogue_line.character,
				dialogue_line.text
			)


func _play_typing_sound(letter: String, letter_index: int) -> void:
	if not typing_sound_enabled:
		return
	if letter in [" ", ".", ",", "!", "?", "\n"]:
		return
	
	var actual_interval := sound_interval if _current_speed_multiplier >= 1.0 else 1
	if letter_index % actual_interval != 0:
		return
	
	var pitch := character_pitches.get(dialogue_line.character, default_pitch)
	var variance := randf_range(-pitch_variance, pitch_variance)
	
	if is_instance_valid(talk_sound):
		talk_sound.pitch_scale = pitch + variance
		talk_sound.play()

# ════════════════════════════════════════════════════════════════
# 信号处理
# ════════════════════════════════════════════════════════════════

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		if enable_exit_animation and _is_dialogue_active:
			_play_exit_animation()
		balloon.hide()
		_is_dialogue_active = false
		dialogue_ended.emit()


func _on_mutated(_mutation: Dictionary) -> void:
	if not _mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(history_action):
		get_viewport().set_input_as_handled()
		toggle_history()
		return
	
	if dialogue_label.is_typing:
		var mouse_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_pressed := event.is_action_pressed(skip_action)
		if mouse_clicked or skip_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return
	
	if not is_waiting_for_input:
		return
	if dialogue_line.responses.size() > 0:
		return
	
	get_viewport().set_input_as_handled()
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


func _on_dialogue_label_spoke(letter: String, letter_index: int, _speed: float) -> void:
	_play_typing_sound(letter, letter_index)




func _on_auto_advance_button_toggled(toggled_on: bool) -> void:
	auto_advance = toggled_on
	_update_indicators()


func _on_history_button_pressed() -> void:
	toggle_history()


func _on_margin_resized() -> void:
	if not is_instance_valid(margin):
		call_deferred("_on_margin_resized")
		return
	
	# 对于 Full Rect 锚点的节点，不要手动设置 position
	# 只设置最小尺寸
	balloon.custom_minimum_size.y = margin.size.y
