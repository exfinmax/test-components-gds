class_name SettingsModule
extends ISaveModule
## 全局存档模块 — 游戏设置
##
## 负责存储所有与设备/账号绑定的设置，
## 属于全局存档（is_global = true），不随槽位切换而改变。
##
## 用法：
##   SaveSystem.register_module(SettingsModule.new())
##
## 读取设置：
##   var vol = SettingsModule.instance.get_value("master_volume", 0.8)
##
## 修改设置：
##   SettingsModule.instance.set_value("master_volume", 0.5)
##   SaveSystem.save_global()   # 立即落盘

signal settings_changed(key: String, value: Variant)

## 单例引用（注册后自动赋值）
static var instance: SettingsModule

# ──────────────────────────────────────────────
# 默认值（新游戏 / 重置用）
# ──────────────────────────────────────────────
const DEFAULTS := {
	"master_volume"  : 0.8,
	"music_volume"   : 0.8,
	"sfx_volume"     : 0.8,
	"screen_shake"   : 0.5,
	"fullscreen"     : false,
	"language"       : "zh_CN",
}

var _values: Dictionary = {}

func _init() -> void:
	_values = DEFAULTS.duplicate(true)
	instance = self

# ──────────────────────────────────────────────
# ISaveModule 接口
# ──────────────────────────────────────────────

func get_module_key() -> String: return "settings"

func is_global() -> bool: return true

func collect_data() -> Dictionary:
	return _values.duplicate(true)

func apply_data(data: Dictionary) -> void:
	for key in data:
		_values[key] = data[key]

func get_default_data() -> Dictionary:
	return DEFAULTS.duplicate(true)

func on_new_game() -> void:
	_values = DEFAULTS.duplicate(true)

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

func get_value(key: String, fallback: Variant = null) -> Variant:
	return _values.get(key, fallback if fallback != null else DEFAULTS.get(key))

func set_value(key: String, value: Variant) -> void:
	_values[key] = value
	settings_changed.emit(key, value)

func reset_to_defaults() -> void:
	_values = DEFAULTS.duplicate(true)

func get_all() -> Dictionary:
	return _values.duplicate(true)
