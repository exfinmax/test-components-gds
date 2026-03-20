extends Node
## ════════════════════════════════════════════════════════════════════
## 立绘气球测试场景
## ══════════════════════════════════════════════════════════════════════
## 测试四个场景：
##   1. 表情切换测试 - 展示6种表情类型
##   2. 位置切换测试 - 展示左右立绘切换
##   3. 动画效果测试 - 展示入场动画和表情过渡
##   4. 功能演示 - 展示自动推进、历史记录、快进慢放

const DIALOGUE_PATH := "res://addons/dialogue_manager/modify_test/demo/illustration_test.dialogue"

var _current_scene: String = ""
var _dialogue_res: DialogueResource = null

@onready var balloon: IllustratedBalloon = $IllustratedBalloon
@onready var main_panel: PanelContainer = $UI/MainPanel
@onready var scene_buttons: VBoxContainer = $UI/MainPanel/VBoxContainer/SceneButtons
@onready var status_label: Label = $UI/MainPanel/VBoxContainer/StatusLabel
@onready var back_button: Button = $UI/MainPanel/VBoxContainer/ButtonRow/BackButton

func _ready() -> void:
	_setup_balloon()
	_connect_buttons()
	back_button.pressed.connect(_on_back_button_pressed)
	_set_status("请选择一个测试场景开始体验")

func _setup_balloon() -> void:
	balloon.auto_save_progress = false
	balloon.enable_enter_animation = true
	balloon.enable_exit_animation = true
	balloon.animation_duration = 0.3
	balloon.dialogue_ended.connect(_on_dialogue_ended)
	balloon.setup_test_characters()

func _connect_buttons() -> void:
	for btn in scene_buttons.get_children():
		if btn is Button:
			btn.pressed.connect(_on_scene_button_pressed.bind(btn))

func _on_scene_button_pressed(btn: Button) -> void:
	var scene_key := ""
	var scene_name := ""
	
	match btn.name:
		"Scene1Button":
			scene_key = "expression_demo"
			scene_name = "表情切换测试"
		"Scene2Button":
			scene_key = "position_demo"
			scene_name = "位置切换测试"
		"Scene3Button":
			scene_key = "animation_demo"
			scene_name = "动画效果测试"
		"Scene4Button":
			scene_key = "feature_demo"
			scene_name = "功能演示"
		_:
			return
	
	_start_scene(scene_key, scene_name)

func _start_scene(key: String, name: String) -> void:
	if not ResourceLoader.exists(DIALOGUE_PATH):
		_set_status("错误：找不到对话文件")
		return
	
	_dialogue_res = load(DIALOGUE_PATH) as DialogueResource
	if _dialogue_res == null:
		_set_status("错误：无法加载对话资源")
		return
	
	_current_scene = name
	balloon.chapter_name = name
	balloon.start(_dialogue_res, key, [self])
	
	_set_status("【%s】场景进行中..." % name)
	_show_scene_ui(false)
	_setup_illustrations()

func _setup_illustrations() -> void:
	var left_ill = balloon.get_node_or_null("Illustrations/LeftIllustration")
	var right_ill = balloon.get_node_or_null("Illustrations/RightIllustration")
	
	if left_ill:
		var left_lihui = _create_test_lihui("主角", Color(0.3, 0.5, 0.8))
		if left_lihui:
			left_ill.lihui_resource = left_lihui
	
	if right_ill:
		var right_lihui = _create_test_lihui("NPC", Color(0.8, 0.4, 0.5))
		if right_lihui:
			right_ill.lihui_resource = right_lihui

func _create_test_lihui(name: String, base_color: Color) -> Resource:
	var script_res = load("res://simple/lihui.gd")
	if script_res == null:
		return null
	
	var LiHuiClass = script_res
	if LiHuiClass.has_method("create_character"):
		return LiHuiClass.create_character(name, base_color)
	return null

func _on_dialogue_ended() -> void:
	_set_status("【%s】演示结束。选择其他场景继续体验。" % _current_scene)
	_show_scene_ui(true)

func _on_back_button_pressed() -> void:
	if is_instance_valid(balloon) and balloon.is_inside_tree():
		balloon.hide()
	_show_scene_ui(true)
	_set_status("请选择一个测试场景开始体验")

func _show_scene_ui(show: bool) -> void:
	for btn in scene_buttons.get_children():
		btn.visible = show
	back_button.visible = not show

func _set_status(msg: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = msg
