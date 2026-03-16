class_name SaveWriter
extends RefCounted
## 纯静态读写工具（无状态）
##
## 职责：
##   - 通过多态收集所有模块数据 → 积累成最终 payload Dictionary
##   - 将 payload 写入 JSON 文件（带版本头 + 时间戳）
##   - 从 JSON 文件读取 payload 并分发给各模块
##
## 设计要点：
##   - 全部为 static 方法，不持有任何状态
##   - 只用 JSON（纯数据，快速解析，人可读）
##   - payload 格式：{
##       "_meta": { "version": int, "saved_at": int, "game_version": String },
##       "module_key_1": { ...模块数据... },
##       "module_key_2": { ...模块数据... },
##     }

const FORMAT_VERSION := 2

# ──────────────────────────────────────────────
# 写入：收集 → 序列化 → 落盘
# ──────────────────────────────────────────────

## 从模块数组收集数据，构建 payload（不含 _meta）
## modules: Array[ISaveModule]
static func collect(modules: Array) -> Dictionary:
	var payload: Dictionary = {}
	for m: ISaveModule in modules:
		var key := m.get_module_key()
		if key.is_empty():
			push_warning("SaveWriter.collect: module has empty key, skipped")
			continue
		payload[key] = m.collect_data()
	return payload

## 将 payload 写入 JSON 文件（自动添加 _meta 头）
## 返回 true 表示成功
static func write_json(payload: Dictionary, path: String, game_version: String = "", encryption_key: String = "") -> bool:
	_ensure_dir(path)
	var envelope := {
		"_meta": {
			"version": FORMAT_VERSION,
			"saved_at": Time.get_unix_time_from_system(),
			"game_version": game_version,
			"encrypted": not encryption_key.is_empty(),
		},
	}
	# 合并模块数据（不污染 _meta）
	for k in payload:
		envelope[k] = payload[k]

	var text := JSON.stringify(envelope, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveWriter: cannot open '%s' for write (err=%d)" % [path, FileAccess.get_open_error()])
		return false
	
	if not encryption_key.is_empty():
		# 加密数据
		var encrypted_data := _encrypt(text, encryption_key)
		file.store_buffer(encrypted_data)
	else:
		file.store_string(text)
	return true

## 一步完成：collect + write
## modules: Array[ISaveModule]
static func write(modules: Array, path: String, game_version: String = "", encryption_key: String = "") -> bool:
	var payload := collect(modules)
	return write_json(payload, path, game_version, encryption_key)

# ──────────────────────────────────────────────
# 读取：从磁盘 → payload → 分发给模块
# ──────────────────────────────────────────────

## 从 JSON 文件读取 payload（去掉 _meta 层）
## 失败时返回空 Dictionary
static func read_json(path: String, encryption_key: String = "") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveWriter: cannot open '%s' for read" % path)
		return {}
	
	var text: String
	if not encryption_key.is_empty():
		# 读取加密数据
		var buffer = file.get_buffer(file.get_length())
		text = _decrypt(buffer, encryption_key)
		if text.is_empty():
			push_error("SaveWriter: failed to decrypt file '%s'" % path)
			return {}
	else:
		text = file.get_as_text()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveWriter: JSON parse error in '%s': %s" % [path, json.get_error_message()])
		return {}
	var data = json.data
	if not (data is Dictionary):
		return {}
	return data as Dictionary

## 将 payload 分发给模块（仅分发各模块关心的 key）
## modules: Array[ISaveModule]
static func apply(payload: Dictionary, modules: Array) -> void:
	for m: ISaveModule in modules:
		var key := m.get_module_key()
		if payload.has(key):
			m.apply_data(payload[key] as Dictionary)

## 一步完成：read_json + apply
## modules: Array[ISaveModule]
static func read(path: String, modules: Array, encryption_key: String = "") -> bool:
	var payload := read_json(path, encryption_key)
	if payload.is_empty():
		return false
	apply(payload, modules)
	return true

# ──────────────────────────────────────────────
# 槽位元信息辅助
# ──────────────────────────────────────────────

## 从已读取的 payload 中提取 _meta
static func get_meta_data(payload: Dictionary) -> Dictionary:
	return payload.get("_meta", {}) as Dictionary

## 读取文件中 _meta（不加载模块数据，用于列表展示）
static func peek_meta(path: String) -> Dictionary:
	return get_meta_data(read_json(path))

# ──────────────────────────────────────────────
# 内部工具
# ──────────────────────────────────────────────

static func _ensure_dir(path: String) -> void:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

# ──────────────────────────────────────────────
# 加密/解密
# ──────────────────────────────────────────────

## 加密数据（使用简单的XOR加密）
static func _encrypt(data: String, key: String) -> PackedByteArray:
	var data_bytes = data.to_utf8_buffer()
	var key_bytes = key.to_utf8_buffer()
	var key_length = key_bytes.size()
	var result = PackedByteArray()
	
	for i in range(data_bytes.size()):
		var key_byte = key_bytes[i % key_length]
		result.append(data_bytes[i] ^ key_byte)
	
	return result

## 解密数据（使用简单的XOR解密）
static func _decrypt(data: PackedByteArray, key: String) -> String:
	var key_bytes = key.to_utf8_buffer()
	var key_length = key_bytes.size()
	var result = PackedByteArray()
	
	for i in range(data.size()):
		var key_byte = key_bytes[i % key_length]
		result.append(data[i] ^ key_byte)
	
	return result.get_string_from_utf8()
