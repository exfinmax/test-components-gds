extends Node2D
class_name ImpactVFXComponent

signal impact_played(node: Node)

@export var impact_scene: PackedScene
@export var default_lifetime: float = 0.35
@export var random_rotation: bool = true

@export_group("GlobalPool")
@export var use_global_pool: bool = true
@export var pool_name: StringName = &"impact_vfx"
@export var auto_register_pool: bool = true
@export var pool_warmup_count: int = 6
@export var pool_max_size: int = 64
@export var pool_auto_expand: bool = true

var _pool: Node = null

func _ready() -> void:
	if not use_global_pool:
		return
	_pool = get_node_or_null("/root/ObjectPool")
	if _pool == null:
		return
	if auto_register_pool and impact_scene != null and not _pool.call("has_pool", pool_name):
		_pool.call("register_pool", pool_name, impact_scene, pool_warmup_count, pool_max_size, pool_auto_expand)

func play_at(world_pos: Vector2, tint: Color = Color.WHITE, scale_mul: float = 1.0) -> void:
	var node := _spawn_impact()
	if node == null:
		return

	if node is Node2D:
		node.global_position = world_pos
		node.scale = Vector2.ONE * maxf(0.01, scale_mul)
		if random_rotation:
			node.global_rotation = randf_range(0.0, TAU)

	if node is CanvasItem:
		node.modulate = tint

	impact_played.emit(node)
	_auto_recycle_or_free(node, default_lifetime)

func _spawn_impact() -> Node:
	if _pool != null and _pool.call("has_pool", pool_name):
		var pooled: Node = _pool.call("acquire", pool_name)
		if pooled != null:
			if pooled.get_parent() != get_tree().current_scene:
				if pooled.get_parent() != null:
					pooled.get_parent().remove_child(pooled)
				get_tree().current_scene.add_child(pooled)
			return pooled

	if impact_scene == null:
		return null

	var node := impact_scene.instantiate()
	get_tree().current_scene.add_child(node)
	return node

func _auto_recycle_or_free(node: Node, lifetime: float) -> void:
	var timer := get_tree().create_timer(maxf(0.01, lifetime))
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(node):
			return
		if _pool != null and _pool.call("has_pool", pool_name):
			_pool.call("release", pool_name, node)
		else:
			node.queue_free()
	, CONNECT_ONE_SHOT)
