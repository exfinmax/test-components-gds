extends CharacterComponentBase
class_name DashComponent
## 冲刺组件 - 管理冲刺能力（方向冲刺、次数、冷却）
##
## 使用方式：
##   作为 CharacterBody2D 的子节点添加
##   需要 InputComponent 提供冲刺输入
##   冲刺时自动禁用 MoveComponent 和 GravityComponent
##
## 信号：
##   dash_started(direction) - 冲刺开始
##   dash_ended - 冲刺结束
##   dash_count_changed(current, max) - 冲刺次数变化
##   dash_ready - 冷却结束，可再次冲刺

signal dash_started(direction: Vector2)
signal dash_ended
signal dash_count_changed(current: int, max_count: int)
signal dash_ready

@export_group("冲刺参数")
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.1
@export var max_dash_count: int = 1       ## 最大冲刺次数
@export var cooldown_time: float = 1.0    ## 冷却时间

@export_group("依赖")
@export var input_component: InputComponent
@export var move_component: MoveComponent
@export var gravity_component: GravityComponent

## 状态
var is_dashing: bool = false
var current_dash_count: int = 1
var can_dash: bool = true
var _dash_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _cooldown_active: bool = false

func _component_ready() -> void:
	if not input_component:
		input_component = find_component(InputComponent) as InputComponent
	if not move_component:
		move_component = find_component(MoveComponent) as MoveComponent
	if not gravity_component:
		gravity_component = find_component(GravityComponent) as GravityComponent

	
	
	if input_component:
		input_component.dash_pressed.connect(_on_dash_pressed)

	current_dash_count = max_dash_count

func _on_disable() -> void:
	# 禁用时如果正在冲刺，强制结束并恢复依赖组件
	if is_dashing:
		is_dashing = false
		_dash_timer = 0.0
		if move_component: move_component.enabled = true
		if gravity_component: gravity_component.set_mode(GravityComponent.GravityMode.NORMAL)
		dash_ended.emit()
	_cooldown_active = false
	_cooldown_timer = 0.0

func _on_enable() -> void:
	# 重新启用时恢复冲刺可用状态
	can_dash = true

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character: return

	# 冷却计时
	if _cooldown_active:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_cooldown_active = false
			can_dash = true
			dash_ready.emit()

	# 冲刺进行中
	if is_dashing:
		character.velocity = _dash_direction * dash_speed
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()

	# 着地恢复冲刺次数
	if character.is_on_floor() and current_dash_count < max_dash_count:
		restore_dash(max_dash_count - current_dash_count)

func _on_dash_pressed() -> void:
	if not enabled or not _can_dash(): return
	start_dash()

func start_dash(override_direction: Vector2 = Vector2.ZERO) -> void:
	## 外部也可调用此方法强制触发冲刺（如弹射）
	if override_direction != Vector2.ZERO:
		_dash_direction = override_direction.normalized()
	else:
		_determine_direction()

	is_dashing = true
	_dash_timer = dash_duration

	# 消耗冲刺次数
	current_dash_count -= 1
	dash_count_changed.emit(current_dash_count, max_dash_count)

	# 禁用移动和重力
	if move_component: move_component.enabled = false
	if gravity_component: gravity_component.set_mode(GravityComponent.GravityMode.LOW)

	character.velocity = _dash_direction * dash_speed
	dash_started.emit(_dash_direction)

func _end_dash() -> void:
	is_dashing = false

	# 恢复移动和重力
	if move_component: move_component.enabled = true
	if gravity_component: gravity_component.set_mode(GravityComponent.GravityMode.NORMAL)
	# 减少向上冲刺后的滞空
	if character.velocity.y < 0:
		character.velocity.y *= 0.6

	# 开始冷却
	_cooldown_active = true
	_cooldown_timer = cooldown_time
	can_dash = false
	dash_ended.emit()

func _determine_direction() -> void:
	if input_component:
		var input_dir := input_component.get_direction()
		if input_dir.length_squared() > 0.1:
			_dash_direction = input_dir.normalized()
			return
	# 无输入时使用角色朝向
	if character and "heading" in character:
		_dash_direction = character.heading
	else:
		_dash_direction = Vector2.RIGHT

func _can_dash() -> bool:
	return can_dash and current_dash_count > 0 and not is_dashing

func restore_dash(amount: int = 1) -> void:
	current_dash_count = mini(current_dash_count + amount, max_dash_count)
	dash_count_changed.emit(current_dash_count, max_dash_count)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_dashing": is_dashing,
		"can_dash": _can_dash(),
		"current_dash_count": current_dash_count,
		"max_dash_count": max_dash_count,
		"dash_speed": dash_speed,
		"dash_duration": dash_duration,
		"cooldown_time": cooldown_time,
		"cooldown_remaining": _cooldown_timer if _cooldown_active else 0.0,
		"dash_direction": _dash_direction,
	}
