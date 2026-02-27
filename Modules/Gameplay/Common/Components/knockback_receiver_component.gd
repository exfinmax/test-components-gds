extends CharacterComponentBase
class_name KnockbackReceiverComponent
## 击退接收组件（Gameplay/Common 层）
## 作用：统一处理击退速度注入与衰减，避免战斗系统和移动系统互相写逻辑。

signal knockback_started(force: Vector2)
signal knockback_ended

@export var damping: float = 8.0
@export var min_speed_to_stop: float = 20.0

var _knockback_velocity: Vector2 = Vector2.ZERO
var _active: bool = false

func apply_knockback(force: Vector2) -> void:
	if not enabled or not character:
		return
	_knockback_velocity += force
	_active = true
	knockback_started.emit(force)

func _physics_process(delta: float) -> void:
	if not self_driven:
		return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character or not _active:
		return
	character.velocity += _knockback_velocity
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, clampf(damping * delta, 0.0, 1.0))
	if _knockback_velocity.length() <= min_speed_to_stop:
		_knockback_velocity = Vector2.ZERO
		_active = false
		knockback_ended.emit()

func clear_knockback() -> void:
	_knockback_velocity = Vector2.ZERO
	_active = false

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"active": _active,
		"velocity": _knockback_velocity,
		"damping": damping,
	}

