## 库存/背包系统 - 物品管理
## 
## 特性：
## - 物品存储和管理
## - 物品堆叠
## - 物品槽位系统
## - 物品搜索和排序
## 
## 使用示例：
##   var inventory = InventoryComponent.new()
##   inventory.set_slot_count(20)
##   var item = ItemData.new("Sword", 1)
##   inventory.add_item(item)
##
extends Node
class_name InventoryComponent

## 物品数据
class ItemData:
	var item_id: String = ""
	var item_name: String = ""
	var quantity: int = 1
	var max_stack: int = 1
	var rarity: String = "common"  # common, uncommon, rare, epic, legendary
	var item_type: String = "misc"  # weapon, armor, consumable, misc
	var description: String = ""
	
	func _init(p_id: String = "", p_name: String = "", p_quantity: int = 1) -> void:
		item_id = p_id
		item_name = p_name
		quantity = p_quantity
	
	func can_stack(other: ItemData) -> bool:
		return item_id == other.item_id and quantity < max_stack

## 物品槽位
class InventorySlot:
	var item: ItemData = null
	var slot_index: int = -1
	
	func _init(p_index: int) -> void:
		slot_index = p_index
	
	func is_empty() -> bool:
		return item == null
	
	func can_add_item(item: ItemData) -> int:
		if is_empty():
			return item.quantity
		if item.can_stack(item):
			return min(item.quantity, item.max_stack - item.quantity)
		return 0

## 物品槽位列表
var slots: Array[InventorySlot] = []

## 物品数量上限
@export var slot_count: int = 20

## 物品信号
signal item_added(item: ItemData, quantity: int)
signal item_removed(item: ItemData, quantity: int)
signal item_moved(from_slot: int, to_slot: int)
signal inventory_changed()

func _ready() -> void:
	set_slot_count(slot_count)

## 设置槽位数量
func set_slot_count(count: int) -> void:
	slots.clear()
	for i in range(count):
		slots.append(InventorySlot.new(i))

## 添加物品
func add_item(item: ItemData) -> bool:
	var remaining = item.quantity
	
	# 先尝试堆叠到现有物品
	for slot in slots:
		if remaining <= 0:
			break
		
		if not slot.is_empty() and slot.item.can_stack(item):
			var can_add = min(remaining, slot.item.max_stack - slot.item.quantity)
			slot.item.quantity += can_add
			remaining -= can_add
	
	# 再添加到空槽位
	for slot in slots:
		if remaining <= 0:
			break
		
		if slot.is_empty():
			var new_item = ItemData.new(item.item_id, item.item_name, remaining)
			new_item.max_stack = item.max_stack
			new_item.rarity = item.rarity
			new_item.item_type = item.item_type
			new_item.description = item.description
			
			slot.item = new_item
			remaining = 0
	
	if remaining <= 0:
		item_added.emit(item, item.quantity)
		inventory_changed.emit()
		return true
	
	# 物品未完全添加
	if item.quantity - remaining > 0:
		item_added.emit(item, item.quantity - remaining)
		inventory_changed.emit()
	
	return remaining == 0

## 移除物品
func remove_item(item_id: String, quantity: int = 1) -> int:
	var removed = 0
	
	for slot in slots:
		if removed >= quantity:
			break
		
		if not slot.is_empty() and slot.item.item_id == item_id:
			var remove_count = min(quantity - removed, slot.item.quantity)
			slot.item.quantity -= remove_count
			removed += remove_count
			
			if slot.item.quantity <= 0:
				var item = slot.item
				slot.item = null
				item_removed.emit(item, remove_count)
	
	if removed > 0:
		inventory_changed.emit()
	
	return removed

## 获取物品数量
func get_item_count(item_id: String) -> int:
	var count = 0
	for slot in slots:
		if not slot.is_empty() and slot.item.item_id == item_id:
			count += slot.item.quantity
	return count

## 获取指定槽位的物品
func get_item_in_slot(slot_index: int) -> ItemData:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index].item

## 移动物品(从槽位A到槽位B)
func move_item(from_slot: int, to_slot: int) -> bool:
	if from_slot < 0 or from_slot >= slots.size():
		return false
	if to_slot < 0 or to_slot >= slots.size():
		return false
	
	var from_item = slots[from_slot].item
	var to_item = slots[to_slot].item
	
	if from_item == null:
		return false
	
	# 到目标槽位是空的
	if to_item == null:
		slots[to_slot].item = from_item
		slots[from_slot].item = null
	else:
		# 到目标槽位有物品
		if from_item.can_stack(to_item):
			# 可以堆叠
			var can_add = min(from_item.quantity, to_item.max_stack - to_item.quantity)
			to_item.quantity += can_add
			from_item.quantity -= can_add
			
			if from_item.quantity <= 0:
				slots[from_slot].item = null
		else:
			# 不能堆叠，交换
			slots[from_slot].item = to_item
			slots[to_slot].item = from_item
	
	item_moved.emit(from_slot, to_slot)
	inventory_changed.emit()
	return true

## 搜索物品
func search_items(item_name: String) -> Array[ItemData]:
	var results = []
	for slot in slots:
		if not slot.is_empty() and item_name.to_lower() in slot.item.item_name.to_lower():
			results.append(slot.item)
	return results

## 获取所有物品
func get_all_items() -> Array[ItemData]:
	var items = []
	for slot in slots:
		if not slot.is_empty():
			items.append(slot.item)
	return items

## 检查物品是否存在
func has_item(item_id: String) -> bool:
	for slot in slots:
		if not slot.is_empty() and slot.item.item_id == item_id:
			return true
	return false

## 获取已用槽位数
func get_used_slots() -> int:
	var count = 0
	for slot in slots:
		if not slot.is_empty():
			count += 1
	return count

## 获取空槽位数
func get_empty_slots() -> int:
	return slots.size() - get_used_slots()

## 清空背包
func clear() -> void:
	for slot in slots:
		slot.item = null
	inventory_changed.emit()

## 调试：输出背包信息
func debug_inventory() -> String:
	var output = "=== Inventory ===\n"
	output += "Slots: %d/%d\n" % [get_used_slots(), slots.size()]
	for slot in slots:
		if not slot.is_empty():
			output += "[%d] %s x%d\n" % [
				slot.slot_index,
				slot.item.item_name,
				slot.item.quantity
			]
		else:
			output += "[%d] empty\n" % slot.slot_index
	return output
