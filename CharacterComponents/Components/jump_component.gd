extends CharacterComponentBase
class_name JumpComponent
## 跳跃组件 - 管理可变高度跳跃、土狼时间、预输入
##
## 使用方式：
##   作为 CharacterBody2D 的子节点添加
##   需要 InputComponent 提供跳跃输入
##   自动处理土狼时间和预输入缓冲
##
## 信号：
##   jumped - 起跳时发射
##   landed - 着地时发射（从空中→地面）

signal jumped
signal landed

@export_group("跳跃参数")
@export var min_jump_speed: float = 200.0  ## 轻按跳跃速度
@export var max_jump_speed: float = 600.0  ## 长按最大跳跃速度
@export var hold_time_max: float = 0.1     ## 达到最大高度需要的按住时长
@export var early_release_damping: float = 0.5  ## 提前松手时的速度衰减

@export_group("辅助机制")
@export var coyote_time: float = 0.2       ## 土狼时间（离地后仍可跳跃的窗口）
@export var pre_jump_time: float = 0.15    ## 预输入时间（落地前提前按跳跃）

@export_group("依赖")
@export var input_component: InputComponent
@export var gravity_component: GravityComponent

## 状态
var is_jumping: bool = false
var jump_hold_timer: float = 0.0
var _coyote_timer: float = 0.0
var _pre_jump_timer: float = 0.0
var _pre_jump_held: bool = false
var _was_on_floor: bool = true

func _component_ready() -> void:
	if not input_component:
		input_component = find_component(InputComponent) as InputComponent
	if not gravity_component:
		gravity_component = find_component(GravityComponent) as GravityComponent

	if input_component:
		input_component.jump_pressed.connect(_on_jump_pressed)
		input_component.jump_released.connect(_on_jump_released)

func _on_disable() -> void:
	# 禁用时取消跳跃状态和缓冲
	is_jumping = false
	jump_hold_timer = 0.0
	_coyote_timer = 0.0
	_pre_jump_timer = 0.0
	_pre_jump_held = false

func _on_enable() -> void:
	# 重新启用时根据当前是否在地面初始化土狼时间
	if character and character.is_on_floor():
		_was_on_floor = true
		_coyote_timer = coyote_time
	else:
		_was_on_floor = false
		_coyote_timer = 0.0

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character: return

	var on_floor := character.is_on_floor()

	# 土狼时间管理
	if on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	# 着地检测
	if not _was_on_floor and on_floor:
		_on_landed()
	_was_on_floor = on_floor

	# 预输入检测：如果有预输入且刚着地
	if _pre_jump_timer > 0.0:
		_pre_jump_timer -= delta
		if on_floor:
			_execute_jump()
			return

	# 跳跃持续阶段：按住时增加速度
	if is_jumping and not _is_released():
		jump_hold_timer += delta
		if jump_hold_timer < hold_time_max:
			var t := clampf(jump_hold_timer / hold_time_max, 0.0, 1.0)
			var target_speed := lerpf(min_jump_speed, max_jump_speed, t)
			if character.velocity.y < 0 and absf(character.velocity.y) < target_speed:
				character.velocity.y = -target_speed

func _on_jump_pressed() -> void:
	if not enabled: return

	# 有土狼时间 → 直接跳
	if _coyote_timer > 0.0:
		_execute_jump()
	else:
		# 空中 → 记录预输入
		_pre_jump_timer = pre_jump_time
		_pre_jump_held = true

func _on_jump_released() -> void:
	if is_jumping and character and character.velocity.y < 0:
		# 提前松手，衰减上升速度 → 短跳
		character.velocity.y *= early_release_damping
	_pre_jump_held = false

func _execute_jump() -> void:
	is_jumping = true
	jump_hold_timer = 0.0
	_coyote_timer = 0.0
	_pre_jump_timer = 0.0
	character.velocity.y = -min_jump_speed
	jumped.emit()

	if input_component:
		input_component.consume_buffered_input("jump")

func _on_landed() -> void:
	if is_jumping:
		is_jumping = false
	landed.emit()

func _is_released() -> bool:
	if input_component:
		return not input_component.is_jump_being_held()
	return true

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_jumping": is_jumping,
		"jump_hold_timer": jump_hold_timer,
		"coyote_timer": _coyote_timer,
		"pre_jump_timer": _pre_jump_timer,
		"min_jump_speed": min_jump_speed,
		"max_jump_speed": max_jump_speed,
		"hold_time_max": hold_time_max,
		"is_on_floor": character.is_on_floor() if character else false,
	}
