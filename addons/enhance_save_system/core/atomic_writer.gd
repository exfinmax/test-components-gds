class_name AtomicWriter
extends RefCounted
## 原子写入子系统
##
## 通过"写临时文件 → 重命名覆盖"保证写入原子性，
## 防止因写入中断（断电、崩溃）导致存档文件损坏。
##
## 可选 .bak 备份：在覆盖目标文件前将旧文件保留为 .bak。
##
## 用法：
##   var err := AtomicWriter.write("user://saves/slot_01.json", data_bytes)
##   var err := AtomicWriter.write("user://saves/slot_01.json", data_bytes, true)  # 启用备份

## 原子写入
## path:           目标文件路径
## data:           要写入的字节数组
## backup_enabled: 是否在覆盖前保留旧文件为 .bak
## 返回 OK 表示成功，FAILED 表示失败（原文件不受影响）
static func write(path: String, data: PackedByteArray, backup_enabled: bool = false) -> Error:
	var tmp_path := get_tmp_path(path)
	var bak_path := get_backup_path(path)

	# 确保目录存在
	_ensure_dir(path)

	# 步骤 1：写入临时文件
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("AtomicWriter: cannot open tmp file '%s' (err=%d)" % [tmp_path, FileAccess.get_open_error()])
		return FAILED
	file.store_buffer(data)
	file = null  # 关闭文件（GDScript 引用计数自动关闭）

	# 验证临时文件写入成功
	if not FileAccess.file_exists(tmp_path):
		push_error("AtomicWriter: tmp file not found after write '%s'" % tmp_path)
		return FAILED

	# 步骤 2（可选）：将旧文件重命名为 .bak
	if backup_enabled and FileAccess.file_exists(path):
		# 若已有 .bak，先删除旧备份
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		var rename_err := DirAccess.rename_absolute(path, bak_path)
		if rename_err != OK:
			push_warning("AtomicWriter: failed to rename '%s' to '%s' (err=%d)" % [path, bak_path, rename_err])
			# 备份失败不中断写入，继续覆盖

	# 步骤 3：将临时文件重命名为目标文件（原子操作）
	var final_err := DirAccess.rename_absolute(tmp_path, path)
	if final_err != OK:
		push_error("AtomicWriter: failed to rename tmp to target '%s' (err=%d)" % [path, final_err])
		# 清理临时文件
		if FileAccess.file_exists(tmp_path):
			DirAccess.remove_absolute(tmp_path)
		return FAILED

	return OK

## 获取备份文件路径
static func get_backup_path(path: String) -> String:
	return path + ".bak"

## 获取临时文件路径
static func get_tmp_path(path: String) -> String:
	return path + ".tmp"

## 清理残留的临时文件（启动时可调用）
static func cleanup_tmp(path: String) -> void:
	var tmp_path := get_tmp_path(path)
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)
		push_warning("AtomicWriter: cleaned up stale tmp file '%s'" % tmp_path)

# ──────────────────────────────────────────────
# 内部工具
# ──────────────────────────────────────────────

static func _ensure_dir(path: String) -> void:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
