extends ComponentBase
class_name ReplayComponent
## 回放组件 - 消费录制帧驱动角色行为
##
## 使用方式：
##   挂在回放角色（CharacterBody2D）下
##   @export record_component 指向录制源
##   两种回放模式：
##     INPUT - 将录制的输入注入 InputComponent，由角色组件驱动物理
##     PATH  - 直接操控 velocity 追踪录制的位置
##
## 可单独测试：挂在 CharacterBody2D 下 + 一个 RecordComponent 即可

signal replay_started        ## 首帧消费时发射
signal replay_frame_consumed(frame: ReplayFrame)
signal replay_ended          ## 缓冲消费完毕

## 动作信号 — 根据录制的组件状态发射（INPUT / PATH 模式均可用）
signal action_dash_started(direction: Vector2)
signal action_dash_ended
signal action_jump_started
signal action_jump_ended

enum ReplayMode {
	INPUT,  ## 输入回放：注入输入 → 组件驱动物理
	PATH,   ## 路径追踪：直接操控速度追踪位置
}

@export var record_component: RecordComponent  ## 数据源
@export var delay_seconds: float = 2.0         ## 延迟时间（录制后多久开始回放）
@export var replay_mode: ReplayMode = ReplayMode.INPUT
@export var auto_start: bool = true

@export_group("路径模式参数")
@export var path_correction_strength: float = 0.15  ## 位置校正强度
@export var path_snap_threshold: float = 600.0       ## 超过此距离直接瞬移

@export_group("外观")
@export var appear_fade_time: float = 0.15

## 出现前的回调 — 外部可连接此信号设置出生位置等
signal about_to_appear

## 依赖（自动查找或手动连接）
@export_group("依赖")
@export var character: CharacterBody2D
@export var input_component: InputComponent
@export var gravity_component: GravityComponent
@export var _anim_player: AnimationPlayer

## 内部状态
var is_replaying: bool = false
var _has_appeared: bool = false
var _local_time: float = 0.0

## 回放时的动作边沿检测
var _prev_replay_dashing: bool = false
var _prev_replay_jumping: bool = false

func _ready() -> void:
	_component_ready()
	# 确保在 CharacterComponent 驱动能力组件之前注入输入
	process_physics_priority = -1

	# 绑定角色
	if owner is CharacterBody2D:
		character = owner as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		character = get_parent() as CharacterBody2D

	if character && input_component == null && gravity_component == null:
		# 查找同级组件：优先使用 CharacterComponent.get_component（处理 Components/ 子节点结构）
		if character.has_method("get_component"):
			input_component = character.get_component(InputComponent) as InputComponent
			gravity_component = character.get_component(GravityComponent) as GravityComponent
		else:
			# 回退：递归搜索
			input_component = _find_child_recursive(character, "InputComponent") as InputComponent
			gravity_component = _find_child_recursive(character, "GravityComponent") as GravityComponent
		# AnimationPlayer 需要递归搜索
		for child in character.get_children():
			if child is AnimationPlayer and not _anim_player:
				_anim_player = child
		if not _anim_player:
			for child in character.get_children():
				for grandchild in child.get_children():
					if grandchild is AnimationPlayer:
						_anim_player = grandchild
						break

	if character:
		character.visible = false

func _on_disable() -> void:
	# 禁用时暂停回放
	is_replaying = false

func _physics_process(delta: float) -> void:
	if not enabled or not record_component: return

	_local_time += delta

	# 检查是否有成熟的帧可以消费
	var frame := _try_consume_frame()
	if not frame: return

	if not is_replaying:
		is_replaying = true
		replay_started.emit()

	if not _has_appeared:
		_appear()

	# 根据模式处理帧
	match replay_mode:
		ReplayMode.INPUT:
			_replay_input(frame, delta)
		ReplayMode.PATH:
			_replay_path(frame, delta)

	# 无论哪种模式，都根据组件状态发射动作信号（视觉特效等）
	_emit_action_signals(frame)

	# 同步动画
	_sync_animation(frame)

	# 同步朝向
	if character and "heading" in character:
		character.heading = frame.heading

	replay_frame_consumed.emit(frame)

#region 帧消费

