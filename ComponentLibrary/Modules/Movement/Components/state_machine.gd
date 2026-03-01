## 状态机 - 通用的状态管理系统
## 
## 特性：
## - 状态的创建、切换、更新
## - 状态的进入、退出回调
## - 状态转移条件
## - 调试支持
## 
## 使用示例：
##   var fsm = StateMachine.new()
##   fsm.add_state("idle", idle_state)
##   fsm.add_state("run", run_state)
##   fsm.add_transition("idle", "run", func(): return is_moving)
##   fsm.set_state("idle")
##
extends Node
class_name StateMachine

## 状态接口
class State:
	var name: String = ""
	var machine: StateMachine = null
	
	func _init(p_name: String) -> void:
		name = p_name
	
	## 进入状态时调用
	func _on_enter() -> void:
		pass
	
	## 退出状态时调用
	func _on_exit() -> void:
		pass
	
	## 状态处理（每帧调用）
	func _on_process(delta: float) -> void:
		pass
	
	## 物理处理
	func _on_physics_process(delta: float) -> void:
		pass
	
	## 输入处理
	func _on_input(event: InputEvent) -> void:
		pass

## 转移条件（避免与全局 Transition 类冲突，内嵌类命名为 StateTransition）
class StateTransition:
	var from_state: String
	var to_state: String
	var condition: Callable
	
	func _init(p_from: String, p_to: String, p_condition: Callable) -> void:
		from_state = p_from
		to_state = p_to
		condition = p_condition

## 状态字典 name -> State
var states: Dictionary[String, State] = {}

## 转移列表
var transitions: Array[StateTransition] = []

## 当前状态
var current_state: State = null

## 上一个状态
var previous_state: State = null

## 状态改变信号
signal state_changed(from_state: String, to_state: String)
signal state_entered(state_name: String)
signal state_exited(state_name: String)

func _ready() -> void:
	set_process(true)
	set_physics_process(true)
	set_process_input(true)

func _process(delta: float) -> void:
	if current_state:
		current_state._on_process(delta)
	
	# 检查状态转移
	_check_transitions()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state._on_physics_process(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state._on_input(event)

## 添加状态
func add_state(state_name: String, state: State) -> void:
	state.name = state_name
	state.machine = self
	states[state_name] = state

## 删除状态
func remove_state(state_name: String) -> void:
	states.erase(state_name)
	
	# 移除相关转移
	transitions = transitions.filter(
		func(t): return t.from_state != state_name and t.to_state != state_name
	)

## 添加转移条件
func add_transition(from_state: String, to_state: String, condition: Callable) -> void:
	if not from_state in states or not to_state in states:
		push_error("One or both states do not exist")
		return
	
	transitions.append(StateTransition.new(from_state, to_state, condition))

## 设置当前状态
func set_state(state_name: String) -> bool:
	if not state_name in states:
		push_error("State '%s' does not exist" % state_name)
		return false
	
	var new_state = states[state_name]
	
	if current_state == new_state:
		return false  # 已经在此状态
	
	# 离开旧状态
	if current_state:
		current_state._on_exit()
		state_exited.emit(current_state.name)
	
	# 保存前一个状态
	previous_state = current_state
	current_state = new_state
	
	# 进入新状态
	current_state._on_enter()
	state_entered.emit(current_state.name)
	
	if previous_state:
		state_changed.emit(previous_state.name, current_state.name)
	else:
		state_changed.emit("", current_state.name)
	
	return true

## 获取当前状态
func get_current_state() -> State:
	return current_state

## 获取当前状态名称
func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""

## 获取上一个状态名称
func get_previous_state_name() -> String:
	if previous_state:
		return previous_state.name
	return ""

## 检查当前状态是否为指定状态
func is_in_state(state_name: String) -> bool:
	if current_state:
		return current_state.name == state_name
	return false

## 内部：检查所有转移条件
func _check_transitions() -> void:
	if not current_state:
		return
	
	var current_state_name = current_state.name
	
	# 查找从当前状态出发的所有转移
	for transition in transitions:
		if transition.from_state == current_state_name:
			if transition.condition.call():
				set_state(transition.to_state)
				return  # 只进行一个转移

## 获取所有状态
func get_all_states() -> Array[String]:
	return states.keys()

## 调试：输出状态信息
func debug_state_info() -> String:
	var output = "=== State Machine ===\n"
	output += "Current: %s\n" % get_current_state_name()
	output += "Previous: %s\n" % get_previous_state_name()
	output += "States: %s\n" % ", ".join(get_all_states())
	output += "Transitions: %d\n" % transitions.size()
	return output
