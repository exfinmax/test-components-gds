extends CharacterBody2D
class_name CharacterComponent
## 角色基类（组件容器）
## 职责：
## 1) 统一驱动子组件 tick/physics_tick
## 2) 执行 move_and_slide
## 3) 维护朝向与时间免疫

signal heading_changed(new_heading: Vector2)

@onready var body: Node2D = get_node_or_null("%Body")
@onready var components: Node = get_node_or_null("Components")

@export var time_immune: bool = false:
	set(v):
		if time_immune == v:
			return
		time_immune = v
		_sync_time_immune_registration()

var heading: Vector2 = Vector2.RIGHT:
	set(v):
		if heading == v:
			return
		heading = v
		heading_changed.emit(heading)
		_update_body_scale()

var is_paused: bool = false

#region 组件缓存
var _component_cache: Dictionary = {}
var _components_cache_dirty: bool = true
var _components_list_cache: Array[CharacterComponentBase] = []

func _ready() -> void:
	_setup_component_watchers()
	_refresh_components_cache()

func _setup_component_watchers() -> void:
	if not components:
		return
	if not components.child_entered_tree.is_connected(_on_components_changed):
		components.child_entered_tree.connect(_on_components_changed)
	if not components.child_exiting_tree.is_connected(_on_components_changed):
		components.child_exiting_tree.connect(_on_components_changed)

func _on_components_changed(_node: Node) -> void:
	_components_cache_dirty = true
	_component_cache.clear()

func _refresh_components_cache() -> void:
	_components_list_cache.clear()
	if not components:
		_components_cache_dirty = false
		return
	for child in components.get_children():
		if child is CharacterComponentBase:
			_components_list_cache.append(child)
	_components_cache_dirty = false

func get_component(type: GDScript) -> CharacterComponentBase:
	if not components:
		return null
	if _components_cache_dirty:
		_refresh_components_cache()

	var type_name := str(type)
	if _component_cache.has(type_name):
		var cached = _component_cache[type_name]
		if is_instance_valid(cached):
			return cached
		_component_cache.erase(type_name)

	for child in _components_list_cache:
		if is_instance_of(child, type):
			_component_cache[type_name] = child
			return child as CharacterComponentBase
	return null

func get_all_components(parent: Node) -> Array[CharacterComponentBase]:
	if parent == components:
		if _components_cache_dirty:
			_refresh_components_cache()
		return _components_list_cache

	var result: Array[CharacterComponentBase] = []
	if not parent:
		return result
	for child in parent.get_children():
		if child is CharacterComponentBase:
			result.append(child)
	return result

func get_all_component_data() -> Dictionary:
	var data := {}
	for comp in get_all_components(components):
		data[comp.name] = comp.get_component_data()
	return data
#endregion

#region 驱动
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
		var factor :float= TimeController.get_compensation_factor()
		velocity *= factor
		move_and_slide()
		velocity /= factor
	else:
		move_and_slide()
	_auto_update_heading()

func _get_physics_delta(delta: float) -> float:
	if time_immune and _has_time_controller():
		return TimeController.get_real_delta(delta)
	return delta

func _get_process_delta(delta: float) -> float:
	if time_immune and _has_time_controller():
		return TimeController.get_real_delta(delta)
	return delta

func _auto_update_heading() -> void:
	if absf(velocity.x) > 1.0:
		heading = Vector2.RIGHT if velocity.x > 0 else Vector2.LEFT

func _update_body_scale() -> void:
	if not body:
		return
	if heading == Vector2.LEFT:
		body.scale.x = -absf(body.scale.x)
	else:
		body.scale.x = absf(body.scale.x)
#endregion

#region 时间免疫
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

#region 暂停
func set_paused(paused: bool) -> void:
	is_paused = paused
	for comp in get_all_components(components):
		comp.enabled = not paused

func freeze() -> void:
	velocity = Vector2.ZERO
	set_paused(true)
#endregion
