class_name CharacterManager
extends RefCounted
## ════════════════════════════════════════════════════════════════
## 角色管理器
## ════════════════════════════════════════════════════════════════
## 整合角色的音效、头像、朝向等配置管理
## 遵循高内聚原则，统一管理角色相关属性

## 信号
signal character_changed(character_name: String)
signal expression_changed(character_name: String, expression: String)
signal direction_changed(character_name: String, direction: String)

## 角色配置类
class CharacterConfig extends RefCounted:
	var character_name: String = ""
	var pitch: float = 1.0
	var direction: String = "left"
	var color: Color = Color.WHITE
	var textures: Dictionary = {}
	var bg_textures: Dictionary = {}
	var head_offset: Vector2 = Vector2.ZERO
	var name_offset: Vector2 = Vector2.ZERO
	var name_scale: Vector2 = Vector2.ONE

## 音效配置
@export var typing_sound_enabled: bool = true
@export var default_pitch: float = 1.0
@export var pitch_variance: float = 0.1
@export var sound_interval: int = 2

## 角色配置字典
var _character_configs: Dictionary = {}

## 当前角色
var _current_character: String = ""
var _current_expression: String = ""

func _init() -> void:
	_setup_default_characters()

func _setup_default_characters() -> void:
	register_character("旁白", {"pitch": 1.0, "direction": "right", "color": Color(0.7, 0.7, 0.7)})
	register_character("Narrator", {"pitch": 1.0, "direction": "right", "color": Color(0.7, 0.7, 0.7)})

func register_character(name: String, config: Dictionary = {}) -> void:
	var char_config := CharacterConfig.new()
	char_config.character_name = name
	char_config.pitch = config.get("pitch", default_pitch)
	char_config.direction = config.get("direction", "left")
	char_config.color = config.get("color", Color.WHITE)
	char_config.textures = config.get("textures", {})
	char_config.bg_textures = config.get("bg_textures", {})
	char_config.head_offset = config.get("head_offset", Vector2.ZERO)
	char_config.name_offset = config.get("name_offset", Vector2.ZERO)
	char_config.name_scale = config.get("name_scale", Vector2.ONE)
	
	_character_configs[name] = char_config

func get_config(character_name: String) -> CharacterConfig:
	return _character_configs.get(character_name)

func has_character(character_name: String) -> bool:
	return _character_configs.has(character_name)

func set_current_character(character_name: String) -> void:
	_current_character = character_name
	character_changed.emit(character_name)

func get_current_character() -> String:
	return _current_character

func set_pitch(character_name: String, pitch: float) -> void:
	var config := get_config(character_name)
	if config:
		config.pitch = pitch

func get_pitch(character_name: String) -> float:
	var config := get_config(character_name)
	return config.pitch if config else default_pitch

func set_direction(character_name: String, direction: String) -> void:
	var config := get_config(character_name)
	if config:
		config.direction = direction
		direction_changed.emit(character_name, direction)

func get_direction(character_name: String) -> String:
	var config := get_config(character_name)
	return config.direction if config else "left"

func set_color(character_name: String, color: Color) -> void:
	var config := get_config(character_name)
	if config:
		config.color = color

func get_color(character_name: String) -> Color:
	var config := get_config(character_name)
	return config.color if config else Color.WHITE

func set_texture(character_name: String, expression: String, texture: Texture2D) -> void:
	var config := get_config(character_name)
	if config:
		if config.textures.is_empty():
			config.textures = {}
		config.textures[expression] = texture

func get_texture(character_name: String, expression: String = "") -> Texture2D:
	var config := get_config(character_name)
	if config and not config.textures.is_empty():
		var key := expression if not expression.is_empty() else "BS"
		return config.textures.get(key, config.textures.get("BS", null))
	return null

func set_expression(expression: String) -> void:
	_current_expression = expression
	if not _current_character.is_empty():
		expression_changed.emit(_current_character, expression)

func get_current_expression() -> String:
	return _current_expression

func set_bg_texture(character_name: String, bg_type: String, texture: Texture2D) -> void:
	var config := get_config(character_name)
	if config:
		if config.bg_textures.is_empty():
			config.bg_textures = {}
		config.bg_textures[bg_type] = texture

func get_bg_texture(character_name: String, bg_type: String) -> Texture2D:
	var config := get_config(character_name)
	if config and not config.bg_textures.is_empty():
		return config.bg_textures.get(bg_type)
	return null

func get_head_offset(character_name: String) -> Vector2:
	var config := get_config(character_name)
	return config.head_offset if config else Vector2.ZERO

func get_name_offset(character_name: String) -> Vector2:
	var config := get_config(character_name)
	return config.name_offset if config else Vector2.ZERO

func get_name_scale(character_name: String) -> Vector2:
	var config := get_config(character_name)
	return config.name_scale if config else Vector2.ONE

func calculate_pitch(character_name: String) -> float:
	var base_pitch := get_pitch(character_name)
	var variance := randf_range(-pitch_variance, pitch_variance)
	return base_pitch + variance

func should_play_sound(letter: String, letter_index: int, speed_multiplier: float) -> bool:
	if not typing_sound_enabled:
		return false
	if letter in [" ", ".", ",", "!", "?", "\n"]:
		return false
	
	var actual_interval := sound_interval if speed_multiplier >= 1.0 else 1
	return letter_index % actual_interval == 0

func clear_all() -> void:
	_character_configs.clear()
	_setup_default_characters()
