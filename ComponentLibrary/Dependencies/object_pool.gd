extends Node
class_name GlobalObjectPool

signal pool_exhausted(pool_name: StringName)

class Pool:
	var scene: PackedScene
	var available: Array[Node] = []
	var in_use: Array[Node] = []
	var parent: Node
	var max_size: int
	var auto_expand: bool

	func _init(s: PackedScene, initial_size: int, p: Node, max_s: int, expand: bool) -> void:
		scene = s
		parent = p
		max_size = max_s
		auto_expand = expand
		_warm_up(initial_size)

	func _warm_up(count: int) -> void:
		for _i in range(max(0, count)):
			var obj := scene.instantiate()
			parent.add_child(obj)
			_deactivate(obj)
			available.append(obj)

	func acquire() -> Node:
		var obj: Node = null
		if not available.is_empty():
			obj = available.pop_back()
		elif auto_expand and (max_size <= 0 or total_count() < max_size):
			obj = scene.instantiate()
			parent.add_child(obj)
		else:
			return null

		in_use.append(obj)
		_activate(obj)
		return obj

	func release(obj: Node) -> void:
		in_use.erase(obj)
		_deactivate(obj)
		available.append(obj)

	func total_count() -> int:
		return available.size() + in_use.size()

	func _activate(obj: Node) -> void:
		if obj is CanvasItem:
			obj.visible = true
		obj.process_mode = Node.PROCESS_MODE_INHERIT

	func _deactivate(obj: Node) -> void:
		if obj is CanvasItem:
			obj.visible = false
		obj.process_mode = Node.PROCESS_MODE_DISABLED

	func clear() -> void:
		for obj in in_use:
			if is_instance_valid(obj):
				obj.queue_free()
		for obj in available:
			if is_instance_valid(obj):
				obj.queue_free()
		in_use.clear()
		available.clear()

var _pools: Dictionary = {}
var _container: Node

func _ready() -> void:
	_container = Node.new()
	_container.name = "PoolContainer"
	add_child(_container)

func register_pool(pool_name: StringName, scene: PackedScene, initial_size: int = 5, max_size: int = 0, auto_expand: bool = true) -> void:
	if scene == null:
		return
	if _pools.has(pool_name):
		unregister_pool(pool_name)
	var pool_parent := Node.new()
	pool_parent.name = String(pool_name)
	_container.add_child(pool_parent)
	_pools[pool_name] = Pool.new(scene, initial_size, pool_parent, max_size, auto_expand)

func unregister_pool(pool_name: StringName) -> void:
	if not _pools.has(pool_name):
		return
	var pool: Pool = _pools[pool_name]
	pool.clear()
	if is_instance_valid(pool.parent):
		pool.parent.queue_free()
	_pools.erase(pool_name)

func has_pool(pool_name: StringName) -> bool:
	return _pools.has(pool_name)

func acquire(pool_name: StringName) -> Node:
	if not _pools.has(pool_name):
		return null
	var pool: Pool = _pools[pool_name]
	var obj := pool.acquire()
	if obj == null:
		pool_exhausted.emit(pool_name)
	return obj

func release(pool_name: StringName, obj: Node) -> void:
	if obj == null:
		return
	if not _pools.has(pool_name):
		obj.queue_free()
		return
	var pool: Pool = _pools[pool_name]
	pool.release(obj)

func release_after(pool_name: StringName, obj: Node, delay: float) -> void:
	var timer := get_tree().create_timer(maxf(delay, 0.0), true, false, true)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(obj):
			release(pool_name, obj)
	, CONNECT_ONE_SHOT)

func release_all(pool_name: StringName) -> void:
	if not _pools.has(pool_name):
		return
	var pool: Pool = _pools[pool_name]
	for obj in pool.in_use.duplicate():
		pool.release(obj)

func clear_all() -> void:
	for pool_name in _pools.keys().duplicate():
		unregister_pool(pool_name)
