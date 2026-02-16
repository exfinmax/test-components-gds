extends Area2D
class_name HitBoxComponent
## 攻击箱组件 - 定义伤害值，被 HurtBoxComponent 检测
##
## 注：因继承 Area2D，无法继承 ComponentBase，
## 但手动实现了相同的 enabled + get_component_data 模式。
## enabled 通过 monitoring/monitorable 控制。

signal enabled_changed(is_enabled: bool)

@warning_ignore("unused_signal")
signal hit_target(target) ## 命中目标时发射，由 HurtBoxComponent 触发

## 组件是否启用 — 关闭时禁用碰撞检测
var enabled: bool = true:
	set(v):
		if enabled == v: return
		enabled = v
		monitoring = v
		monitorable = v
		enabled_changed.emit(enabled)

@export var damage: float = 5

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"damage": damage,
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
	}
