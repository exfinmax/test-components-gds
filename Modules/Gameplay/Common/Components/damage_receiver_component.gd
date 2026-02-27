extends Node
class_name DamageReceiverComponent
## 受伤入口组件（Gameplay/Common 层）
## 作用：统一处理受击入口（无敌判定、减血、受击信号），供 HurtBox/陷阱/脚本复用。

signal damaged(amount: float, source: Node)
signal blocked(amount: float, source: Node)

@export var enabled: bool = true
@export var health_component: HealthComponent
@export var invincibility_component: InvincibilityComponent
@export var default_invincibility: float = 0.0

func apply_damage(amount: float, source: Node = null, trigger_invincible: bool = true) -> bool:
	if not enabled:
		blocked.emit(amount, source)
		return false
	if amount <= 0.0:
		return false
	if invincibility_component and not invincibility_component.can_take_hit():
		blocked.emit(amount, source)
		return false
	if not health_component:
		push_warning("[DamageReceiverComponent] 未绑定 HealthComponent")
		return false

	health_component.damage(amount)
	damaged.emit(amount, source)
	if trigger_invincible and invincibility_component and default_invincibility > 0.0:
		invincibility_component.trigger(default_invincibility)
	return true

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"has_health_component": health_component != null,
		"has_invincibility_component": invincibility_component != null,
		"default_invincibility": default_invincibility,
	}

