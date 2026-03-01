## 属性系统和修饰符演示 - Modifier系统基础教程
##
extends PackDemo
class_name AttributeSystemTutorial

var attr_system: AttributeSystem = null

func _ready() -> void:
	super._ready()
	_demo_basic_attributes()
	_demo_modifiers()
	_demo_temporary_modifiers()

func _demo_basic_attributes() -> void:
	print("\n=== 属性系统 Demo ===\n")
	
	attr_system = AttributeSystem.new()
	add_child(attr_system)
	
	# 设置基础属性
	attr_system.set_base_value("strength", 10)
	attr_system.set_base_value("intelligence", 8)
	attr_system.set_base_value("health", 100)
	
	print("基础属性设置：")
	print("  力量: %f" % attr_system.get_value("strength"))
	print("  智力: %f" % attr_system.get_value("intelligence"))
	print("  生命值: %f" % attr_system.get_value("health"))

func _demo_modifiers() -> void:
	print("\n=== 修饰符系统 Demo ===\n")
	
	# 创建修饰符 - 加成
	var bonus = AttributeSystem.ModifierData.new(5, AttributeSystem.ModifierData.Type.ADDITIVE, "等级提升")
	attr_system.add_modifier("strength", bonus)
	print("添加 +5 力量修饰符后: %f" % attr_system.get_value("strength"))
	
	# 百分比修饰符
	var percent = AttributeSystem.ModifierData.new(0.2, AttributeSystem.ModifierData.Type.PERCENTAGE, "装备加成")
	attr_system.add_modifier("strength", percent)
	print("添加 +20%% 力量修饰符后: %f" % attr_system.get_value("strength"))
	
	# 乘数修饰符
	var multi = AttributeSystem.ModifierData.new(1.5, AttributeSystem.ModifierData.Type.MULTIPLY, "天赋加强")
	attr_system.add_modifier("strength", multi)
	print("添加 ×1.5 力量修饰符后: %f" % attr_system.get_value("strength"))
	
	print("\n计算过程: ((10 + 5) × (1 + 0.2)) × 1.5 = %.1f" % attr_system.get_value("strength"))

func _demo_temporary_modifiers() -> void:
	print("\n=== 临时修饰符 Demo ===\n")
	
	# 创建临时修饰符（会自动过期）
	var temp = AttributeSystem.ModifierData.new(-2.0, AttributeSystem.ModifierData.Type.ADDITIVE, "诅咒")
	temp.is_temporary = true
	temp.duration = 3.0  # 3秒后自动移除
	
	attr_system.add_modifier("intelligence", temp)
	print("添加临时修饰符（诅咒 -2 智力）")
	print("当前智力: %f" % attr_system.get_value("intelligence"))
	
	# 模拟时间流逝
	await get_tree().create_timer(1.0).timeout
	print("1秒后智力: %f" % attr_system.get_value("intelligence"))
	
	await get_tree().create_timer(2.1).timeout
	print("3.1秒后（诅咒已过期）智力: %f" % attr_system.get_value("intelligence"))

func _process(delta: float) -> void:
	if attr_system and attr_system.is_queued_for_deletion() == false:
		attr_system.process(delta)
