class_name LevelModule
extends ISaveModule
## 槽位存档模块 — 关卡进度
##
## 存储当前槽位内的关卡解锁、最高分、完成状态等。
## 属于槽位存档（is_global = false），随槽位切换而改变。
##
## 用法：
##   SaveSystem.register_module(LevelModule.new())
##
## 解锁关卡：
##   LevelModule.instance.unlock_level("level_02")
##   SaveSystem.save_slot()
##
## 读取完成状态：
##   if LevelModule.instance.is_completed("level_01"):
##       show_star_rating()

## 单例引用
static var instance: LevelModule

## key = level_id，value = { "unlocked": bool, "completed": bool, "best_score": int, "stars": int }
var _levels: Dictionary = {}

## 当前加载/激活的关卡 ID
var current_level_id: String = ""

func _init() -> void:
	instance = self

# ──────────────────────────────────────────────
# ISaveModule 接口
# ──────────────────────────────────────────────

func get_module_key() -> String: return "level"

func is_global() -> bool: return false

func collect_data() -> Dictionary:
	return {
		"levels":           _levels.duplicate(true),
		"current_level_id": current_level_id,
	}

func apply_data(data: Dictionary) -> void:
	_levels           = (data.get("levels", {}) as Dictionary).duplicate(true)
	current_level_id  = str(data.get("current_level_id", ""))

func get_default_data() -> Dictionary:
	return {
		"levels":           {},
		"current_level_id": "",
	}

func on_new_game() -> void:
	_levels = {}
	current_level_id = ""

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

## 解锁关卡
func unlock_level(level_id: String) -> void:
	var entry := _get_or_create(level_id)
	entry["unlocked"] = true
	_levels[level_id] = entry

## 标记关卡完成
func complete_level(level_id: String, score: int = 0, stars: int = 0) -> void:
	var entry := _get_or_create(level_id)
	entry["unlocked"]   = true
	entry["completed"]  = true
	entry["best_score"] = maxi(int(entry.get("best_score", 0)), score)
	entry["stars"]      = maxi(int(entry.get("stars", 0)), stars)
	_levels[level_id]   = entry

## 关卡是否已解锁
func is_unlocked(level_id: String) -> bool:
	return bool(_levels.get(level_id, {}).get("unlocked", false))

## 关卡是否已完成
func is_completed(level_id: String) -> bool:
	return bool(_levels.get(level_id, {}).get("completed", false))

## 获取关卡最高分
func get_best_score(level_id: String) -> int:
	return int(_levels.get(level_id, {}).get("best_score", 0))

## 获取关卡星级
func get_stars(level_id: String) -> int:
	return int(_levels.get(level_id, {}).get("stars", 0))

## 获取所有已解锁关卡 ID
func get_unlocked_levels() -> Array:
	return _levels.keys().filter(func(id): return is_unlocked(id))

## 获取所有已完成关卡 ID
func get_completed_levels() -> Array:
	return _levels.keys().filter(func(id): return is_completed(id))

## 获取完整关卡记录（用于 UI）
func get_level_record(level_id: String) -> Dictionary:
	return _levels.get(level_id, {}).duplicate()

# ──────────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────────

func _get_or_create(level_id: String) -> Dictionary:
	if not _levels.has(level_id):
		_levels[level_id] = {
			"unlocked":   false,
			"completed":  false,
			"best_score": 0,
			"stars":      0,
		}
	return _levels[level_id]
