extends Node
## 存档管理器（多槽位版）
## 设计说明：
## 1) 主存储继续使用 Resource（SaveGame），保留自定义资源扩展能力。
## 2) 额外提供多槽位、导入导出（Resource 文件复制 + JSON 导出导入）。
## 3) 保持原有 API 兼容：save_game/load_game/delete_save/has_save 等仍可用。

signal save_started
signal save_completed(err: Error)
signal load_started
signal load_completed
signal slot_save_started(slot: int)
signal slot_save_completed(slot: int, err: Error)
signal slot_load_started(slot: int)
signal slot_load_completed(slot: int, success: bool)
signal slot_changed(slot: int)

const SAVE_DIR := "user://saves"
const SLOT_FILE_PATTERN := "slot_%02d.tres"
const SLOT_JSON_PATTERN := "slot_%02d.json"
const MANIFEST_PATH := "user://saves/manifest.data"

@export var max_slots: int = 8
@export var current_slot: int = 1

## 已注册的可存档节点 (uuid -> SaveableComponent)
var _registry: Dictionary = {}

## 当前槽位载入后的 SaveGame
var _save: SaveGame = null

func _ready() -> void:
	_ensure_save_dir()
	_load_from_disk(current_slot)

#region 公开 API（兼容）

func has_save() -> bool:
	return _save != null

func get_data(uuid: String) -> SaveData:
	if not _save:
		return null
	return _save.get_data(uuid)

func save_node_data(uuid: String, data: Dictionary) -> void:
	if not _save:
		_save = SaveGame.new()
	_save.set_data(uuid, data)

func save_game() -> void:
	save_game_to_slot(current_slot)

func load_game() -> bool:
	return load_game_from_slot(current_slot)

func new_game() -> void:
	_save = SaveGame.new()

func delete_save() -> void:
	delete_slot(current_slot)

func get_all_uuids() -> PackedStringArray:
	if not _save:
		return PackedStringArray()
	return _save.get_all_uuids()

#endregion

#region 多槽位 API

func set_current_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	current_slot = slot
	_load_from_disk(current_slot)
	slot_changed.emit(current_slot)
	return true

func save_game_to_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	save_started.emit()
	slot_save_started.emit(slot)

	var save_obj := SaveGame.new()
	for uuid in _registry:
		var comp = _registry[uuid]
		if is_instance_valid(comp) and comp.has_method("get_save_data"):
			save_obj.set_data(uuid, comp.get_save_data())

	var path := _get_slot_path(slot)
	var err := ResourceSaver.save(save_obj, path)
	if err == OK:
		if slot == current_slot:
			_save = save_obj
		_touch_manifest_slot(slot, save_obj.saved_data_list.size())
	save_completed.emit(err)
	slot_save_completed.emit(slot, err)
	return err == OK

func load_game_from_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	load_started.emit()
	slot_load_started.emit(slot)

	var ok := _load_from_disk(slot)
	if ok:
		current_slot = slot
		for uuid in _registry:
			var comp = _registry[uuid]
			if is_instance_valid(comp) and comp.has_method("apply_save_data"):
				var sd: SaveData = _save.get_data(uuid)
				if sd:
					comp.apply_save_data(sd.data)
		slot_changed.emit(current_slot)

	load_completed.emit()
	slot_load_completed.emit(slot, ok)
	return ok

func delete_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	var path := _get_slot_path(slot)
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err != OK:
			return false
	if current_slot == slot:
		_save = null
	_remove_manifest_slot(slot)
	return true

func slot_exists(slot: int) -> bool:
	return _is_valid_slot(slot) and FileAccess.file_exists(_get_slot_path(slot))

func list_slots() -> Array[Dictionary]:
	var manifest := _load_manifest()
	var result: Array[Dictionary] = []
	for i in range(1, max_slots + 1):
		var key := str(i)
		var meta: Dictionary = manifest.get(key, {})
		result.append({
			"slot": i,
			"exists": slot_exists(i),
			"updated_unix": meta.get("updated_unix", 0),
			"entry_count": meta.get("entry_count", 0),
		})
	return result

#endregion

#region 导入导出

## 导出槽位为外部 .tres 文件（完整保留 Resource 结构）
func export_slot_resource(slot: int, out_path: String) -> bool:
	if not slot_exists(slot):
		return false
	var err := DirAccess.copy_absolute(_get_slot_path(slot), out_path)
	return err == OK

## 从外部 .tres 导入到指定槽位
func import_slot_resource(slot: int, in_path: String) -> bool:
	if not _is_valid_slot(slot):
		return false
	if not FileAccess.file_exists(in_path):
		return false
	var err := DirAccess.copy_absolute(in_path, _get_slot_path(slot))
	if err != OK:
		return false
	var loaded := ResourceLoader.load(_get_slot_path(slot)) as SaveGame
	if loaded:
		loaded._rebuild_index()
		_touch_manifest_slot(slot, loaded.saved_data_list.size())
		if slot == current_slot:
			_save = loaded
	return loaded != null

## 导出槽位为 JSON（便于跨项目迁移与人工检查）
func export_slot_json(slot: int, out_path: String) -> bool:
	if not slot_exists(slot):
		return false
	var sg := ResourceLoader.load(_get_slot_path(slot)) as SaveGame
	if not sg:
		return false
	var json_text := JSON.stringify(sg.to_dict(), "\t")
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(json_text)
	return true

## 从 JSON 导入到槽位
func import_slot_json(slot: int, in_path: String) -> bool:
	if not _is_valid_slot(slot):
		return false
	if not FileAccess.file_exists(in_path):
		return false

	var file := FileAccess.open(in_path, FileAccess.READ)
	if not file:
		return false
	var content := file.get_as_text()

	var json := JSON.new()
	var parse_err := json.parse(content)
	if parse_err != OK:
		return false
	if not (json.data is Dictionary):
		return false

	var sg := SaveGame.new()
	sg.from_dict(json.data)
	var err := ResourceSaver.save(sg, _get_slot_path(slot))
	if err != OK:
		return false
	_touch_manifest_slot(slot, sg.saved_data_list.size())
	if slot == current_slot:
		_save = sg
	return true

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

func _is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= max_slots

func _get_slot_path(slot: int) -> String:
	return "%s/%s" % [SAVE_DIR, SLOT_FILE_PATTERN % slot]

func _ensure_save_dir() -> void:
	DirAccess.make_dir_absolute(SAVE_DIR)

func _load_from_disk(slot: int) -> bool:
	var path := _get_slot_path(slot)
	if ResourceLoader.exists(path):
		_save = ResourceLoader.load(path) as SaveGame
		if _save:
			_save._rebuild_index()
			return true
	_save = null
	return false

func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not file:
		return {}
	var data = file.get_var()
	return data if data is Dictionary else {}

func _save_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file:
		file.store_var(manifest)

func _touch_manifest_slot(slot: int, entry_count: int) -> void:
	var manifest := _load_manifest()
	manifest[str(slot)] = {
		"updated_unix": Time.get_unix_time_from_system(),
		"entry_count": entry_count,
	}
	_save_manifest(manifest)

func _remove_manifest_slot(slot: int) -> void:
	var manifest := _load_manifest()
	manifest.erase(str(slot))
	_save_manifest(manifest)

#endregion

func get_component_data() -> Dictionary:
	return {
		"has_save": has_save(),
		"current_slot": current_slot,
		"max_slots": max_slots,
		"registered_count": _registry.size(),
		"saved_uuids": get_all_uuids(),
		"slots": list_slots(),
	}
