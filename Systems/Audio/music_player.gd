extends Node

enum BUS{MASTER, SFX, BGM}

signal sfx_finish

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

# 淡入淡出配置
var default_bgm_fade_percent: float = 0.02  # BGM 默认淡入淡出百分比（2%）
var default_sfx_fade_percent: float = 0.10  # SFX 默认淡入淡出百分比（10%）
var min_fade_duration: float = 0.1  # 最小淡入淡出时长（秒）
var max_fade_duration: float = 5.0  # 最大淡入淡出时长（秒）
var active_tweens: Dictionary = {}  # 存储活动的 Tween 对象

func play_sfx(_name: String) -> void :
	var player: = sfx.get_node(_name) as AudioStreamPlayer
	if not player:
		return
	player.play()
	var pitch = 1
	player.pitch_scale = randf_range(pitch - 0.2, pitch + 0.2)
	sfx_finish.emit()

func play_sfx_looping(_name: String) -> void:
	"""播放循环音效 - 音效播放完成后自动重新播放"""
	var player: = sfx.get_node(_name) as AudioStreamPlayer
	if not player:
		return
	
	# 如果已经在播放，不重复播放
	if player.playing:
		return
	
	player.play()
	var pitch = 1
	player.pitch_scale = randf_range(pitch - 0.2, pitch + 0.2)
	
	# 连接播放完成信号以实现循环
	if not player.finished.is_connected(_on_looping_sfx_finished.bind(_name)):
		player.finished.connect(_on_looping_sfx_finished.bind(_name))

func _on_looping_sfx_finished(_name: String) -> void:
	"""循环音效播放完成后重新播放"""
	var player: = sfx.get_node(_name) as AudioStreamPlayer
	if not player:
		return
	
	# 只有在没有被手动停止的情况下才重新播放
	# 通过检查是否还连接着信号来判断
	if player.finished.is_connected(_on_looping_sfx_finished.bind(_name)):
		player.play()
		var pitch = 1
		player.pitch_scale = randf_range(pitch - 0.2, pitch + 0.2)


func play_bgm(stream: AudioStream) -> void :
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.play()

func play_bgm_fade_in(stream: AudioStream, fade_duration: float = -1.0) -> void:
	"""播放背景音乐并淡入
	fade_duration: 淡入时长（秒），-1 表示使用音频长度的百分比（默认 2%）
	"""
	# 如果已经在播放相同的音乐，不做任何操作
	if bgm_player.stream == stream and bgm_player.playing:
		return
	
	# 计算淡入时长
	if fade_duration < 0:
		var audio_length = stream.get_length()
		fade_duration = clamp(audio_length * default_bgm_fade_percent, min_fade_duration, max_fade_duration)
	
	# 取消之前的淡入淡出
	_cancel_tween("bgm")
	
	# 设置音乐并从静音开始
	bgm_player.stream = stream
	bgm_player.volume_db = -80.0  # 开始时静音
	bgm_player.play()
	
	# 创建淡入动画
	var tween = create_tween()
	active_tweens["bgm"] = tween
	tween.tween_property(bgm_player, "volume_db", 0.0, fade_duration)
	tween.finished.connect(func(): active_tweens.erase("bgm"))
	
	DebugHelper.log("MusicPlayer: BGM fade in started (%.2fs, %.1f%% of %.1fs)" % [fade_duration, default_bgm_fade_percent * 100, stream.get_length()])

func stop_bgm_fade_out(fade_duration: float = -1.0) -> void:
	"""停止背景音乐并淡出
	fade_duration: 淡出时长（秒），-1 表示使用音频长度的百分比（默认 2%）
	"""
	if not bgm_player.playing:
		return
	
	# 计算淡出时长
	if fade_duration < 0:
		if bgm_player.stream:
			var audio_length = bgm_player.stream.get_length()
			fade_duration = clamp(audio_length * default_bgm_fade_percent, min_fade_duration, max_fade_duration)
		else:
			fade_duration = min_fade_duration
	
	# 取消之前的淡入淡出
	_cancel_tween("bgm")
	
	# 创建淡出动画
	var tween = create_tween()
	active_tweens["bgm"] = tween
	tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
	tween.finished.connect(func(): 
		bgm_player.stop()
		bgm_player.volume_db = 0.0  # 重置音量
		active_tweens.erase("bgm")
	)
	
	DebugHelper.log("MusicPlayer: BGM fade out started (%.2fs)" % fade_duration)

