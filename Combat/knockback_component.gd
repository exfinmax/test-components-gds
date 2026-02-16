extends CharacterComponentBase
class_name KnockbackComponent
## 击退组件 - 管理受击时的击退效果
##
## 为什么需要击退组件？
##   当角色被攻击时，不应该只是扣血，还应该被"推开"
##   这就是击退（Knockback）。它让战斗有"重量感"：
##     - 被打中 → 朝反方向飞出去
##     - 大招命中 → 击飞效果更强
##     - 冲刺撞到墙 → 反弹
##
##   对于时间跑酷游戏：
##     - 碰到陷阱 → 被弹开
##     - 踩弹簧 → 被弹飞
##     - 时停解除瞬间 → 累积力量释放
##
## 使用方式：
##   1. 作为 CharacterBody2D 的子节点
##   2. 被击中时调用 apply_knockback(direction, force)
##   3. 组件自动处理速度施加和衰减
##
## 信号：
##   knockback_started(direction, force) - 击退开始
##   knockback_ended                     - 击退结束

signal knockback_started(direction: Vector2, force: float)
signal knockback_ended

@export_group("击退参数")
## 击退持续时间
@export var knockback_duration: float = 0.2
## 击退衰减曲线（1.0 = 线性衰减）
@export var decay_power: float = 2.0
## 击退期间是否禁用玩家输入
@export var disable_input: bool = true
## 击退抗性（0.0 = 无抗性，1.0 = 完全免疫击退）
@export var resistance: float = 0.0

@export_group("依赖")
@export var input_component: InputComponent
@export var move_component: MoveComponent

var is_knocked_back: bool = false
var _knockback_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_initial: Vector2 = Vector2.ZERO

func _component_ready() -> void:
	if not input_component:
		input_component = find_component(InputComponent) as InputComponent
	if not move_component:
		move_component = find_component(MoveComponent) as MoveComponent

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character: return
	if not is_knocked_back: return
	
	_knockback_timer -= delta
	
	if _knockback_timer <= 0.0:
		_end_knockback()
		return
	
	# 根据衰减曲线计算当前击退力度
	var t := _knockback_timer / knockback_duration
	var strength := pow(t, decay_power)
	_knockback_velocity = _knockback_initial * strength
	
	# 应用到角色速度
	character.velocity = _knockback_velocity

## 施加击退
## direction: 击退方向（从攻击者指向被击者）
## force: 击退力度
func apply_knockback(direction: Vector2, force: float) -> void:
	if not enabled: return
	
	# 应用抗性
	var actual_force := force * (1.0 - resistance)
	if actual_force <= 0.0: return
	
	is_knocked_back = true
	_knockback_timer = knockback_duration
	_knockback_initial = direction.normalized() * actual_force
	_knockback_velocity = _knockback_initial
	
	# 禁用输入控制
	if disable_input:
		if input_component: input_component.enabled = false
		if move_component: move_component.enabled = false
	
	character.velocity = _knockback_velocity
	knockback_started.emit(direction, actual_force)

func _end_knockback() -> void:
	is_knocked_back = false
	_knockback_timer = 0.0
	_knockback_velocity = Vector2.ZERO
	
	# 恢复输入
	if disable_input:
		if input_component: input_component.enabled = true
		if move_component: move_component.enabled = true
	
	knockback_ended.emit()

## 立即取消击退
func cancel_knockback() -> void:
	if is_knocked_back:
		_end_knockback()

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_knocked_back": is_knocked_back,
		"knockback_timer": _knockback_timer,
		"knockback_velocity": _knockback_velocity,
		"resistance": resistance,
	}
