extends Node
## 存档管理器 - 管理存档的保存/加载/注册
##
## 作为 Autoload 使用：SaveManager
## 职责单一：只管存档，设置管理已分离到 SettingsManager

signal save_started
signal save_completed(err: Error)
signal load_started
signal load_completed

const SAVE_PATH = "user://savegame.tres"

## 已注册的可存档节点 (uuid → SaveableComponent)
var _registry: Dictionary = {}

## 当前存档
var _save: SaveGame = null

func _ready() -> void:
	_load_from_disk()

#region 公开 API

## 是否有存档
func has_save() -> bool:
	return _save != null

## 获取指定 UUID 的数据
func get_data(uuid: String) -> SaveData:
	if not _save: return null
	return _save.get_data(uuid)

## 保存单个节点数据（不写入磁盘）
func save_node_data(uuid: String, data: Dictionary) -> void:
	if not _save:
		_save = SaveGame.new()
	_save.set_data(uuid, data)

## 保存整个游戏（收集所有注册节点 → 写入磁盘）
func save_game() -> void:
	save_started.emit()

	if not _save:
		_save = SaveGame.new()
	else:
		_save.clear()

	# 收集所有已注册节点的数据
	for uuid in _registry:
		var comp = _registry[uuid]
		if is_instance_valid(comp) and comp.has_method("get_save_data"):
			_save.set_data(uuid, comp.get_save_data())

	var err := ResourceSaver.save(_save, SAVE_PATH)
	save_completed.emit(err)

## 加载游戏（通知所有注册节点恢复数据）
func load_game() -> bool:
	load_started.emit()

	if not _save:
		load_completed.emit()
		return false

	for uuid in _registry:
		var comp = _registry[uuid]
		if is_instance_valid(comp) and comp.has_method("apply_save_data"):
			var sd: SaveData = _save.get_data(uuid)
			if sd:
				comp.apply_save_data(sd.data)

	load_completed.emit()
	return true

## 新建游戏
func new_game() -> void:
	_save = SaveGame.new()

## 删除存档
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_save = null

## 获取所有已保存的 UUID
func get_all_uuids() -> PackedStringArray:
	if not _save: return PackedStringArray()
	return _save.get_all_uuids()

#endregion

#region 注册/注销

func register_saveable(comp: Node) -> void:
	if "node_uuid" in comp:
		_registry[comp.node_uuid] = comp

func unregister_saveable(comp: Node) -> void:
	if "node_uuid" in comp:
		_registry.erase(comp.node_uuid)

#endregion

#region 内部

func _load_from_disk() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		_save = load(SAVE_PATH) as SaveGame
		if _save:
			_save._rebuild_index()
	else:
		_save = null

#endregion

func get_component_data() -> Dictionary:
	return {
		"has_save": has_save(),
		"registered_count": _registry.size(),
		"saved_uuids": get_all_uuids(),
	}
