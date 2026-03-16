class_name KeybindingModule
extends ISaveModule
## 全局存档模块 — 按键绑定
##
## 负责将 InputMap 中所有动作的当前绑定序列化/反序列化，
## 存入全局存档（is_global = true），跨槽位共享。
##
## 支持：InputEventKey / InputEventMouseButton /
##         InputEventJoypadButton / InputEventJoypadMotion
##
## 用法：
##   SaveSystem.register_module(KeybindingModule.new())
##
## 重置默认按键：
##   KeybindingModule.instance.reset_to_defaults()
##   SaveSystem.save_global()
##
## 监听按键变更：
##   KeybindingModule.instance.bindings_changed.connect(func(): refresh_ui())

signal bindings_changed

## 单例引用
static var instance: KeybindingModule

## 跳过这些前缀的内置动作（避免覆盖 Godot UI 系统按键）
const SKIP_PREFIXES := ["ui_"]

## 默认绑定快照（首次加载时从 InputMap 读取，用于 reset_to_defaults）
## action_name → Array[Dictionary]（已序列化）
var _defaults: Dictionary = {}

func _init() -> void:
	instance = self
	_snapshot_defaults()

# ──────────────────────────────────────────────
# ISaveModule 接口
# ──────────────────────────────────────────────

func get_module_key() -> String: return "keybindings"
func is_global()      -> bool:   return true

## 收集 InputMap 中所有用户动作的当前绑定
func collect_data() -> Dictionary:
	var out: Dictionary = {}
	for action in InputMap.get_actions():
		if _should_skip(action):
			continue
		var events_data: Array = []
		for ev in InputMap.action_get_events(action):
			var d := ResourceSerializer.serialize_event(ev)
			if not d.is_empty():
				events_data.append(d)
		out[action] = events_data
	return out

## 将加载到的绑定应用到 InputMap
func apply_data(data: Dictionary) -> void:
	for action in data:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var events_data: Array = data[action] as Array
		for ev_dict in events_data:
			var ev := ResourceSerializer.deserialize_event(ev_dict)
			if ev:
				InputMap.action_add_event(action, ev)
	bindings_changed.emit()

func get_default_data() -> Dictionary:
	return _defaults.duplicate(true)

func on_new_game() -> void:
	reset_to_defaults()

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

## 重新绑定单个动作的指定事件
func rebind_action_event(action: String, index: int, new_event: InputEvent) -> void:
	if not InputMap.has_action(action):
		push_warning("KeybindingModule: action '%s' 不存在" % action)
		return
	var events := InputMap.action_get_events(action)
	if index < 0 or index >= events.size():
		push_warning("KeybindingModule: index %d out of range" % index)
		return
	InputMap.action_erase_event(action, events[index])
	InputMap.action_add_event(action, new_event)
	bindings_changed.emit()

## 添加新的按键绑定
func add_action_event(action: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action):
		push_warning("KeybindingModule: action '%s' 不存在" % action)
		return
	InputMap.action_add_event(action, new_event)
	bindings_changed.emit()

## 删除指定的按键绑定
func remove_action_event(action: String, index: int) -> void:
	if not InputMap.has_action(action):
		push_warning("KeybindingModule: action '%s' 不存在" % action)
		return
	var events := InputMap.action_get_events(action)
	if index < 0 or index >= events.size():
		push_warning("KeybindingModule: index %d out of range" % index)
		return
	InputMap.action_erase_event(action, events[index])
	bindings_changed.emit()

## 重新排序按键绑定
func reorder_action_events(action: String, from_index: int, to_index: int) -> void:
	if not InputMap.has_action(action):
		push_warning("KeybindingModule: action '%s' 不存在" % action)
		return
	var events := InputMap.action_get_events(action)
	if from_index < 0 or from_index >= events.size() or to_index < 0 or to_index >= events.size():
		push_warning("KeybindingModule: index out of range")
		return
	var event := events[from_index]
	InputMap.action_erase_event(action, event)
	# 重新添加事件到新位置
	var new_events = events.duplicate()
	new_events.remove_at(from_index)
	new_events.insert(to_index, event)
	InputMap.action_erase_events(action)
	for ev in new_events:
		InputMap.action_add_event(action, ev)
	bindings_changed.emit()

## 检测按键冲突
func check_conflict(new_event: InputEvent) -> Array:
	var conflicts: Array = []
	for action in InputMap.get_actions():
		if _should_skip(action):
			continue
		var events := InputMap.action_get_events(action)
		for ev in events:
			if _events_equal(ev, new_event):
				conflicts.append(action)
				break
	return conflicts

## 重新绑定单个动作的第一个事件（保留其余事件）
func rebind_action_primary(action: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action):
		push_warning("KeybindingModule: action '%s' 不存在" % action)
		return
	# 移除旧的第一个事件，插入新事件
	var events := InputMap.action_get_events(action)
	if events.size() > 0:
		InputMap.action_erase_event(action, events[0])
	InputMap.action_add_event(action, new_event)
	bindings_changed.emit()

## 获取动作的所有绑定事件
func get_action_events(action: String) -> Array[InputEvent]:
	if not InputMap.has_action(action):
		return []
	return InputMap.action_get_events(action)

# ──────────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────────

## 比较两个输入事件是否相等
func _events_equal(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.keycode == b.keycode
	elif a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	elif a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	elif a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and a.axis_value == b.axis_value
	return false

## 重置全部绑定到默认值
func reset_to_defaults() -> void:
	InputMap.load_from_project_settings()
	bindings_changed.emit()

## 获取指定动作的第一个绑定事件（用于 UI 显示）
func get_primary_event(action: String) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	var events := InputMap.action_get_events(action)
	return events[0] if events.size() > 0 else null

## 获取所有用户动作名称（过滤内置前缀）
func get_user_actions() -> PackedStringArray:
	var result: PackedStringArray = []
	for action in InputMap.get_actions():
		if not _should_skip(action):
			result.append(action)
	return result

# ──────────────────────────────────────────────
# 内部
# ──────────────────────────────────────────────

func _snapshot_defaults() -> void:
	# 从 ProjectSettings 原始 InputMap 快照（在任何 apply_data 之前）
	InputMap.load_from_project_settings()
	_defaults = collect_data()

func _should_skip(action: String) -> bool:
	for prefix in SKIP_PREFIXES:
		if action.begins_with(prefix):
			return true
	return false
