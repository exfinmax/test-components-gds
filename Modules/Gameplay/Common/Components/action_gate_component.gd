extends ComponentBase
class_name ActionGateComponent
## 行为门组件（Gameplay/Common 层）
## 作用：把“资源消耗 + 冷却检查”统一收口，避免能力组件重复写样板代码。

signal action_succeeded(action: StringName)
signal action_blocked(action: StringName, reason: StringName)

@export var cooldown_component: CooldownComponent
@export var resource_pool: ResourcePoolComponent

func _component_ready() -> void:
	if not cooldown_component:
		cooldown_component = find_sibling(CooldownComponent) as CooldownComponent
	if not resource_pool:
		resource_pool = find_sibling(ResourcePoolComponent) as ResourcePoolComponent

## 尝试执行行为。
## 返回 true 表示执行成功；false 表示被拦截。
func try_perform(action: StringName, cost: float = 0.0, cooldown: float = 0.0) -> bool:
	if not enabled:
		action_blocked.emit(action, &"disabled")
		return false
	if cooldown_component and not cooldown_component.is_ready(action):
		action_blocked.emit(action, &"cooldown")
		return false
	if resource_pool and cost > 0.0 and not resource_pool.consume(cost):
		action_blocked.emit(action, &"resource")
		return false
	if cooldown_component and cooldown > 0.0:
		cooldown_component.start_cooldown(action, cooldown)
	action_succeeded.emit(action)
	return true

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"has_cooldown_component": cooldown_component != null,
		"has_resource_pool": resource_pool != null,
	}

