class_name SlotInfo
extends RefCounted
## 槽位信息值对象（只读，用于 UI 展示）
##
## 由 SaveSystem.list_slots() 返回，不持有任何可变状态

## 槽位编号（1-based）
var slot: int = 0

## 该槽位是否有存档文件
var exists: bool = false

## 存档文件 Unix 时间戳（0 = 未知）
var saved_at: int = 0

## 游戏版本字符串（来自 _meta）
var game_version: String = ""

## 预览图路径（如果存在）
var screenshot_path: String = ""

## 存档描述（可选，由开发者写入）
var description: String = ""

## 存档格式版本号（来自 _meta.version）
var format_version: int = 0

## 加密类型（来自 _meta.encryption_type，如 "xor"/"aes_cbc"/"aes_gcm"）
var encryption_type: String = ""

## 压缩类型（来自 _meta.compression，如 "gzip"/"deflate"）
var compression: String = ""

## 创建一个 SlotInfo
static func make(p_slot: int, p_exists: bool, p_meta: Dictionary) -> SlotInfo:
	var info := SlotInfo.new()
	info.slot = p_slot
	info.exists = p_exists
	if p_exists:
		info.saved_at       = int(p_meta.get("saved_at", 0))
		info.game_version   = str(p_meta.get("game_version", ""))
		info.screenshot_path = str(p_meta.get("screenshot_path", ""))
		info.description    = str(p_meta.get("description", ""))
		info.format_version = int(p_meta.get("version", 0))
		info.encryption_type = str(p_meta.get("encryption_type", ""))
		info.compression    = str(p_meta.get("compression", ""))
	return info

## 返回可读的存档时间字符串（空槽位返回 "—"）
func get_time_string() -> String:
	if not exists or saved_at == 0:
		return "—"
	var dt := Time.get_datetime_dict_from_unix_time(saved_at)
	return "%04d-%02d-%02d  %02d:%02d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"],
	]

## 调试用字符串
func _to_string() -> String:
	if not exists:
		return "Slot[%d] EMPTY" % slot
	return "Slot[%d] saved=%s ver=%s" % [slot, get_time_string(), game_version]
