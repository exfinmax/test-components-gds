extends Node2D
class_name HealthComponent
## 生命值组件 - 管理生命值、受伤和死亡
##
## 注：因继承 Node2D（飘字需要位置），无法继承 ComponentBase，
## 但手动实现了相同的 enabled + get_component_data 模式。

signal enabled_changed(is_enabled: bool)
signal died
signal health_changed(cur_percent: float)

## 组件是否启用 — 禁用时 damage/heal 无效
var enabled: bool = true:
	set(v):
		if enabled == v: return
		enabled = v
		enabled_changed.emit(enabled)

@export var max_health: float = 10
@export_group("其他组件")
@export var FloatingTextScene: PackedScene ## 飘字显示

var current_health: float

func _ready() -> void:
	current_health = max_health
	health_changed.emit(get_health_percent())

func get_health_percent() -> float:
	if max_health <= 0:
		return 0
	return min(current_health / max_health, 1)

func heal(amount: float) -> void:
	if not enabled: return
	damage(-amount)

func damage(damage_amount: float) -> void:
	if not enabled: return
	current_health = clamp(current_health - damage_amount, 0, max_health)
	_show_floating_text(damage_amount)
	health_changed.emit(get_health_percent())
	Callable(func():
		if current_health <= 0:
			died.emit()
	).call_deferred()

func _show_floating_text(damage_amount: float) -> void:
	if FloatingTextScene == null: return
	var floating_text: Node2D = FloatingTextScene.instantiate()
	get_tree().current_scene.add_child(floating_text)
	var randf_rotation = Mathf.create_randf_offset(30)
	floating_text.modulate = Color.CRIMSON if damage_amount > 0 else Color.CHARTREUSE
	floating_text.global_position = global_position + Vector2.UP.rotated(randf_rotation) * 16
	floating_text.rotation = randf_rotation
	var format_string = "%0.0f" if round(damage_amount) == damage_amount else "%0.1f"
	floating_text.start(format_string % damage_amount)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"max_health": max_health,
		"current_health": current_health,
		"health_percent": get_health_percent(),
		"is_alive": current_health > 0,
	}
