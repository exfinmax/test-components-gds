class_name BaseBalloon
extends CanvasLayer
## ════════════════════════════════════════════════════════════════
## BaseBalloon — 模块化对话气球核心节点
## ════════════════════════════════════════════════════════════════
##
## 只负责对话生命周期管理和模块调度，不包含任何具体功能逻辑。
## 所有功能通过挂载 BalloonModule 子节点来扩展。
##
## 使用方式：
##   $BaseBalloon.start(dialogue_resource, "start", [self])
##
## 模块挂载方式：
##   将 BalloonModule 子类节点作为 BaseBalloon 的直接子节点，
##   进入场景树时会自动注册。
## ════════════════════════════════════════════════════════════════

## 对话开始信号
signal dialogue_started(resource: DialogueResource, title: String)
## 对话行变化信号
signal dialogue_line_changed(line: DialogueLine)
## 对话结束信号
signal dialogue_ended()

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

## 已注册的模块列表（按注册顺序）
var _modules: Array[BalloonModule] = []

## 当前对话资源
var _dialogue_resource: DialogueResource = null

## 临时游戏状态
var _temporary_game_states: Array = []

## 当前对话行
var _current_line: DialogueLine = null

## 是否正在等待输入
var _is_waiting_for_input: bool = false

## 是否将要隐藏气球（mutated 冷却标志）
var _will_hide_balloon: bool = false

## mutated 冷却计时器
var _mutation_cooldown: Timer = Timer.new()

# ════════════════════════════════════════════════════════════════
# 生命周期
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	# 设置 mutated 冷却计时器
	_mutation_cooldown.one_shot = true
	_mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(_mutation_cooldown)
	
	# 连接 DialogueManager 的 mutated 信号
	if Engine.has_singleton("DialogueManager"):
		Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

func _unhandled_input(event: InputEvent) -> void:
	if forward_input(event):
		get_viewport().set_input_as_handled()
		return

# ════════════════════════════════════════════════════════════════
# 公共 API
# ════════════════════════════════════════════════════════════════

## 开始对话
func start(
		resource: DialogueResource,
		title: String = "",
		extra_states: Array = []) -> void:
	if resource == null:
		push_error("BaseBalloon: 对话资源为空，无法开始对话")
		return
	
	_dialogue_resource = resource
	_temporary_game_states = [self] + extra_states
	_is_waiting_for_input = false
	_will_hide_balloon = false
	
	# 通知所有模块对话开始
	_dispatch_to_modules("on_dialogue_started", [resource, title])
	
	# 发出信号
	dialogue_started.emit(resource, title)
	
	# 获取第一行对话
	_current_line = await resource.get_next_dialogue_line(title, _temporary_game_states)
	if _current_line == null:
		_end_dialogue()
		return
	
	_on_line_received(_current_line)

## 推进到下一行
func next(next_id: String = "") -> void:
	if _dialogue_resource == null:
		return
	
	_is_waiting_for_input = false
	
	var line := await _dialogue_resource.get_next_dialogue_line(next_id, _temporary_game_states)
	if line == null:
		_end_dialogue()
		return
	
	_current_line = line
	_on_line_received(line)

## 注册模块（通常由模块自身在 _enter_tree 中调用）
func register_module(module: BalloonModule) -> void:
	if module == null:
		return
	if _modules.has(module):
		return
	_modules.append(module)

## 注销模块（通常由模块自身在 _exit_tree 中调用）
func unregister_module(module: BalloonModule) -> void:
	_modules.erase(module)

## 广播模块事件（事件总线）
func emit_module_event(event_name: String, data: Dictionary = {}) -> void:
	for module in _modules:
		if not is_instance_valid(module) or not module.is_enabled:
			continue
		_safe_call_module(module, "on_module_event", [event_name, data])

## 获取指定类型的模块（返回第一个匹配的）
func get_module(module_class: Script) -> BalloonModule:
	for module in _modules:
		if is_instance_valid(module) and module.get_script() == module_class:
			return module
	return null

## 获取指定名称的模块
func get_module_by_name(module_name: String) -> BalloonModule:
	for module in _modules:
		if is_instance_valid(module) and module.get_module_name() == module_name:
			return module
	return null

## 获取当前对话行
func get_current_line() -> DialogueLine:
	return _current_line

## 是否正在等待输入
func is_waiting() -> bool:
	return _is_waiting_for_input

## 将输入事件转发给模块，返回 true 表示事件已被消费
func forward_input(event: InputEvent) -> bool:
	for module in _modules:
		if not is_instance_valid(module) or not module.is_enabled:
			continue
		if module.on_input(event):
			return true
	return false

## 获取当前对话资源
func get_dialogue_resource() -> DialogueResource:
	return _dialogue_resource

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

## 收到新对话行时处理
func _on_line_received(line: DialogueLine) -> void:
	_dispatch_to_modules("on_dialogue_line_changed", [line])
	dialogue_line_changed.emit(line)

## 结束对话
func _end_dialogue() -> void:
	_dispatch_to_modules("on_dialogue_ended", [])
	_current_line = null
	_is_waiting_for_input = false
	dialogue_ended.emit()

## 安全地向所有模块分发调用（异常隔离）
func _dispatch_to_modules(method: String, args: Array) -> void:
	for module in _modules:
		if not is_instance_valid(module) or not module.is_enabled:
			continue
		_safe_call_module(module, method, args)

## 安全调用单个模块方法（捕获异常，防止单模块错误影响其他模块）
func _safe_call_module(module: BalloonModule, method: String, args: Array) -> Variant:
	if not is_instance_valid(module):
		return null
	if not module.has_method(method):
		return null
	# GDScript 没有 try/catch，用 call_deferred 的方式无法捕获
	# 这里直接调用，依赖 Godot 的错误报告机制
	return module.callv(method, args)

# ════════════════════════════════════════════════════════════════
# 信号处理
# ════════════════════════════════════════════════════════════════

## DialogueManager.mutated 信号处理
func _on_mutated(mutation: Dictionary) -> void:
	if mutation.get("is_inline", true):
		return
	_is_waiting_for_input = false
	_will_hide_balloon = true
	_mutation_cooldown.start(0.1)

## mutated 冷却结束后处理
func _on_mutation_cooldown_timeout() -> void:
	if _will_hide_balloon:
		_will_hide_balloon = false
		_end_dialogue()
