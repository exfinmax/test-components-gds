class_name SaveWriter
extends RefCounted
## 纯静态读写工具（无状态）
##
## 写入管线：JSON 字符串 → [compress] → [encrypt] → 二进制格式 → AtomicWriter/直接写
## 读取管线：读文件 → 解析格式头 → [decrypt] → [decompress] → JSON.parse → payload
##
## 二进制文件格式（加密或压缩时启用）：
##   [4字节 LE: header_len][header JSON bytes][body bytes]
##   header JSON 包含 _meta（含 iv/tag/hmac 等加密参数）
##
## 纯文本格式（无加密无压缩时）：
##   完整 JSON 文本（向后兼容）

const FORMAT_VERSION := 3

## 魔数：用于识别新二进制格式（header 长度不可能超过此值的纯文本文件）
const _MAX_HEADER_LEN := 65536

## 写入选项（由 SaveSystem 构建后传入）
class WriteOptions:
	var game_version: String = ""
	var encryption_enabled: bool = false
	var encryption_key: String = ""
	var encryption_mode: String = "xor"   # "xor" / "aes_cbc" / "aes_gcm"
	var compression_enabled: bool = false
	var compression_mode: String = "gzip" # "gzip" / "deflate"
	var atomic_write_enabled: bool = true
	var backup_enabled: bool = false
	var split_modules_enabled: bool = false

## 读取选项
class ReadOptions:
	var encryption_key: String = ""
	var split_modules_enabled: bool = false

# ──────────────────────────────────────────────
# 写入：收集 → 序列化 → 落盘
# ──────────────────────────────────────────────

## 从模块数组收集数据，构建 payload（不含 _meta）
static func collect(modules: Array) -> Dictionary:
	var payload: Dictionary = {}
	for m: ISaveModule in modules:
		var key := m.get_module_key()
		if key.is_empty():
			push_warning("SaveWriter.collect: module has empty key, skipped")
			continue
		payload[key] = m.collect_data()
	return payload

## 将 payload 写入文件（自动添加 _meta 头）
static func write_json(payload: Dictionary, path: String, opts: WriteOptions = null) -> bool:
	if opts == null:
		opts = WriteOptions.new()

	_ensure_dir(path)

	# 分模块文件模式
	if opts.split_modules_enabled:
		var meta := _build_meta(opts)
		return _write_split(payload, path, meta, opts)

	# 构建完整 envelope（含 _meta）
	var meta := _build_meta(opts)
	var envelope: Dictionary = { "_meta": meta }
	for k in payload:
		envelope[k] = payload[k]

	# 序列化 payload 为 JSON bytes
	var body := JSON.stringify(envelope, "\t").to_utf8_buffer()

	# 若无加密无压缩：直接写纯文本 JSON（向后兼容格式）
	if not opts.encryption_enabled and not opts.compression_enabled:
		return _flush(body, path, opts)

	# 压缩（先压缩后加密）
	if opts.compression_enabled:
		var cmode := Compressor.mode_from_string(opts.compression_mode)
		body = Compressor.compress(body, cmode)
		if body.is_empty():
			push_error("SaveWriter: compression failed for '%s'" % path)
			return false

	# 加密：执行后把 iv/tag/hmac 写入 meta
	if opts.encryption_enabled:
		var emode := Encryptor.mode_from_string(opts.encryption_mode)
		var enc := Encryptor.encrypt(body, opts.encryption_key, emode)
		if enc.is_empty():
			push_error("SaveWriter: encryption failed for '%s'" % path)
			return false
		# 将加密参数存入 meta（base64 编码）
		var iv: PackedByteArray  = enc.get("iv",   PackedByteArray())
		var tag: PackedByteArray = enc.get("tag",  PackedByteArray())
		var hmac: PackedByteArray = enc.get("hmac", PackedByteArray())
		if not iv.is_empty():
			meta["iv"]   = Marshalls.raw_to_base64(iv)
		if not tag.is_empty():
			meta["tag"]  = Marshalls.raw_to_base64(tag)
		if not hmac.is_empty():
			meta["hmac"] = Marshalls.raw_to_base64(hmac)
		body = enc.get("ciphertext", PackedByteArray())

	# 打包为二进制格式：[4字节 header_len][header JSON][body]
	var header_bytes := JSON.stringify(meta).to_utf8_buffer()
	var file_data := _pack_binary(header_bytes, body)
	return _flush(file_data, path, opts)

## 一步完成：collect + write_json
static func write(modules: Array, path: String, opts: WriteOptions = null) -> bool:
	var payload := collect(modules)
	return write_json(payload, path, opts)

