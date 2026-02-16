extends ComponentBase
class_name HitFlashComponent
## 受击闪白组件 - 生命值下降时触发白色闪烁效果
##
## 使用方式：
##   作为角色子节点添加
##   连接 HealthComponent 和目标 Sprite
##   受伤时自动播放白色闪烁

const HIT_FLASH_MATERIAL := preload("uid://dmsuxnolkqhij")

@export var health_component: HealthComponent
@export var sprite: Node2D

var last_percent: float = 1.0
var hit_flash_tween: Tween

func _component_ready() -> void:
	health_component = find_sibling(HealthComponent)
	if health_component != null: health_component.health_changed.connect(on_health_change.bind())
	search_source()
	if sprite: sprite.material = HIT_FLASH_MATERIAL.duplicate()


func search_source() -> void:
	if sprite:
		return
	
	if not owner:
		return
	var found_node = _find_visual_recursive(owner)
	if found_node:
		if found_node is Sprite2D:
			sprite = found_node
		elif found_node is AnimatedSprite2D:
			sprite = found_node

func _find_visual_recursive(node: Node) -> Node:
	if node is Sprite2D or node is AnimatedSprite2D:
		return node
	
	for child in node.get_children():
		if child == self: # 防止死循环或查找到自己（如果有子节点）
			continue
		var result = _find_visual_recursive(child)
		if result:
			return result
	return null


func _on_disable() -> void:
	# 禁用时终止正在播放的闪白动画
	if hit_flash_tween != null and hit_flash_tween.is_valid():
		hit_flash_tween.kill()
		(sprite.material as ShaderMaterial).set_shader_parameter("lerp_percent", 0.0)

func _on_enable() -> void:
	# 重新启用时同步当前生命百分比
	if health_component:
		last_percent = health_component.get_health_percent()

func on_health_change(cur_percent: float) -> void:
	if not enabled: return
	if last_percent < cur_percent: return
	last_percent = cur_percent
	if hit_flash_tween != null and hit_flash_tween.is_valid():
		hit_flash_tween.kill()
	flash()

func flash() -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("lerp_percent", 1.0)
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(sprite.material, "shader_parameter/lerp_percent", 0.0, .25)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"last_percent": last_percent,
		"has_health_component": health_component != null,
		"has_sprite": sprite != null,
	}
