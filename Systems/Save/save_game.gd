extends Resource
class_name SaveGame
## 存档文件 - 用 Dictionary 索引替代 Array 线性查找
##
## 内部使用 _data_map (uuid → Dictionary) 做快速查找
## 序列化时转为 saved_data_list (Array[SaveData]) 因为 Godot Resource 不支持嵌套 Dictionary<String, Resource>

@export var saved_data_list: Array[SaveData] = []

## 内存中的快速索引（不序列化）
var _data_map: Dictionary = {}  # uuid → SaveData

func _init() -> void:
	saved_data_list = []
	_data_map = {}

## 从序列化列表重建索引（加载后调用）
func _rebuild_index() -> void:
	_data_map.clear()
	for sd in saved_data_list:
		_data_map[sd.node_uuid] = sd

## 根据 UUID 获取数据
func get_data(uuid: String) -> SaveData:
	if _data_map.is_empty() and not saved_data_list.is_empty():
		_rebuild_index()
	return _data_map.get(uuid, null)

## 根据 UUID 设置数据
func set_data(uuid: String, data: Dictionary) -> void:
	var existing: SaveData = _data_map.get(uuid, null)
	if existing:
		existing.data = data
	else:
		var sd := SaveData.new()
		sd.node_uuid = uuid
		sd.data = data
		saved_data_list.append(sd)
		_data_map[uuid] = sd

## 删除指定 UUID 的数据
func remove_data(uuid: String) -> void:
	var sd: SaveData = _data_map.get(uuid, null)
	if sd:
		saved_data_list.erase(sd)
		_data_map.erase(uuid)

## 清空
func clear() -> void:
	saved_data_list.clear()
	_data_map.clear()

## 获取所有 UUID
func get_all_uuids() -> PackedStringArray:
	if _data_map.is_empty() and not saved_data_list.is_empty():
		_rebuild_index()
	var uuids := PackedStringArray()
	for uuid in _data_map:
		uuids.append(uuid)
	return uuids

## 导出为 Dictionary（用于 JSON 导出）
func to_dict() -> Dictionary:
	if _data_map.is_empty() and not saved_data_list.is_empty():
		_rebuild_index()
	var entries: Array[Dictionary] = []
	for uuid in _data_map:
		var sd: SaveData = _data_map[uuid]
		entries.append({
			"node_uuid": sd.node_uuid,
			"data": sd.data,
		})
	return {
		"version": 1,
		"entries": entries,
	}

## 从 Dictionary 恢复（用于 JSON 导入）
func from_dict(payload: Dictionary) -> void:
	clear()
	var entries: Array = payload.get("entries", [])
	for item in entries:
		if item is Dictionary:
			var uuid: String = item.get("node_uuid", "")
			var data: Dictionary = item.get("data", {})
			if not uuid.is_empty():
				set_data(uuid, data)
