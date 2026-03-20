extends Control
## 综合功能 Demo
## 演示加密 + 压缩 + 原子写入 + 迁移 + UI 的完整工作流

const TEST_SLOT := 9  # 使用槽位 9 避免覆盖用户数据

@onready var _log: RichTextLabel = $VBox/Log
@onready var _enc_check: CheckBox = $VBox/Options/EncCheck
@onready var _comp_check: CheckBox = $VBox/Options/CompCheck
@onready var _atomic_check: CheckBox = $VBox/Options/AtomicCheck
@onready var _backup_check: CheckBox = $VBox/Options/BackupCheck

func _ready() -> void:
	_log.bbcode_enabled = true
	_append("[b]综合功能 Demo[/b]")
	_append("FORMAT_VERSION = %d\n" % SaveWriter.FORMAT_VERSION)
	_enc_check.button_pressed = true
	_comp_check.button_pressed = true
	_atomic_check.button_pressed = true

func _on_save_pressed() -> void:
	_append("\n[b]── 保存测试 ──[/b]")
	var opts := SaveWriter.WriteOptions.new()
	opts.game_version        = "1.0.0"
	opts.encryption_enabled  = _enc_check.button_pressed
	opts.encryption_key      = "demo-secret-key"
	opts.encryption_mode     = "aes_gcm"
	opts.compression_enabled = _comp_check.button_pressed
	opts.compression_mode    = "gzip"
	opts.atomic_write_enabled = _atomic_check.button_pressed
	opts.backup_enabled      = _backup_check.button_pressed

	var payload := {
		"player": { "hp": 100, "name": "Hero", "score": 9999 },
		"level":  { "current": 5, "unlocked": [1,2,3,4,5] },
	}

	var path := "user://saves/slot_%02d.json" % TEST_SLOT
	var ok := SaveWriter.write_json(payload, path, opts)

	_append("加密：%s | 压缩：%s | 原子写入：%s | 备份：%s" % [
		_yn(opts.encryption_enabled), _yn(opts.compression_enabled),
		_yn(opts.atomic_write_enabled), _yn(opts.backup_enabled)
	])
	if ok:
		_append("[color=green]✓ 保存成功：%s[/color]" % path)
		var size := FileAccess.open(path, FileAccess.READ).get_length() if FileAccess.file_exists(path) else 0
		_append("文件大小：%d 字节" % size)
	else:
		_append("[color=red]✗ 保存失败[/color]")

func _on_load_pressed() -> void:
	_append("\n[b]── 加载测试 ──[/b]")
	var path := "user://saves/slot_%02d.json" % TEST_SLOT
	if not FileAccess.file_exists(path):
		_append("[color=red]文件不存在，请先保存[/color]")
		return

	var opts := SaveWriter.ReadOptions.new()
	opts.encryption_key = "demo-secret-key" if _enc_check.button_pressed else ""

	var payload := SaveWriter.read_json(path, opts)
	if payload.is_empty():
		_append("[color=red]✗ 加载失败（解密/解压错误）[/color]")
		return

	_append("[color=green]✓ 加载成功[/color]")
	_append("数据：" + JSON.stringify(payload, "  "))

func _on_wrong_key_pressed() -> void:
	_append("\n[b]── 错误密钥测试（验证完整性保护）──[/b]")
	var path := "user://saves/slot_%02d.json" % TEST_SLOT
	if not FileAccess.file_exists(path):
		_append("[color=red]文件不存在，请先保存[/color]")
		return
	var opts := SaveWriter.ReadOptions.new()
	opts.encryption_key = "wrong-key-12345"
	var payload := SaveWriter.read_json(path, opts)
	if payload.is_empty():
		_append("[color=green]✓ 正确：错误密钥被拒绝（完整性验证通过）[/color]")
	else:
		_append("[color=red]✗ 警告：错误密钥未被检测到[/color]")

func _on_cleanup_pressed() -> void:
	var path := "user://saves/slot_%02d.json" % TEST_SLOT
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_append("\n[color=orange]已清理测试文件[/color]")

