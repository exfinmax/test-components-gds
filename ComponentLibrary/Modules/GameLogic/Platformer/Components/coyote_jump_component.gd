extends Node
class_name CoyoteJumpComponent

signal jump_buffered(remaining: float)
signal jump_consumed
signal jump_rejected(reason: StringName)

@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.15

var _grounded: bool = false
var _coyote_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0

func notify_grounded(is_grounded: bool) -> void:
	_grounded = is_grounded
	if is_grounded:
		_coyote_remaining = coyote_time

func queue_jump() -> void:
	_jump_buffer_remaining = jump_buffer_time
	jump_buffered.emit(_jump_buffer_remaining)

func can_consume_jump() -> bool:
	if _jump_buffer_remaining <= 0.0:
		return false
	if _grounded:
		return true
	return _coyote_remaining > 0.0

func consume_jump() -> bool:
	if can_consume_jump():
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		jump_consumed.emit()
		return true

	if _jump_buffer_remaining <= 0.0:
		jump_rejected.emit(&"no_buffer")
	else:
		jump_rejected.emit(&"no_ground_window")
	return false

func _process(delta: float) -> void:
	_tick(delta)

func _local_time_process(delta: float) -> void:
	_tick(delta)

func _tick(delta: float) -> void:
	var d := maxf(delta, 0.0)
	if not _grounded:
		_coyote_remaining = maxf(_coyote_remaining - d, 0.0)
	_jump_buffer_remaining = maxf(_jump_buffer_remaining - d, 0.0)
