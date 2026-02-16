extends Node2D
class_name CanyingComponent
## 残影组件 - 生成角色拖尾残影效果
##
## 注：因继承 Node2D（需要变换），无法继承 ComponentBase，
## 但手动实现了相同的 enabled + get_component_data 模式。

signal enabled_changed(is_enabled: bool)

@export var source_sprite: Sprite2D
@export var source_animated: AnimatedSprite2D
@export var spawn_frame: int = 2

## 组件是否启用
var enabled: bool = false:
	set(v):
		if enabled == v: return
		enabled = v
		enabled_changed.emit(enabled)

func _ready() -> void:
	if owner is Node2D:
		global_position = owner.global_position
	search_source()

func search_source() -> void:
	if source_sprite or source_animated:
		return
	
	if not owner:
		return
	var found_node = _find_visual_recursive(owner)
	if found_node:
		if found_node is Sprite2D:
			source_sprite = found_node
		elif found_node is AnimatedSprite2D:
			source_animated = found_node

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

func set_enable(bo: bool) -> void:
	enabled = bo

func _process(delta: float) -> void:
	if not enabled:
		return
	if Engine.get_process_frames() % spawn_frame == 0:
		spawn_canying()


func spawn_canying() -> void:
	var canying
	if source_sprite:
		canying = source_sprite.duplicate()
	elif source_animated:
		canying = source_animated.duplicate()
	else:
		# 如果还没找到，尝试再次查找（可选，防止ready时还没初始化好）
		search_source()
		if source_sprite:
			canying = source_sprite.duplicate()
		elif source_animated:
			canying = source_animated.duplicate()
		else:
			return # 没有源时不报错，避免刷屏
			
	add_child(canying)
	canying.top_level = true # 设为顶级节点，使其不跟随父节点移动，实现拖尾效果
	if source_sprite:
		canying.global_transform = source_sprite.global_transform
	elif source_animated:
		canying.global_transform = source_animated.global_transform
		
	var tween := create_tween()
	tween.tween_property(canying,"modulate:a", 0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(canying.queue_free)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"has_source_sprite": source_sprite != null,
		"has_source_animated": source_animated != null,
		"spawn_frame": spawn_frame,
	}