func _try_consume_frame() -> ReplayFrame:
	var peek := record_component.peek_frame()
	if not peek: return null

	# 检查延迟是否足够
	var elapsed := _local_time - peek.time
	if elapsed < delay_seconds: return null

	return record_component.consume_frame()

#endregion

#region INPUT 模式

func _replay_input(frame: ReplayFrame, _delta: float) -> void:
	if not input_component: return

	# 注入输入方向
	input_component.simulate_move(frame.input_direction)

	# 注入跳跃边沿事件
	if frame.actions.get("jump_just_pressed", false):
		input_component.simulate_jump(true)
	elif frame.actions.get("jump_just_released", false):
		input_component.simulate_jump(false)

	# 注入冲刺边沿事件
	if frame.actions.get("dash_just_pressed", false):
		input_component.simulate_dash(true)
	elif frame.actions.get("dash_just_released", false):
		input_component.simulate_dash(false)

#endregion

#region 动作信号发射（两种模式通用）

func _emit_action_signals(frame: ReplayFrame) -> void:
	## 根据录制的组件状态检测边沿，发射动作信号
	## 视觉特效（残影、等）可连接这些信号而不依赖具体组件
	var cur_dashing: bool = frame.actions.get("is_dashing", false)
	var cur_jumping: bool = frame.actions.get("is_jumping", false)

	# 冲刺边沿
	if cur_dashing and not _prev_replay_dashing:
		var dir: Vector2 = frame.extra.get("dash_direction", frame.heading)
		action_dash_started.emit(dir)
	elif not cur_dashing and _prev_replay_dashing:
		action_dash_ended.emit()

	# 跳跃边沿
	if cur_jumping and not _prev_replay_jumping:
		action_jump_started.emit()
	elif not cur_jumping and _prev_replay_jumping:
		action_jump_ended.emit()

	_prev_replay_dashing = cur_dashing
	_prev_replay_jumping = cur_jumping

#endregion

#region PATH 模式

func _replay_path(frame: ReplayFrame, delta: float) -> void:
	if not character: return

	var target_pos := frame.position
	var diff := target_pos - character.global_position

	# 超远距离 → 直接瞬移
	if diff.length() > path_snap_threshold:
		character.global_position = target_pos
		character.velocity = frame.velocity
		return

	# 使用录制的速度为基础
	character.velocity = frame.velocity

	# 位置校正（将位置误差转化为附加速度）
	if diff.length() > 2.0:
		character.velocity += diff * path_correction_strength / maxf(delta, 0.0001)

	# PATH 模式下禁用重力组件（由录制速度包含重力效果）
	if gravity_component:
		gravity_component.enabled = false

#endregion

#region 动画同步

func _sync_animation(frame: ReplayFrame) -> void:
	if not _anim_player: return
	if frame.animation_name.is_empty(): return
	if _anim_player.current_animation != frame.animation_name:
		_anim_player.play(frame.animation_name)

#endregion

#region 外观

func _appear() -> void:
	_has_appeared = true
	if not character: return

	# 允许外部在出现前设置位置等
	about_to_appear.emit()

	character.visible = true

	# 找一个 Sprite 做淡入
	var sprite: Node = character.get_node_or_null("Body/Sprite2D")
	if not sprite:
		sprite = character.get_node_or_null("%Body")
	if sprite and "modulate" in sprite:
		var old_alpha: float = sprite.modulate.a
		sprite.modulate.a = 0.0
		var tw := character.create_tween()
		tw.tween_property(sprite, "modulate:a", old_alpha, appear_fade_time)

#endregion

func get_component_data() -> Dictionary:
	return {
		"enabled": enabled,
		"is_replaying": is_replaying,
		"replay_mode": ReplayMode.keys()[replay_mode],
		"delay_seconds": delay_seconds,
		"local_time": _local_time,
		"has_appeared": _has_appeared,
		"has_record_source": record_component != null,
		"has_input_component": input_component != null,
		"has_gravity_component": gravity_component != null,
		"buffer_available": record_component.get_buffer_size() if record_component else 0,
	}

#region 内部工具

## 递归查找子节点（按 class_name 匹配）
func _find_child_recursive(node: Node, type_name: String) -> Node:
	for child in node.get_children():
		if child.get_script() and child.get_script().get_global_name() == type_name:
			return child
		var found := _find_child_recursive(child, type_name)
		if found:
			return found
	return null

#endregion
