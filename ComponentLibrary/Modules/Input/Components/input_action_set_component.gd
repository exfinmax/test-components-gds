## InputActionSetComponent — 输入动作集合管理组件
## 
## 运行时管理输入动作的启用/禁用，实现"输入上下文切换"
## 例如：游戏中、菜单中、对话中使用不同的输入集合
## 
## 使用示例：
##   var sets = InputActionSetComponent.new()
##   sets.define_set(&"gameplay", [&"jump", &"attack", &"dash"])
##   sets.define_set(&"menu",     [&"ui_accept", &"ui_cancel"])
##   sets.activate_set(&"menu")
##   sets.deactivate_set(&"gameplay")

extends Node
class_name InputActionSetComponent

# ── 信号 ─────────────────────────────────────────────────────────────
signal set_activated(set_id: StringName)
signal set_deactivated(set_id: StringName)

# ── 内部状态 ──────────────────────────────────────────────────────────
## set_id → Array[StringName] (action names)
var _sets:       Dictionary = {}
## 当前激活的集合 IDs
var _active_sets: Array[StringName] = []
## 被此组件禁用的动作原始事件备份  action → Array[InputEvent]
var _disabled_backup: Dictionary = {}

# ── 公共 API ──────────────────────────────────────────────────────────

## 定义一个输入集合
func define_set(set_id: StringName, actions: Array[StringName]) -> void:
	_sets[set_id] = actions

## 激活集合（其中的动作会被启用）
## 注意：目前仅做追踪，不实际修改 InputMap 事件；
## 如需真正禁用，请用 block_set/unblock_set
func activate_set(set_id: StringName) -> void:
	if not _sets.has(set_id):
		push_warning("InputActionSetComponent: unknown set '%s'" % set_id)
		return
	if set_id in _active_sets:
		return
	_active_sets.append(set_id)
	set_activated.emit(set_id)

## 停用集合
func deactivate_set(set_id: StringName) -> void:
	if set_id in _active_sets:
		_active_sets.erase(set_id)
		set_deactivated.emit(set_id)

## 仅激活指定集合，停用其他所有
func switch_to(set_id: StringName) -> void:
	var prev := _active_sets.duplicate()
	_active_sets.clear()
	for old in prev:
		if old != set_id:
			set_deactivated.emit(old)
	activate_set(set_id)

## 检查集合是否处于激活状态
func is_set_active(set_id: StringName) -> bool:
	return set_id in _active_sets

## 检查某个 action 是否在任何激活的集合中
func is_action_in_active_set(action: StringName) -> bool:
	for sid in _active_sets:
		if _sets.has(sid) and action in _sets[sid]:
			return true
	return false

## 获取当前所有激活集合中的所有动作（去重）
func get_active_actions() -> Array[StringName]:
	var result: Array[StringName] = []
	for sid in _active_sets:
		if _sets.has(sid):
			for a: StringName in _sets[sid]:
				if a not in result:
					result.append(a)
	return result

## 获取当前激活的集合 ID 列表
func get_active_sets() -> Array[StringName]:
	return _active_sets.duplicate()

## 清除所有集合定义
func clear_sets() -> void:
	_sets.clear()
	_active_sets.clear()
