extends Node
class_name TimeRewindComponent
## 时间倒流组件 - 让角色回到过去的位置（波斯王子 / Braid 核心机制）
##
## 什么是时间倒流？
##   你跳过一个悬崖失败了，按下倒流键——
##   角色的位置像录像带倒放一样回到几秒前，
##   你松开倒流键，从那个时间点重新开始操作。
##   
##   这是时间操控跑酷的**签名机制**。
##
## 工作原理（超级简单）：
##   每一帧（1/60秒）都记录一个快照：位置、速度、朝向
##   ↓ 这些快照存在一个固定大小的数组里（环形缓冲区）
##   ↓ 按下倒流键 → 从数组末尾往前读，把角色位置设回去
##   ↓ 松开倒流键 → 停止回放，从当前位置继续正常游戏
##   ↓ 数组满了 → 最旧的记录自动被覆盖（只能倒流 N 秒）
##
## 使用方式：
##   1. 作为 CharacterBody2D 子节点
##   2. 设置 max_rewind_seconds（最多能倒流几秒）
##   3. 调用 start_rewind() / stop_rewind()
##   4. 或设置 rewind_action 让玩家按键操控
##
## 与 EventBus 配合：
##   倒流开始时广播 time_rewind_started
##   倒流结束时广播 time_rewind_ended
##   其他系统（如粒子、音乐）可以监听这些信号做出反应

signal rewind_started
signal rewind_ended
signal rewind_energy_changed(ratio: float)  ## 0-1 能量比例

## 最大倒流时长（秒）
@export var max_rewind_seconds: float = 5.0

## 每秒记录帧数（不必和渲染帧率一样，30fps 够用且省内存）
@export var record_fps: int = 30

## 倒流时的回放速度倍率（1.0 = 正常速度倒放，2.0 = 双倍速倒放）
@export var rewind_speed: float = 1.5

## 绑定的输入动作名（按住倒流，松开停止；留空则手动调用 API）
@export var rewind_action: StringName = &"rewind"

## 倒流时是否使用能量（限制无限倒流）
@export var use_energy: bool = true

## 能量恢复速度（每秒恢复比例，1.0 = 每秒恢复满）
@export var energy_regen_rate: float = 0.2

## 倒流时是否禁用角色控制
@export var disable_control_while_rewinding: bool = true

## ———— 内部状态 ————

## 快照结构
class Snapshot:
	var position: Vector2
	var velocity: Vector2
	var heading: int  # 1 = 右, -1 = 左
	var animation: StringName

## 环形缓冲区
var _buffer: Array[Snapshot] = []
var _buffer_size: int = 0
var _write_index: int = 0
var _count: int = 0  # 当前已记录的帧数

## 录制计时
var _record_interval: float
var _record_timer: float = 0.0

## 倒流状态
var is_rewinding: bool = false
var _rewind_index: float = 0.0  # 当前回放到哪一帧（支持小数步进）

## 能量（0-1）
var energy: float = 1.0

## 角色引用
var _character: CharacterBody2D

func _ready() -> void:
	# 绑定角色
	if owner is CharacterBody2D:
		_character = owner
	elif get_parent() is CharacterBody2D:
		_character = get_parent()
	
	if not _character:
		push_warning("[TimeRewindComponent] 未找到 CharacterBody2D")
		return
	
	# 初始化环形缓冲区
	_buffer_size = int(max_rewind_seconds * record_fps)
	_buffer.resize(_buffer_size)
	for i in _buffer_size:
		_buffer[i] = Snapshot.new()
	
	_record_interval = 1.0 / record_fps

func _physics_process(delta: float) -> void:
	if not _character: return
	
	if is_rewinding:
		_process_rewind(delta)
	else:
		_process_record(delta)
		if use_energy and energy < 1.0:
			energy = minf(energy + energy_regen_rate * delta, 1.0)
			rewind_energy_changed.emit(energy)

func _unhandled_input(event: InputEvent) -> void:
	if rewind_action == &"": return
	if not InputMap.has_action(rewind_action): return
	
	if event.is_action_pressed(rewind_action):
		start_rewind()
	elif event.is_action_released(rewind_action):
		stop_rewind()

#region 录制

