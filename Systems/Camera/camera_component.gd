extends Camera2D
class_name CameraComponent
## 摄像机组件 - 跟随、震动、前瞻、区域锁定
##
## 使用方式：
##   1. 作为场景根节点的子节点添加（不是角色的子节点）
##   2. 设置 target 为要跟随的节点
##   3. 支持屏幕震动、前瞻偏移、平滑跟随、区域限制
##
## 信号：
##   shake_started - 开始震动
##   shake_finished - 震动结束
##
## 时间控制兼容：
##   支持 TimeController 的时间缩放，震动不受时间缩放影响（可选）

signal shake_started
signal shake_finished

#region 导出参数

@export_group("跟随")
@export var target: Node2D
@export var follow_speed: float = 8.0
@export var follow_offset: Vector2 = Vector2.ZERO
@export var dead_zone: Vector2 = Vector2(16.0, 8.0)

@export_group("前瞻")
@export var lookahead_enabled: bool = true
@export var lookahead_distance: float = 64.0
@export var lookahead_speed: float = 4.0

@export_group("震动")
@export var default_shake_duration: float = 0.2
@export var default_shake_strength: float = 8.0
@export var shake_immune_to_timescale: bool = true

@export_group("区域限制")
@export var use_limits: bool = false
@export var limit_rect: Rect2 = Rect2(-10000, -10000, 20000, 20000)

#endregion

#region 运行状态

var _shake_timer: float = 0.0
var _shake_strength: float = 0.0
var _shake_decay: float = 1.0
var _current_lookahead: Vector2 = Vector2.ZERO
var _target_lookahead: Vector2 = Vector2.ZERO
var _is_following: bool = true
var _original_offset: Vector2 = Vector2.ZERO
var _freeze_position: Vector2 = Vector2.ZERO
var _is_frozen: bool = false

#endregion

func _ready() -> void:
	_original_offset = follow_offset
	if use_limits:
		_apply_limits()
	make_current()

func _process(delta: float) -> void:
	if _is_frozen: return
	if not target or not is_instance_valid(target): return
	
	var real_delta := _get_real_delta(delta)
	
	_update_follow(real_delta)
	_update_lookahead(real_delta)
	_update_shake(real_delta)

#region 跟随

func _update_follow(delta: float) -> void:
	var target_pos := target.global_position + follow_offset
	
	# 死区检测
	var diff := target_pos - global_position
	if absf(diff.x) < dead_zone.x:
		target_pos.x = global_position.x
	if absf(diff.y) < dead_zone.y:
		target_pos.y = global_position.y
	
	# 平滑跟随
	var final_pos := target_pos + _current_lookahead
	global_position = global_position.lerp(final_pos, 1.0 - exp(-follow_speed * delta))

func set_target(new_target: Node2D) -> void:
	target = new_target

## 暂停跟随
func pause_following() -> void:
	_is_following = false

## 恢复跟随
func resume_following() -> void:
	_is_following = true

## 延迟恢复跟随
func resume_following_after(delay: float) -> void:
	_is_following = false
	get_tree().create_timer(delay).timeout.connect(func(): _is_following = true)

## 立即移动到目标位置（无平滑）
func snap_to_target() -> void:
	if target and is_instance_valid(target):
		global_position = target.global_position + follow_offset

#endregion

#region 前瞻

func _update_lookahead(delta: float) -> void:
	if not lookahead_enabled: return
	
	if target is CharacterBody2D:
		var cb := target as CharacterBody2D
		if absf(cb.velocity.x) > 10.0:
			_target_lookahead.x = signf(cb.velocity.x) * lookahead_distance
		else:
			_target_lookahead.x = 0.0
	
	_current_lookahead = _current_lookahead.lerp(_target_lookahead, 1.0 - exp(-lookahead_speed * delta))

func set_lookahead(enabled: bool, distance: float = -1.0) -> void:
	lookahead_enabled = enabled
	if distance >= 0.0:
		lookahead_distance = distance
	if not enabled:
		_current_lookahead = Vector2.ZERO
		_target_lookahead = Vector2.ZERO

#endregion

#region 震动

func shake(strength: float = -1.0, duration: float = -1.0) -> void:
	_shake_strength = strength if strength > 0 else default_shake_strength
	_shake_timer = duration if duration > 0 else default_shake_duration
	_shake_decay = _shake_strength / _shake_timer
	shake_started.emit()

func stop_shake() -> void:
	_shake_timer = 0.0
	_shake_strength = 0.0
	offset = Vector2.ZERO

func _update_shake(delta: float) -> void:
	if _shake_timer <= 0.0:
		return
	
	_shake_timer -= delta
	_shake_strength -= _shake_decay * delta
	
	if _shake_timer <= 0.0 or _shake_strength <= 0.0:
		_shake_timer = 0.0
		_shake_strength = 0.0
		offset = Vector2.ZERO
		shake_finished.emit()
		return
	
	offset = Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	)

#endregion

#region 区域限制

func _apply_limits() -> void:
	limit_left = int(limit_rect.position.x)
	limit_top = int(limit_rect.position.y)
	limit_right = int(limit_rect.position.x + limit_rect.size.x)
	limit_bottom = int(limit_rect.position.y + limit_rect.size.y)

func set_camera_limits(rect: Rect2) -> void:
	limit_rect = rect
	use_limits = true
	_apply_limits()

func clear_limits() -> void:
	use_limits = false
	limit_left = -10000000
	limit_right = 10000000
	limit_top = -10000000
	limit_bottom = 10000000

#endregion

#region 冻结（时停等场景）

func freeze_camera() -> void:
	_is_frozen = true
	_freeze_position = global_position

func unfreeze_camera() -> void:
	_is_frozen = false

#endregion

#region 时间补偿

func _get_real_delta(delta: float) -> float:
	if shake_immune_to_timescale:
		var ts := Engine.time_scale
		return delta / ts if ts > 0.0 else delta
	return delta

#endregion

#region 调试

func get_component_data() -> Dictionary:
	return {
		"type": "CameraComponent",
		"target": target.name if target else "null",
		"is_following": _is_following,
		"is_frozen": _is_frozen,
		"shake_remaining": _shake_timer,
		"current_lookahead": _current_lookahead,
		"global_position": global_position,
		"follow_speed": follow_speed,
		"dead_zone": dead_zone,
	}

#endregion
