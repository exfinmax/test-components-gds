extends Node
class_name ObjectPoolComponent

@export var pool_name: StringName = &""
@export var prefab: PackedScene
@export var warmup_count: int = 8
@export var max_size: int = 64
@export var auto_expand: bool = true
@export var auto_register_on_ready: bool = true
@export var auto_unregister_on_exit: bool = false

func _ready() -> void:
	if auto_register_on_ready:
		_ensure_registered()

func _exit_tree() -> void:
	if auto_unregister_on_exit:
		unregister_pool()

func borrow(parent: Node = null) -> Node:
	if not _ensure_registered():
		return null

	var pool := _get_global_pool()
	var item: Node = pool.call("acquire", _resolved_pool_name())
	if item == null:
		return null

	if parent != null and item.get_parent() != parent:
		if item.get_parent() != null:
			item.get_parent().remove_child(item)
		parent.add_child(item)
	return item

func recycle(item: Node) -> void:
	if item == null:
		return
	var pool := _get_global_pool()
	if pool == null:
		item.queue_free()
		return
	pool.call("release", _resolved_pool_name(), item)

func recycle_all() -> void:
	var pool := _get_global_pool()
	if pool == null:
		return
	if pool.call("has_pool", _resolved_pool_name()):
		pool.call("release_all", _resolved_pool_name())

func unregister_pool() -> void:
	var pool := _get_global_pool()
	if pool == null:
		return
	if pool.call("has_pool", _resolved_pool_name()):
		pool.call("unregister_pool", _resolved_pool_name())

func _ensure_registered() -> bool:
	var pool := _get_global_pool()
	if pool == null:
		push_warning("[ObjectPoolComponent] 未找到全局 ObjectPool")
		return false
	if prefab == null:
		push_warning("[ObjectPoolComponent] 未设置 prefab")
		return false
	if not pool.call("has_pool", _resolved_pool_name()):
		pool.call("register_pool", _resolved_pool_name(), prefab, warmup_count, max_size, auto_expand)
	return true

func _resolved_pool_name() -> StringName:
	if pool_name != StringName():
		return pool_name
	return StringName(name)

func _get_global_pool() -> Node:
	var pool := get_node_or_null("/root/ObjectPool")
	if pool == null:
		return null
	if not pool.has_method("register_pool") or not pool.has_method("acquire"):
		return null
	return pool
