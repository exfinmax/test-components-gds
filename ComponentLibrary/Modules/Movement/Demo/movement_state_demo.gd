## 运动和状态机Demo - 展示玩家在Idle/Run/Jump/Fall状态的切换
##
extends PackDemo
class_name MovementStateDemo

var fsm: StateMachine = null
var player_pos: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

const MOVE_SPEED = 200.0
const JUMP_FORCE = -400.0
const GRAVITY = 800.0

func _ready() -> void:
	super._ready()
	_setup_state_machine()
	print("状态机Demo已初始化")
	print("WASD - 控制移动")
	print("Space - 跳跃")

func _setup_state_machine() -> void:
	fsm = StateMachine.new()
	add_child(fsm)
	
	# 定义状态
	var idle_state = StateMachine.State.new("idle", _create_idle_handler())
	var run_state = StateMachine.State.new("run", _create_run_handler())
	var jump_state = StateMachine.State.new("jump", _create_jump_handler())
	var fall_state = StateMachine.State.new("fall", _create_fall_handler())
	
	# 添加状态
	fsm.add_state("idle", idle_state)
	fsm.add_state("run", run_state)
	fsm.add_state("jump", jump_state)
	fsm.add_state("fall", fall_state)
	
	# 定义转移
	# idle 到 run
	fsm.add_transition("idle", "run", func() -> bool:
		return Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")
	)
	
	# idle 到 jump
	fsm.add_transition("idle", "jump", func() -> bool:
		return Input.is_action_just_pressed("ui_accept")
	)
	
	# run 到 idle
	fsm.add_transition("run", "idle", func() -> bool:
		return not (Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"))
	)
	
	# run 到 jump
	fsm.add_transition("run", "jump", func() -> bool:
		return Input.is_action_just_pressed("ui_accept")
	)
	
	# jump 到 fall（在到达最高点时）
	fsm.add_transition("jump", "fall", func() -> bool:
		return velocity.y > 0
	)
	
	# fall 到 idle（落地）
	fsm.add_transition("fall", "idle", func() -> bool:
		return is_on_ground() and velocity.x == 0
	)
	
	# fall 到 run（落地但有水平速度）
	fsm.add_transition("fall", "run", func() -> bool:
		return is_on_ground() and velocity.x != 0
	)
	
	# 设置初始状态
	fsm.set_state("idle")

func _create_idle_handler() -> StateMachine.StateHandler:
	var handler = StateMachine.StateHandler.new()
	handler.on_enter = func():
		velocity.x = 0
		print("[状态] 进入 Idle 状态")
	
	handler.on_process = func(delta: float):
		velocity.y = min(velocity.y + GRAVITY * delta, 500)
	
	return handler

func _create_run_handler() -> StateMachine.StateHandler:
	var handler = StateMachine.StateHandler.new()
	handler.on_enter = func():
		print("[状态] 进入 Run 状态")
	
	handler.on_process = func(delta: float):
		# 水平移动
		if Input.is_action_pressed("ui_right"):
			velocity.x = MOVE_SPEED
		elif Input.is_action_pressed("ui_left"):
			velocity.x = -MOVE_SPEED
		else:
			velocity.x = 0
		
		# 重力
		velocity.y = min(velocity.y + GRAVITY * delta, 500)
	
	return handler

func _create_jump_handler() -> StateMachine.StateHandler:
	var handler = StateMachine.StateHandler.new()
	handler.on_enter = func():
		velocity.y = JUMP_FORCE
		print("[状态] 进入 Jump 状态")
	
	handler.on_process = func(delta: float):
		# 在跳跃中可以改变水平方向
		if Input.is_action_pressed("ui_right"):
			velocity.x = MOVE_SPEED
		elif Input.is_action_pressed("ui_left"):
			velocity.x = -MOVE_SPEED
		
		velocity.y = min(velocity.y + GRAVITY * delta, 500)
	
	return handler

func _create_fall_handler() -> StateMachine.StateHandler:
	var handler = StateMachine.StateHandler.new()
	handler.on_enter = func():
		print("[状态] 进入 Fall 状态")
	
	handler.on_process = func(delta: float):
		# 下落中可以改变水平方向
		if Input.is_action_pressed("ui_right"):
			velocity.x = MOVE_SPEED
		elif Input.is_action_pressed("ui_left"):
			velocity.x = -MOVE_SPEED
		
		velocity.y = min(velocity.y + GRAVITY * delta, 500)
	
	return handler

func _process(delta: float) -> void:
	if fsm:
		fsm.process(delta)
	
	# 更新位置
	player_pos += velocity * delta
	
	# 地面碰撞检测（简化为y轴）
	if player_pos.y >= 400:
		player_pos.y = 400
		velocity.y = 0

func is_on_ground() -> bool:
	return player_pos.y >= 400

func _input(event: InputEvent) -> void:
	if fsm:
		fsm.input(event)
