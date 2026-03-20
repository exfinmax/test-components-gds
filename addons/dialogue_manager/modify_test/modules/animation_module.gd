class_name AnimationModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## AnimationModule — 动画模块
## ════════════════════════════════════════════════════════════════
##
## 持有 BalloonAnimator 实例，管理气球入场/出场动画。
## 以及响应选项的逐项淡入动画。
## ════════════════════════════════════════════════════════════════

@export_group("动画设置")
## 是否启用入场动画
@export var enable_enter_animation: bool = true
## 是否启用出场动画
@export var enable_exit_animation: bool = true
## 入场动画类型
@export_enum("scale","fade","pop","slide_up","slide_down","none") var enter_animation_type: String = "scale"
## 出场动画类型
@export_enum("scale","fade","pop","slide_up","slide_down","none") var exit_animation_type: String = "scale"
## 动画持续时间（秒）
@export_range(0.1, 1.0, 0.05) var animation_duration: float = 0.25
## 响应选项动画延迟间隔（秒）
@export_range(0.0, 0.2, 0.01) var response_animation_delay: float = 0.05

## 气球 Control 节点引用（由场景配置）
var balloon_control: Control

## 响应菜单节点引用（由场景配置）
var responses_menu: DialogueResponsesMenu

# ════════════════════════════════════════════════════════════════
# 内部状态
# ════════════════════════════════════════════════════════════════

var _animator: BalloonAnimator

# ════════════════════════════════════════════════════════════════
# 生命周期
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	_animator = BalloonAnimator.new()

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "animation"

func on_dialogue_started(_resource: DialogueResource, _title: String) -> void:
	if not is_instance_valid(balloon_control):
		return
	
	if enable_enter_animation:
		var config := _make_config(enter_animation_type)
		_animator.create_show_animation([balloon_control], config)
	else:
		balloon_control.show()

func on_dialogue_line_changed(line: DialogueLine) -> void:
	# 响应选项逐项淡入
	if line.responses.size() > 0 and is_instance_valid(responses_menu):
		_play_responses_animation()

func on_dialogue_ended() -> void:
	if not is_instance_valid(balloon_control):
		return
	
	if enable_exit_animation:
		var config := _make_config(exit_animation_type)
		_animator.create_hide_animation([balloon_control], config)
	else:
		balloon_control.hide()

# ════════════════════════════════════════════════════════════════
# 内部方法
# ════════════════════════════════════════════════════════════════

func _play_responses_animation() -> void:
	if not is_instance_valid(_animator) or not is_instance_valid(responses_menu):
		return
	
	var items: Array = []
	for child in responses_menu.get_children():
		if child.visible:
			items.append(child)
	
	if items.is_empty():
		return
	
	var config := BalloonAnimator.AnimConfig.new()
	config.anim_type = BalloonAnimator.AnimType.FADE
	config.duration = animation_duration * 0.8
	config.delay = response_animation_delay
	
	_animator.create_show_animation(items, config)

func _make_config(anim_name: String) -> BalloonAnimator.AnimConfig:
	var config := BalloonAnimator.AnimConfig.new()
	config.anim_type = _get_anim_type(anim_name)
	config.duration = animation_duration
	return config

func _get_anim_type(anim_name: String) -> int:
	match anim_name.to_lower():
		"scale":   return BalloonAnimator.AnimType.SCALE
		"fade":    return BalloonAnimator.AnimType.FADE
		"pop":     return BalloonAnimator.AnimType.POP
		"slide_up":   return BalloonAnimator.AnimType.SLIDE_UP
		"slide_down": return BalloonAnimator.AnimType.SLIDE_DOWN
		_:         return BalloonAnimator.AnimType.NONE
