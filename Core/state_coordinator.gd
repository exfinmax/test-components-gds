extends Node
class_name StateCoordinator
## 状态协调器 - 管理组件间的互斥关系和状态转换
##
## 解决的问题：
##   DashComponent 直接设置 move_component.enabled = false 造成耦合
##   StateCoordinator 统一管理这些组件间的互斥规则
##
## 使用方式：
##   1. 作为 CharacterBody2D 的子节点添加（与 Components 同级）
##   2. 自动发现同级能力组件，注册协调规则
##   3. 组件只发信号，由 StateCoordinator 决定谁该禁用/启用
##
## 规则定义：
##   add_rule("dash", ["move", "gravity"], StateRule.DISABLE)
##   当 "dash" 状态激活时，自动禁用 move 和 gravity 组件
##
## 示例（冲刺时禁用移动和重力）：
##   coordinator.activate_state("dash")   # 自动禁用 move, gravity
##   coordinator.deactivate_state("dash") # 自动恢复 move, gravity

signal state_activated(state_name: StringName)
signal state_deactivated(state_name: StringName)

enum StateAction { DISABLE, ENABLE, LOW_GRAVITY, NO_GRAVITY }

class StateRule:
	var target_component_name: StringName
	var action: StateAction
	var priority: int
	
	func _init(target: StringName, act: StateAction, prio: int = 0) -> void:
		target_component_name = target
		action = act
		priority = prio

## {state_name: Array[StateRule]}
var _rules: Dictionary = {}

## 当前激活的状态栈（支持嵌套：dash + wall_slide 同时激活）
var _active_states: Array[StringName] = []

## 组件名 → 组件引用缓存
var _component_map: Dictionary = {}

## 组件被哪些状态禁用的计数 {component_name: int}
var _disable_counts: Dictionary = {}

## 自动发现的组件父节点
@export var components_parent: Node

func _ready() -> void:
	if not components_parent:
		components_parent = owner.get_node_or_null("Components") if owner else get_parent()
	if components_parent:
		_discover_components()
	call_deferred("_auto_connect")

#region 组件发现

func _discover_components() -> void:
	if not components_parent: return
	for child in components_parent.get_children():
		if child is CharacterComponentBase:
			_component_map[child.name] = child

func get_component(comp_name: StringName) -> CharacterComponentBase:
	return _component_map.get(comp_name) as CharacterComponentBase

#endregion

#region 规则管理

## 添加协调规则：当 state_name 激活时，对 target_components 执行 action
func add_rule(state_name: StringName, target_components: Array[StringName], action: StateAction, priority: int = 0) -> void:
	if not _rules.has(state_name):
		_rules[state_name] = []
	for target in target_components:
		var exists := false
		for rule: StateRule in _rules[state_name]:
			if rule.target_component_name == target and rule.action == action and rule.priority == priority:
				exists = true
				break
		if not exists:
			_rules[state_name].append(StateRule.new(target, action, priority))

## 移除某状态的所有规则
func remove_rules(state_name: StringName) -> void:
	_rules.erase(state_name)

## 清除所有规则
func clear_rules() -> void:
	_rules.clear()

#endregion

#region 状态激活/停用

## 激活状态 - 应用所有关联规则
func activate_state(state_name: StringName) -> void:
	if state_name in _active_states: return
	_active_states.append(state_name)
	
	if _rules.has(state_name):
		for rule: StateRule in _rules[state_name]:
			_apply_rule(rule)
	
	state_activated.emit(state_name)

## 停用状态 - 撤销所有关联规则
func deactivate_state(state_name: StringName) -> void:
	if state_name not in _active_states: return
	_active_states.erase(state_name)
	
	if _rules.has(state_name):
		for rule: StateRule in _rules[state_name]:
			_revert_rule(rule)
	
	state_deactivated.emit(state_name)

## 检查状态是否激活
func is_state_active(state_name: StringName) -> bool:
	return state_name in _active_states

