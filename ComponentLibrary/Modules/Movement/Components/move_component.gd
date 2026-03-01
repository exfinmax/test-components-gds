extends CharacterComponentBase
class_name MoveComponent
## 移动组件 - 管理角色的水平地面移动
##
## 使用方式：
##   作为 CharacterBody2D 的子节点添加
##   需要 InputComponent 提供输入方向
##   自动处理加速/减速、朝向翻转
##
## 信号：
##   started_moving - 开始移动
##   stopped_moving - 停止移动

signal started_moving
signal stopped_moving

@export var speed: float = 400.0
@export var acceleration: float = 2048.0
@export var speed_multiplier: float = 1.0
@export var air_speed_multiplier: float = .5


## 依赖（可选但推荐 @export 连接）
@export var input_component: InputComponent

var is_moving: bool = false
var _prev_moving: bool = false

func _component_ready() -> void:
	if not input_component:
		input_component = find_component(InputComponent) as InputComponent

func _on_disable() -> void:
	# 被禁用时清理移动状态（如被 DashComponent / WallClimbComponent 禁用）
	if is_moving:
		is_moving = false
		_prev_moving = false
		stopped_moving.emit()

func _on_enable() -> void:
	# 重新启用时重置前一帧状态，避免误触信号
	_prev_moving = false

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character: return

	var dir := Vector2.ZERO
	if input_component:
		dir = input_component.get_direction()

	var target_vx := dir.x * speed * speed_multiplier
	character.velocity.x = move_toward(character.velocity.x, target_vx, acceleration * delta)

	# 移动状态变化检测
	is_moving = abs(character.velocity.x) > 1.0
	if is_moving and not _prev_moving:
		started_moving.emit()
	elif not is_moving and _prev_moving:
		stopped_moving.emit()
	_prev_moving = is_moving

func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"speed": speed,
		"acceleration": acceleration,
		"speed_multiplier": speed_multiplier,
		"is_moving": is_moving,
		"current_velocity_x": character.velocity.x if character else 0.0,
	}
