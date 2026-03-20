extends Node
## ════════════════════════════════════════════════════════════════
##  EnhancedBalloon 完整演示场景控制脚本
## ════════════════════════════════════════════════════════════════
##
## 演示三个场景：
##   1. 新手教程引导场景 - 展示入场动画、自动推进、快进慢放、历史记录
##   2. 角色对话场景 - 展示头像系统、气泡方向、角色颜色、打字音效
##   3. 分支选择场景 - 展示多选项分支、URL链接、选项动画

@onready var balloon: EnhancedBalloon = $EnhancedBalloon
@onready var main_panel: PanelContainer = $UI/MainPanel
@onready var scene_buttons: VBoxContainer = $UI/MainPanel/VBoxContainer/SceneButtons
@onready var status_label: Label = $UI/MainPanel/VBoxContainer/StatusLabel
@onready var back_button: Button = $UI/MainPanel/VBoxContainer/ButtonRow/BackButton

const SCENE1_PATH := "res://addons/dialogue_manager/modify_test/demo/scene1_tutorial.dialogue"
const SCENE2_PATH := "res://addons/dialogue_manager/modify_test/demo/scene2_characters.dialogue"
const SCENE3_PATH := "res://addons/dialogue_manager/modify_test/demo/scene3_branch.dialogue"

var _current_scene: String = ""
var _dialogue_res: DialogueResource = null

func _ready() -> void:
	_setup_balloon()
	_connect_buttons()
	back_button.pressed.connect(_on_back_button_pressed)
	_set_status("请选择一个演示场景开始体验")


func _setup_balloon() -> void:
	balloon.auto_save_progress = false
	balloon.enable_enter_animation = true
	balloon.enable_exit_animation = true
	#balloon.enter_animation_type = "pop"
	#balloon.exit_animation_type = "scale"
	balloon.animation_duration = 0.3
	balloon.enable_custom_tags = true
	balloon.dialogue_ended.connect(_on_dialogue_ended)


func _connect_buttons() -> void:
	for btn in scene_buttons.get_children():
		if btn is Button:
			btn.pressed.connect(_on_scene_button_pressed.bind(btn))


func _on_scene_button_pressed(btn: Button) -> void:
	var scene_path := ""
	var scene_name := ""
	
	match btn.name:
		"Scene1Button":
			scene_path = SCENE1_PATH
			scene_name = "新手教程"
		"Scene2Button":
			scene_path = SCENE2_PATH
			scene_name = "角色对话"
		"Scene3Button":
			scene_path = SCENE3_PATH
			scene_name = "分支选择"
		_:
			return
	
	_start_scene(scene_path, scene_name)


func _start_scene(path: String, name: String) -> void:
	if not ResourceLoader.exists(path):
		_set_status("错误：找不到对话文件 %s" % path)
		return
	
	_dialogue_res = load(path) as DialogueResource
	if _dialogue_res == null:
		_set_status("错误：无法加载对话资源")
		return
	
	_current_scene = name
	balloon.chapter_name = name
	balloon.start(_dialogue_res, "start", [self])
	
	_set_status("【%s】场景进行中…" % name)
	_show_scene_ui(false)


func _on_dialogue_ended() -> void:
	_set_status("【%s】演示结束。选择其他场景继续体验。" % _current_scene)
	_show_scene_ui(true)


func _on_back_button_pressed() -> void:
	if is_instance_valid(balloon) and balloon.is_inside_tree():
		balloon.hide()
	_show_scene_ui(true)
	_set_status("请选择一个演示场景开始体验")


func _show_scene_ui(show: bool) -> void:
	for btn in scene_buttons.get_children():
		btn.visible = show
	back_button.visible = not show


func _set_status(msg: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = msg
