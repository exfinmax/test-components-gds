class_name BalloonModule
extends Node
## ════════════════════════════════════════════════════════════════
## BalloonModule — 气球功能模块基类
## ════════════════════════════════════════════════════════════════
##
## 所有功能模块的基类，继承此类并重写虚方法来实现具体功能。
## 模块作为 BaseBalloon 的子节点挂载，进入场景树时自动注册。
##
## 使用方式：
##   1. 继承 BalloonModule
##   2. 重写 get_module_name() 返回唯一标识
##   3. 重写需要的生命周期虚方法
##   4. 将模块节点挂载到 BaseBalloon 下
## ════════════════════════════════════════════════════════════════

## 是否启用此模块（禁用时跳过所有回调）
@export var is_enabled: bool = true

## 宿主气球引用（弱引用，由 setup 注入）
var _balloon: BaseBalloon

# ════════════════════════════════════════════════════════════════
# 生命周期
# ════════════════════════════════════════════════════════════════

func _enter_tree() -> void:
	# 检查父节点是否为 BaseBalloon，若是则自动注册
	var parent := get_parent()
	if parent is BaseBalloon:
		setup(parent as BaseBalloon)
		parent.register_module(self)

func _exit_tree() -> void:
	# 离开场景树时自动注销
	if is_instance_valid(_balloon):
		_balloon.unregister_module(self)
	_balloon = null

# ════════════════════════════════════════════════════════════════
# 公共 API
# ════════════════════════════════════════════════════════════════

## 注入宿主引用，由 BaseBalloon 调用
func setup(balloon: BaseBalloon) -> void:
	_balloon = balloon

## 返回模块唯一标识，子类必须重写
func get_module_name() -> String:
	return "base_module"

# ════════════════════════════════════════════════════════════════
# 虚方法（子类按需重写）
# ════════════════════════════════════════════════════════════════

## 对话开始时调用
func on_dialogue_started(_resource: DialogueResource, _title: String) -> void:
	pass

## 对话行变化时调用
func on_dialogue_line_changed(_line: DialogueLine) -> void:
	pass

## 对话结束时调用
func on_dialogue_ended() -> void:
	pass

## 输入事件处理，返回 true 表示消费该事件（后续模块不再处理）
func on_input(_event: InputEvent) -> bool:
	return false

## 模块事件处理（事件总线）
func on_module_event(_event_name: String, _data: Dictionary) -> void:
	pass
