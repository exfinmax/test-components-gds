## RPG系统集成Demo - 展示库存、任务、对话系统
##
extends PackDemo
class_name RPGSystemsDemo

@onready var player = $Player

var inventory: InventoryComponent = null
var quest_system: QuestSystem = null
var dialogue_system: DialogueSystem = null

func _ready() -> void:
	super._ready()
	_setup_systems()
	_populate_inventory()
	_populate_quests()
	_populate_dialogues()
	_print_instructions()

func _setup_systems() -> void:
	# 创建库存系统
	inventory = InventoryComponent.new()
	inventory.set_slot_count(20)
	add_child(inventory)
	
	# 创建任务系统
	quest_system = QuestSystem.new()
	add_child(quest_system)
	
	# 创建对话系统
	dialogue_system = DialogueSystem.new()
	add_child(dialogue_system)

func _populate_inventory() -> void:
	# 添加初始物品
	var sword = InventoryComponent.ItemData.new("sword_001", "铁剑", 1)
	sword.max_stack = 1
	sword.item_type = "weapon"
	sword.description = "一把普通的铁剑"
	inventory.add_item(sword)
	
	var potion = InventoryComponent.ItemData.new("potion_001", "生命药水", 5)
	potion.max_stack = 10
	potion.item_type = "consumable"
	potion.description = "恢复50点生命值"
	inventory.add_item(potion)
	
	var gold = InventoryComponent.ItemData.new("gold", "金币", 100)
	gold.max_stack = 999
	gold.item_type = "misc"
	inventory.add_item(gold)
	
	print("库存系统初始化完成")
	print(inventory.debug_inventory())

func _populate_quests() -> void:
	# 创建任务1
	var quest1 = QuestSystem.QuestData.new("quest_001", "击败哥布林", "击败营地中的5个哥布林")
	quest1.is_main_quest = true
	quest1.level_requirement = 1
	quest1.add_objective("击败哥布林", 5)
	quest1.reward.gold = 100
	quest1.reward.experience = 200
	quest_system.add_available_quest(quest1)
	
	# 创建任务2
	var quest2 = QuestSystem.QuestData.new("quest_002", "收集药草", "收集10株魔力药草")
	quest2.level_requirement = 2
	quest2.add_objective("收集魔力药草", 10)
	quest2.reward.gold = 150
	quest2.reward.experience = 300
	quest_system.add_available_quest(quest2)
	
	print("可用任务已添加")

func _populate_dialogues() -> void:
	# 创建一个简单的对话树
	var start_node = DialogueSystem.DialogueNode.new("start")
	start_node.speaker = "村长"
	start_node.text = "欢迎冒险者！我们的村庄需要帮助。"
	
	var opt1 = start_node.add_option("我想了解更多", "explain")
	var opt2 = start_node.add_option("我想现在接受任务", "quest")
	var opt3 = start_node.add_option("我先走了", "end")
	
	dialogue_system.add_node(start_node)
	
	# 解释节点
	var explain = DialogueSystem.DialogueNode.new("explain")
	explain.speaker = "村长"
	explain.text = "哥布林袭击了我们的农场。我们需要勇敢的冒险者去解决这个问题。"
	explain.add_option("好的，我接受这个任务", "quest")
	explain.add_option("再见", "end")
	
	dialogue_system.add_node(explain)
	
	# 任务节点
	var quest_node = DialogueSystem.DialogueNode.new("quest")
	quest_node.speaker = "村长"
	quest_node.text = "谢谢你！这是你的奖励"
	quest_node.on_select = func():
		quest_system.accept_quest("quest_001")
		print("已接受任务：击败哥布林")
	quest_node.add_option("了解了", "end")
	
	dialogue_system.add_node(quest_node)
	
	# 结束节点
	var end = DialogueSystem.DialogueNode.new("end")
	end.speaker = "村长"
	end.text = "再见！"
	
	dialogue_system.add_node(end)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_1"):
		print("\n=== 库存系统 ===")
		print(inventory.debug_inventory())
	
	if Input.is_action_just_pressed("ui_2"):
		print("\n=== 任务系统 ===")
		if quest_system.get_available_quests().size() > 0:
			var first_quest_id = quest_system.available_quests.keys()[0]
			if quest_system.accept_quest(first_quest_id):
				print("已接受任务！")
				print(quest_system.debug_quests())
	
	if Input.is_action_just_pressed("ui_3"):
		print("\n=== 对话系统 ===")
		if not dialogue_system.is_in_dialogue():
			dialogue_system.start_dialogue("start")
			_print_dialogue()
	
	if Input.is_action_just_pressed("ui_select"):
		if dialogue_system.is_in_dialogue():
			var options = dialogue_system.get_available_options()
			if options.size() > 0:
				dialogue_system.select_option(options[0])
				if dialogue_system.is_in_dialogue():
					_print_dialogue()

func _print_dialogue() -> void:
	print("【%s】：%s" % [
		dialogue_system.get_current_speaker(),
		dialogue_system.get_current_text()
	])
	var options = dialogue_system.get_available_options()
	for i in range(options.size()):
		print("  %d) %s" % [i + 1, options[i].text])

func _print_instructions() -> void:
	print("\n=== 控制说明 ===")
	print("1 键：显示库存")
	print("2 键：接受任务")
	print("3 键：开始对话")
	print("Enter：选择对话选项")
	print("==================\n")
