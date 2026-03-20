class_name AsyncSaveIO
extends RefCounted
## ════════════════════════════════════════════════════════════════
## 异步存档 I/O 系统
## ════════════════════════════════════════════════════════════════
## 提供非阻塞式文件读写功能，确保存档操作不影响主线程运行

## 信号
signal save_completed(slot: int, success: bool, error_message: String)
signal load_completed(slot: int, data: Dictionary, success: bool, error_message: String)
signal delete_completed(slot: int, success: bool)
signal progress_updated(operation: String, progress: float)

## 配置
var max_retries: int = 3
var retry_delay_ms: int = 100

## 内部状态
var _pending_operations: Dictionary = {}
var _operation_id: int = 0

## 异步保存
func save_async(slot: int, data: Dictionary, path: String, encrypt: bool, key: String) -> int:
	var op_id := _operation_id
	_operation_id += 1
	
	_pending_operations[op_id] = {
		"type": "save",
		"slot": slot,
		"data": data,
		"path": path,
		"encrypt": encrypt,
		"key": key
	}
	
	WorkerThreadPool.add_task(func(): _execute_save(op_id))
	
	return op_id

## 异步加载
func load_async(slot: int, path: String, decrypt: bool, key: String) -> int:
	var op_id := _operation_id
	_operation_id += 1
	
	_pending_operations[op_id] = {
		"type": "load",
		"slot": slot,
		"path": path,
		"decrypt": decrypt,
		"key": key
	}
	
	WorkerThreadPool.add_task(func(): _execute_load(op_id))
	
	return op_id

## 异步删除
func delete_async(slot: int, path: String) -> int:
	var op_id := _operation_id
	_operation_id += 1
	
	_pending_operations[op_id] = {
		"type": "delete",
		"slot": slot,
		"path": path
	}
	
	WorkerThreadPool.add_task(func(): _execute_delete(op_id))
	
	return op_id

## 执行保存操作
func _execute_save(op_id: int) -> void:
	var op: Dictionary = _pending_operations.get(op_id, {})
	if op.is_empty():
		return
	
	var slot: int = op.slot
	var data: Dictionary = op.data
	var path: String = op.path
	var encrypt: bool = op.encrypt
	var key: String = op.key
	
	var success := false
	var error_msg := ""
	
	for retry in range(max_retries):
		var result := _do_save(data, path, encrypt, key)
		if result.success:
			success = true
			break
		else:
			error_msg = result.error
			OS.delay_msec(retry_delay_ms)
	
	_pending_operations.erase(op_id)
	
	call_deferred("_emit_save_completed", slot, success, error_msg)

## 执行加载操作
func _execute_load(op_id: int) -> void:
	var op: Dictionary = _pending_operations.get(op_id, {})
	if op.is_empty():
		return
	
	var slot: int = op.slot
	var path: String = op.path
	var decrypt: bool = op.decrypt
	var key: String = op.key
	
	var success := false
	var error_msg := ""
	var loaded_data := {}
	
	for retry in range(max_retries):
		var result := _do_load(path, decrypt, key)
		if result.success:
			success = true
			loaded_data = result.data
			break
		else:
			error_msg = result.error
			OS.delay_msec(retry_delay_ms)
	
	_pending_operations.erase(op_id)
	
	call_deferred("_emit_load_completed", slot, loaded_data, success, error_msg)

## 执行删除操作
func _execute_delete(op_id: int) -> void:
	var op: Dictionary = _pending_operations.get(op_id, {})
	if op.is_empty():
		return
	
	var slot: int = op.slot
	var path: String = op.path
	
	var success := false
	
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		success = (err == OK)
	else:
		success = true
	
	_pending_operations.erase(op_id)
	
	call_deferred("_emit_delete_completed", slot, success)

## 实际保存逻辑
func _do_save(data: Dictionary, path: String, encrypt: bool, key: String) -> Dictionary:
	var json_string := JSON.stringify(data)
	
	var file_data: PackedByteArray
	if encrypt:
		file_data = SaveWriter._encrypt(json_string, key)
	else:
		file_data = json_string.to_utf8_buffer()
	
	var dir_path := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var err := DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			return {"success": false, "error": "无法创建目录: %s" % dir_path}
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "无法打开文件: %s" % path}
	
	file.store_buffer(file_data)
	file.close()
	
	return {"success": true, "error": ""}

## 实际加载逻辑
func _do_load(path: String, decrypt: bool, key: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"success": false, "error": "文件不存在", "data": {}}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "error": "无法打开文件", "data": {}}
	
	var file_data := file.get_buffer(file.get_length())
	file.close()
	
	var json_string: String
	if decrypt:
		json_string = SaveWriter._decrypt(file_data, key)
		if json_string.is_empty():
			return {"success": false, "error": "解密失败或数据被篡改", "data": {}}
	else:
		json_string = file_data.get_string_from_utf8()
	
	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		return {"success": false, "error": "JSON解析失败", "data": {}}
	
	return {"success": true, "error": "", "data": json.data}

## 发射信号
func _emit_save_completed(slot: int, success: bool, error_message: String) -> void:
	save_completed.emit(slot, success, error_message)

func _emit_load_completed(slot: int, data: Dictionary, success: bool, error_message: String) -> void:
	load_completed.emit(slot, data, success, error_message)

func _emit_delete_completed(slot: int, success: bool) -> void:
	delete_completed.emit(slot, success)

## 检查是否有待处理操作
func has_pending_operations() -> bool:
	return _pending_operations.size() > 0

## 获取待处理操作数量
func get_pending_count() -> int:
	return _pending_operations.size()

## 取消所有操作
func cancel_all() -> void:
	_pending_operations.clear()
