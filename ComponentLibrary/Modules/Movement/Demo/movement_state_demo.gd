## 运动状态机 Demo — 展示 Idle / Run / Jump / Fall 状态切换
## 使用 StateMachine.State 子类方式定义状态行为
##
extends PackDemo
class_name MovementStateDemo

const MOVE_SPEED := 200.0
const JUMP_FORCE := -400.0
const GRAVITY    := 800.0

var fsm: StateMachine = null
var player_pos: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

# ─── 状态子类 ────────────────────────────────────────────────────

class IdleState extends StateMachine.State:
	var _demo: MovementStateDemo
	func _init(demo: MovementStateDemo) -> void:
		super._init("idle")
		_demo = demo
	func _on_enter() -> void:
		_demo.velocity.x = 0
		print("[状态] -> Idle")
	func _on_process(_delta: float) -> void:
		_demo.velocity.y = minf(_demo.velocity.y + _demo.GRAVITY * _delta, 500.0)

class RunState extends StateMachine.State:
	var _demo: MovementStateDemo
	func _init(demo: MovementStateDemo) -> void:
		super._init("run")
		_demo = demo
	func _on_enter() -> void:
		print("[状态] -> Run")
	func _on_process(_delta: float) -> void:
		if Input.is_action_pressed("ui_right"):
			_demo.velocity.x = _demo.MOVE_SPEED
		elif Input.is_action_pressed("ui_left"):
			_demo.velocity.x = -_demo.MOVE_SPEED
		else:
			_demo.velocity.x = 0.0
		_demo.velocity.y = minf(_demo.velocity.y + _demo.GRAVITY * _delta, 500.0)

class JumpState extends StateMachine.State:
	var _demo: MovementStateDemo
	func _init(demo: MovementStateDemo) -> void:
		super._init("jump")
		_demo = demo
	func _on_enter() -> void:
		_demo.velocity.y = _demo.JUMP_FORCE
		print("[状态] -> Jump")
	func _on_process(_delta: float) -> void:
		if Input.is_action_pressed("ui_right"):
			_demo.velocity.x = _demo.MOVE_SPEED
		elif Input.is_action_pressed("ui_left"):
			_demo.velocity.x = -_demo.MOVE_SPEED
		_demo.velocity.y = minf(_demo.velocity.y + _demo.GRAVITY * _delta, 500.0)

class FallState extends StateMachine.State:
	var _demo: MovementStateDemo
	func _init(demo: MovementStateDemo) -> void:
		super._init("fall")
		_demo = demo
	func _on_enter() -> void:
		print("[状态] -> Fall")
	func _on_process(_delta: float) -> void:
		if Input.is_action_pressed("ui_right"):
			_demo.velocity.x = _demo.MOVE_SPEED
		elif Input.is_action_pressed("ui_left"):
			_demo.velocity.x = -_demo.MOVE_SPEED
		_demo.velocity.y = minf(_demo.velocity.y + _demo.GRAVITY * _delta, 500.0)

# ─── 初始化 ──────────────────────────────────────────────────────

func _ready() -> void:
	super._ready()
	_setup_state_machine()
	print("按 方向键 移动，Space / ui_accept 跳跃")

func _setup_state_machine() -> void:
	fsm = StateMachine.new()
	add_child(fsm)

	fsm.add_state("idle",  IdleState.new(self))
	fsm.add_state("run",   RunState.new(self))
	fsm.add_state("jump",  JumpState.new(self))
	fsm.add_state("fall",  FallState.new(self))

	# idle ↔ run
	fsm.add_transition("idle", "run", func() -> bool:
		return Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"))
	fsm.add_transition("run", "idle", func() -> bool:
		return not (Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")))

	# jump
	fsm.add_transition("idle", "jump", func() -> bool:
		return Input.is_action_just_pressed("ui_accept"))
	fsm.add_transition("run",  "jump", func() -> bool:
		return Input.is_action_just_pressed("ui_accept"))

	# jump → fall → idle/run
	fsm.add_transition("jump", "fall", func() -> bool: return velocity.y > 0.0)
	fsm.add_transition("fall", "idle", func() -> bool:
		return _is_on_ground() and is_zero_approx(velocity.x))
	fsm.add_transition("fall", "run", func() -> bool:
		return _is_on_ground() and not is_zero_approx(velocity.x))

	fsm.state_changed.connect(func(from: String, to: String):
		print("[FSM] %s → %s" % [from, to]))

	fsm.set_state("idle")

# ─── 每帧 ─────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	player_pos += velocity * delta
	# 简化地面：y >= 400 视为落地
	if player_pos.y >= 400.0:
		player_pos.y = 400.0
		velocity.y = 0.0

func _is_on_ground() -> bool:
	return player_pos.y >= 400.0

func is_on_ground() -> bool:
	return player_pos.y >= 400
