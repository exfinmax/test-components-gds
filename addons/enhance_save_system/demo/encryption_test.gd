class_name EncryptionTest
extends Control

## 存档加密解密测试

@onready var save_system = get_node_or_null("/root/SaveSystem")
@onready var encryption_checkbox = $VBoxContainer/HBoxContainer/EncryptionCheckbox
@onready var encryption_key = $VBoxContainer/HBoxContainer2/EncryptionKey
@onready var save_button = $VBoxContainer/HBoxContainer3/SaveButton
@onready var load_button = $VBoxContainer/HBoxContainer3/LoadButton
@onready var test_data = $VBoxContainer/HBoxContainer4/TestData
@onready var status_label = $VBoxContainer/StatusLabel

var test_module = TestModule.new()

func _ready() -> void:
	# 注册测试模块
	if save_system:
		save_system.register_module(test_module)
		# 初始化UI状态
		encryption_checkbox.button_pressed = save_system.encryption_enabled
		encryption_key.text = save_system.encryption_key
		_update_status("系统已初始化")
	else:
		_update_status("错误：未找到SaveSystem")
	
	# 连接信号
	encryption_checkbox.toggled.connect(_on_encryption_toggled)
	encryption_key.text_changed.connect(_on_encryption_key_changed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)

func _on_encryption_toggled(enabled: bool) -> void:
	if save_system:
		save_system.encryption_enabled = enabled
		_update_status("加密已%s" % ("启用" if enabled else "禁用"))

func _on_encryption_key_changed(text: String) -> void:
	if save_system:
		save_system.encryption_key = text
		_update_status("加密密钥已更新")

func _on_save_pressed() -> void:
	if save_system:
		# 更新测试数据
		test_module.test_data = test_data.text
		# 保存到槽位1
		var success = save_system.save_slot(1)
		_update_status("保存到槽位 1: %s" % ("成功" if success else "失败"))

func _on_load_pressed() -> void:
	if save_system:
		# 从槽位1加载
		var success = save_system.load_slot(1)
		if success:
			# 更新UI显示
			test_data.text = test_module.test_data
			_update_status("从槽位 1 加载: 成功")
		else:
			_update_status("从槽位 1 加载: 失败")

func _update_status(message: String) -> void:
	status_label.text = "状态: %s" % message

# 测试模块
class TestModule extends ISaveModule:
	var test_data: String = "测试数据"
	
	func _init() -> void:
		pass
	
	func get_module_key() -> String:
		return "test"
	
	func is_global() -> bool:
		return false
	
	func collect_data() -> Dictionary:
		return {"test_data": test_data}
	
	func apply_data(data: Dictionary) -> void:
		test_data = str(data.get("test_data", "测试数据"))
	
	func get_default_data() -> Dictionary:
		return {"test_data": "测试数据"}
	
	func on_new_game() -> void:
		test_data = "测试数据"