func _process_record(delta: float) -> void:
	_record_timer += delta
	if _record_timer < _record_interval: return
	_record_timer -= _record_interval
	
	# 写入当前帧快照
	var snap := _buffer[_write_index]
	snap.position = _character.global_position
	snap.velocity = _character.velocity
	
	# 尝试获取朝向
	if "heading" in _character:
		snap.heading = _character.heading
	else:
		snap.heading = 1
	
	# 尝试获取当前动画
	snap.animation = &""
	var anim_player := _character.get_node_or_null("Body/AnimationPlayer") as AnimationPlayer
	if anim_player and anim_player.is_playing():
		snap.animation = anim_player.current_animation
	
	# 推进写入指针
	_write_index = (_write_index + 1) % _buffer_size
	_count = mini(_count + 1, _buffer_size)

#endregion

#region 倒流

func _process_rewind(delta: float) -> void:
	if _count <= 0:
		stop_rewind()
		return
	
	# 能量消耗
	if use_energy:
		var cost := delta * rewind_speed / max_rewind_seconds
		energy -= cost
		rewind_energy_changed.emit(energy)
		if energy <= 0:
			energy = 0
			stop_rewind()
			return
	
	# 计算要回退多少帧
	var frames_to_rewind := rewind_speed * record_fps * delta
	_rewind_index += frames_to_rewind
	
	# 读取快照（从写入位置往回读）
	var read_pos := int(_write_index - 1 - int(_rewind_index))
	while read_pos < 0:
		read_pos += _buffer_size
	read_pos = read_pos % _buffer_size
	
	if int(_rewind_index) >= _count:
		# 已经倒到最远了
		stop_rewind()
		return
	
	var snap := _buffer[read_pos]
	
	# 应用快照到角色
	_character.global_position = snap.position
	_character.velocity = snap.velocity
	
	if "heading" in _character:
		_character.heading = snap.heading
	
	# 可选：倒放动画
	var anim_player := _character.get_node_or_null("Body/AnimationPlayer") as AnimationPlayer
	if anim_player and snap.animation != &"":
		if anim_player.current_animation != snap.animation:
			anim_player.play(snap.animation)
		anim_player.speed_scale = -rewind_speed  # 倒放

#endregion

#region API

## 开始倒流
func start_rewind() -> void:
	if is_rewinding: return
	if _count <= 0: return
	if use_energy and energy <= 0: return
	
	is_rewinding = true
	_rewind_index = 0.0
	
	# 禁用角色控制
	if disable_control_while_rewinding:
		_set_character_control(false)
	
	rewind_started.emit()
	
	if EventBus:
		EventBus.time_rewind_started.emit()

## 停止倒流
func stop_rewind() -> void:
	if not is_rewinding: return
	
	is_rewinding = false
	
	# 清除已倒流的帧（从当前位置重新开始录制）
	var rewound_frames := int(_rewind_index)
	_count = maxi(_count - rewound_frames, 0)
	_write_index = (_write_index - rewound_frames) % _buffer_size
	while _write_index < 0:
		_write_index += _buffer_size
	
	# 恢复角色控制
	if disable_control_while_rewinding:
		_set_character_control(true)
	
	# 恢复动画速度
	var anim_player := _character.get_node_or_null("Body/AnimationPlayer") as AnimationPlayer
	if anim_player:
		anim_player.speed_scale = 1.0
	
	rewind_ended.emit()
	
	if EventBus:
		EventBus.time_rewind_ended.emit()

## 获取能量比例
func get_energy_ratio() -> float:
	return energy

## 获取已录制时长（秒）
func get_recorded_duration() -> float:
	return float(_count) / record_fps

## 清空录制缓冲区
func clear_buffer() -> void:
	_count = 0
	_write_index = 0

#endregion

#region 内部

func _set_character_control(value: bool) -> void:
	for child in _character.get_children():
		if child == self: continue
		if child is CharacterComponentBase:
			child.enabled = value
		elif "enabled" in child and child.has_signal("enabled_changed"):
			child.enabled = value

#endregion

#region 自省

func get_component_data() -> Dictionary:
	return {
		"is_rewinding": is_rewinding,
		"energy": energy,
		"recorded_frames": _count,
		"recorded_seconds": get_recorded_duration(),
		"max_rewind_seconds": max_rewind_seconds,
		"buffer_size": _buffer_size,
		"rewind_speed": rewind_speed,
	}

#endregion
