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
@export var damage_receiver: DamageReceiverComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if not damage_receiver:
		damage_receiver = get_node_or_null("%DamageReceiverComponent") as DamageReceiverComponent

func _on_area_entered(area: Area2D) -> void:
	if not area is HitBoxComponent:
		return
	var hitbox := area as HitBoxComponent

	if damage_receiver != null:
		damage_receiver.apply_damage(hitbox.damage, owner)
		hitbox.hit_target.emit(owner)
		hurt.emit(hitbox)
	elif health_component != null:
		health_component.damage(hitbox.damage)
		hitbox.hit_target.emit(owner)
		hurt.emit(hitbox)
	else:
		owner.queue_free()

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"has_health_component": health_component != null,
		"has_damage_receiver": damage_receiver != null,
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
	}
