## 基础RPG角色模板 - 包含库存、任务、对话系统
##
extends CharacterBody2D
class_name BasicNPCTemplate

# 核心组件
var inventory: InventoryComponent = null
var quest_mgr: QuestSystem = null
var dialogue_mgr: DialogueSystem = null

# 角色信息
@export var npc_name: String = "NPC"
@export var dialogue_tree_id: String = "default"
@export var quest_id: String = ""

var is_talking: bool = false
var talk_range: float = 100.0

func _ready() -> void:
	_setup_inventory()
	_setup_quests()
	_setup_dialogue()
	print("NPC[%s]初始化完成" % npc_name)

func _setup_inventory() -> void:
	inventory = InventoryComponent.new()
	inventory.set_slot_count(10)
	add_child(inventory)

func _setup_quests() -> void:
	quest_mgr = QuestSystem.new()
	add_child(quest_mgr)
	
	# 添加任务（子类可覆盖此方法来自定义任务）
	_populate_quests()

func _setup_dialogue() -> void:
	dialogue_mgr = DialogueSystem.new()
	add_child(dialogue_mgr)
	
	# 添加对话树（子类可覆盖此方法来自定义对话）
	_populate_dialogue_tree()

func _populate_quests() -> void:
	# 默认实现 - 子类覆盖以添加特定任务
	pass

func _populate_dialogue_tree() -> void:
	# 默认实现 - 子类覆盖以添加特定对话
	var greeting = DialogueSystem.DialogueNode.new("greeting")
	greeting.speaker = npc_name
	greeting.text = "你好！很高兴见到你。"
	greeting.add_option("再见", "goodbye")
	
	var goodbye = DialogueSystem.DialogueNode.new("goodbye")
	goodbye.speaker = npc_name
	goodbye.text = "再见！"
	
	dialogue_mgr.add_node(greeting)
	dialogue_mgr.add_node(goodbye)

func start_dialogue() -> void:
	if not is_talking:
		is_talking = true
		dialogue_mgr.start_dialogue("greeting" if dialogue_mgr.has_node("greeting") else "start")

func end_dialogue() -> void:
	is_talking = false
	dialogue_mgr.end_dialogue()

func get_available_quests() -> Array:
	return quest_mgr.get_available_quests().values()

func trade_item(item_id: String, quantity: int) -> bool:
	return inventory.has_item(item_id)

func _process(delta: float) -> void:
	if is_talking and not dialogue_mgr.is_in_dialogue():
		end_dialogue()

func debug_info() -> String:
	return "NPC: %s | 物品槽位: %d" % [
		npc_name,
		inventory.get_slot_count()
	]