# ──────────────────────────────────────────────
# 读取：从磁盘 → payload → 分发给模块
# ──────────────────────────────────────────────

## 从文件读取 payload（含 _meta）
static func read_json(path: String, opts: ReadOptions = null) -> Dictionary:
	if opts == null:
		opts = ReadOptions.new()

	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveWriter: cannot open '%s' for read" % path)
		return {}
	var raw := file.get_buffer(file.get_length())
	file = null

	# 尝试解析文件格式
	var meta: Dictionary = {}
	var body: PackedByteArray

	var parsed_binary := _try_unpack_binary(raw)
	if parsed_binary.size() == 2:
		# 新二进制格式：header 中含完整 meta（包括 iv/tag/hmac）
		meta = parsed_binary[0]
		body = parsed_binary[1]
	else:
		# 旧纯文本 JSON 格式（向后兼容）
		var text := raw.get_string_from_utf8()
		var json := JSON.new()
		if json.parse(text) != OK:
			push_error("SaveWriter: JSON parse error in '%s'" % path)
			return {}
		var data = json.data
		if not (data is Dictionary):
			return {}
		var d := data as Dictionary
		# 旧格式：检查是否有 XOR 加密（无 encryption_type 字段的旧存档）
		var old_meta: Dictionary = d.get("_meta", {})
		if old_meta.get("encrypted", false) and old_meta.get("encryption_type", "") == "":
			# 旧版 XOR 存档：整个文件是 XOR 加密的
			var decrypted := Encryptor.decrypt_xor(raw, opts.encryption_key)
			var json2 := JSON.new()
			if json2.parse(decrypted.get_string_from_utf8()) != OK:
				push_error("SaveWriter: XOR decrypt failed for '%s'" % path)
				return {}
			var d2 = json2.data
			if not (d2 is Dictionary):
				return {}
			return d2 as Dictionary
		return d

	# 解密
	var encryption_type: String = meta.get("encryption_type", "")
	if not encryption_type.is_empty() and not opts.encryption_key.is_empty():
		var dec_meta := {
			"mode":       encryption_type,
			"ciphertext": body,
			"iv":         Marshalls.base64_to_raw(str(meta.get("iv",   ""))),
			"tag":        Marshalls.base64_to_raw(str(meta.get("tag",  ""))),
			"hmac":       Marshalls.base64_to_raw(str(meta.get("hmac", ""))),
		}
		body = Encryptor.decrypt(dec_meta, opts.encryption_key)
		if body.is_empty():
			push_error("SaveWriter: decryption failed for '%s'" % path)
			return {}

	# 解压
	var compression: String = meta.get("compression", "")
	if not compression.is_empty():
		var cmode := Compressor.mode_from_string(compression)
		body = Compressor.decompress(body, cmode)
		if body.is_empty():
			push_error("SaveWriter: decompression failed for '%s'" % path)
			return {}

	# JSON 解析 body
	var text := body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveWriter: JSON parse error in body of '%s': %s" % [path, json.get_error_message()])
		return {}
	var data = json.data
	if not (data is Dictionary):
		return {}
	var result := data as Dictionary

	# 将 header 中的 meta 合并回 result（确保 _meta 完整）
	if not result.has("_meta"):
		result["_meta"] = meta

	# 分模块文件模式
	if result.get("_meta", {}).get("split_modules", false):
		return _read_split(result, path, opts)

	return result

## 将 payload 分发给模块
static func apply(payload: Dictionary, modules: Array) -> void:
	for m: ISaveModule in modules:
		var key := m.get_module_key()
		if payload.has(key):
			m.apply_data(payload[key] as Dictionary)

## 一步完成：read_json + apply
static func read(path: String, modules: Array, opts: ReadOptions = null) -> bool:
	var payload := read_json(path, opts)
	if payload.is_empty():
		return false
	apply(payload, modules)
	return true

# ──────────────────────────────────────────────
# 槽位元信息辅助
# ──────────────────────────────────────────────

static func get_meta_data(payload: Dictionary) -> Dictionary:
	return payload.get("_meta", {}) as Dictionary

