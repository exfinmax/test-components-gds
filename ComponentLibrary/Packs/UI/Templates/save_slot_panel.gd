extends Control
class_name SaveSlotPanel
## 多槽位存档面板模板
## 作用：展示槽位列表并提供保存/读取/删除按钮逻辑。

@export var slot_count: int = 6

@onready var _slot_list: ItemList = $VBox/Slots
@onready var _status: Label = $VBox/Status
@onready var _save_manager: Node = get_node_or_null("/root/SaveManager")

func _ready() -> void:
	_refresh_slots()

func _refresh_slots() -> void:
	_slot_list.clear()
	if not _is_save_manager_valid():
		_status.text = "SaveManager 未找到或接口不完整"
		return

	var exists_by_slot: Dictionary = {}
	var slots: Array = _save_manager.call("list_slots")
	for item in slots:
		var slot: int = int(item.get("slot", 0))
		exists_by_slot[slot] = bool(item.get("exists", false))

	for slot in range(1, slot_count + 1):
		var exists := bool(exists_by_slot.get(slot, false))
		var mark := "[已存档]" if exists else "[空槽]"
		_slot_list.add_item("槽位 %d %s" % [slot, mark])

	_status.text = "当前槽位: %d" % _get_current_slot()

func _get_selected_slot() -> int:
	var indices := _slot_list.get_selected_items()
	if indices.is_empty():
		return _get_current_slot()
	return int(indices[0]) + 1

func _get_current_slot() -> int:
	if _save_manager == null:
		return 1
	var slot = _save_manager.get("current_slot")
	return int(slot) if slot is int else 1

func _is_save_manager_valid() -> bool:
	return _save_manager != null \
		and _save_manager.has_method("list_slots") \
		and _save_manager.has_method("save_game_to_slot") \
		and _save_manager.has_method("load_game_from_slot") \
		and _save_manager.has_method("delete_slot")

func _on_save_pressed() -> void:
	if not _is_save_manager_valid():
		_status.text = "SaveManager 不可用"
		return
	var slot := _get_selected_slot()
	var ok := bool(_save_manager.call("save_game_to_slot", slot))
	_status.text = "保存槽位 %d %s" % [slot, "成功" if ok else "失败"]
	_refresh_slots()

func _on_load_pressed() -> void:
	if not _is_save_manager_valid():
		_status.text = "SaveManager 不可用"
		return
	var slot := _get_selected_slot()
	var ok := bool(_save_manager.call("load_game_from_slot", slot))
	_status.text = "读取槽位 %d %s" % [slot, "成功" if ok else "失败"]
	_refresh_slots()

func _on_delete_pressed() -> void:
	if not _is_save_manager_valid():
		_status.text = "SaveManager 不可用"
		return
	var slot := _get_selected_slot()
	var ok := bool(_save_manager.call("delete_slot", slot))
	_status.text = "删除槽位 %d %s" % [slot, "成功" if ok else "失败"]
	_refresh_slots()

func _on_refresh_pressed() -> void:
	_refresh_slots()