func crossfade_bgm(new_stream: AudioStream, fade_duration: float = -1.0) -> void:
	"""交叉淡入淡出切换背景音乐
	fade_duration: 总切换时长（秒），-1 表示使用新音频长度的百分比（默认 2%）
	"""
	# 如果已经在播放相同的音乐，不做任何操作
	if bgm_player.stream == new_stream and bgm_player.playing:
		return
	
	# 如果当前没有播放音乐，直接淡入
	if not bgm_player.playing:
		play_bgm_fade_in(new_stream, fade_duration)
		return
	
	# 计算淡入淡出时长
	if fade_duration < 0:
		var audio_length = new_stream.get_length()
		fade_duration = clamp(audio_length * default_bgm_fade_percent, min_fade_duration, max_fade_duration)
	
	# 淡出当前音乐，然后淡入新音乐
	_cancel_tween("bgm")
	
	var tween = create_tween()
	active_tweens["bgm"] = tween
	
	# 淡出当前音乐
	tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration * 0.5)
	
	# 切换音乐并淡入
	tween.tween_callback(func():
		bgm_player.stream = new_stream
		bgm_player.play()
	)
	tween.tween_property(bgm_player, "volume_db", 0.0, fade_duration * 0.5)
	tween.finished.connect(func(): active_tweens.erase("bgm"))
	
	DebugHelper.log("MusicPlayer: BGM crossfade started (%.2fs, %.1f%% of %.1fs)" % [fade_duration, default_bgm_fade_percent * 100, new_stream.get_length()])

func setup_ui_sounds(node: Node) -> void :
	var button: = node as Button
	if button:
		button.pressed.connect(play_sfx.bind("UIPress"))
		button.focus_entered.connect(play_sfx.bind("UIFocus"))
		button.mouse_entered.connect(button.grab_focus)

	var slider: = node as Slider
	if slider:
		slider.value_changed.connect(play_sfx.bind("UIPress").unbind(1))
		slider.focus_entered.connect(play_sfx.bind("UIFocus"))
		slider.mouse_entered.connect(slider.grab_focus)

	for child in node.get_children():
		setup_ui_sounds(child)

func stop_sfx(_name: String) -> void :
	var player: = sfx.get_node(_name) as AudioStreamPlayer
	if not player:
		return
	
	# 断开循环信号（如果存在）
	if player.finished.is_connected(_on_looping_sfx_finished.bind(_name)):
		player.finished.disconnect(_on_looping_sfx_finished.bind(_name))
	
	player.stop()

func play_sfx_fade_in(_name: String, fade_duration: float = -1.0) -> void:
	"""播放音效并淡入
	fade_duration: 淡入时长（秒），-1 表示使用音频长度的百分比（默认 10%）
	"""
	var player: = sfx.get_node(_name) as AudioStreamPlayer
	if not player:
		return
	
	# 计算淡入时长
	if fade_duration < 0:
		if player.stream:
			var audio_length = player.stream.get_length()
			fade_duration = clamp(audio_length * default_sfx_fade_percent, min_fade_duration, max_fade_duration)
		else:
			fade_duration = min_fade_duration
	
	# 取消之前的淡入淡出
	_cancel_tween("sfx_" + _name)
	
	# 从静音开始播放
	var original_volume = player.volume_db
	player.volume_db = -80.0
	player.play()
	
	# 应用随机音调
	var pitch = 1
	player.pitch_scale = randf_range(pitch - 0.2, pitch + 0.2)
	
	# 创建淡入动画
	var tween = create_tween()
	active_tweens["sfx_" + _name] = tween
	tween.tween_property(player, "volume_db", original_volume, fade_duration)
	tween.finished.connect(func(): 
		active_tweens.erase("sfx_" + _name)
		sfx_finish.emit()
	)
	
	if player.stream:
		DebugHelper.log("MusicPlayer: SFX '%s' fade in started (%.2fs, %.1f%% of %.1fs)" % [_name, fade_duration, default_sfx_fade_percent * 100, player.stream.get_length()])

