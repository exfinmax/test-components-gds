class_name PlayerModule
extends ISaveModule
## 槽位存档模块 — 玩家状态（物品栏、属性、位置等）
##
## 存储当前槽位内与玩家角色相关的所有运行时数据。
## 属于槽位存档（is_global = false），随槽位切换而改变。
##
## 用法：
##   SaveSystem.register_module(PlayerModule.new())
##
## 保存玩家位置：
##   PlayerModule.instance.position = player.global_position
##   SaveSystem.save_slot()
##
## 读取血量：
##   player.hp = PlayerModule.instance.hp

## 单例引用
static var instance: PlayerModule

# ──────────────────────────────────────────────
# 玩家核心属性
# ──────────────────────────────────────────────

var hp: int        = 100
var max_hp: int    = 100
var mp: int        = 50
var max_mp: int    = 50
var level: int     = 1
var experience: int = 0
var gold: int       = 0

## 上次保存时的位置（scene_path + 坐标）
var scene_path: String = ""
var position: Vector2  = Vector2.ZERO

## 物品栏：Array of { "id": String, "count": int, "data": Dictionary }
var inventory: Array = []

## 装备：slot_name → item_id
var equipment: Dictionary = {}

## 自定义玩家数据（开放扩展）
var custom: Dictionary = {}

func _init() -> void:
	instance = self

# ──────────────────────────────────────────────
# ISaveModule 接口
# ──────────────────────────────────────────────

func get_module_key() -> String: return "player"

func is_global() -> bool: return false

func collect_data() -> Dictionary:
	return {
		"hp":          hp,
		"max_hp":      max_hp,
		"mp":          mp,
		"max_mp":      max_mp,
		"level":       level,
		"experience":  experience,
		"gold":        gold,
		"scene_path":  scene_path,
		"position":    { "x": position.x, "y": position.y },
		"inventory":   inventory.duplicate(true),
		"equipment":   equipment.duplicate(true),
		"custom":      custom.duplicate(true),
	}

func apply_data(data: Dictionary) -> void:
	hp          = int(data.get("hp",         100))
	max_hp      = int(data.get("max_hp",     100))
	mp          = int(data.get("mp",          50))
	max_mp      = int(data.get("max_mp",      50))
	level       = int(data.get("level",        1))
	experience  = int(data.get("experience",   0))
	gold        = int(data.get("gold",         0))
	scene_path  = str(data.get("scene_path",  ""))
	var pos     = data.get("position", {})
	position    = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0))) if pos is Dictionary else Vector2.ZERO
	inventory   = (data.get("inventory", []) as Array).duplicate(true)
	equipment   = (data.get("equipment", {}) as Dictionary).duplicate(true)
	custom      = (data.get("custom",    {}) as Dictionary).duplicate(true)

func get_default_data() -> Dictionary:
	return {
		"hp": 100, "max_hp": 100, "mp": 50, "max_mp": 50,
		"level": 1, "experience": 0, "gold": 0,
		"scene_path": "", "position": {"x": 0.0, "y": 0.0},
		"inventory": [], "equipment": {}, "custom": {},
	}

func on_new_game() -> void:
	apply_data(get_default_data())

# ──────────────────────────────────────────────
# 物品栏辅助
# ──────────────────────────────────────────────

## 添加物品（已有则叠加数量）
func add_item(item_id: String, count: int = 1, item_data: Dictionary = {}) -> void:
	for entry in inventory:
		if entry["id"] == item_id:
			entry["count"] = int(entry["count"]) + count
			return
	inventory.append({ "id": item_id, "count": count, "data": item_data.duplicate(true) })

## 移除物品（返回 false 表示数量不足）
func remove_item(item_id: String, count: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			var cur := int(inventory[i]["count"])
			if cur < count:
				return false
			if cur == count:
				inventory.remove_at(i)
			else:
				inventory[i]["count"] = cur - count
			return true
	return false

## 获取物品数量（0 表示没有）
func get_item_count(item_id: String) -> int:
	for entry in inventory:
		if entry["id"] == item_id:
			return int(entry["count"])
	return 0

## 是否拥有指定物品
func has_item(item_id: String, count: int = 1) -> bool:
	return get_item_count(item_id) >= count
