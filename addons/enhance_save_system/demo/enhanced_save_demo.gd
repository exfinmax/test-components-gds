class_name EnhancedSaveDemo
extends Control

## 增强型存档系统演示

@onready var save_system = get_node_or_null("/root/SaveSystem")
@onready var keybinding_ui = $VBoxContainer/KeybindingUI
@onready var save_slot_spinbox = $VBoxContainer/VBoxContainer2/HBoxContainer/SaveSlotSpinBox
@onready var save_button = $VBoxContainer/VBoxContainer2/HBoxContainer/SaveButton
@onready var load_button = $VBoxContainer/VBoxContainer2/HBoxContainer/LoadButton
@onready var auto_save_checkbox = $VBoxContainer/VBoxContainer2/HBoxContainer2/AutoSaveCheckbox
@onready var auto_save_interval = $VBoxContainer/VBoxContainer2/HBoxContainer2/AutoSaveInterval
@onready var screenshot_checkbox = $VBoxContainer/VBoxContainer2/HBoxContainer3/ScreenshotCheckbox
@onready var encryption_checkbox = $VBoxContainer/VBoxContainer2/HBoxContainer4/EncryptionCheckbox
@onready var status_label = $VBoxContainer/StatusLabel

func _ready() -> void:
	# 初始化按键绑定UI
	keybinding_ui.label_map = {
		"move_left": "向左移动",
		"move_right": "向右移动",
		"jump": "跳跃",
		"attack": "攻击",
		"defend": "防御",
	}
	
	# 连接信号
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	auto_save_checkbox.toggled.connect(_on_auto_save_toggled)
	auto_save_interval.value_changed.connect(_on_auto_save_interval_changed)
	screenshot_checkbox.toggled.connect(_on_screenshot_toggled)
	encryption_checkbox.toggled.connect(_on_encryption_toggled)
	
	# 初始化UI状态
	if save_system:
		auto_save_checkbox.button_pressed = save_system.auto_save_enabled
		auto_save_interval.value = save_system.auto_save_interval
		screenshot_checkbox.button_pressed = save_system.save_screenshots_enabled
		encryption_checkbox.button_pressed = save_system.encryption_enabled
		_update_status("系统已初始化")
	else:
		_update_status("错误：未找到SaveSystem")

func _on_save_pressed() -> void:
	if save_system:
		var slot = int(save_slot_spinbox.value)
		var success = save_system.save_slot(slot)
		_update_status("保存到槽位 %d: %s" % [slot, "成功" if success else "失败"])

func _on_load_pressed() -> void:
	if save_system:
		var slot = int(save_slot_spinbox.value)
		var success = save_system.load_slot(slot)
		_update_status("从槽位 %d 加载: %s" % [slot, "成功" if success else "失败"])

func _on_auto_save_toggled(enabled: bool) -> void:
	if save_system:
		save_system.enable_auto_save(enabled)
		_update_status("自动存档已%s" % ("启用" if enabled else "禁用"))

func _on_auto_save_interval_changed(value: float) -> void:
	if save_system:
		save_system.set_auto_save_interval(int(value))
		_update_status("自动存档间隔已设置为 %d 秒" % int(value))

func _on_screenshot_toggled(enabled: bool) -> void:
	if save_system:
		save_system.save_screenshots_enabled = enabled
		_update_status("存档预览图已%s" % ("启用" if enabled else "禁用"))

func _on_encryption_toggled(enabled: bool) -> void:
	if save_system:
		save_system.encryption_enabled = enabled
		_update_status("存档加密已%s" % ("启用" if enabled else "禁用"))

func _update_status(message: String) -> void:
	status_label.text = "状态: %s" % message