func _on_compression_bench_pressed() -> void:
	_append("\n[b]── 压缩性能基准测试 ──[/b]")

	# 生成大数据：模拟 1000 个 NPC 的存档数据（高重复性，适合压缩）
	var big_payload: Dictionary = {}
	var npcs: Array = []
	for i in range(1000):
		npcs.append({
			"id": i,
			"name": "NPC_%04d" % i,
			"hp": 100,
			"mp": 50,
			"level": (i % 20) + 1,
			"position": { "x": float(i * 3), "y": 0.0, "z": float(i * 2) },
			"inventory": ["sword", "shield", "potion", "potion", "potion"],
			"flags": { "alive": true, "hostile": (i % 3 == 0), "quest_giver": (i % 10 == 0) },
			"stats": { "str": 10, "dex": 8, "int": 6, "vit": 12 },
		})
	big_payload["npcs"] = { "list": npcs }
	big_payload["world"] = {
		"seed": 123456789,
		"time": 72000,
		"weather": "sunny",
		"tiles": range(500),  # 500 个地图格子
	}

	var path_plain := "user://saves/bench_plain.json"
	var path_gzip  := "user://saves/bench_gzip.json"
	var path_enc   := "user://saves/bench_enc.json"

	# 无压缩
	var opts_plain := SaveWriter.WriteOptions.new()
	opts_plain.game_version = "bench"
	opts_plain.atomic_write_enabled = false
	SaveWriter.write_json(big_payload, path_plain, opts_plain)

	# gzip 压缩
	var opts_gzip := SaveWriter.WriteOptions.new()
	opts_gzip.game_version = "bench"
	opts_gzip.compression_enabled = true
	opts_gzip.compression_mode = "gzip"
	opts_gzip.atomic_write_enabled = false
	SaveWriter.write_json(big_payload, path_gzip, opts_gzip)

	# gzip + AES-GCM 加密
	var opts_enc := SaveWriter.WriteOptions.new()
	opts_enc.game_version = "bench"
	opts_enc.compression_enabled = true
	opts_enc.compression_mode = "gzip"
	opts_enc.encryption_enabled = true
	opts_enc.encryption_key = "bench-key"
	opts_enc.encryption_mode = "aes_gcm"
	opts_enc.atomic_write_enabled = false
	SaveWriter.write_json(big_payload, path_enc, opts_enc)

	# 读取文件大小
	var sz_plain := _file_size(path_plain)
	var sz_gzip  := _file_size(path_gzip)
	var sz_enc   := _file_size(path_enc)

	_append("数据规模：1000 个 NPC + 世界数据")
	_append("原始 JSON：    [color=white]%s[/color]" % _fmt_size(sz_plain))
	_append("gzip 压缩：    [color=green]%s[/color]（压缩率 %.1f%%）" % [_fmt_size(sz_gzip),  100.0 * (1.0 - float(sz_gzip)  / sz_plain)])
	_append("gzip + AES-GCM：[color=cyan]%s[/color]（压缩率 %.1f%%）" % [_fmt_size(sz_enc),   100.0 * (1.0 - float(sz_enc)   / sz_plain)])

	# 验证解压后数据完整性
	var opts_read := SaveWriter.ReadOptions.new()
	opts_read.encryption_key = "bench-key"
	var loaded := SaveWriter.read_json(path_enc, opts_read)
	var npc_count: int = (loaded.get("npcs", {}) as Dictionary).get("list", []).size()
	if npc_count == 1000:
		_append("[color=green]✓ 解压验证通过：NPC 数量 = %d[/color]" % npc_count)
	else:
		_append("[color=red]✗ 解压验证失败：NPC 数量 = %d（期望 1000）[/color]" % npc_count)

	# 清理基准文件
	for p in [path_plain, path_gzip, path_enc]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

func _file_size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_length() if f else 0

func _fmt_size(bytes: int) -> String:
	if bytes >= 1024:
		return "%.1f KB (%d B)" % [bytes / 1024.0, bytes]
	return "%d B" % bytes

func _yn(v: bool) -> String:
	return "[color=green]是[/color]" if v else "[color=gray]否[/color]"

func _append(text: String) -> void:
	_log.append_text(text + "\n")
