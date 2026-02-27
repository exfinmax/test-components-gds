extends Node2D
class_name HealthComponent
## 生命组件
## 改进：支持可选对象池显示飘字，减少高频 instantiate/queue_free 抖动。

signal enabled_changed(is_enabled: bool)
signal died
signal health_changed(cur_percent: float)

var enabled: bool = true:
	set(v):
		if enabled == v:
			return
		enabled = v
		enabled_changed.emit(enabled)

@export var max_health: float = 10
@export_group("其他组件")
@export var FloatingTextScene: PackedScene
@export var use_object_pool: bool = false
@export var floating_text_pool_name: StringName = &"floating_text"
@export var floating_text_auto_release_delay: float = 0.9

var current_health: float

func _ready() -> void:
	current_health = max_health
	health_changed.emit(get_health_percent())

func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return min(current_health / max_health, 1.0)

func heal(amount: float) -> void:
	if not enabled:
		return
	damage(-amount)

func damage(damage_amount: float) -> void:
	if not enabled:
		return
	current_health = clamp(current_health - damage_amount, 0, max_health)
	_show_floating_text(damage_amount)
	health_changed.emit(get_health_percent())
	Callable(func():
		if current_health <= 0:
			died.emit()
	).call_deferred()

func _show_floating_text(damage_amount: float) -> void:
	if FloatingTextScene == null and not use_object_pool:
		return

	var floating_text: Node2D = null
	if use_object_pool and _has_object_pool() and ObjectPool.has_pool(floating_text_pool_name):
		floating_text = ObjectPool.acquire(floating_text_pool_name) as Node2D
	elif FloatingTextScene != null:
		floating_text = FloatingTextScene.instantiate() as Node2D
		get_tree().current_scene.add_child(floating_text)

	if floating_text == null:
		return

	var randf_rotation = Mathf.create_randf_offset(30)
	floating_text.modulate = Color.CRIMSON if damage_amount > 0 else Color.CHARTREUSE
	floating_text.global_position = global_position + Vector2.UP.rotated(randf_rotation) * 16
	floating_text.rotation = randf_rotation
	var format_string = "%0.0f" if round(damage_amount) == damage_amount else "%0.1f"
	floating_text.start(format_string % damage_amount)

	if use_object_pool and _has_object_pool() and ObjectPool.has_pool(floating_text_pool_name):
		ObjectPool.release_after(floating_text_pool_name, floating_text, floating_text_auto_release_delay)

func _has_object_pool() -> bool:
	return Engine.has_singleton("ObjectPool") or get_node_or_null("/root/ObjectPool") != null

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"max_health": max_health,
		"current_health": current_health,
		"health_percent": get_health_percent(),
		"is_alive": current_health > 0,
		"use_object_pool": use_object_pool,
		"pool_name": floating_text_pool_name,
	}