func stop_sfx_fade_out(_name: String, fade_duration: float = -1.0) -> void:
	"""停止音效并淡出
	fade_duration: 淡出时长（秒），-1 表示使用音频长度的百分比（默认 10%）
	"""
	var player: = sfx.get_node(_name) as AudioStreamPlayer
	if not player:
		return
	
	if not player.playing:
		return
	
	# 计算淡出时长
	if fade_duration < 0:
		if player.stream:
			var audio_length = player.stream.get_length()
			fade_duration = clamp(audio_length * default_sfx_fade_percent, min_fade_duration, max_fade_duration)
		else:
			fade_duration = min_fade_duration
	
	# 断开循环信号（如果存在）
	if player.finished.is_connected(_on_looping_sfx_finished.bind(_name)):
		player.finished.disconnect(_on_looping_sfx_finished.bind(_name))
	
	# 取消之前的淡入淡出
	_cancel_tween("sfx_" + _name)
	
	# 保存原始音量
	var original_volume = player.volume_db
	
	# 创建淡出动画
	var tween = create_tween()
	active_tweens["sfx_" + _name] = tween
	tween.tween_property(player, "volume_db", -80.0, fade_duration)
	tween.finished.connect(func(): 
		player.stop()
		player.volume_db = original_volume  # 重置音量
		active_tweens.erase("sfx_" + _name)
	)
	
	DebugHelper.log("MusicPlayer: SFX '%s' fade out started (%.2fs)" % [_name, fade_duration])

func stop_all_sfx() -> void:
	for i:AudioStreamPlayer in sfx.get_children():
		i.stop()

func stop_music() -> void:
	bgm_player.stop()

func _cancel_tween(key: String) -> void:
	"""取消指定的 Tween 动画"""
	if active_tweens.has(key):
		var tween = active_tweens[key]
		if tween and tween.is_valid():
			tween.kill()
		active_tweens.erase(key)



func set_bgm_fade_percent(percent: float) -> void:
	"""设置 BGM 默认淡入淡出百分比
	percent: 百分比值（0.0 到 1.0），例如 0.02 表示 2%
	"""
	default_bgm_fade_percent = clamp(percent, 0.001, 0.5)  # 限制在 0.1% 到 50%
	DebugHelper.log("MusicPlayer: BGM fade percent set to %.1f%%" % (default_bgm_fade_percent * 100))

func set_sfx_fade_percent(percent: float) -> void:
	"""设置 SFX 默认淡入淡出百分比
	percent: 百分比值（0.0 到 1.0），例如 0.10 表示 10%
	"""
	default_sfx_fade_percent = clamp(percent, 0.001, 0.5)  # 限制在 0.1% 到 50%
	DebugHelper.log("MusicPlayer: SFX fade percent set to %.1f%%" % (default_sfx_fade_percent * 100))

func set_fade_limits(min_duration: float, max_duration: float) -> void:
	"""设置淡入淡出时长的最小和最大限制
	min_duration: 最小时长（秒）
	max_duration: 最大时长（秒）
	"""
	min_fade_duration = max(0.01, min_duration)
	max_fade_duration = max(min_fade_duration, max_duration)
	DebugHelper.log("MusicPlayer: Fade limits set to %.2fs - %.2fs" % [min_fade_duration, max_fade_duration])

func get_volume(bus_index: int) -> float:
	var db: = AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(db)


func set_volume(bus_index: int, v: float) -> void :
	var db: = linear_to_db(v)
	AudioServer.set_bus_volume_db(bus_index, db)
