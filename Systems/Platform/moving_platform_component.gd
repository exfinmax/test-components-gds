extends AnimatableBody2D
class_name MovingPlatformComponent
## 移动平台组件 - 按路径移动的平台，受时间缩放影响
##
## 为什么用 AnimatableBody2D？
##   普通 StaticBody2D 不会动，CharacterBody2D 碰撞规则不适合平台。
##   AnimatableBody2D 专门设计给"被动移动的物理体"——
##   它会自动把站在上面的角色一起带走（sync_to_physics）。
##
## 使用方式：
##   1. 创建 AnimatableBody2D 场景
##   2. 添加 CollisionShape2D（平台形状）
##   3. 添加 Sprite2D（平台外观）
##   4. 挂载此脚本
##   5. 设置 waypoints（路径点）或 move_direction + move_distance
##
## 与时间操控的关系：
##   - 平台移动使用 _physics_process(delta)，delta 自动被 Engine.time_scale 影响
##   - 时间慢放 → 平台移动变慢 → 玩家可以安全跳上原本太快的平台
##   - 时间冻结 → 平台完全停止 → 变成临时落脚点
##   - 时间加速 → 平台飞速移动 → 需要精确时机跳上
##
## 移动模式：
##   PING_PONG: A→B→A→B（来回，最常用）
##   LOOP:      A→B→C→A→B→C（循环，适合传送带式）
##   ONE_SHOT:  A→B 停止（适合触发式升降台）

signal reached_waypoint(index: int)
signal completed_path

## 移动模式
enum MoveMode { PING_PONG, LOOP, ONE_SHOT }
@export var move_mode: MoveMode = MoveMode.PING_PONG

## 移动速度（像素/秒）
@export var speed: float = 100.0

## 路径点（局部坐标偏移）
## 如果为空，则使用 move_direction * move_distance 自动生成两个点
@export var waypoints: Array[Vector2] = []

## 简单模式：移动方向 + 距离（waypoints 为空时使用）
@export var move_direction: Vector2 = Vector2.RIGHT
@export var move_distance: float = 200.0

## 在路径点停留的时间（秒）
@export var wait_time: float = 0.5

## 启动延迟（秒）
@export var start_delay: float = 0.0

## 是否一开始就移动
@export var auto_start: bool = true

## 缓动类型
enum EaseType { LINEAR, EASE_IN_OUT, EASE_IN, EASE_OUT }
@export var ease_type: EaseType = EaseType.EASE_IN_OUT

## 是否受时间缩放影响（false = 免疫时间操控，永远匀速移动）
@export var affected_by_time_scale: bool = true

## 内部状态
var _waypoints_global: Array[Vector2] = []
var _current_index: int = 0
var _target_index: int = 1
var _direction: int = 1  # 1 = 正向, -1 = 反向
var _is_moving: bool = false
var _is_waiting: bool = false
var _wait_timer: float = 0.0
var _start_timer: float = 0.0
var _origin: Vector2

## 移动进度 (0-1 在当前两点之间)
var _progress: float = 0.0

func _ready() -> void:
	_origin = global_position
	sync_to_physics = true
	_setup_waypoints()
	
	if auto_start:
		if start_delay > 0:
			_start_timer = start_delay
		else:
			_is_moving = true

func _setup_waypoints() -> void:
	if waypoints.is_empty():
		# 简单模式：两点
		_waypoints_global = [
			_origin,
			_origin + move_direction.normalized() * move_distance
		]
	else:
		# 路径点模式：相对于起始位置
		_waypoints_global = []
		for wp in waypoints:
			_waypoints_global.append(_origin + wp)
		# 第一个点是自身位置
		if _waypoints_global.size() > 0 and _waypoints_global[0] != _origin:
			_waypoints_global.insert(0, _origin)

func _physics_process(delta: float) -> void:
	var dt := delta
	if not affected_by_time_scale:
		# 免疫时间缩放：补偿 delta
		var ts := Engine.time_scale
		if ts > 0:
			dt = delta / ts
		else:
			dt = 1.0 / 60.0  # 冻结时仍然移动
	
	# 启动延迟
	if _start_timer > 0:
		_start_timer -= dt
		if _start_timer <= 0:
			_is_moving = true
		return
	
	if not _is_moving: return
	
	# 等待计时
	if _is_waiting:
		_wait_timer -= dt
		if _wait_timer <= 0:
			_is_waiting = false
			_advance_target()
		return
	
	# 移动
	if _waypoints_global.size() < 2: return
	
	var from := _waypoints_global[_current_index]
	var to := _waypoints_global[_target_index]
	var total_distance := from.distance_to(to)
	
	if total_distance < 0.01:
		_arrive_at_waypoint()
		return
	
	# 更新进度
	_progress += (speed * dt) / total_distance
	_progress = clampf(_progress, 0.0, 1.0)
	
	# 应用缓动
	var eased := _apply_ease(_progress)
	
	# 更新位置
	global_position = from.lerp(to, eased)
	
	# 到达目标点
	if _progress >= 1.0:
		_arrive_at_waypoint()

func _arrive_at_waypoint() -> void:
	_progress = 0.0
	_current_index = _target_index
	reached_waypoint.emit(_current_index)
	
	if wait_time > 0:
		_is_waiting = true
		_wait_timer = wait_time
	else:
		_advance_target()

func _advance_target() -> void:
	var count := _waypoints_global.size()
	
	match move_mode:
		MoveMode.PING_PONG:
			_target_index += _direction
			if _target_index >= count:
				_direction = -1
				_target_index = count - 2
			elif _target_index < 0:
				_direction = 1
				_target_index = 1
		
		MoveMode.LOOP:
			_target_index = (_current_index + 1) % count
		
		MoveMode.ONE_SHOT:
			if _current_index >= count - 1:
				_is_moving = false
				completed_path.emit()
				return
			_target_index = _current_index + 1

func _apply_ease(t: float) -> float:
	match ease_type:
		EaseType.LINEAR:
			return t
		EaseType.EASE_IN_OUT:
			return t * t * (3.0 - 2.0 * t)  # smoothstep
		EaseType.EASE_IN:
			return t * t
		EaseType.EASE_OUT:
			return 1.0 - (1.0 - t) * (1.0 - t)
	return t

#region 外部控制 API

## 开始移动
func start_moving() -> void:
	_is_moving = true

## 停止移动
func stop_moving() -> void:
	_is_moving = false
	_is_waiting = false

## 暂停/恢复（保留当前进度）
func pause() -> void:
	_is_moving = false

func resume() -> void:
	_is_moving = true

## 重置到起点
func reset() -> void:
	_is_moving = false
	_is_waiting = false
	_progress = 0.0
	_current_index = 0
	_target_index = 1
	_direction = 1
	global_position = _waypoints_global[0] if _waypoints_global.size() > 0 else _origin

## 跳转到指定路径点
func go_to_waypoint(index: int) -> void:
	if index < 0 or index >= _waypoints_global.size(): return
	_current_index = index
	_target_index = mini(index + 1, _waypoints_global.size() - 1)
	_progress = 0.0
	global_position = _waypoints_global[index]

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"is_moving": _is_moving,
		"is_waiting": _is_waiting,
		"current_index": _current_index,
		"target_index": _target_index,
		"progress": _progress,
		"speed": speed,
		"move_mode": MoveMode.keys()[move_mode],
		"waypoints_count": _waypoints_global.size(),
	}

#endregion
