extends Area2D
class_name HurtBoxComponent
## 受击盒组件
## 作用：检测 HitBox 并转发伤害。
## 改进：优先使用 DamageReceiverComponent（更低耦合），回退到 HealthComponent 直连模式。

signal enabled_changed(is_enabled: bool)
signal hurt(hitbox: HitBoxComponent)

var enabled: bool = true:
	set(v):
		if enabled == v:
			return
		enabled = v
		monitoring = v
		enabled_changed.emit(enabled)

@export var health_component: HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	

func _on_area_entered(area: Area2D) -> void:
	if not area is HitBoxComponent:
		return
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