## 只读取文件的 _meta 头，不解密/解压 body
## 对加密文件同样有效（meta 存在 header 中，明文可读）
static func peek_meta(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_buffer(file.get_length())
	file = null

	# 新二进制格式：header 是明文 JSON，直接读取，无需解密
	var parsed := _try_unpack_binary(raw)
	if parsed.size() == 2:
		return parsed[0]  # 就是 meta dict

	# 旧纯文本 JSON 格式
	var text := raw.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		return (json.data as Dictionary).get("_meta", {}) as Dictionary
	return {}

# ──────────────────────────────────────────────
# 二进制格式打包/解包
# ──────────────────────────────────────────────

## 打包：[4字节 LE header_len][header bytes][body bytes]
static func _pack_binary(header: PackedByteArray, body: PackedByteArray) -> PackedByteArray:
	var hlen := header.size()
	var result := PackedByteArray()
	result.resize(4 + hlen + body.size())
	# 写入 header 长度（小端序 4 字节）
	result[0] = hlen & 0xFF
	result[1] = (hlen >> 8) & 0xFF
	result[2] = (hlen >> 16) & 0xFF
	result[3] = (hlen >> 24) & 0xFF
	# 写入 header
	for i in range(hlen):
		result[4 + i] = header[i]
	# 写入 body
	for i in range(body.size()):
		result[4 + hlen + i] = body[i]
	return result

## 解包：返回 [meta_dict, body_bytes]，失败返回空数组 []
static func _try_unpack_binary(data: PackedByteArray) -> Array:
	if data.size() < 4:
		return []

	# 读取 header 长度（小端序）
	var hlen: int = data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24)

	# 合理性检查：header 长度必须在合理范围内
	if hlen <= 0 or hlen > _MAX_HEADER_LEN or (4 + hlen) > data.size():
		return []

	# 尝试解析 header JSON
	var header_bytes := data.slice(4, 4 + hlen)
	var header_text := header_bytes.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(header_text) != OK:
		return []
	var parsed = json.data
	if not (parsed is Dictionary):
		return []

	var meta := parsed as Dictionary
	# 验证：必须包含 version 字段（确认是我们的格式）
	if not meta.has("version"):
		return []

	var body := data.slice(4 + hlen)
	return [meta, body]

# ──────────────────────────────────────────────
# 分模块文件写入/读取
# ──────────────────────────────────────────────

static func _write_split(payload: Dictionary, path: String, meta: Dictionary, opts: WriteOptions) -> bool:
	var base := path.get_basename()
	var index: Dictionary = {}

	for key in payload:
		var module_path := "%s_%s.json" % [base, key]
		index[key] = module_path
		var module_envelope := { "_meta": meta, key: payload[key] }
		var module_text := JSON.stringify(module_envelope, "\t")
		var module_data := module_text.to_utf8_buffer()
		var f := FileAccess.open(module_path, FileAccess.WRITE)
		if f == null:
			push_error("SaveWriter: cannot write split module file '%s'" % module_path)
			return false
		f.store_buffer(module_data)

	var main_envelope := { "_meta": meta, "_index": index }
	var main_data := JSON.stringify(main_envelope, "\t").to_utf8_buffer()
	return _flush(main_data, path, opts)

static func _read_split(main_data: Dictionary, _path: String, _opts: ReadOptions) -> Dictionary:
	var index: Dictionary = main_data.get("_index", {})
	var result: Dictionary = { "_meta": main_data.get("_meta", {}) }
	for key in index:
		var module_path: String = index[key]
		if not FileAccess.file_exists(module_path):
			push_warning("SaveWriter: split module file not found '%s'" % module_path)
			continue
		var f := FileAccess.open(module_path, FileAccess.READ)
		if f == null:
			continue
		var text := f.get_as_text()
		var json := JSON.new()
		if json.parse(text) != OK:
			continue
		var module_data = json.data
		if module_data is Dictionary and (module_data as Dictionary).has(key):
			result[key] = (module_data as Dictionary)[key]
	return result

# ──────────────────────────────────────────────
# 内部工具
# ──────────────────────────────────────────────

## 构建 _meta 字典（不含加密参数，加密后再填入）
static func _build_meta(opts: WriteOptions) -> Dictionary:
	var meta: Dictionary = {
		"version":      FORMAT_VERSION,
		"saved_at":     Time.get_unix_time_from_system(),
		"game_version": opts.game_version,
		"encrypted":    opts.encryption_enabled,
	}
	if opts.encryption_enabled:
		meta["encryption_type"] = opts.encryption_mode
	if opts.compression_enabled:
		meta["compression"] = opts.compression_mode
	if opts.split_modules_enabled:
		meta["split_modules"] = true
	return meta

## 将数据写入文件（原子或直接）
static func _flush(data: PackedByteArray, path: String, opts: WriteOptions) -> bool:
	if opts.atomic_write_enabled:
		return AtomicWriter.write(path, data, opts.backup_enabled) == OK
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveWriter: cannot open '%s' for write (err=%d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_buffer(data)
	return true

static func _ensure_dir(path: String) -> void:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
