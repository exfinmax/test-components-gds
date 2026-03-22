@tool
extends EditorPlugin

const AUTOLOAD_NAME := "SoundManager"

func _enter_tree():
	if not ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, get_plugin_path() + "/sound_manager.gd")


func _exit_tree():
	if ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)


func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()
