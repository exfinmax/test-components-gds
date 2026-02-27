extends Node
class_name ObjectPoolComponent
## 通用对象池（Foundation 层）
## 作用：复用临时节点（弹道、飘字、特效），减少频繁创建/销毁导致的卡顿。

@export var prefab: PackedScene
@export var warmup_count: int = 8
@export var max_size: int = 64
@export var recycle_on_tree_exit: bool = true

var _available: Array[Node] = []
var _borrowed: Dictionary = {}

func _ready() -> void:
	if warmup_count > 0:
		for _i in range(warmup_count):
			var item := _create_instance()
			if item:
				_recycle_internal(item)

func borrow(parent: Node = null) -> Node:
	var item: Node = null
	if not _available.is_empty():
		item = _available.pop_back()
	else:
		item = _create_instance()
	if item == null:
		return null

	if parent != null and item.get_parent() != parent:
		if item.get_parent() != null:
			item.get_parent().remove_child(item)
		parent.add_child(item)
	elif item.get_parent() == null:
		add_child(item)

	if item is CanvasItem:
		(item as CanvasItem).visible = true
	item.set_process(true)
	item.set_physics_process(true)
	_borrowed[item.get_instance_id()] = item
	return item

func recycle(item: Node) -> void:
	if item == null:
		return
	var key := item.get_instance_id()
	if not _borrowed.has(key):
		return
	_borrowed.erase(key)
	_recycle_internal(item)

func recycle_all() -> void:
	for key in _borrowed.keys():
		var item: Node = _borrowed[key]
		_recycle_internal(item)
	_borrowed.clear()

func _create_instance() -> Node:
	if prefab == null:
		return null
	var item := prefab.instantiate()
	if recycle_on_tree_exit:
		item.tree_exiting.connect(func():
			# 如果节点被外部释放，避免池里残留脏引用。
			var id := item.get_instance_id()
			_borrowed.erase(id)
			_available.erase(item)
		)
	return item

func _recycle_internal(item: Node) -> void:
	if item == null:
		return
	item.set_process(false)
	item.set_physics_process(false)
	if item is CanvasItem:
		item.visible = false
	if item.get_parent() != self:
		if item.get_parent() != null:
			item.get_parent().remove_child(item)
		add_child(item)
	if _available.size() >= max_size:
		item.queue_free()
		return
	_available.append(item)
