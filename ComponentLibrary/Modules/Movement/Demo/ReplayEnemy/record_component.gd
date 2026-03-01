extends ComponentBase
class_name RecordComponent
## 录制组件 - 录制目标节点的帧数据
##
## 使用方式：
##   挂在任意节点下，@export 指定 target（要录制的角色）
##   自动每帧录制目标的位置、速度、输入、动画等
##   其他组件（如 ReplayComponent）从 buffer 读取数据
##
## 可单独测试：只需要一个 target 节点即可录制

signal recording_started
signal recording_stopped

enum RecordMode {
	INPUT,  ## 录制输入 + 速度 + 状态（适合输入回放）
	PATH,   ## 录制位置 + 动画（适合路径追踪）
	BOTH,   ## 同时录制所有数据
}

@export var target: CharacterBody2D          ## 要录制的目标
@export var record_mode: RecordMode = RecordMode.BOTH
@export var auto_start: bool = false         ## 是否自动开始录制
@export var max_buffer_seconds: float = 30.0 ## 最大缓冲时长（防止内存泄漏）

## 帧缓冲区（FIFO 队列）
var buffer: Array[ReplayFrame] = []
var is_recording: bool = false
var _local_time: float = 0.0

## 输入边沿检测（用于录制 just_pressed / just_released 事件）
var _prev_jump_held: bool = false
var _prev_dash_held: bool = false

func _ready() -> void:
	_component_ready()
	if auto_start and target:
		start_recording()

func _physics_process(delta: float) -> void:
	if not enabled or not is_recording or not target: return

	_local_time += delta
	var frame := _capture_frame()
	buffer.append(frame)

	# 限制缓冲区大小
	var max_frames := int(max_buffer_seconds * Engine.physics_ticks_per_second)
	while buffer.size() > max_frames:
		buffer.pop_front()

#region 公开 API

func start_recording() -> void:
	if is_recording: return
	is_recording = true
	_local_time = 0.0
	recording_started.emit()

func stop_recording() -> void:
	if not is_recording: return
	is_recording = false
	recording_stopped.emit()

func clear_buffer() -> void:
	buffer.clear()
	_local_time = 0.0

## 获取并移除最早的帧（供 ReplayComponent 消费）
func consume_frame() -> ReplayFrame:
	if buffer.is_empty(): return null
	return buffer.pop_front()

## 查看最早的帧但不移除
func peek_frame() -> ReplayFrame:
	if buffer.is_empty(): return null
	return buffer[0]

## 当前缓冲区长度（秒数近似）
func get_buffer_duration() -> float:
	if buffer.is_empty(): return 0.0
	return buffer[-1].time - buffer[0].time

func get_buffer_size() -> int:
	return buffer.size()

#endregion

#region 帧捕获（内部）

func _capture_frame() -> ReplayFrame:
	var frame := ReplayFrame.new()
	frame.time = _local_time
	frame.position = target.global_position
	frame.velocity = target.velocity

	# 朝向
	if "heading" in target:
		frame.heading = target.heading

	# 输入数据（INPUT / BOTH 模式）
	if record_mode != RecordMode.PATH:
		_capture_input(frame)

	# 组件状态（所有模式都需要，用于 PATH 模式下的信号回放）
	_capture_states(frame)

	# 动画数据
	_capture_animation(frame)

	return frame

func _capture_input(frame: ReplayFrame) -> void:
	## 从 InputComponent 获取输入 + 边沿事件
	var input_comp: Node = _find_child_of_type(target, "InputComponent")
	if input_comp:
		frame.input_direction = input_comp.direction if "direction" in input_comp else Vector2.ZERO

		var cur_jump: bool = input_comp.is_jump_held if "is_jump_held" in input_comp else false
		var cur_dash: bool = input_comp.is_dash_held if "is_dash_held" in input_comp else false

		# 持续状态
		frame.actions["jump_held"] = cur_jump
		frame.actions["dash_held"] = cur_dash

		# 边沿事件（just_pressed / just_released）
		frame.actions["jump_just_pressed"] = cur_jump and not _prev_jump_held
		frame.actions["jump_just_released"] = (not cur_jump) and _prev_jump_held
		frame.actions["dash_just_pressed"] = cur_dash and not _prev_dash_held
		frame.actions["dash_just_released"] = (not cur_dash) and _prev_dash_held

		_prev_jump_held = cur_jump
		_prev_dash_held = cur_dash
	else:
		# 回退：使用全局 Input
		frame.input_direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		frame.input_direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		frame.actions["jump_just_pressed"] = Input.is_action_just_pressed("jump")
		frame.actions["jump_just_released"] = Input.is_action_just_released("jump")
		frame.actions["dash_just_pressed"] = Input.is_action_just_pressed("dash")
		frame.actions["dash_just_released"] = Input.is_action_just_released("dash")
		frame.actions["jump_held"] = Input.is_action_pressed("jump")
		frame.actions["dash_held"] = Input.is_action_pressed("dash")

func _capture_states(frame: ReplayFrame) -> void:
	## 捕获组件状态（所有模式都录制，PATH 模式依靠此数据回放信号）
	var jump_comp: Node = _find_child_of_type(target, "JumpComponent")
	if jump_comp:
		frame.actions["is_jumping"] = jump_comp.is_jumping if "is_jumping" in jump_comp else false

	var dash_comp: Node = _find_child_of_type(target, "DashComponent")
	if dash_comp:
		frame.actions["is_dashing"] = dash_comp.is_dashing if "is_dashing" in dash_comp else false
		if "is_dashing" in dash_comp and dash_comp.is_dashing and "_dash_direction" in dash_comp:
			frame.extra["dash_direction"] = dash_comp._dash_direction

func _capture_animation(frame: ReplayFrame) -> void:
	var anim_player: AnimationPlayer = _find_animation_player(target)
	if anim_player:
		frame.animation_name = anim_player.current_animation

func _find_child_of_type(node: Node, type_name: String) -> Node:
	for child in node.get_children():
		if child.get_script() and child.get_script().get_global_name() == type_name:
			return child
		# 递归搜索子节点（支持 Components/ 子结构）
		var found := _find_child_of_type(child, type_name)
		if found:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	# 常见位置搜索
	for path in ["AnimationPlayer", "Body/AnimationPlayer"]:
		var ap := node.get_node_or_null(path)
		if ap is AnimationPlayer:
			return ap
	# 递归搜索第一层子节点
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		for grandchild in child.get_children():
			if grandchild is AnimationPlayer:
				return grandchild
	return null

#endregion

func _on_disable() -> void:
	# 禁用时停止录制
	if is_recording:
		stop_recording()

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_recording": is_recording,
		"record_mode": RecordMode.keys()[record_mode],
		"buffer_size": buffer.size(),
		"buffer_duration": get_buffer_duration(),
		"local_time": _local_time,
		"has_target": target != null,
	}
