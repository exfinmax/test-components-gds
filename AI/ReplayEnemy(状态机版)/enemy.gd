extends Character
class_name Enemy

# --- 引用设置 ---
@export_category("Target & Settings")
@export var is_start:bool
@export var player: CharacterBody2D       # 拖入玩家节点
@export var delay_seconds: float = 2.0    # 延迟时间

@export_category("Visuals")
@export var ghost_sprite: Sprite2D
@export var ghost_anim: AnimationPlayer
@export var appear_fade_time: float = 0.15
@export_category("Debug")
@export var debug: bool = false

@onready var sprite_2d: Sprite2D = $Body/Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
#@onready var particles_manager: Node2D = $ParticlesManager

# --- 数据结构：记录操作，而不是位置 ---
class GhostFrame:
	# 记录玩家当帧的物理/状态数据（以及输入快照）
	var recorded_velocity: Vector2 = Vector2.ZERO
	var state_name: String = ""    # 玩家当帧的状态机名字（move/jump/dash/fall）
	var anim_name: String = ""     # 动画名称，用于同步视觉
	var input_direction_x: float = 0.0
	var just_jumped: bool = false
	var just_dashed: bool = false
	var time: float = 0.0
	var accumulated_dash_dir: float = 0.0
	var recorded_dash_vector: Vector2 = Vector2.ZERO
	var recorded_is_charging: bool = false
	var player_pos: Vector2 = Vector2.ZERO
	var state_data: Dictionary = {}
	var player_local_time: float = 0.0

# 缓冲区 (FIFO)
var history_buffer: Array[GhostFrame] = []
var target_buffer_size: int = 0
var _local_time: float = 0.0
var _playback_anchor_set: bool = false


# 关键动作标志
var is_dashing: bool = false
var dash_timer: float = 0.0
var _dash_end_engine_time: float = 0.0
var _dash_end_player_local_time: float = 0.0
const MAX_CHARGE_TIME = 0.1
const DASH_DURATION = 0.1  # 冲刺持续时间 (与玩家逻辑一致)
const DASH_POWER = 900.0   # 冲刺速度 (与玩家逻辑一致)

# --- AI 模式 ---
const AI_MODE_INPUT: int = 0       # 回放玩家输入/动作（延迟重现）
const AI_MODE_PATH: int = 1        # 轨迹复刻：完美抵达记录的玩家位置/动画（逐点同步）
@export var ai_mode: int = AI_MODE_INPUT
@export var position_follow_speed: float = 400.0    # 跟随位置模式基础水平速度
@export var position_follow_accel: float = 2500.0   # 加速度用于平滑追逐
@export var vertical_follow_speed: float = 900.0    # 垂直追逐最大速度（坠落/向上跟随）
@export var fall_horizontal_dampen: float = 0.3     # 下落时横向追击阻尼系数（0~1，越小越慢）
@export var fall_lock_height: float = 48.0          # 垂直距离超过该值才开始阻尼横向
@export var fall_vertical_scale: float = 6.0        # 垂直跟随放大量（原来是 6.0）
@export var path_pos_correction_threshold: float = 12.0  # PATH 模式微校正阈值（距离超过才修正）
@export var path_pos_correction_strength_x: float = 0.15 # X 轴偏差转化为速度比例
@export var path_pos_correction_strength_y: float = 0.12 # Y 轴偏差转化为速度比例
@export var path_axis_threshold_x: float = 8.0           # X 轴独立阈值
@export var path_axis_threshold_y: float = 8.0           # Y 轴独立阈值
@export var path_use_recorded_velocity: bool = true      # 使用录制的速度作为基础（否则使用位置驱动）
var _mode_blend_timer: float = 0.0
var _mode_blend_duration: float = 0.15
var _pre_switch_velocity: Vector2 = Vector2.ZERO
var is_dash:bool:
	set(v):
		var canying_component = get_node_or_null("%CanyingComponent")
		if canying_component:
			canying_component.is_enable = v

