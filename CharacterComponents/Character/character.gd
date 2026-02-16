extends CharacterBody2D
class_name CharacterComponent
## 角色基类 - 轻量级组件容器
##
## 使用方式：
##   角色只负责物理（move_and_slide）和朝向管理
##   所有能力由子节点的组件提供（MoveComponent、JumpComponent 等）
##   通过 get_component() 获取组件引用
##
## 驱动模式（self_driven）：
##   组件 self_driven=true  → 组件自行运行 _process/_physics_process（默认，适合独立测试）
##   组件 self_driven=false → Character 统一调用 physics_tick(delta)/tick(delta)
##                            子类可重写 _get_physics_delta/_get_process_delta 传入补偿 delta
##
## 最小可运行场景：
##   CharacterBody2D (character.gd)
##     └─ CollisionShape2D
##   即使没有任何组件也不会报错

signal heading_changed(new_heading: Vector2)

@onready var body: Node2D = get_node_or_null("%Body")
@onready var components: Node = get_node_or_null("Components")

## 是否免疫全局时间缩放
@export var time_immune: bool = false:
	set(v):
		if time_immune == v: return
		time_immune = v
		_sync_time_immune_registration()

## 角色朝向（只有 LEFT 和 RIGHT）
var heading: Vector2 = Vector2.RIGHT:
	set(v):
		if heading == v: return
		heading = v
		heading_changed.emit(heading)
		_update_body_scale()

## 是否暂停（禁用所有组件）
var is_paused: bool = false

#region 组件快捷访问（按需缓存）

var _component_cache: Dictionary = {}

## 获取指定类型的组件（缓存结果）
func get_component(type: GDScript) -> CharacterComponentBase:
	var type_name := str(type)
	if _component_cache.has(type_name):
		var cached = _component_cache[type_name]
		if is_instance_valid(cached):
			return cached
		_component_cache.erase(type_name)

	for child in components.get_children():
		if is_instance_of(child, type):
			_component_cache[type_name] = child
			return child as CharacterComponentBase
	return null

## 获取所有组件
func get_all_components(parent: Node) -> Array[CharacterComponentBase]:
	var result: Array[CharacterComponentBase] = []
	for child in parent.get_children():
		if child is CharacterComponentBase:
			result.append(child)
	return result

## 获取所有组件的自省数据
func get_all_component_data() -> Dictionary:
	var data := {}
	for comp in get_all_components(components):
		data[comp.name] = comp.get_component_data()
	return data

#endregion

#region 物理

func _process(delta: float) -> void:
	var drive_delta := _get_process_delta(delta)
	for comp in get_all_components(components):
		if not comp.self_driven:
			comp.tick(drive_delta)

func _physics_process(delta: float) -> void:
	var drive_delta := _get_physics_delta(delta)
	for comp in get_all_components(components):
		if not comp.self_driven:
			comp.physics_tick(drive_delta)

	if _should_apply_time_compensation():
		var factor := TimeController.get_compensation_factor()
		velocity *= factor
		move_and_slide()
		velocity /= factor
	else:
		move_and_slide()
	_auto_update_heading()

## 子类重写此方法来提供补偿后的 physics delta
## 例如玩家免疫时间缩放时返回 TimeController.get_real_delta(delta)
func _get_physics_delta(delta: float) -> float:
	if time_immune and _has_time_controller():
		return TimeController.get_real_delta(delta)
	return delta

## 子类重写此方法来提供补偿后的 process delta
func _get_process_delta(delta: float) -> float:
	if time_immune and _has_time_controller():
		return TimeController.get_real_delta(delta)
	return delta

func _auto_update_heading() -> void:
	if absf(velocity.x) > 1.0:
		heading = Vector2.RIGHT if velocity.x > 0 else Vector2.LEFT

func _update_body_scale() -> void:
	if not body: return
	if heading == Vector2.LEFT:
		body.scale.x = -absf(body.scale.x)
	else:
		body.scale.x = absf(body.scale.x)

func _enter_tree() -> void:
	_sync_time_immune_registration()

func _exit_tree() -> void:
	if _has_time_controller():
		TimeController.include(self)

func _sync_time_immune_registration() -> void:
	if not _has_time_controller():
		return
	if time_immune:
		TimeController.exclude(self)
	else:
		TimeController.include(self)

func _should_apply_time_compensation() -> bool:
	return time_immune and _has_time_controller() and TimeController.engine_time_scale > 0.0

func _has_time_controller() -> bool:
	return Engine.has_singleton("TimeController") or get_node_or_null("/root/TimeController") != null

#endregion

#region 暂停控制

func set_paused(paused: bool) -> void:
	is_paused = paused
	for comp in get_all_components(components):
		comp.enabled = not paused

func freeze() -> void:
	velocity = Vector2.ZERO
	set_paused(true)

#endregion
