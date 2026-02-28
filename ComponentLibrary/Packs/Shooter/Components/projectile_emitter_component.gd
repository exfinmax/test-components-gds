extends Node2D
class_name ProjectileEmitterComponent

signal projectile_spawned(projectile: Node)
signal fired(direction: Vector2, count: int)

@export var projectile_scene: PackedScene
@export var muzzle_path: NodePath
@export var fire_interval: float = 0.12
@export var burst_count: int = 1
@export var spread_degrees: float = 6.0
@export var projectile_speed: float = 520.0

@export_group("OptionalPool")
@export var use_global_pool: bool = true
@export var pool_name: StringName = &"projectile_pool"
@export var auto_register_pool: bool = true
@export var pool_warmup_count: int = 12
@export var pool_max_size: int = 128

var _cooldown: float = 0.0
var _pool: Node = null

func _ready() -> void:
	if use_global_pool:
		_pool = get_node_or_null("/root/ObjectPool")
		if _pool != null and auto_register_pool and projectile_scene != null and not _pool.call("has_pool", pool_name):
			_pool.call("register_pool", pool_name, projectile_scene, pool_warmup_count, pool_max_size, true)

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

func can_fire() -> bool:
	return _cooldown <= 0.0 and projectile_scene != null

func fire(direction: Vector2 = Vector2.RIGHT) -> bool:
	if not can_fire():
		return false

	var dir := direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

	var muzzle := get_node_or_null(muzzle_path) as Node2D
	var origin := global_position if muzzle == null else muzzle.global_position
	var base_angle := dir.angle()
	var count := maxi(burst_count, 1)

	for i in range(count):
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var offset_deg := lerpf(-spread_degrees, spread_degrees, t)
		var spawn_dir := Vector2.RIGHT.rotated(base_angle + deg_to_rad(offset_deg))
		var projectile := _spawn_projectile()
		if projectile == null:
			continue
		_configure_projectile(projectile, origin, spawn_dir)
		projectile_spawned.emit(projectile)

	_cooldown = maxf(fire_interval, 0.0)
	fired.emit(dir, count)
	return true

func _spawn_projectile() -> Node:
	if _pool != null and _pool.call("has_pool", pool_name):
		var pooled: Node = _pool.call("acquire", pool_name)
		if pooled != null:
			_attach_to_current_scene(pooled)
			return pooled

	if projectile_scene == null:
		return null

	var node := projectile_scene.instantiate()
	_attach_to_current_scene(node)
	return node

func _attach_to_current_scene(node: Node) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if node.get_parent() != scene:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		scene.add_child(node)

func _configure_projectile(projectile: Node, origin: Vector2, direction: Vector2) -> void:
	if projectile is Node2D:
		(projectile as Node2D).global_position = origin
		(projectile as Node2D).global_rotation = direction.angle()

	var velocity := direction.normalized() * projectile_speed
	if projectile.has_method("set_velocity"):
		projectile.call("set_velocity", velocity)
	elif _has_property(projectile, &"velocity"):
		projectile.set("velocity", velocity)
	elif _has_property(projectile, &"linear_velocity"):
		projectile.set("linear_velocity", velocity)
	if projectile.has_method("setup_from_emitter"):
		projectile.call("setup_from_emitter", self)

func _has_property(obj: Object, property_name: StringName) -> bool:
	for item in obj.get_property_list():
		if StringName(item.get("name", "")) == property_name:
			return true
	return false
