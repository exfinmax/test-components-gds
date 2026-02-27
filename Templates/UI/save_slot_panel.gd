extends Control
class_name SaveSlotPanel
## 多槽位存档面板模板
## 作用：展示槽位列表并提供保存/读取/删除的基础按钮逻辑。

@export var slot_count: int = 6

@onready var _slot_list: ItemList = $VBox/Slots
@onready var _status: Label = $VBox/Status

func _ready() -> void:
	_refresh_slots()

func _refresh_slots() -> void:
	if not SaveManager:
		_status.text = "SaveManager 未找到"
		return
	_slot_list.clear()
	var slots := SaveManager.list_slots()
	for item in slots:
		var slot: int = item.get("slot", 0)
		if slot > slot_count:
			continue
		var exists: bool = item.get("exists", false)
		var mark := "[已存档]" if exists else "[空槽]"
		var text := "槽位 %d %s" % [slot, mark]
		_slot_list.add_item(text)
	_status.text = "当前槽位: %d" % SaveManager.current_slot

func _get_selected_slot() -> int:
	var idx := _slot_list.get_selected_items()
	if idx.is_empty():
		return SaveManager.current_slot
	return idx[0] + 1

func _on_save_pressed() -> void:
	var slot := _get_selected_slot()
	var ok := SaveManager.save_game_to_slot(slot)
	_status.text = "保存槽位 %d %s" % [slot, "成功" if ok else "失败"]
	_refresh_slots()

func _on_load_pressed() -> void:
	var slot := _get_selected_slot()
	var ok := SaveManager.load_game_from_slot(slot)
	_status.text = "读取槽位 %d %s" % [slot, "成功" if ok else "失败"]
	_refresh_slots()

func _on_delete_pressed() -> void:
	var slot := _get_selected_slot()
	var ok := SaveManager.delete_slot(slot)
	_status.text = "删除槽位 %d %s" % [slot, "成功" if ok else "失败"]
	_refresh_slots()

func _on_refresh_pressed() -> void:
	_refresh_slots()
