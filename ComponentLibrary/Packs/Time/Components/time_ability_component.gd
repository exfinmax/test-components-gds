extends CharacterComponentBase
class_name TimeAbilityComponent
## 时间能力组件（Gameplay/Time 层）
## 作用：统一处理“时缓/时停/时间冲刺”等时间能力触发流程。
## 说明：默认只广播信号，不强绑具体系统；可按项目接 TimeController 或自定义系统。

signal ability_started(ability: StringName)
signal ability_ended(ability: StringName)
signal ability_blocked(ability: StringName, reason: StringName)

@export var energy_component: TimeEnergyComponent
@export var action_gate: ActionGateComponent

@export_group("能力参数")
@export var slow_time_cost: float = 20.0
@export var slow_time_cooldown: float = 1.5
@export var slow_time_scale: float = 0.35
@export var slow_time_duration: float = 0.8

@export var time_dash_cost: float = 12.0
@export var time_dash_cooldown: float = 0.8
@export var time_dash_speed_multiplier: float = 1.8
@export var time_dash_duration: float = 0.25

var _slow_time_remaining: float = 0.0
var _dash_remaining: float = 0.0
var _original_scale: float = 1.0
var _dash_move_component: MoveComponent
var _dash_prev_speed_multiplier: float = 1.0

func _component_ready() -> void:
	if not energy_component:
		energy_component = find_sibling(TimeEnergyComponent) as TimeEnergyComponent
	if not action_gate:
		action_gate = find_sibling(ActionGateComponent) as ActionGateComponent

func _physics_process(delta: float) -> void:
	if not self_driven:
		return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled:
		return
	if _slow_time_remaining > 0.0:
		_slow_time_remaining -= delta
		if _slow_time_remaining <= 0.0:
			_end_slow_time()
	if _dash_remaining > 0.0:
		_dash_remaining -= delta
		if _dash_remaining <= 0.0:
			_end_time_dash()

func try_slow_time() -> bool:
	var ability := &"slow_time"
	if action_gate and not action_gate.try_perform(ability, slow_time_cost, slow_time_cooldown):
		ability_blocked.emit(ability, &"gate")
		return false
	if not action_gate and energy_component and not energy_component.consume(slow_time_cost):
		ability_blocked.emit(ability, &"energy")
		return false

	_slow_time_remaining = slow_time_duration
	_original_scale = TimeController.engine_time_scale if _has_time_controller() else 1.0
	if _has_time_controller():
		TimeController.engine_time_scale = slow_time_scale
	ability_started.emit(ability)
	return true

func try_time_dash(move_component: MoveComponent) -> bool:
	var ability := &"time_dash"
	if action_gate and not action_gate.try_perform(ability, time_dash_cost, time_dash_cooldown):
		ability_blocked.emit(ability, &"gate")
		return false
	if not action_gate and energy_component and not energy_component.consume(time_dash_cost):
		ability_blocked.emit(ability, &"energy")
		return false
	if move_component:
		_dash_move_component = move_component
		_dash_prev_speed_multiplier = move_component.speed_multiplier
		move_component.set_speed_multiplier(_dash_prev_speed_multiplier * time_dash_speed_multiplier)
	_dash_remaining = time_dash_duration
	ability_started.emit(ability)
	return true

func _end_slow_time() -> void:
	if _has_time_controller():
		TimeController.engine_time_scale = _original_scale
	ability_ended.emit(&"slow_time")

func _end_time_dash() -> void:
	if _dash_move_component:
		_dash_move_component.set_speed_multiplier(_dash_prev_speed_multiplier)
	_dash_move_component = null
	_dash_prev_speed_multiplier = 1.0
	ability_ended.emit(&"time_dash")

func _has_time_controller() -> bool:
	return Engine.has_singleton("TimeController") or get_node_or_null("/root/TimeController") != null

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"slow_time_remaining": _slow_time_remaining,
		"time_dash_remaining": _dash_remaining,
		"slow_time_scale": slow_time_scale,
	}