## 获取所有激活状态
func get_active_states() -> Array[StringName]:
	return _active_states.duplicate()

#endregion

#region 规则应用

func _apply_rule(rule: StateRule) -> void:
	var comp := get_component(rule.target_component_name)
	if not comp: return
	
	match rule.action:
		StateAction.DISABLE:
			if not _disable_counts.has(rule.target_component_name):
				_disable_counts[rule.target_component_name] = 0
			_disable_counts[rule.target_component_name] += 1
			comp.enabled = false
		
		StateAction.ENABLE:
			comp.enabled = true
		
		StateAction.LOW_GRAVITY:
			if comp is GravityComponent:
				(comp as GravityComponent).set_mode(GravityComponent.GravityMode.LOW)
		
		StateAction.NO_GRAVITY:
			if comp is GravityComponent:
				(comp as GravityComponent).set_mode(GravityComponent.GravityMode.NONE)

func _revert_rule(rule: StateRule) -> void:
	var comp := get_component(rule.target_component_name)
	if not comp: return
	
	match rule.action:
		StateAction.DISABLE:
			if _disable_counts.has(rule.target_component_name):
				_disable_counts[rule.target_component_name] -= 1
				# 只有当没有其他状态禁用该组件时才恢复
				if _disable_counts[rule.target_component_name] <= 0:
					_disable_counts.erase(rule.target_component_name)
					comp.enabled = true
		
		StateAction.ENABLE:
			pass  # enable 无需 revert
		
		StateAction.LOW_GRAVITY, StateAction.NO_GRAVITY:
			if comp is GravityComponent:
				# 检查是否有其他状态也在修改重力
				var still_modified := false
				for active_state in _active_states:
					if _rules.has(active_state):
						for other_rule: StateRule in _rules[active_state]:
							if other_rule.target_component_name == rule.target_component_name:
								if other_rule.action in [StateAction.LOW_GRAVITY, StateAction.NO_GRAVITY]:
									still_modified = true
				if not still_modified:
					(comp as GravityComponent).set_mode(GravityComponent.GravityMode.NORMAL)

#endregion

#region 自动连接（可选 - 自动为已有组件创建默认规则）

func _auto_connect() -> void:
	# 检查是否有 DashComponent，自动创建冲刺协调规则
	var dash := get_component(&"DashComponent")
	if dash and dash is DashComponent:
		var dc := dash as DashComponent
		if not dc.dash_started.is_connected(_on_dash_started):
			dc.dash_started.connect(_on_dash_started)
		if not dc.dash_ended.is_connected(_on_dash_ended):
			dc.dash_ended.connect(_on_dash_ended)
		add_rule(&"dash", [&"MoveComponent"], StateAction.DISABLE)
		add_rule(&"dash", [&"GravityComponent"], StateAction.LOW_GRAVITY)
	
	# WallClimb 组件
	var wall := get_component(&"WallClimbComponent")
	if wall and wall is WallClimbComponent:
		var wc := wall as WallClimbComponent
		if not wc.wall_slide_started.is_connected(_on_wall_slide_started):
			wc.wall_slide_started.connect(_on_wall_slide_started)
		if not wc.wall_slide_ended.is_connected(_on_wall_slide_ended):
			wc.wall_slide_ended.connect(_on_wall_slide_ended)

func _on_dash_started(_dir: Vector2) -> void:
	activate_state(&"dash")

func _on_dash_ended() -> void:
	deactivate_state(&"dash")

func _on_wall_slide_started() -> void:
	activate_state(&"wall_slide")

func _on_wall_slide_ended() -> void:
	deactivate_state(&"wall_slide")

#endregion

#region 调试

func get_component_data() -> Dictionary:
	return {
		"type": "StateCoordinator",
		"active_states": _active_states.duplicate(),
		"registered_rules": _rules.keys(),
		"component_count": _component_map.size(),
		"disable_counts": _disable_counts.duplicate(),
	}

#endregion
