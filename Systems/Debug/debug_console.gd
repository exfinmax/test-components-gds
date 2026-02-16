extends Control

@onready var rich_text_label: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/RichTextLabel
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var clear_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ClearButton
@onready var auto_scroll_check: CheckBox = $MarginContainer/VBoxContainer/HBoxContainer/AutoScrollCheck

var max_lines: int = 1000
var current_lines: int = 0
var auto_scroll: bool = true

func _ready() -> void:
	# 连接按钮信号
	clear_button.pressed.connect(_on_clear_pressed)
	auto_scroll_check.toggled.connect(_on_auto_scroll_toggled)
	auto_scroll_check.button_pressed = true
	
	# 添加到调试控制台组
	add_to_group("debug_console")
	
	# 重定向 print 输出
	_setup_print_redirect()
	
	# 添加欢迎消息
	add_message("[color=cyan][DebugConsole] Initialized - Ready to capture logs[/color]")

func _setup_print_redirect() -> void:
	"""设置 print 输出重定向"""
	# Godot 4.x 中我们需要手动捕获输出
	# 我们将通过修改 InputBlocker 和其他脚本来直接调用 add_message
	pass

func add_message(message: String) -> void:
	"""添加消息到控制台"""
	if current_lines >= max_lines:
		# 移除最旧的行
		var text = rich_text_label.text
		var first_newline = text.find("\n")
		if first_newline != -1:
			rich_text_label.text = text.substr(first_newline + 1)
			current_lines -= 1
	
	# 添加时间戳
	var time = Time.get_time_dict_from_system()
	var timestamp = "[%02d:%02d:%02d] " % [time.hour, time.minute, time.second]
	
	rich_text_label.append_text(timestamp + message + "\n")
	current_lines += 1
	
	# 自动滚动到底部
	if auto_scroll:
		await get_tree().process_frame
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

func add_error(message: String) -> void:
	"""添加错误消息"""
	add_message("[color=red][ERROR] " + message + "[/color]")

func add_warning(message: String) -> void:
	"""添加警告消息"""
	add_message("[color=yellow][WARNING] " + message + "[/color]")

func add_info(message: String) -> void:
	"""添加信息消息"""
	add_message("[color=cyan][INFO] " + message + "[/color]")

func add_success(message: String) -> void:
	"""添加成功消息"""
	add_message("[color=green][SUCCESS] " + message + "[/color]")

func _on_clear_pressed() -> void:
	"""清空控制台"""
	rich_text_label.clear()
	current_lines = 0
	add_message("[color=cyan][DebugConsole] Console cleared[/color]")

func _on_auto_scroll_toggled(toggled_on: bool) -> void:
	"""切换自动滚动"""
	auto_scroll = toggled_on
