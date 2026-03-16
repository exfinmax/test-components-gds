## ─────────────────────────────────────────────────────────────────────────
## 模板：全局存档模块（复制此文件后重命名 class_name 和 get_module_key）
## 全局存档存储与槽位无关的数据：设置、统计、成就、选项等
## ─────────────────────────────────────────────────────────────────────────
class_name CustomGlobalModule     ## ← 改为你的模块名
extends ISaveModule

## 单例引用（可选，方便其他脚本直接访问）
static var instance: CustomGlobalModule

# ──────────────────────────────────────────────
# 你的数据字段（全部用基本类型：bool / int / float / String / Array / Dictionary）
# ──────────────────────────────────────────────
var my_bool_value: bool = false
var my_int_value: int   = 0
var my_string_value: String = ""
# var custom_dict: Dictionary = {}

func _init() -> void:
	instance = self

# ──────────────────────────────────────────────
# ISaveModule 接口（必须实现）
# ──────────────────────────────────────────────

## ← 改为唯一的模块键名（在同一 SaveSystem 内不能重复）
func get_module_key() -> String: return "custom_global"

## 全局模块固定返回 true
func is_global() -> bool: return true

## 收集当前状态 → 返回可 JSON 序列化的字典
func collect_data() -> Dictionary:
	return {
		"my_bool"  : my_bool_value,
		"my_int"   : my_int_value,
		"my_string": my_string_value,
		# "custom"   : custom_dict.duplicate(true),
	}

## 将加载到的数据应用到当前状态
func apply_data(data: Dictionary) -> void:
	my_bool_value   = bool(data.get("my_bool",   false))
	my_int_value    = int(data.get("my_int",      0))
	my_string_value = str(data.get("my_string",   ""))
	# custom_dict = (data.get("custom", {}) as Dictionary).duplicate(true)

## 新游戏时的默认值（可选重写）
func get_default_data() -> Dictionary:
	return {
		"my_bool"  : false,
		"my_int"   : 0,
		"my_string": "",
	}

# ──────────────────────────────────────────────
# 你的业务 API（可选添加）
# ──────────────────────────────────────────────

# func some_action() -> void:
#     my_int_value += 1
