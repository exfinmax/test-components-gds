extends Node

enum BUS { MASTER, SFX, BGM }

signal sfx_finish

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var default_bgm_fade_percent: float = 0.02
var default_sfx_fade_percent: float = 0.10
var min_fade_duration: float = 0.1
var max_fade_duration: float = 5.0
var _looping_sfx: Dictionary = {}

func _ready() -> void:
	_sync_settings()

func _get_sound_manager() -> Node:
	return get_node_or_null('/root/SoundManager')

func _sync_settings() -> void:
	var settings := SettingsModule.instance
	if settings != null:
		AudioBridge.sync_settings(settings)

func _find_stream(name: String) -> AudioStream:
	if sfx != null and sfx.has_node(name):
		var player := sfx.get_node(name) as AudioStreamPlayer
		if player != null:
			return player.stream
	if name == 'BGMPlayer' and bgm_player != null:
		return bgm_player.stream
	return null

func play_sfx(name: String) -> void:
	var stream := _find_stream(name)
	if stream == null:
		return
	AudioBridge.play_sound(stream, false, randf_range(0.8, 1.2))
	sfx_finish.emit()

func play_sfx_looping(name: String) -> void:
	var stream := _find_stream(name)
	if stream == null:
		return
	stop_sfx(name)
	var player := AudioBridge.play_sound(stream, false, 1.0)
	if player == null:
		return
	player.finished.connect(func():
		if _looping_sfx.has(name):
			play_sfx_looping(name)
	, CONNECT_ONE_SHOT)
	_looping_sfx[name] = player

func stop_sfx(name: String) -> void:
	var stream := _find_stream(name)
	if stream != null:
		AudioBridge.stop_sound(stream)
	_looping_sfx.erase(name)

func play_bgm(stream: AudioStream) -> void:
	AudioBridge.play_music(stream, 0.0)

func play_bgm_fade_in(stream: AudioStream, fade_duration: float = -1.0) -> void:
	var actual := _resolve_fade_duration(stream, fade_duration, default_bgm_fade_percent)
	AudioBridge.play_music(stream, actual)

func stop_bgm_fade_out(fade_duration: float = -1.0) -> void:
	var actual := min_fade_duration if fade_duration < 0.0 else fade_duration
	AudioBridge.stop_music(actual)

func crossfade_bgm(new_stream: AudioStream, fade_duration: float = -1.0) -> void:
	var actual := _resolve_fade_duration(new_stream, fade_duration, default_bgm_fade_percent)
	AudioBridge.play_music(new_stream, actual)

func setup_ui_sounds(node: Node) -> void:
	var button := node as BaseButton
	if button != null:
		button.pressed.connect(_play_named_ui_sound.bind('UIPress'))
		button.focus_entered.connect(_play_named_ui_sound.bind('UIFocus'))
		button.mouse_entered.connect(button.grab_focus)
	var slider := node as Slider
	if slider != null:
		slider.value_changed.connect(func(_value: float): _play_named_ui_sound('UIPress'))
	for child in node.get_children():
		setup_ui_sounds(child)

func _play_named_ui_sound(name: String) -> void:
	var stream := _find_stream(name)
	if stream != null:
		AudioBridge.play_sound(stream, true, 1.0)

func play_sfx_fade_in(name: String, fade_duration: float = -1.0) -> void:
	play_sfx(name)

func stop_sfx_fade_out(name: String, fade_duration: float = -1.0) -> void:
	stop_sfx(name)

func stop_all_sfx() -> void:
	for name in _looping_sfx.keys():
		stop_sfx(String(name))

func stop_music() -> void:
	AudioBridge.stop_music(0.0)

func set_bgm_fade_percent(percent: float) -> void:
	default_bgm_fade_percent = clampf(percent, 0.001, 0.5)

func set_sfx_fade_percent(percent: float) -> void:
	default_sfx_fade_percent = clampf(percent, 0.001, 0.5)

func set_fade_limits(min_duration_value: float, max_duration_value: float) -> void:
	min_fade_duration = maxf(0.01, min_duration_value)
	max_fade_duration = maxf(min_fade_duration, max_duration_value)

func get_volume(bus_index: int) -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func set_volume(bus_index: int, v: float) -> void:
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(v))

func _resolve_fade_duration(stream: AudioStream, fade_duration: float, percent: float) -> float:
	if stream == null:
		return min_fade_duration
	if fade_duration >= 0.0:
		return fade_duration
	return clampf(stream.get_length() * percent, min_fade_duration, max_fade_duration)