func set_ai_mode(new_mode: int) -> void:
	if new_mode not in [AI_MODE_INPUT, AI_MODE_PATH]:
		return
	if ai_mode == new_mode:
		return
	_pre_switch_velocity = velocity
	ai_mode = new_mode
	_mode_blend_timer = _mode_blend_duration
	if new_mode == 1:
		collision_shape_2d.set_deferred("disabled", true)
		no_gravity = true
	else:
		collision_shape_2d.set_deferred("disabled", false)
		no_gravity = false
	if debug:
		var name_map = {AI_MODE_INPUT:"INPUT", AI_MODE_PATH:"PATH"}
		print("[Enemy] Switch AI mode -> ", name_map.get(ai_mode, "UNKNOWN"))

# Path 模式内部状态
var _path_last_pos: Vector2 = Vector2.ZERO
var _path_initialized: bool = false
@export var path_snap_distance: float = 600.0   # 切入轨迹模式如果距离过大直接瞬移（防止长距离追逐抖动）
@export var path_blend_time: float = 0.08       # 进入 PATH 初期位置插值时间
var _path_blend_timer: float = 0.0

# 录制阶段变量（用于捕获玩家在蓄力时的方向积分）
var _recording_is_charging: bool = false
var _recording_charge_accum: float = 0.0

# 回放阶段变量（用于在敌人一侧模拟蓄力过程）
var _replay_is_charging: bool = false
var _replay_charge_timer: float = 0.0
var _replay_dash_direction: Vector2 = Vector2.ZERO
# 预跳（prejump）队列：当回放帧包含 prejump 信息时保存计时器，落地且计时器未到期则触发跳跃
var _queued_prejump: bool = false
var _queued_prejump_timer: float = 0.0
var _queued_prejump_velocity: Vector2 = Vector2.ZERO
var _queued_prejump_scale: float = 1.0
var _player_local_time_accum: float = 0.0
var _replay_player_local_time: float = 0.0

func _ready():
	## 旧的基于帧的缓冲长度仍保留为回退，但主回放使用时间戳
	#if Global.player != null:
		#player = Global.player
		#GameEvents.player_died.connect(reset_ghost)
		## 对话开始/结束信号，用于在对话时暂停敌人
		#DialogHandler.dialogue_start.connect(on_dialogue_start)
		#DialogHandler.dialogue_end.connect(on_dialogue_end.unbind(1))
	#set_ai_mode(1)
	target_buffer_size = int(delay_seconds * Engine.physics_ticks_per_second)
	visible = false
	if ghost_anim:
		ghost_anim.active = true

func start() -> void:
	is_start = true
	# global_position = Global.player.global_position




