## 基础玩家模板 - 完整集成运动、战斗和系统
##
extends CharacterBody2D
class_name BasicPlayerTemplate

# 运动组件
var state_machine: StateMachine = null
var current_state: String = "idle"

# 战斗组件
var attrs:     AttributeSetComponent = null
var status_fx: StatusEffectComponent  = null

# RPG组件
var inventory: InventoryComponent = null

# 运动参数
@export var move_speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 800.0

# 初始属性
@export var initial_health: float = 100.0
@export var initial_attack: float = 20.0

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_setup_movement()
	_setup_combat()
	_setup_inventory()
	print("玩家初始化完成")

func _setup_movement() -> void:
	state_machine = StateMachine.new()
	add_child(state_machine)
	
	# 创建状态
	var idle_state = StateMachine.State.new("idle")
	var run_state = StateMachine.State.new("run")
	var jump_state = StateMachine.State.new("jump")
	
	state_machine.add_state("idle", idle_state)
	state_machine.add_state("run", run_state)
	state_machine.add_state("jump", jump_state)
	
	# 转移规则
	state_machine.add_transition("idle", "run", func() -> bool:
		return Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")
	)
	
	state_machine.add_transition("idle", "jump", func() -> bool:
		return Input.is_action_just_pressed("ui_accept") and is_on_floor()
	)
	
	state_machine.add_transition("run", "idle", func() -> bool:
		return not (Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"))
	)
	
	state_machine.add_transition("run", "jump", func() -> bool:
		return Input.is_action_just_pressed("ui_accept") and is_on_floor()
	)
	
	state_machine.set_state("idle")

func _setup_combat() -> void:
	attrs = AttributeSetComponent.new()
	attrs.name = "AttributeSetComponent"
	add_child(attrs)
	attrs.set_base_attribute(&"health",  initial_health)
	attrs.set_base_attribute(&"attack",  initial_attack)
	attrs.set_base_attribute(&"defense", 5.0)
	status_fx = StatusEffectComponent.new()
	status_fx.name = "StatusEffectComponent"
	add_child(status_fx)

func _setup_inventory() -> void:
	inventory = InventoryComponent.new()
	inventory.set_slot_count(20)
	add_child(inventory)

func take_damage(damage: float) -> void:
	var current_health = attribute_system.get_value("health")
	attribute_system.modify_base_value("health", -damage)
	print("玩家受到 %.0f 伤害！剩余生命值: %.0f" % [
		damage,
		attribute_system.get_value("health")
	])

func _process(delta: float) -> void:
	if state_machine:
		state_machine.process(delta)
	
	# 处理移动
	match current_state:
		"idle":
			velocity.x = 0
		"run":
			if Input.is_action_pressed("ui_right"):
				velocity.x = move_speed
			elif Input.is_action_pressed("ui_left"):
				velocity.x = -move_speed
		"jump":
			velocity.y = jump_force
	
	# 应用重力
	velocity.y = min(velocity.y + gravity * delta, 500)
	
	# 移动
	velocity = move_and_slide(velocity)
	
	# 更新当前状态名称
	current_state = state_machine.get_current_state() if state_machine else "idle"
	
func get_health() -> float:
	return attrs.get_attribute(&"health")

func get_max_health() -> float:
	return attrs.get_base_attribute(&"health")

func debug_status() -> String:
	return "HP: %.0f/%.0f | ATK: %.0f | 状态: %s" % [
		get_health(), get_max_health(),
		attrs.get_attribute(&"attack"),
		current_state,
	]
