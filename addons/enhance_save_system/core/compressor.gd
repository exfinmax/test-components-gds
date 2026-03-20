class_name Compressor
extends RefCounted
## 存档压缩/解压子系统
##
## 格式：[4字节 LE 原始大小][压缩数据]
## 前置原始大小是为了让 decompress() 能正确调用 PackedByteArray.decompress()
##
## 支持 gzip 和 deflate 两种算法。
## 写入顺序：JSON bytes → compress() → [encrypt()] → 写文件
## 读取顺序：读文件 → [decrypt()] → decompress() → JSON.parse()

enum Mode { GZIP, DEFLATE }

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

## 压缩字节数组，返回 [4字节原始大小 LE][压缩数据]
## 失败时返回空数组
static func compress(data: PackedByteArray, mode: Mode = Mode.GZIP) -> PackedByteArray:
	if data.is_empty():
		return data
	var original_size := data.size()
	var godot_mode := _to_godot_mode(mode)
	var compressed := data.compress(godot_mode)
	if compressed.is_empty():
		push_error("Compressor.compress: compression failed")
		return PackedByteArray()
	# 前置4字节原始大小（小端序）
	var result := PackedByteArray()
	result.resize(4 + compressed.size())
	result[0] = original_size & 0xFF
	result[1] = (original_size >> 8) & 0xFF
	result[2] = (original_size >> 16) & 0xFF
	result[3] = (original_size >> 24) & 0xFF
	for i in range(compressed.size()):
		result[4 + i] = compressed[i]
	return result

## 解压字节数组（格式：[4字节原始大小][压缩数据]）
## 失败时返回空数组
static func decompress(data: PackedByteArray, mode: Mode = Mode.GZIP) -> PackedByteArray:
	if data.size() < 5:
		push_error("Compressor.decompress: data too short")
		return PackedByteArray()
	# 读取原始大小
	var original_size: int = data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24)
	if original_size <= 0 or original_size > 256 * 1024 * 1024:  # 最大 256MB 合理性检查
		push_error("Compressor.decompress: invalid original size %d" % original_size)
		return PackedByteArray()
	var compressed := data.slice(4)
	var godot_mode := _to_godot_mode(mode)
	var result := compressed.decompress(original_size, godot_mode)
	if result.is_empty():
		push_error("Compressor.decompress: decompression failed")
		return PackedByteArray()
	return result

## 将模式枚举转为字符串
static func mode_to_string(mode: Mode) -> String:
	match mode:
		Mode.GZIP:    return "gzip"
		Mode.DEFLATE: return "deflate"
	return "gzip"

## 将字符串转为模式枚举
static func mode_from_string(s: String) -> Mode:
	match s:
		"deflate": return Mode.DEFLATE
	return Mode.GZIP

# ──────────────────────────────────────────────
# 内部工具
# ──────────────────────────────────────────────

static func _to_godot_mode(mode: Mode) -> FileAccess.CompressionMode:
	match mode:
		Mode.DEFLATE: return FileAccess.COMPRESSION_DEFLATE
	return FileAccess.COMPRESSION_GZIP
