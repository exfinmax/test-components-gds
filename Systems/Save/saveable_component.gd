extends Node
class_name SaveableComponent
## 可存档组件
## 改进：支持槽位存档 API（当 SaveManager 提供多槽位方法时自动使用）。

@export var node_uuid: String = ""
@export var is_static: bool = true
@export var auto_load: bool = false
@export var apply_delay_frames: int = 0

func _ready() -> void:
	if node_uuid.is_empty():
		node_uuid = "%s_%d" % [owner.name if owner else name, randi()]
	_register()
	if auto_load:
		_try_auto_load()

func _exit_tree() -> void:
	if not is_static:
		_unregister()

#region 子类重写
func get_save_data() -> Dictionary:
	return {}

func apply_save_data(_data: Dictionary) -> void:
	pass
#endregion

#region 手动操作
func save_now() -> void:
	var sm := _get_save_manager()
	if sm:
		sm.save_node_data(node_uuid, get_save_data())

func save_to_slot(slot: int) -> bool:
	var sm := _get_save_manager()
	if not sm:
		return false
	sm.save_node_data(node_uuid, get_save_data())
	if sm.has_method("save_game_to_slot"):
		return sm.save_game_to_slot(slot)
	sm.save_game()
	return true

func load_from_slot(slot: int) -> bool:
	var sm := _get_save_manager()
	if not sm:
		return false
	if sm.has_method("load_game_from_slot"):
		return sm.load_game_from_slot(slot)
	return sm.load_game()
#endregion

#region 内部
func _register() -> void:
	var sm := _get_save_manager()
	if sm:
		sm.register_saveable(self)

func _unregister() -> void:
	var sm := _get_save_manager()
	if sm:
		sm.unregister_saveable(self)

func _try_auto_load() -> void:
	var sm := _get_save_manager()
	if not sm or not sm.has_save():
		return
	var sd: SaveData = sm.get_data(node_uuid)
	if not sd:
		return
	if apply_delay_frames > 0:
		for _i in apply_delay_frames:
			await get_tree().process_frame
	apply_save_data(sd.data)

func _get_save_manager() -> Node:
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("SaveManager")
	return null
#endregion

func get_component_data() -> Dictionary:
	return {
		"node_uuid": node_uuid,
		"is_static": is_static,
		"auto_load": auto_load,
	}
