extends CharacterComponentBase
class_name GravityComponent
## 重力组件 - 管理角色的重力和下落行为
##
## 使用方式：
##   作为 CharacterBody2D 的子节点添加即可
##   支持正常重力、低重力、无重力三种模式
##
## 信号：
##   started_falling - 开始下落时发射
##   landed - 着地时发射

signal started_falling
signal landed

@export var gravity_force: float = 980.0
@export var low_gravity_multiplier: float = 0.1
@export var max_fall_speed: float = 1200.0

enum GravityMode { NORMAL, LOW, NONE }

var gravity_mode: GravityMode = GravityMode.NORMAL
var _was_on_floor: bool = false

func _component_ready() -> void:
	_was_on_floor = true

func _on_disable() -> void:
	# 禁用时同步地面状态，防止重新启用时误触着地/离地信号
	if character:
		_was_on_floor = character.is_on_floor()

func _on_enable() -> void:
	# 重新启用时刷新地面状态
	if character:
		_was_on_floor = character.is_on_floor()

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character: return

	var was_falling := character.velocity.y > 0

	match gravity_mode:
		GravityMode.NORMAL:
			character.velocity.y += gravity_force * delta
		GravityMode.LOW:
			character.velocity.y += gravity_force * low_gravity_multiplier * delta
		GravityMode.NONE:
			pass

	# 限制最大下落速度
	if character.velocity.y > max_fall_speed:
		character.velocity.y = max_fall_speed

	# 检测着地/离地
	var on_floor := character.is_on_floor()
	if not _was_on_floor and on_floor:
		landed.emit()
	elif _was_on_floor and not on_floor and character.velocity.y > 0:
		started_falling.emit()
	_was_on_floor = on_floor

func set_mode(mode: GravityMode) -> void:
	gravity_mode = mode

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"gravity_force": gravity_force,
		"gravity_mode": GravityMode.keys()[gravity_mode],
		"low_gravity_multiplier": low_gravity_multiplier,
		"max_fall_speed": max_fall_speed,
		"is_on_floor": character.is_on_floor() if character else false,
	}
