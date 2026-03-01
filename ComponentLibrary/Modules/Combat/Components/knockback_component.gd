extends CharacterComponentBase
class_name KnockbackComponent
## 击退组件 — 统一处理受击时的速度冲量与衰减
##
## 两种衰减模式（DecayMode）：
##   CURVE  — 计时器 + 幂次曲线，适合"被打飞"的夸张动作感
##   LERP   — 每帧速度插值衰减，适合物理感更真实的场景
##
## 抗性与输入锁定：
##   resistance 0..1 缩减实际受力；disable_input 期间自动挂起
##   InputComponent / StateCoordinator，与组件系统完全集成。
##
## API：
##   apply_knockback(direction, force)    # 方向 + 标量力度
##   apply_knockback_force(force_vec)     # 直接传 Vector2（方向已编码）

signal knockback_started(force: Vector2)
signal knockback_ended

enum DecayMode {
	CURVE,  ## 计时器 × 幂次曲线（原始版本），可精确控制"飞出感"
	LERP,   ## 每帧线性阻尼（简单物理感），阻尼系数由 lerp_damping 控制
}

@export_group("击退参数")
@export var decay_mode: DecayMode = DecayMode.CURVE
## [CURVE] 击退持续时间（秒）
@export var knockback_duration: float = 0.2
## [CURVE] 衰减幂次（1.0 线性，2.0 先快后慢）
@export var decay_power: float = 2.0
## [LERP] 速度阻尼系数（越大衰减越快）
@export var lerp_damping: float = 8.0
## [LERP] 速度低于此值时视为停止
@export var min_speed_to_stop: float = 20.0
## 击退期间禁止玩家输入（通过 StateCoordinator 或直接 disable）
@export var disable_input: bool = true
## 抗性 0.0 无抗性 → 1.0 完全免疫
@export var resistance: float = 0.0

@export_group("依赖")
@export var input_component: InputComponent
@export var move_component: MoveComponent

var is_knocked_back: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_initial: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0


func _component_ready() -> void:
	if not input_component:
		input_component = find_component(InputComponent) as InputComponent
	if not move_component:
		move_component = find_component(MoveComponent) as MoveComponent

func _physics_process(delta: float) -> void:
	if not self_driven: return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character or not is_knocked_back: return

	match decay_mode:
		DecayMode.CURVE:
			_tick_curve(delta)
		DecayMode.LERP:
			_tick_lerp(delta)

func _tick_curve(delta: float) -> void:
	_knockback_timer -= delta
	if _knockback_timer <= 0.0:
		_end_knockback()
		return
	var t := _knockback_timer / knockback_duration
	_knockback_velocity = _knockback_initial * pow(t, decay_power)
	character.velocity = _knockback_velocity

func _tick_lerp(delta: float) -> void:
	character.velocity += _knockback_velocity
	_knockback_velocity = _knockback_velocity.lerp(
			Vector2.ZERO, clampf(lerp_damping * delta, 0.0, 1.0))
	if _knockback_velocity.length() <= min_speed_to_stop:
		_knockback_velocity = Vector2.ZERO
		_end_knockback()


# ─── 公开 API ────────────────────────────────────────────────────

## 施加击退：方向 + 标量力度（force ≥ 0）
func apply_knockback(direction: Vector2, force: float) -> void:
	apply_knockback_force(direction.normalized() * force)

## 施加击退：直接传 Vector2（方向已编码在向量中）
func apply_knockback_force(force_vec: Vector2) -> void:
	if not enabled: return
	var actual := force_vec * (1.0 - clampf(resistance, 0.0, 1.0))
	if actual.is_zero_approx(): return

	is_knocked_back = true
	_knockback_velocity = actual
	_knockback_initial  = actual
	_knockback_timer    = knockback_duration

	if disable_input:
		if input_component: input_component.enabled = false
		if move_component:  move_component.enabled  = false

	if character:
		character.velocity = actual
	knockback_started.emit(actual)

func cancel_knockback() -> void:
	if is_knocked_back:
		_end_knockback()

func _end_knockback() -> void:
	is_knocked_back = false
	_knockback_timer    = 0.0
	_knockback_velocity = Vector2.ZERO

	if disable_input:
		if input_component: input_component.enabled = true
		if move_component:  move_component.enabled  = true

	knockback_ended.emit()

func get_component_data() -> Dictionary:
	return {
		"enabled":         enabled,
		"is_knocked_back": is_knocked_back,
		"decay_mode":      DecayMode.keys()[decay_mode],
		"resistance":      resistance,
		"velocity":        _knockback_velocity,
	}
