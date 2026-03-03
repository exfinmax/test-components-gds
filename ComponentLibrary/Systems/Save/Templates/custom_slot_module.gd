## ─────────────────────────────────────────────────────────────────────────
## 模板：槽位存档模块（复制此文件后重命名 class_name 和 get_module_key）
## 槽位存档存储与存档槽绑定的数据：关卡进度、玩家状态、物品栏等
## ─────────────────────────────────────────────────────────────────────────
class_name CustomSlotModule     ## ← 改为你的模块名
extends ISaveModule

## 单例引用（可选，方便其他脚本直接访问）
static var instance: CustomSlotModule

# ──────────────────────────────────────────────
# 你的数据字段（全部用基本类型：bool / int / float / String / Array / Dictionary）
# ──────────────────────────────────────────────
var checkpoint: String = ""
var collected_items: Array = []
var flags: Dictionary  = {}     # key → bool，用于任务/事件标志

func _init() -> void:
	instance = self

# ──────────────────────────────────────────────
# ISaveModule 接口（必须实现）
# ──────────────────────────────────────────────

## ← 改为唯一的模块键名
func get_module_key() -> String: return "custom_slot"

## 槽位模块固定返回 false
func is_global() -> bool: return false

## 收集当前状态 → 返回可 JSON 序列化的字典
func collect_data() -> Dictionary:
	return {
		"checkpoint"     : checkpoint,
		"collected_items": collected_items.duplicate(true),
		"flags"          : flags.duplicate(true),
	}

## 将加载到的数据应用到当前状态
func apply_data(data: Dictionary) -> void:
	checkpoint      = str(data.get("checkpoint",      ""))
	collected_items = (data.get("collected_items", []) as Array).duplicate(true)
	flags           = (data.get("flags",           {}) as Dictionary).duplicate(true)

## 新游戏默认值（可选重写）
func get_default_data() -> Dictionary:
	return {
		"checkpoint":      "",
		"collected_items": [],
		"flags":           {},
	}

## 切换到新游戏时重置
func on_new_game() -> void:
	apply_data(get_default_data())

# ──────────────────────────────────────────────
# 你的业务 API（可选添加）
# ──────────────────────────────────────────────

## 设置/读取任务标志
func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value

func get_flag(key: String, default: bool = false) -> bool:
	return bool(flags.get(key, default))

## 收集物品
func collect(item_id: String) -> void:
	if not collected_items.has(item_id):
		collected_items.append(item_id)

func has_collected(item_id: String) -> bool:
	return collected_items.has(item_id)
