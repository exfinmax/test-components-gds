class_name KeybindingRow
extends HBoxContainer
## 按键绑定单行组件（场景版）
##
## 场景结构（keybinding_row.tscn）：
##   HBoxContainer  ← 本脚本
##   ├── ActionLabel  (Label)   — unique_name_in_owner
##   ├── VBoxContainer (BindingsContainer) — unique_name_in_owner
##   └── AddButton    (Button)  — unique_name_in_owner
##
## KeybindingUI 实例化场景后调用 setup() 完成初始化。

signal binding_changed(action: String, new_event: InputEvent)

## 对应的 InputMap 动作名
var action: String = ""

## 本地化显示名（空则直接显示 action）
var display_name: String = ""

## 共享弹窗（由 KeybindingUI 传入）
var _capture_dialog: KeyCaptureDialog

@onready var _label: Label        = %ActionLabel
@onready var _bindings_container: VBoxContainer = %BindingsContainer
@onready var _add_button: Button  = %AddButton

var _binding_buttons: Array[Button] = []

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

## 初始化行数据，必须在 add_child 之后调用
func setup(p_action: String, p_display: String, capture_dialog: KeyCaptureDialog) -> void:
	action          = p_action
	display_name    = p_display
	_capture_dialog = capture_dialog
	_label.text     = p_display if not p_display.is_empty() else p_action
	_add_button.pressed.connect(_on_add_button_pressed)
	refresh()

## 直接从 InputMap 读取当前绑定刷新按钮文字
## ⚠ 不依赖 SaveSystem，InputMap 全局随时可用，无初始化时序问题
func refresh() -> void:
	# 清空现有按钮
	for button in _binding_buttons:
		if is_instance_valid(button):
			button.queue_free()
	_binding_buttons.clear()
	
	# 添加新按钮
	if InputMap.has_action(action):
		var events := InputMap.action_get_events(action)
		for i in range(events.size()):
			var button := Button.new()
			button.text = ResourceSerializer.event_to_display_string(events[i])
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(_create_binding_pressed_func(i))
			_bindings_container.add_child(button)
			_binding_buttons.append(button)
	
	# 如果没有绑定，显示默认文本
	if _binding_buttons.size() == 0:
		var button := Button.new()
		button.text = "未绑定"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_create_binding_pressed_func(-1))
		_bindings_container.add_child(button)
		_binding_buttons.append(button)

# ──────────────────────────────────────────────
# 内部
# ──────────────────────────────────────────────

func _create_binding_pressed_func(index: int) -> Callable:
	return func():
		_on_binding_button_pressed(index)

func _on_add_button_pressed() -> void:
	_on_binding_button_pressed(-1)

func _on_binding_button_pressed(index: int) -> void:
	if not is_instance_valid(_capture_dialog):
		push_error("KeybindingRow: _capture_dialog 未设置")
		return
	# 断开旧连接（避免多次叠加）
	if _capture_dialog.key_captured.is_connected(_on_key_captured):
		_capture_dialog.key_captured.disconnect(_on_key_captured)
	_capture_dialog.key_captured.connect(func(event: InputEvent, captured_action: String):
		_on_key_captured(event, captured_action, index)
	, CONNECT_ONE_SHOT)
	_capture_dialog.open_for(action, display_name)

func _on_key_captured(event: InputEvent, captured_action: String, index: int) -> void:
	if captured_action != action:
		return
	# 优先走模块（含信号广播）；无 SaveSystem 时降级直接操作 InputMap
	var km := _get_keybinding_module()
	if km:
		if index == -1:
			# 添加新绑定
			km.add_action_event(action, event)
		else:
			# 修改现有绑定
			km.rebind_action_event(action, index, event)
		var ss := _get_save_system()
		if ss and ss.has_method("save_global"):
			ss.save_global()
	else:
		if InputMap.has_action(action):
			if index == -1:
				# 添加新绑定
				InputMap.action_add_event(action, event)
			else:
				# 修改现有绑定
				var old_events := InputMap.action_get_events(action)
				if index < old_events.size():
					InputMap.action_erase_event(action, old_events[index])
				InputMap.action_add_event(action, event)
	refresh()
	binding_changed.emit(action, event)

static func _get_keybinding_module() -> KeybindingModule:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var ss := tree.root.get_node_or_null("SaveSystem")
	if ss and ss.has_method("get_module"):
		return ss.get_module("keybindings") as KeybindingModule
	return null

static func _get_save_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	return tree.root.get_node_or_null("SaveSystem")
