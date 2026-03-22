class_name AudioBridge
extends RefCounted

static func get_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("SoundManager")

static func has_manager() -> bool:
	return get_manager() != null

static func sync_settings(settings_module: Object) -> void:
	if settings_module == null:
		return
	var manager := get_manager()
	if manager == null:
		return
	if settings_module.has_method("get_value"):
		if manager.has_method("set_music_volume"):
			manager.call("set_music_volume", float(settings_module.call("get_value", "music_volume", 0.8)))
		if manager.has_method("set_sound_volume"):
			manager.call("set_sound_volume", float(settings_module.call("get_value", "sfx_volume", 0.8)))

static func play_sound(stream: AudioStream, is_ui: bool = false, pitch: float = 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null
	var manager := get_manager()
	if manager == null:
		return null
	if is_ui:
		if manager.has_method("play_ui_sound_with_pitch"):
			return manager.call("play_ui_sound_with_pitch", stream, pitch) as AudioStreamPlayer
		if manager.has_method("play_ui_sound"):
			return manager.call("play_ui_sound", stream) as AudioStreamPlayer
	else:
		if manager.has_method("play_sound_with_pitch"):
			return manager.call("play_sound_with_pitch", stream, pitch) as AudioStreamPlayer
		if manager.has_method("play_sound"):
			return manager.call("play_sound", stream) as AudioStreamPlayer
	return null

static func stop_sound(stream: AudioStream, is_ui: bool = false) -> void:
	var manager := get_manager()
	if manager == null or stream == null:
		return
	if is_ui and manager.has_method("stop_ui_sound"):
		manager.call("stop_ui_sound", stream)
	elif not is_ui and manager.has_method("stop_sound"):
		manager.call("stop_sound", stream)

static func play_music(stream: AudioStream, crossfade_duration: float = 0.0) -> AudioStreamPlayer:
	var manager := get_manager()
	if manager == null or stream == null:
		return null
	if manager.has_method("play_music"):
		return manager.call("play_music", stream, crossfade_duration) as AudioStreamPlayer
	return null

static func stop_music(fade_out_duration: float = 0.0) -> void:
	var manager := get_manager()
	if manager == null:
		return
	if manager.has_method("stop_music"):
		manager.call("stop_music", fade_out_duration)
