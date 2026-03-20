## 迁移模块模板
##
## 演示如何为存档模块实现 migrate_payload() 迁移钩子，
## 以便在游戏版本升级时自动将旧存档数据迁移到新格式。
##
## 使用步骤：
##   1. 复制此文件到你的项目中
##   2. 修改 class_name 和 get_module_key()
##   3. 在 migrate_payload() 中添加你的迁移逻辑
##   4. 调用 SaveSystem.register_module(MyMigrationModule.new())

class_name MigrationModuleTemplate
extends ISaveModule

# ──────────────────────────────────────────────
# ISaveModule 必须实现的方法
# ──────────────────────────────────────────────


func get_module_key() -> String:
	return "my_module"  # ← 修改为你的模块键名

func is_global() -> bool:
	return false  # ← true = 全局存档，false = 槽位存档

func collect_data() -> Dictionary:
	# 收集当前游戏状态
	return {
		"level":       1,
		"score":       0,
		"player_name": "Player",
		# v2 新增字段
		"achievements": [],
		"play_time":    0.0,
	}

func apply_data(data: Dictionary) -> void:
	# 将存档数据应用到游戏状态
	# 此时 data 已经过迁移，可以安全访问所有当前版本字段
	var level:       int    = data.get("level", 1)
	var score:       int    = data.get("score", 0)
	var player_name: String = data.get("player_name", "Player")
	var achievements: Array = data.get("achievements", [])
	var play_time:   float  = data.get("play_time", 0.0)

	# 应用到你的游戏状态...
	print("应用存档：level=%d, score=%d, name=%s, achievements=%d, play_time=%.1f" % [
		level, score, player_name, achievements.size(), play_time
	])

# ──────────────────────────────────────────────
# migrate_payload — 版本迁移钩子（可选重写）
# ──────────────────────────────────────────────
##
## 当存档文件版本低于当前 FORMAT_VERSION 时，
## MigrationManager 会依次调用此方法升级数据。
##
## old_payload:  该模块在旧版本中的数据字典
## old_version:  存档文件中的旧版本号
## 返回：迁移后的数据字典

func migrate_payload(old_payload: Dictionary, old_version: int) -> Dictionary:
	var data := old_payload.duplicate(true)  # 深拷贝，避免修改原始数据

	# ── 从版本 1 迁移到版本 2 ──────────────────
	if old_version < 2:
		# 示例：v1 没有 achievements 字段，v2 新增
		if not data.has("achievements"):
			data["achievements"] = []

		# 示例：v1 的 "high_score" 字段在 v2 改名为 "score"
		if data.has("high_score") and not data.has("score"):
			data["score"] = data["high_score"]
			data.erase("high_score")

	# ── 从版本 2 迁移到版本 3 ──────────────────
	if old_version < 3:
		# 示例：v2 没有 play_time 字段，v3 新增
		if not data.has("play_time"):
			data["play_time"] = 0.0

		# 示例：v2 的 "name" 字段在 v3 改名为 "player_name"
		if data.has("name") and not data.has("player_name"):
			data["player_name"] = data["name"]
			data.erase("name")

	# ── 添加更多版本迁移逻辑 ──────────────────
	# if old_version < 4:
	#     data["new_field"] = default_value

	return data

# ──────────────────────────────────────────────
# 可选：注册全局迁移函数（在游戏启动时调用）
# ──────────────────────────────────────────────
##
## 除了模块级迁移，你也可以注册全局迁移函数：
##
##   func _ready():
##       SaveSystem.register_migration(1, _migrate_v1_to_v2)
##       SaveSystem.register_migration(2, _migrate_v2_to_v3)
##
##   static func _migrate_v1_to_v2(payload: Dictionary) -> Dictionary:
##       # 处理跨模块的全局迁移逻辑
##       return payload
