class_name KeyCaptureDialog
extends AcceptDialog
## 按键捕获弹窗
##
## 弹出后显示提示文字，等待玩家按下任意键 / 鼠标键 / 手柄键，
## 捕获到后自动关闭并通过信号回传事件。
##
## 用法（通常由 KeybindingRow 内部使用）：
##   var dlg := KeyCaptureDialog.new()
##   add_child(dlg)
##   dlg.key_captured.connect(func(ev, action): do_rebind(action, ev))
##   dlg.open_for(action_name, display_name)

## 捕获到输入后触发，携带事件和对应的 action 名称
signal key_captured(event: InputEvent, action: String)
## 用户取消（点击 OK 按钮或按 ESC）
signal capture_cancelled(action: String)

## 当前正在重绑定的 action 名称
var _current_action: String = ""

## 是否正在等待输入
var _waiting: bool = false

## 内部 Label
var _label: Label

func _ready() -> void:
	title        = "按键设置"
	min_size     = Vector2i(320, 120)
	exclusive    = true
	unresizable  = true

	# 隐藏内置 OK 按钮，改为显示「取消」
	ok_button_text = "取消"

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size  = Vector2(280, 60)
	add_child(_label)

	# AcceptDialog OK 按钮 → 视为取消
	confirmed.connect(_on_cancelled)
	canceled.connect(_on_cancelled)

# ──────────────────────────────────────────────
# 公开 API
# ──────────────────────────────────────────────

## 打开弹窗，准备捕获 action 的新绑定
func open_for(action: String, display_name: String = "") -> void:
	_current_action = action
	_waiting        = true
	var show_name   := display_name if not display_name.is_empty() else action
	_label.text     = "正在设置：%s\n\n请按下新按键…\n（按「取消」保持不变）" % show_name
	popup_centered()

# ──────────────────────────────────────────────
# 输入捕获
# ──────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not _waiting or not visible:
		return

	var accepted := false

	if event is InputEventKey and event.pressed and not event.is_echo():
		# 忽略纯修饰键（Ctrl / Shift / Alt / Meta 单独按下时不触发）
		var kc: int = event.keycode
		if kc not in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META,
					  KEY_CAPSLOCK, KEY_NUMLOCK, KEY_SCROLLLOCK]:
			accepted = true

	elif event is InputEventMouseButton and event.pressed:
		accepted = true

	elif event is InputEventJoypadButton and event.pressed:
		accepted = true

	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		accepted = true

	if accepted:
		get_viewport().set_input_as_handled()
		_waiting = false
		var captured_event := event
		
		# 检查按键冲突
		var conflicts := _check_conflicts(captured_event)
		if conflicts.size() > 0:
			# 显示冲突提示
			var conflict_text := "检测到按键冲突：\n"
			for action in conflicts:
				if action != _current_action:
					conflict_text += "- %s\n" % action
			conflict_text += "\n是否覆盖？"
			
			# 创建确认对话框
			var confirm_dlg := AcceptDialog.new()
			confirm_dlg.title = "按键冲突"
			confirm_dlg.add_child(Label.new())
			confirm_dlg.get_child(0).text = conflict_text
			confirm_dlg.ok_button_text = "覆盖"
			confirm_dlg.add_cancel_button("取消")
			add_child(confirm_dlg)
			
			# 连接信号
			var captured_action = _current_action
			confirm_dlg.confirmed.connect(func():
				confirm_dlg.queue_free()
				hide()
				key_captured.emit(captured_event, captured_action)
			)
			confirm_dlg.canceled.connect(func():
				confirm_dlg.queue_free()
				open_for(_current_action, _label.text.split("\n")[0].replace("正在设置：", ""))
			)
			confirm_dlg.popup_centered()
		else:
			hide()
			key_captured.emit(captured_event, _current_action)

# ──────────────────────────────────────────────
# 内部辅助
# ──────────────────────────────────────────────

func _check_conflicts(event: InputEvent) -> Array:
	var km := _get_keybinding_module()
	if km and km.has_method("check_conflict"):
		return km.check_conflict(event)
	return []

static func _get_keybinding_module() -> KeybindingModule:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var ss := tree.root.get_node_or_null("SaveSystem")
	if ss and ss.has_method("get_module"):
		return ss.get_module("keybindings") as KeybindingModule
	return null

# ──────────────────────────────────────────────
# 内部
# ──────────────────────────────────────────────

func _on_cancelled() -> void:
	if not _waiting:
		return
	_waiting = false
	hide()
	capture_cancelled.emit(_current_action)