func _physics_process(delta):
	if not player:
		return
	if not is_start:
		return

	# 如果处于对话暂停状态则停止所有逻辑（跟随玩家的需求：对话期间敌人不能移动）
	if is_pause:
		return

	# 本地时间（使用 physics delta 积分），与 Engine.time_scale 一致
	_local_time += delta

	# ============================
	# 1. 录制玩家状态 (Player Recording)
	# ============================
	var frame_data = GhostFrame.new()
	# 记录玩家当帧的速度和状态（更可靠且无需访问私有输入函数）
	if player:
		frame_data.recorded_velocity = player.velocity
		# 尝试读取状态机与结构化状态数据
		if player.has_method("get_node") and player.has_node("StateMachine"):
			var sm = null
			if "state_machine" in player:
				sm = player.state_machine
			elif player.has_node("StateMachine"):
				sm = player.get_node("StateMachine")
			if sm and sm.has_method("get_current_state_name"):
				frame_data.state_name = sm.get_current_state_name()
			elif sm and sm.has_method("get_current_state"):
				frame_data.state_name = sm.get_current_state().name if sm.get_current_state() else ""
			if sm and sm.has_method("get_current_state"):
				var st_inst = sm.get_current_state()
				if st_inst and st_inst.has_method("get_state_data"):
					frame_data.state_data = st_inst.get_state_data()
		# 记录动画名
		var p_anim = null
		if player.has_node("AnimationPlayer"):
			p_anim = player.get_node("AnimationPlayer")
		elif player.has_node("Body/AnimationPlayer"):
			p_anim = player.get_node("Body/AnimationPlayer")
		if p_anim:
			frame_data.anim_name = p_anim.current_animation
		# 记录当帧的输入快照（使用全局 Input，这能反映玩家的实际按键）
		frame_data.input_direction_x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		frame_data.just_jumped = Input.is_action_just_pressed("jump")
		frame_data.just_dashed = Input.is_action_just_pressed("dash")
		# 记录时间戳（以 engine time 积分 delta 为基础），在 time_scale 改变时仍能对齐
		frame_data.time = _local_time
		frame_data.player_local_time = _player_local_time_accum
		# 记录玩家当帧位置
		frame_data.player_pos = player.global_position
		# dash 状态时的额外尝试读取（优先从状态中拿真实向量/蓄力数据）
		if frame_data.state_name == "dash":
			var is_charge_frame = frame_data.recorded_velocity.length() < 1.0
			if player and player.has_method("get_node") and ("state_machine" in player or player.has_node("StateMachine")):
				var sm2 = player.state_machine if "state_machine" in player else player.get_node("StateMachine")
				if sm2 and sm2.has_method("get_current_state") and sm2.get_current_state_name() == "dash":
					var st = sm2.get_current_state()
					if st:
						if "dash_direction" in st:
							frame_data.recorded_dash_vector = st.dash_direction
						if "is_charging" in st:
							frame_data.recorded_is_charging = st.is_charging
						if st.has_method("get_state_data"):
							frame_data.state_data = st.get_state_data()
			if is_charge_frame:
				if not _recording_is_charging:
					_recording_is_charging = true
					_recording_charge_accum = 0.0
				_recording_charge_accum += frame_data.input_direction_x * delta
				if frame_data.just_dashed:
					if frame_data.recorded_dash_vector == Vector2.ZERO:
						frame_data.accumulated_dash_dir = _recording_charge_accum
					_recording_is_charging = false
					_recording_charge_accum = 0.0
			else:
				_recording_is_charging = false

	# end if player
	
	history_buffer.append(frame_data)

	# ============================
	# 2. 重放 (Replay & Physics Logic) - 使用本地 time 积分来触发回放（与 Engine.time_scale 保持一致）
	# 优先使用记录的 player_local_time 触发（若记录存在），否则回退到基于 engine time 的触发
	# 先更新 replay 的 player-local 时间累计（使用队列头帧的 build_time_scale 作为当前缩放近似）
	_replay_player_local_time += delta

	# 不同模式的帧消费策略：
	# INPUT: 消费并基于输入/状态重放
	# PATH: 消费并直接对齐到记录的玩家位置（完美轨迹）
	var consumed_anim_name: String = ""  # 最近消费的帧动画名（供动画同步）
	if history_buffer.size() > 0 and ai_mode in [AI_MODE_INPUT, AI_MODE_PATH]:
		var head = history_buffer[0]
		var use_player_local = head.player_local_time > 0.0
		var is_ready = false
		if use_player_local:
			is_ready = (_replay_player_local_time - head.player_local_time) >= delay_seconds
		else:
			is_ready = (_local_time - head.time) >= delay_seconds
		if is_ready:
			var past_frame = history_buffer.pop_front()
			consumed_anim_name = past_frame.anim_name
			if ai_mode == AI_MODE_PATH:
				# PATH 轨迹复刻（物理还原版）：保留录制的速度 / 跳跃 / 冲刺，不直接瞬移
				if not visible:
					appear()
				var target_pos: Vector2 = past_frame.player_pos
				var _dist = global_position.distance_to(target_pos) # 保留计算（可用于未来逻辑）
				# 初始化插值（仅用于过渡，不直接瞬移垂直速度）
				if not _path_initialized:
					_path_initialized = true
					_path_last_pos = global_position
					_path_blend_timer = path_blend_time
				# 基础重力（除非 dash 正在进行）
				if not is_on_floor():
					velocity.y += gravity * delta
				# 选择基础速度：录制速度 或 位置驱动
				if path_use_recorded_velocity:
					velocity = past_frame.recorded_velocity
				else:
					velocity = (target_pos - global_position) / max(delta, 0.0001)
				# 模式初期插值位置（不覆盖垂直速度，使用插值偏差叠加纠偏）
				if _path_blend_timer > 0.0:
					var t = 1.0 - (_path_blend_timer / path_blend_time)
					var interp = _path_last_pos.lerp(target_pos, t)
					var blend_diff = interp - global_position
					velocity += blend_diff / max(delta, 0.0001)
					_path_blend_timer = max(0.0, _path_blend_timer - delta)
				# 微位置校正：超过阈值时将偏差部分转化为额外速度，逐帧逼近
				var pos_diff = target_pos - global_position
				# 分轴微校正：仅当相应轴超过阈值时添加校正速度
				if abs(pos_diff.x) > path_axis_threshold_x:
					velocity.x += pos_diff.x * path_pos_correction_strength_x / max(delta, 0.0001)
				if abs(pos_diff.y) > path_axis_threshold_y:
					velocity.y += pos_diff.y * path_pos_correction_strength_y / max(delta, 0.0001)
				# 长度整体超阈值时可再附加少量全向校正（防止对角漂移）
				if pos_diff.length() > path_pos_correction_threshold:
					velocity += pos_diff * 0.05 / max(delta, 0.0001)
				if debug and (abs(pos_diff.x) > path_axis_threshold_x or abs(pos_diff.y) > path_axis_threshold_y):
					print("[Enemy][PATH] corr vx=", velocity.x, " vy=", velocity.y, " diff=", pos_diff)
				# PATH prejump 支持：录制帧若存在 has_prejump 且未处于 build，队列处理
				var pstate_path: Dictionary = past_frame.state_data if past_frame.state_data else {}
				if pstate_path.get("has_prejump", false):
					_queued_prejump = true
					_queued_prejump_timer = pstate_path.get("prejump_timer", 0.0)
					_queued_prejump_velocity = pstate_path.get("velocity", Vector2.ZERO)
					if debug:
						print("[Enemy][PATH] queued prejump t=", _queued_prejump_timer)
				# 跳跃/冲刺物理还原
				if past_frame.state_name == "dash":
					# 使用录制的冲刺速度和剩余时间（若有）
					is_dashing = true
					is_dash = true
					var pstate_dash = past_frame.state_data if past_frame.state_data else {}
					var dash_time_left_local = pstate_dash.get("dash_time_left", DASH_DURATION)
					_dash_end_engine_time = _local_time + dash_timer
				else:
					is_dash = false
					if past_frame.state_name == "jump":
						if abs(past_frame.recorded_velocity.y) > 0.1:
							velocity.y = past_frame.recorded_velocity.y
						elif player and "jump_speed" in player:
							velocity.y = -player.jump_speed
						else:
							velocity.y = -400.0
				# 更新自身速度并移动（不强制对齐位置）
				self.velocity = velocity
				move_and_slide()
				# 设置动画 dash 标志用于残影
				# 跳过 INPUT 剩余分支，只进行公共动画同步
				# 防止继续执行输入回放逻辑：直接跳出消费分支（后续公共动画同步基于 consumed_anim_name 正常运行）
				# 使用 else/return 不方便，此处通过设置标志并提前落到底部动画同步。
				# 标志不再需要，因我们已 return 整个 _physics_process。
				# PATH 模式内直接同步动画（避免提前 return 跳过统一动画段）
				if ghost_anim:
					if consumed_anim_name != "":
						if ghost_anim.current_animation != consumed_anim_name:
							ghost_anim.play(consumed_anim_name)
					else:
						ghost_anim.stop()
				pass
				return
			# 尝试从记录的 state_data 恢复若干状态字段（D）以减少慢一拍或状态不同步问题
			var pstate: Dictionary = past_frame.state_data if past_frame.state_data else {}
			var want_start_dash_from_state: bool = false
			if pstate.has("can_dash"):
				can_dash = pstate.get("can_dash")
				if debug:
					print("[Enemy] Restored can_dash=", can_dash, " @local=", _replay_player_local_time)
			if pstate.get("is_dashing", false) and not is_dashing:
				want_start_dash_from_state = true
			if not visible:
				appear()

			# A. 重力
			if not is_on_floor():
				velocity.y += gravity * delta

			# B. 根据录制的状态/速度重放行为
			if past_frame.state_name == "dash":
				if past_frame.recorded_velocity.length() > 0.1:
					velocity = velocity.lerp(past_frame.recorded_velocity, 0.9)
				else:
					var is_charge_frame = past_frame.recorded_velocity.length() < 1.0
					var state_info: Dictionary = past_frame.state_data if past_frame.state_data else {}
					var recorded_is_charging_local = state_info.get("is_charging", past_frame.recorded_is_charging)
					var recorded_dash_vec_local = state_info.get("dash_direction", past_frame.recorded_dash_vector)
					var recorded_is_dashing_local = state_info.get("is_dashing", false)
					var dash_time_left_local = state_info.get("dash_time_left", 0.0)
					if is_charge_frame:
						if recorded_is_charging_local and recorded_dash_vec_local != Vector2.ZERO:
							self._replay_is_charging = true
							self._replay_charge_timer = 0.0
							self._replay_dash_direction = recorded_dash_vec_local
							low_gravity = true
							can_dash = false
						else:
							if not self._replay_is_charging:
								self._replay_is_charging = true
								self._replay_charge_timer = 0.0
								self._replay_dash_direction = Vector2.ZERO
							self._replay_dash_direction += Vector2(past_frame.input_direction_x, 0) * delta
							self._replay_charge_timer += delta
						if past_frame.just_dashed or recorded_is_dashing_local or want_start_dash_from_state:
							var dash_dir_use = Vector2.ZERO
							if recorded_dash_vec_local != Vector2.ZERO:
								dash_dir_use = recorded_dash_vec_local.normalized() if recorded_dash_vec_local.length() > 0.1 else (Vector2(1,0) if not ghost_sprite.flip_h else Vector2(-1,0))
							else:
								dash_dir_use = self._replay_dash_direction.normalized() if self._replay_dash_direction.length() > 0.1 else (Vector2(1,0) if not ghost_sprite.flip_h else Vector2(-1,0))
							var use_dash_speed_now = DASH_POWER
							if player and "dash_speed" in player:
								use_dash_speed_now = player.dash_speed
							if debug:
								print("[Enemy] Dash start; local=", _replay_player_local_time, " recorded_is_dashing=", recorded_is_dashing_local)
							velocity = dash_dir_use * use_dash_speed_now
							is_dashing = true
							self._replay_is_charging = false
							low_gravity = false
							is_dash = true
					else:
						if (recorded_is_dashing_local or want_start_dash_from_state) and not is_dashing:
							var dash_vel = past_frame.recorded_velocity
							if dash_vel.length() < 1.0:
								var dir_fallback = recorded_dash_vec_local
								if dir_fallback == Vector2.ZERO:
									dir_fallback = (Vector2(1,0) if not ghost_sprite.flip_h else Vector2(-1,0))
								var use_speed = (player and "dash_speed" in player) and player.dash_speed or DASH_POWER
								dash_vel = dir_fallback.normalized() * use_speed
							velocity = dash_vel
							is_dashing = true
							is_dash = true
							low_gravity = false
							self._replay_is_charging = false
			# 非 dash 状态：处理移动与跳跃
			if past_frame.state_name != "dash":
				if not is_dashing:
					var desired_speed = 0
					if player and "speed" in player:
						desired_speed = player.speed
					else:
						velocity.x = past_frame.input_direction_x * desired_speed
					var sdata: Dictionary = past_frame.state_data if past_frame.state_data else {}
					if sdata.get("has_prejump", false):
						_queued_prejump = true
						_queued_prejump_timer = sdata.get("prejump_timer", 0.0)
						_queued_prejump_velocity = sdata.get("velocity", Vector2.ZERO)
					elif sdata.get("is_ascending", false) or past_frame.just_jumped:
						if is_on_floor():
							if sdata.has("velocity") and abs(sdata["velocity"].y) > 0.1:
								velocity.y = sdata["velocity"].y
							elif player and "jump_speed" in player:
								velocity.y = -player.jump_speed
							else:
								velocity.y = -400.0
					if is_on_floor():
						can_dash = true
						if past_frame.state_name == "jump":
							if abs(past_frame.recorded_velocity.y) > 0.1:
								velocity.y = past_frame.recorded_velocity.y
							elif player and "jump_speed" in player:
								velocity.y = -player.jump_speed
							else:
								velocity.y = -400.0

		# 处理冲刺结束：优先使用时间戳，其次回退 dash_timer
		if is_dashing:
			var end_reached = false
			if _dash_end_engine_time > 0.0 and _local_time >= _dash_end_engine_time:
				end_reached = true
			elif dash_timer > 0.0:
				# 仍保留旧逻辑，逐帧递减以防时间戳未正确设定
				dash_timer = max(0.0, dash_timer - delta)
				if dash_timer == 0.0:
					end_reached = true
			if end_reached:
				is_dashing = false
				is_dash = false
				if velocity.y < 0:
					velocity.y *= 0.6
				low_gravity = false
				_dash_end_engine_time = 0.0
				_dash_end_player_local_time = 0.0

		# E. 物理移动（输入回放模式）
		self.velocity = velocity
		move_and_slide()

		if ai_mode == AI_MODE_PATH:
			if not visible:
				appear()
			var target_pos = head.player_pos
			var time_left = 0.0
			if use_player_local:
				time_left = delay_seconds - (_replay_player_local_time - head.player_local_time)
			else:
				time_left = delay_seconds - (_local_time - head.time)
			
			if time_left > delta:
				velocity = (target_pos - global_position) / time_left
			else:
				velocity = (target_pos - global_position) / delta
			
			move_and_slide()


		
		# 2. 动画同步（使用已消费帧的动画名）
	if ghost_anim:
		if consumed_anim_name != "":
			if ghost_anim.current_animation != consumed_anim_name:
				ghost_anim.play(consumed_anim_name)
		else:
			ghost_anim.stop()

	# 在每帧末尾处理预跳队列（递减计时器并在落地时触发）
	if _queued_prejump_timer > 0.0:
		# 使用记录的 build_time_scale 缩放计时器递减速率
		_queued_prejump_timer = max(0.0, _queued_prejump_timer - delta * _queued_prejump_scale)
		if _queued_prejump and is_on_floor() and _queued_prejump_timer > 0.0:
			# 在落地窗口内复刻跳跃
			if abs(_queued_prejump_velocity.y) > 0.1:
				velocity.y = _queued_prejump_velocity.y
			elif player and "jump_speed" in player:
				velocity.y = -player.jump_speed
			else:
				velocity.y = -400.0
			_queued_prejump = false
			_queued_prejump_timer = 0.0

	# 重置冲刺状态 (如果在地面上)
	if is_on_floor():
		can_dash = true

	# 如果历史已消费完，重置回放锚点以便下一次出现时重新锚定
	if history_buffer.size() == 0:
		_playback_anchor_set = false

