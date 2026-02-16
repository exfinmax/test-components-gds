extends Node
class_name ObjectPool
## 对象池 - 预创建对象并重复使用，避免频繁 instantiate/queue_free
##
## 为什么需要对象池？
##   每次 instantiate() 一个场景（如浮动伤害数字、粒子），Godot 需要：
##     1. 从磁盘读场景  2. 分配内存  3. 初始化节点树  4. 添加到场景树
##   queue_free() 也需要 GC 回收内存
##   如果每帧都创建/销毁大量节点（如弹幕游戏），会造成卡顿
##
##   对象池的做法：提前创建好 N 个对象，用完不销毁，而是"回收"隐藏起来
##   下次需要时直接"借出"，跳过创建步骤
##
## 使用方式：
##   # 注册一种对象类型
##   ObjectPool.register_pool("floating_text", floating_text_scene, 10)
##   
##   # 借出一个对象
##   var text = ObjectPool.acquire("floating_text")
##   text.global_position = pos
##   text.start("999")
##     
##   # 用完归还
##   ObjectPool.release("floating_text", text)
##
## 适合池化的对象：浮动文字、子弹/弹幕、粒子特效、残影、音效播放器

signal pool_exhausted(pool_name: StringName)

## 单个池的数据
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
		for i in count:
			var obj := scene.instantiate()
			parent.add_child(obj)
			_deactivate(obj)
			available.append(obj)
	
	func acquire() -> Node:
		var obj: Node
		if available.size() > 0:
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
		obj.visible = true
		obj.process_mode = Node.PROCESS_MODE_INHERIT
		if obj is CollisionObject2D:
			(obj as CollisionObject2D).set_deferred("monitoring", true)
	
	func _deactivate(obj: Node) -> void:
		obj.visible = false
		obj.process_mode = Node.PROCESS_MODE_DISABLED
		if obj is CollisionObject2D:
			(obj as CollisionObject2D).set_deferred("monitoring", false)
	
	func clear() -> void:
		for obj in in_use:
			if is_instance_valid(obj):
				obj.queue_free()
		for obj in available:
			if is_instance_valid(obj):
				obj.queue_free()
		in_use.clear()
		available.clear()

## 所有注册的池 {pool_name: Pool}
var _pools: Dictionary = {}

## 池化对象的容器节点（保持场景树整洁）
var _container: Node

func _ready() -> void:
	_container = Node.new()
	_container.name = "PoolContainer"
	add_child(_container)

#region 注册 / 注销

## 注册一个对象池
## pool_name: 池名称（标识符）
## scene: 场景资源
## initial_size: 预热数量（提前创建多少个）
## max_size: 最大数量（0 = 无限）
## auto_expand: 池耗尽时是否自动扩容
func register_pool(pool_name: StringName, scene: PackedScene, initial_size: int = 5, max_size: int = 0, auto_expand: bool = true) -> void:
	if _pools.has(pool_name):
		push_warning("[ObjectPool] 池 '%s' 已存在，先清除旧池" % pool_name)
		unregister_pool(pool_name)
	
	var pool_parent := Node.new()
	pool_parent.name = String(pool_name)
	_container.add_child(pool_parent)
	
	_pools[pool_name] = Pool.new(scene, initial_size, pool_parent, max_size, auto_expand)

## 注销并销毁池中所有对象
func unregister_pool(pool_name: StringName) -> void:
	if not _pools.has(pool_name): return
	var pool: Pool = _pools[pool_name]
	pool.clear()
	if is_instance_valid(pool.parent):
		pool.parent.queue_free()
	_pools.erase(pool_name)

#endregion

#region 借出 / 归还

## 从池中借出一个对象（已激活，可直接使用）
func acquire(pool_name: StringName) -> Node:
	if not _pools.has(pool_name):
		push_error("[ObjectPool] 池 '%s' 不存在" % pool_name)
		return null
	
	var pool: Pool = _pools[pool_name]
	var obj := pool.acquire()
	
	if obj == null:
		pool_exhausted.emit(pool_name)
		push_warning("[ObjectPool] 池 '%s' 已耗尽 (可用:%d 在用:%d)" % [pool_name, pool.available.size(), pool.in_use.size()])
	
	return obj

## 归还对象到池中（自动停用隐藏）
func release(pool_name: StringName, obj: Node) -> void:
	if not _pools.has(pool_name):
		push_warning("[ObjectPool] 池 '%s' 不存在，直接释放节点" % pool_name)
		obj.queue_free()
		return
	
	var pool: Pool = _pools[pool_name]
	pool.release(obj)

## 延迟归还（常用于特效播放完毕后自动回收）
func release_after(pool_name: StringName, obj: Node, delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(
		func(): 
			if is_instance_valid(obj):
				release(pool_name, obj)
	)

#endregion

#region 全部归还

## 归还某个池中所有正在使用的对象
func release_all(pool_name: StringName) -> void:
	if not _pools.has(pool_name): return
	var pool: Pool = _pools[pool_name]
	var in_use_copy := pool.in_use.duplicate()
	for obj in in_use_copy:
		pool.release(obj)

## 归还所有池中所有正在使用的对象
func release_all_pools() -> void:
	for pool_name in _pools:
		release_all(pool_name)

#endregion

#region 查询

func get_available_count(pool_name: StringName) -> int:
	if not _pools.has(pool_name): return 0
	return (_pools[pool_name] as Pool).available.size()

func get_in_use_count(pool_name: StringName) -> int:
	if not _pools.has(pool_name): return 0
	return (_pools[pool_name] as Pool).in_use.size()

func has_pool(pool_name: StringName) -> bool:
	return _pools.has(pool_name)

#endregion

#region 调试

func get_component_data() -> Dictionary:
	var pools_info := {}
	for pool_name in _pools:
		var pool: Pool = _pools[pool_name]
		pools_info[pool_name] = {
			"available": pool.available.size(),
			"in_use": pool.in_use.size(),
			"total": pool.total_count(),
			"max_size": pool.max_size,
		}
	return {
		"type": "ObjectPool",
		"pool_count": _pools.size(),
		"pools": pools_info,
	}

#endregion
