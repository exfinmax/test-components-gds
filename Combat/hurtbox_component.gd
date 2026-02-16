extends Area2D
class_name HurtBoxComponent
## 受击箱组件 - 检测来自 HitBoxComponent 的攻击并转发给 HealthComponent
##
## 注：因继承 Area2D，无法继承 ComponentBase，
## 但手动实现了相同的 enabled + get_component_data 模式。
## enabled 通过 monitoring 控制。

signal enabled_changed(is_enabled: bool)
signal hurt(hitbox: HitBoxComponent) ## 受到攻击时发射，用于外部处理击退/特效等

## 组件是否启用 — 关闭时不检测攻击
var enabled: bool = true:
	set(v):
		if enabled == v: return
		enabled = v
		monitoring = v
		enabled_changed.emit(enabled)

@export var health_component: HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not area is HitBoxComponent: return
	var hitbox := area as HitBoxComponent

	if health_component != null:
		health_component.damage(hitbox.damage)
		hitbox.hit_target.emit(owner)
		hurt.emit(hitbox)
	else:
		owner.queue_free()

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"has_health_component": health_component != null,
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
	}
