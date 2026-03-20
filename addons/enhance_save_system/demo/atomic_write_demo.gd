extends Control
## 原子写入 Demo
## 演示 AtomicWriter 的原子写入和 .bak 备份功能

const TEST_PATH := "user://saves/atomic_test.json"

@onready var _log: RichTextLabel = $VBox/Log
@onready var _backup_check: CheckBox = $VBox/Controls/BackupCheck

func _ready() -> void:
	_log.text = "[b]原子写入 Demo[/b]\n\n"
	_log.bbcode_enabled = true
	_append("就绪。点击按钮测试原子写入功能。\n")

func _on_write_pressed() -> void:
	var data := JSON.stringify({
		"test": "atomic_write",
		"timestamp": Time.get_unix_time_from_system(),
		"value": randi() % 1000,
	}).to_utf8_buffer()

	var backup := _backup_check.button_pressed
	_append("\n[color=yellow]写入数据（backup=%s）...[/color]" % str(backup))

	var err := AtomicWriter.write(TEST_PATH, data, backup)
	if err == OK:
		_append("[color=green]✓ 写入成功：%s[/color]" % TEST_PATH)
		_check_files()
	else:
		_append("[color=red]✗ 写入失败（err=%d）[/color]" % err)

func _on_read_pressed() -> void:
	if not FileAccess.file_exists(TEST_PATH):
		_append("\n[color=red]文件不存在：%s[/color]" % TEST_PATH)
		return
	var f := FileAccess.open(TEST_PATH, FileAccess.READ)
	var content := f.get_as_text()
	_append("\n[color=cyan]读取内容：[/color]\n%s" % content)

func _on_cleanup_pressed() -> void:
	AtomicWriter.cleanup_tmp(TEST_PATH)
	for path in [TEST_PATH, AtomicWriter.get_backup_path(TEST_PATH), AtomicWriter.get_tmp_path(TEST_PATH)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_append("\n[color=orange]已清理所有测试文件[/color]")
	_check_files()

func _check_files() -> void:
	_append("\n[b]文件状态：[/b]")
	for label_path in {
		"主文件":   TEST_PATH,
		"备份(.bak)": AtomicWriter.get_backup_path(TEST_PATH),
		"临时(.tmp)": AtomicWriter.get_tmp_path(TEST_PATH),
	}:
		var path: String = {
			"主文件":   TEST_PATH,
			"备份(.bak)": AtomicWriter.get_backup_path(TEST_PATH),
			"临时(.tmp)": AtomicWriter.get_tmp_path(TEST_PATH),
		}[label_path]
		var exists := FileAccess.file_exists(path)
		var color := "green" if exists else "gray"
		_append("  [color=%s]%s: %s[/color]" % [color, label_path, "存在" if exists else "不存在"])

func _append(text: String) -> void:
	_log.append_text(text + "\n")
