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
	get_ok_button().text = "取消"

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
		hide()
		key_captured.emit(captured_event, _current_action)

# ──────────────────────────────────────────────
# 内部
# ──────────────────────────────────────────────

func _on_cancelled() -> void:
	if not _waiting:
		return
	_waiting = false
	hide()
	capture_cancelled.emit(_current_action)
