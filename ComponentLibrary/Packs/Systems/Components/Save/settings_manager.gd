extends Node
## 设置管理器 - 管理游戏设置（音量、画质等）
##
## 从 SaveManager 中分离出来，职责单一
## 可作为 Autoload 使用，也可以挂在任意节点下

signal settings_changed

const SETTINGS_PATH = "user://settings.data"

## 默认设置
var _defaults: Dictionary = {
	"Master": 0.5,
	"Music": 0.5,
	"SFX": 0.5,
	"ShakeStrength": 0.5,
}

## 当前设置
var current: Dictionary = {}

func _ready() -> void:
	current = _defaults.duplicate()
	load_settings()

func get_value(key: String, default_value = null):
	return current.get(key, default_value if default_value != null else _defaults.get(key))

func set_value(key: String, value) -> void:
	current[key] = value
	settings_changed.emit()

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(current)

func load_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var saved = file.get_var()
		if saved is Dictionary:
			for key in saved:
				current[key] = saved[key]

func reset_to_defaults() -> void:
	current = _defaults.duplicate()
	settings_changed.emit()

func get_component_data() -> Dictionary:
	return current.duplicate()
