extends Control

@onready var _status: Label = %Status

func _ready() -> void:
	var checks := []
	checks.append(_has_root_node("SceneManager"))
	checks.append(_has_root_node("SoundManager"))
	checks.append(_has_root_node("PhantomCameraManager"))
	checks.append(_resource_exists("res://addons/godot_state_charts/state_chart.gd"))
	checks.append(_resource_exists("res://addons/gdfxr/SFXRGenerator.gd"))
	_status.text = "\n".join(checks)

func _on_play_ui_sound_pressed() -> void:
	var sound_manager := get_node_or_null("/root/SoundManager")
	if sound_manager == null:
		_status.text = "SoundManager not available"
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	var player = sound_manager.call("play_ui_sound", stream)
	_status.text = "Played UI sound through SoundManager: %s" % [str(player != null)]

func _on_scene_manager_pressed() -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	_status.text = "SceneManager ready: %s" % [str(scene_manager != null and scene_manager.has_method("change_scene_to_file"))]

func _on_state_chart_pressed() -> void:
	var state_chart_script := load("res://addons/godot_state_charts/state_chart.gd")
	if state_chart_script == null:
		_status.text = "StateChart script missing"
		return
	var chart = state_chart_script.new()
	_status.text = "StateChart instantiated: %s" % [str(chart != null)]
	if chart != null:
		chart.free()

func _has_root_node(name: String) -> String:
	return "%s: %s" % [name, str(get_node_or_null("/root/" + name) != null)]

func _resource_exists(path: String) -> String:
	return "%s: %s" % [path.get_file(), str(ResourceLoader.exists(path))]
