extends ComponentBase
class_name InventoryComponent

var slot_count: int = 0
var items: Array = []

func set_slot_count(count: int) -> void:
	slot_count = maxi(count, 0)
	items.resize(slot_count)

func add_item(item: Variant) -> bool:
	for i in range(items.size()):
		if items[i] == null:
			items[i] = item
			return true
	return false

func remove_item(index: int) -> Variant:
	if index < 0 or index >= items.size():
		return null
	var item = items[index]
	items[index] = null
	return item

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"slot_count": slot_count,
		"occupied": items.count(null) != items.size(),
	}
