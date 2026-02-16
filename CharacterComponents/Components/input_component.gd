extends CharacterComponentBase
class_name InputComponent
## 输入组件 - 统一的输入抽象层
##
## 使用方式：
##   作为 CharacterBody2D 的子节点添加
##   支持三种输入源：玩家(PLAYER)、AI、回放(REPLAY)
##   其他组件监听此组件的信号获取输入
##
## 外部控制（AI/回放）：
##   input_component.simulate_move(Vector2.RIGHT)
##   input_component.simulate_jump(true)

signal movement_input(direction: Vector2)
signal jump_pressed
signal jump_released
signal dash_pressed
signal dash_released
signal interact_pressed

enum InputSource { PLAYER, AI, REPLAY }

@export var input_source: InputSource = InputSource.PLAYER
@export var buffer_time: float = 0.1

## 输入映射（可自定义按键名）
@export_group("输入映射")
@export var action_left: StringName = &"left"
@export var action_right: StringName = &"right"
@export var action_up: StringName = &"up"
@export var action_down: StringName = &"down"
@export var action_jump: StringName = &"jump"
@export var action_dash: StringName = &"dash"
@export var action_interact: StringName = &"interact"

## 当前输入状态（只读）
var direction: Vector2 = Vector2.ZERO
var is_jump_held: bool = false
var is_dash_held: bool = false
var jump_hold_time: float = 0.0
var dash_hold_time: float = 0.0

## 输入缓冲
var _input_buffer: Dictionary = {}

func _on_disable() -> void:
	# 禁用时清空所有输入状态，防止残留
	clear_all()

func _on_enable() -> void:
	# 重新启用时确保干净的输入状态
	clear_all()

func _process(delta: float) -> void:
	if not self_driven: return
	tick(delta)

func tick(delta: float) -> void:
	if not enabled: return

	if input_source == InputSource.PLAYER:
		_process_player_input()

	movement_input.emit(direction)
	_update_hold_timers(delta)
	_update_buffer(delta)

#region 玩家输入处理

func _process_player_input() -> void:
	# 移动
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength(action_right) - Input.get_action_strength(action_left)
	dir.y = Input.get_action_strength(action_down) - Input.get_action_strength(action_up)
	simulate_move(dir)

	# 跳跃
	if Input.is_action_just_pressed(action_jump):
		simulate_jump(true)
	elif Input.is_action_just_released(action_jump):
		simulate_jump(false)

	# 冲刺
	if Input.is_action_just_pressed(action_dash):
		simulate_dash(true)
	elif Input.is_action_just_released(action_dash):
		simulate_dash(false)

	# 交互
	if Input.is_action_just_pressed(action_interact):
		simulate_interact()

#endregion

#region 外部模拟接口（AI/回放通过这些方法注入输入）

func simulate_move(dir: Vector2) -> void:
	direction = dir

func simulate_jump(pressed: bool) -> void:
	if pressed:
		if not is_jump_held:
			is_jump_held = true
			jump_hold_time = 0.0
			_buffer_input("jump")
			jump_pressed.emit()
	else:
		if is_jump_held:
			is_jump_held = false
			jump_released.emit()

func simulate_dash(pressed: bool) -> void:
	if pressed:
		if not is_dash_held:
			is_dash_held = true
			dash_hold_time = 0.0
			_buffer_input("dash")
			dash_pressed.emit()
	else:
		if is_dash_held:
			is_dash_held = false
			dash_released.emit()

func simulate_interact() -> void:
	interact_pressed.emit()

#endregion

#region 输入查询

func get_direction() -> Vector2:
	return direction if enabled else Vector2.ZERO

func is_jump_being_held() -> bool:
	return is_jump_held

func has_buffered_input(action: String) -> bool:
	return _input_buffer.has(action)

func consume_buffered_input(action: String) -> bool:
	if _input_buffer.has(action):
		_input_buffer.erase(action)
		return true
	return false

func clear_all() -> void:
	direction = Vector2.ZERO
	is_jump_held = false
	is_dash_held = false
	jump_hold_time = 0.0
	dash_hold_time = 0.0
	_input_buffer.clear()

#endregion

#region 内部

func _update_hold_timers(delta: float) -> void:
	if is_jump_held:
		jump_hold_time += delta
	if is_dash_held:
		dash_hold_time += delta

func _buffer_input(action: String) -> void:
	_input_buffer[action] = buffer_time

func _update_buffer(delta: float) -> void:
	var expired: Array[String] = []
	for action in _input_buffer:
		_input_buffer[action] -= delta
		if _input_buffer[action] <= 0:
			expired.append(action)
	for a in expired:
		_input_buffer.erase(a)

#endregion

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"input_source": InputSource.keys()[input_source],
		"direction": direction,
		"is_jump_held": is_jump_held,
		"is_dash_held": is_dash_held,
		"jump_hold_time": jump_hold_time,
		"dash_hold_time": dash_hold_time,
		"buffered_inputs": _input_buffer.keys(),
	}