func appear():
	# 使用 Tween 将 sprite 的 modulate.a 从 0 淡入到 1
	if visible:
		return
	visible = true
	var target_sprite: Sprite2D = ghost_sprite if ghost_sprite else sprite_2d
	if target_sprite:
		var c: Color = target_sprite.modulate
		c.a = 0.0
		target_sprite.modulate = c
		var t = create_tween()
		t.tween_property(target_sprite, "modulate:a", 1.0, appear_fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		# 如果没有 sprite 引用，则仅显示节点
		visible = true


func freeze() -> void:
	velocity = Vector2.ZERO
	set_paused(true)


func on_dialogue_start(_id:String, bo: bool) -> void:
	if bo:
		freeze()


func on_dialogue_end() -> void:
	# 在对话结束时恢复敌人（仅当敌人处于暂停时）
	if is_pause:
		set_paused(false)



func reset_ghost():
	# ... (省略重置逻辑)
	history_buffer.clear()
	velocity = Vector2.ZERO
	is_dashing = false

func die() -> void:
	#var particles :Array = particles_manager.get_children()
	#for i in particles:
		#i.emitting = true
	#set_physics_process(false)
	#await get_tree().create_timer(.8).timeout
	queue_free()


func _on_death_area_body_entered(body: Node2D) -> void:
	body.die()
	die()
