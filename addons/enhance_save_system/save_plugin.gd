@tool
class_name SavePlugin
extends EditorPlugin

static var instance : SavePlugin

func _init() -> void:
	instance = self

## 插件加载时执行
func _enable_plugin() -> void:
	# 注册SaveSystem为AutoLoad
	add_autoload_singleton("SaveSystem", get_plugin_path() + "/core/save_system.gd")

## 插件卸载时执行
func _disable_plugin() -> void:
	remove_autoload_singleton("DialogueManager")

static func get_plugin_path() -> String:
	if not is_instance_valid(instance):
		return ""
	return instance.get_script().resource_path.get_base_dir()
