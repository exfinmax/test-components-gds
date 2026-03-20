extends Control
## 存档迁移 Demo
## 演示从旧版本（version=1）存档迁移到当前 FORMAT_VERSION 的完整流程

const TEST_PATH := "user://saves/migration_test.json"

@onready var _log: RichTextLabel = $VBox/Log

func _ready() -> void:
	_log.bbcode_enabled = true
	_append("[b]存档迁移 Demo[/b]\n")
	_append("当前 FORMAT_VERSION = %d\n" % SaveWriter.FORMAT_VERSION)

func _on_create_old_save_pressed() -> void:
	# 创建一个模拟的旧版本（version=1）存档
	var old_save := {
		"_meta": {
			"version": 1,
			"saved_at": Time.get_unix_time_from_system(),
			"game_version": "0.1.0",
		},
		"player": {
			"hp": 100,
			"name": "Hero",          # v1 字段名
			"high_score": 9999,      # v1 字段名（v2 改为 score）
		},
		"level": {
			"current": 3,
		}
	}
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(old_save, "\t"))
	_append("\n[color=yellow]已创建旧版本存档（version=1）：[/color]")
	_append(JSON.stringify(old_save, "  "))

func _on_migrate_pressed() -> void:
	if not FileAccess.file_exists(TEST_PATH):
		_append("\n[color=red]请先创建旧版本存档[/color]")
		return

	# 读取旧存档
	var f := FileAccess.open(TEST_PATH, FileAccess.READ)
	var json := JSON.new()
	json.parse(f.get_as_text())
	var payload: Dictionary = json.data

	var old_version: int = payload.get("_meta", {}).get("version", 0)
	_append("\n[color=cyan]读取存档，版本：%d[/color]" % old_version)

	# 创建迁移管理器并注册迁移函数
	var mm := MigrationManager.new()

	# v1 → v2：player.name 改为 player.player_name，high_score 改为 score
	mm.register(1, func(p: Dictionary) -> Dictionary:
		if p.has("player"):
			var player: Dictionary = p["player"].duplicate()
			if player.has("name") and not player.has("player_name"):
				player["player_name"] = player["name"]
				player.erase("name")
			if player.has("high_score") and not player.has("score"):
				player["score"] = player["high_score"]
				player.erase("high_score")
			if not player.has("achievements"):
				player["achievements"] = []
			p["player"] = player
		return p
	)

	# v2 → v3：player 新增 play_time 字段
	mm.register(2, func(p: Dictionary) -> Dictionary:
		if p.has("player"):
			var player: Dictionary = p["player"].duplicate()
			if not player.has("play_time"):
				player["play_time"] = 0.0
			p["player"] = player
		return p
	)

	# 执行迁移
	var migrated := mm.migrate(payload, old_version, SaveWriter.FORMAT_VERSION)

	if not mm.last_error.is_empty():
		_append("[color=red]迁移失败：%s[/color]" % mm.last_error)
		return

	var new_version: int = migrated.get("_meta", {}).get("version", 0)
	_append("[color=green]✓ 迁移成功：%d → %d[/color]" % [old_version, new_version])
	_append("\n[b]迁移后数据：[/b]")
	_append(JSON.stringify(migrated, "  "))

	# 保存迁移后的存档
	var fw := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	fw.store_string(JSON.stringify(migrated, "\t"))
	_append("\n[color=green]已保存迁移后的存档[/color]")

func _on_cleanup_pressed() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)
	var bak := TEST_PATH + ".pre_migration.bak"
	if FileAccess.file_exists(bak):
		DirAccess.remove_absolute(bak)
	_append("\n[color=orange]已清理测试文件[/color]")

func _append(text: String) -> void:
	_log.append_text(text + "\n")
