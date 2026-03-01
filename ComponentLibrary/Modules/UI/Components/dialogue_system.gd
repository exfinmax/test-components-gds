## 对话系统 - 分支对话管理
##
## 特性：
## - 分支对话树
## - 对话选项
## - 对话历史
## - 对话条件和回调
##
## 使用示例：
##   var dialogue = DialogueSystem.new()
##   var node_hello = DialogueNode.new("start")
##   node_hello.text = "Hello there!"
##   node_hello.add_option("Hi!", "response1")
##   dialogue.add_node(node_hello)
##
extends Node
class_name DialogueSystem

## 对话选项
class DialogueOption:
	var text: String = ""
	var next_node_id: String = ""
	var condition: Callable = func(): return true
	var on_select: Callable = func(): pass
	
	func _init(p_text: String = "", p_next: String = "") -> void:
		text = p_text
		next_node_id = p_next

## 对话节点
class DialogueNode:
	var node_id: String = ""
	var text: String = ""
	var speaker: String = ""
	var options: Array[DialogueOption] = []
	var on_enter: Callable = func(): pass
	var on_exit: Callable = func(): pass
	
	func _init(p_id: String = "") -> void:
		node_id = p_id
	
	func add_option(text: String, next_id: String) -> DialogueOption:
		var option = DialogueOption.new(text, next_id)
		options.append(option)
		return option
	
	func get_available_options() -> Array[DialogueOption]:
		var available = []
		for option in options:
			if option.condition.call():
				available.append(option)
		return available

## 所有对话节点
var nodes: Dictionary[String, DialogueNode] = {}

## 当前对话节点
var current_node: DialogueNode = null
var current_node_id: String = ""

## 对话历史
var history: Array[String] = []

## 对话信号
signal dialogue_started(node_id: String)
signal dialogue_node_changed(from_id: String, to_id: String)
signal dialogue_option_selected(option_text: String)
signal dialogue_ended()

func _ready() -> void:
	pass

## 添加对话节点
func add_node(node: DialogueNode) -> void:
	nodes[node.node_id] = node

## 开始对话
func start_dialogue(node_id: String) -> bool:
	if not node_id in nodes:
		push_error("Dialogue node '%s' not found" % node_id)
		return false
	
	current_node = nodes[node_id]
	current_node_id = node_id
	history.append(node_id)
	
	current_node.on_enter.call()
	dialogue_started.emit(node_id)
	
	return true

## 获取当前对话文本
func get_current_text() -> String:
	if current_node:
		return current_node.text
	return ""

## 获取当前说话者
func get_current_speaker() -> String:
	if current_node:
		return current_node.speaker
	return ""

## 获取可用选项
func get_available_options() -> Array[DialogueOption]:
	if current_node:
		return current_node.get_available_options()
	return []

## 选择选项
func select_option(option: DialogueOption) -> bool:
	if not current_node:
		return false
	
	if option not in current_node.options:
		return false
	
	# 检查选项是否可用
	if not option.condition.call():
		return false
	
	# 执行选项回调
	option.on_select.call()
	dialogue_option_selected.emit(option.text)
	
	# 获取下一个节点
	var next_id = option.next_node_id
	
	# 退出当前节点
	current_node.on_exit.call()
	
	# 没有下一个节点表示对话结束
	if next_id.is_empty():
		current_node = null
		current_node_id = ""
		dialogue_ended.emit()
		return true
	
	# 进入下一个节点
	if not next_id in nodes:
		push_error("Next dialogue node '%s' not found" % next_id)
		current_node = null
		current_node_id = ""
		dialogue_ended.emit()
		return false
	
	var prev_id = current_node_id
	current_node = nodes[next_id]
	current_node_id = next_id
	history.append(next_id)
	
	current_node.on_enter.call()
	dialogue_node_changed.emit(prev_id, next_id)
	
	return true

## 跳过对话（快进到结束或下一个分支）
func skip_to_node(node_id: String) -> bool:
	if not node_id in nodes:
		return false
	
	if current_node:
		current_node.on_exit.call()
	
	current_node = nodes[node_id]
	current_node_id = node_id
	history.append(node_id)
	
	current_node.on_enter.call()
	dialogue_node_changed.emit("", node_id)
	
	return true

## 结束对话
func end_dialogue() -> void:
	if current_node:
		current_node.on_exit.call()
	
	current_node = null
	current_node_id = ""
	dialogue_ended.emit()

## 是否在对话中
func is_in_dialogue() -> bool:
	return current_node != null

## 获取对话历史
func get_history() -> Array[String]:
	return history.duplicate()

## 清楚对话历史
func clear_history() -> void:
	history.clear()

## 调试：输出对话树
func debug_dialogue_tree() -> String:
	var output = "=== Dialogue Tree ===\n"
	output += "Current: %s\n" % current_node_id
	output += "Nodes:\n"
	for node_id in nodes:
		var node = nodes[node_id]
		output += "  [%s] %s (%d options)\n" % [
			node_id,
			node.text.substr(0, 20) + "..." if node.text.length() > 20 else node.text,
			node.options.size()
		]
	return output
