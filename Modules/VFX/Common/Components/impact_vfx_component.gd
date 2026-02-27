extends Node2D
class_name ImpactVFXComponent
## 通用命中特效组件（VFX 通用层）
## 作用：统一生成命中特效并支持对象池接入，避免战斗逻辑与特效逻辑耦合。

@export var impact_scene: PackedScene
@export var default_lifetime: float = 0.35
@export var random_rotation: bool = true
@export var pool_path: NodePath

var _pool: ObjectPoolComponent

func _ready() -> void:
	if pool_path != NodePath():
		_pool = get_node_or_null(pool_path) as ObjectPoolComponent

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

	_auto_recycle_or_free(node, default_lifetime)

func _spawn_impact() -> Node:
	if _pool != null:
		return _pool.borrow(get_tree().current_scene)
	if impact_scene == null:
		return null
	var node := impact_scene.instantiate()
	get_tree().current_scene.add_child(node)
	return node

func _auto_recycle_or_free(node: Node, lifetime: float) -> void:
	var timer := get_tree().create_timer(maxf(0.01, lifetime))
	timer.timeout.connect(func():
		if not is_instance_valid(node):
			return
		if _pool != null:
			_pool.recycle(node)
		else:
			node.queue_free()
	)

