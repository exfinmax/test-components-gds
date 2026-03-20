class_name TypingSoundModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## TypingSoundModule — 打字音效模块
## ════════════════════════════════════════════════════════════════
##
## 监听 DialogueLabel.spoke 信号，按角色音调播放打字音效。
## 跳过空格和标点，支持音调随机偏移。
## ════════════════════════════════════════════════════════════════

@export_group("音效设置")
## 是否启用打字音效
@export var typing_sound_enabled: bool = true
## 默认音调
@export_range(0.5, 2.0, 0.1) var default_pitch: float = 1.0
## 音调随机偏差范围
@export_range(0.0, 0.3, 0.05) var pitch_variance: float = 0.1
## 每隔多少字符播放一次（正常速度下）
@export_range(1, 8, 1) var sound_interval: int = 2
## 打字音效资源
@export var typing_sound: AudioStream

## 对话标签节点引用（由场景配置）
var dialogue_label: DialogueLabel

## CharacterManager 引用（由场景配置，用于读取角色音调）
var character_manager: CharacterManager

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

var _audio_player: AudioStreamPlayer
var _current_pitch: float = 1.0
var _current_speed_multiplier: float = 1.0

# ════════════════════════════════════════════════════════════════
# 生命周期
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	# 创建内部音频播放器
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "typing_sound"

func setup(balloon: BaseBalloon) -> void:
	super.setup(balloon)

func on_dialogue_line_changed(line: DialogueLine) -> void:
	# 从 CharacterManager 读取当前角色音调
	if is_instance_valid(character_manager) and not line.character.is_empty():
		_current_pitch = character_manager.get_pitch(line.character)
	else:
		_current_pitch = default_pitch
	
	# 连接 DialogueLabel.spoke 信号
	if is_instance_valid(dialogue_label):
		if not dialogue_label.spoke.is_connected(_on_spoke):
			dialogue_label.spoke.connect(_on_spoke)

func on_dialogue_ended() -> void:
	if is_instance_valid(dialogue_label) and dialogue_label.spoke.is_connected(_on_spoke):
		dialogue_label.spoke.disconnect(_on_spoke)

func on_module_event(event_name: String, data: Dictionary) -> void:
	if event_name == "speed_changed":
		_current_speed_multiplier = data.get("multiplier", 1.0)

# ════════════════════════════════════════════════════════════════
# 纯函数：音效播放条件判断
# ════════════════════════════════════════════════════════════════

## 判断是否应该播放音效（纯函数，便于测试）
## c: 当前字符，i: 字符索引，speed_multiplier: 当前速度倍率
func should_play_sound(c: String, i: int, speed_multiplier: float) -> bool:
	if not typing_sound_enabled:
		return false
	# 跳过空格和标点
	if c in [" ", ".", ",", "!", "?", "\n", "，", "。", "！", "？"]:
		return false
	# 慢速时每字都播放，正常/快速时按间隔播放
	var effective_interval := 1 if speed_multiplier < 1.0 else sound_interval
	return i % effective_interval == 0

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

func _on_spoke(letter: String, letter_index: int, _speed: float) -> void:
	if not should_play_sound(letter, letter_index, _current_speed_multiplier):
		return
	
	# 叠加随机音调偏移
	var variance := randf_range(-pitch_variance, pitch_variance)
	var final_pitch := clampf(_current_pitch + variance, 0.1, 4.0)
	
	if is_instance_valid(_audio_player):
		# 优先使用配置的音效，否则使用默认
		if typing_sound != null:
			_audio_player.stream = typing_sound
		_audio_player.pitch_scale = final_pitch
		_audio_player.play()
