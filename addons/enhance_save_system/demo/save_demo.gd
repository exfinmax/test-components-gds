extends Node
## ════════════════════════════════════════════════════════════════
##  SaveSystem 演示脚本
##  说明：将本节点添加到场景，运行后查看 Output 面板的打印结果
## ════════════════════════════════════════════════════════════════
##
## 演示内容：
##   1. 注册模块（全局 + 槽位）
##   2. 新游戏初始化
##   3. 修改数据并保存
##   4. 加载并验证
##   5. 多槽位切换
##   6. 导出 / 导入 JSON
##   7. 删除槽位
##   8. 彩蛋触发
## ════════════════════════════════════════════════════════════════

func _ready() -> void:
	print("\n═══════════════════════════════════════")
	print(" SaveSystem Demo 开始运行")
	print("═══════════════════════════════════════\n")

	# ── 步骤 1：注册模块 ────────────────────────────────────────
	print("【1】注册模块...")
	var sm := get_tree().root.get_node_or_null("SaveSystem")        # 演示用：手动实例化（游戏中用 AutoLoad）
	sm.game_version = "0.1.0-demo"
	sm.max_slots = 4

	var settings := SettingsModule.new()
	var stats    := StatsModule.new()
	var level    := LevelModule.new()
	var player   := PlayerModule.new()

	sm.register_module(settings)    # 全局
	sm.register_module(stats)       # 全局
	sm.register_module(level)       # 槽位
	sm.register_module(player)      # 槽位

	print("  注册完成：", sm.get_registered_keys())

	# ── 步骤 2：新游戏初始化 ─────────────────────────────────────
	print("\n【2】新游戏初始化（槽位 1）...")
	sm.new_game(1)
	print("  player.hp   = ", player.hp)
	print("  level._levels = ", level._levels)

	# ── 步骤 3：修改数据 ─────────────────────────────────────────
	print("\n【3】修改游戏数据...")
	settings.set_value("master_volume", 0.6)
	settings.set_value("fullscreen", true)

	stats.on_new_game()                   # 开始一次游戏（+1 次数）
	stats.increment("enemies_killed", 5)

	level.unlock_level("level_01")
	level.complete_level("level_01", 9800, 3)
	level.unlock_level("level_02")

	player.hp       = 80
	player.level    = 3
	player.gold     = 250
	player.scene_path = "res://levels/level_02.tscn"
	player.position = Vector2(128.0, 256.0)
	player.add_item("sword_01")
	player.add_item("potion_hp", 5)
	player.equipment["weapon"] = "sword_01"

	print("  settings.master_volume = ", settings.get_value("master_volume"))
	print("  stats.total_play_count = ", stats.total_play_count)
	print("  level.is_completed(level_01) = ", level.is_completed("level_01"))
	print("  player.gold = ", player.gold, "  inventory = ", player.inventory)

	# ── 步骤 4：保存 ──────────────────────────────────────────────
	print("\n【4】保存数据...")
	var ok_global :bool= sm.save_global()
	var ok_slot1  :bool= sm.save_slot(1)
	print("  save_global OK =", ok_global, "  save_slot(1) OK =", ok_slot1)

	# ── 步骤 5：加载并验证 ────────────────────────────────────────
	print("\n【5】重置内存状态后加载...")
	sm.new_game(1)           # 先清空
	print("  （重置后）player.gold =", player.gold)

	sm.load_global()
	sm.load_slot(1)
	print("  （加载后）player.gold =", player.gold)
	print("  （加载后）player.position =", player.position)
	print("  （加载后）settings.fullscreen =", settings.get_value("fullscreen"))
	print("  （加载后）level.get_stars(level_01) =", level.get_stars("level_01"))
	print("  （加载后）player.has_item(potion_hp) =", player.has_item("potion_hp"))

	# ── 步骤 6：多槽位 ────────────────────────────────────────────
	print("\n【6】保存到槽位 2...")
	player.gold = 500
	level.complete_level("level_02", 7500, 2)
	sm.save_slot(2)

	# 列出所有槽位
	print("  槽位列表：")
	for info: SlotInfo in sm.list_slots():
		print("    ", info)

	# 切换到槽位 1 验证不互相污染
	sm.load_slot(1)
	print("  切回槽位 1 → player.gold =", player.gold)   # 应为 250
	sm.load_slot(2)
	print("  切到槽位 2 → player.gold =", player.gold)   # 应为 500

	# ── 步骤 7：导出 / 导入 ────────────────────────────────────────
	print("\n【7】导出槽位 1 → 导入为槽位 3...")
	var export_path := "user://saves/export_demo.json"
	var ok_export :bool= sm.export_slot(1, export_path)
	var ok_import :bool= sm.import_slot(3, export_path)
	print("  export OK =", ok_export, "  import OK =", ok_import)

	sm.load_slot(3)
	print("  （从槽位 3 加载）player.gold =", player.gold)   # 应与槽位 1 相同（250）

	# 预览文件中的 _meta
	var meta := SaveWriter.peek_meta(export_path)
	print("  export _meta =", meta)

	# ── 步骤 8：彩蛋 ─────────────────────────────────────────────
	print("\n【8】彩蛋触发测试...")
	stats.easter_egg_triggered.connect(func(egg): print("  🎉 彩蛋触发：", egg))
	var fired1 := stats.trigger_egg("first_blood")
	var fired2 := stats.trigger_egg("first_blood")   # 重复不会再触发
	print("  first_blood 第一次触发 =", fired1, "  第二次触发 =", fired2)
	print("  所有已触发彩蛋 =", stats.get_all_eggs())

	# ── 步骤 9：删除槽位 ──────────────────────────────────────────
	print("\n【9】删除槽位 3...")
	sm.delete_slot(3)
	print("  槽位 3 存在 =", sm.slot_exists(3))

	# ── 完成 ──────────────────────────────────────────────────────
	print("\n【快捷 API】quick_save / quick_load...")
	sm.current_slot = 1
	var qs :bool= sm.quick_save()
	var ql :bool= sm.quick_load()
	print("  quick_save OK =", qs, "  quick_load OK =", ql)

	print("\n═══════════════════════════════════════")
	print(" SaveSystem Demo 完成！")
	print("═══════════════════════════════════════\n")

	print("【SaveSystem 状态快照】")
	print(sm.get_component_data())
