extends CharacterComponentBase
class_name OneWayDropComponent
## 单向平台下落组件（Gameplay/Platformer 层）
## 作用：按键后短时间关闭角色对单向平台层的碰撞，实现“下落穿透”。

signal drop_started(duration: float)
signal drop_ended

@export var drop_action: StringName = &"down"
@export var drop_duration: float = 0.22
@export var one_way_mask_bit: int = 2

var _dropping: bool = false
var _remaining: float = 0.0

func _physics_process(delta: float) -> void:
	if not self_driven:
		return
	physics_tick(delta)

func physics_tick(delta: float) -> void:
	if not enabled or not character:
		return
	if _dropping:
		_remaining -= delta
		if _remaining <= 0.0:
			_end_drop()
		return
	if Input.is_action_just_pressed(drop_action):
		start_drop()

func start_drop(duration: float = -1.0) -> void:
	if not character:
		return
	if duration > 0.0:
		drop_duration = duration
	if _dropping:
		_remaining = maxf(_remaining, drop_duration)
		return
	_dropping = true
	_remaining = drop_duration
	character.set_collision_mask_value(one_way_mask_bit, false)
	drop_started.emit(drop_duration)

func _end_drop() -> void:
	_dropping = false
	_remaining = 0.0
	if character:
		character.set_collision_mask_value(one_way_mask_bit, true)
	drop_ended.emit()

func _exit_tree() -> void:
	if character:
		character.set_collision_mask_value(one_way_mask_bit, true)

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"dropping": _dropping,
		"remaining": _remaining,
		"one_way_mask_bit": one_way_mask_bit,
	}
