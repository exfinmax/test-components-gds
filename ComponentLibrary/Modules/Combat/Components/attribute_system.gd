## 属性系统 - 支持修饰符的属性管理
## 
## 特性：
## - 基础属性和衍生属性
## - 支持多种修饰符（固定值、百分比、乘数）
## - 实时属性计算
## - 属性变化信号通知
## 
## 使用示例：
##   var attr = AttributeSystem.new()
##   attr.set_base_value("health", 100)
##   attr.add_modifier("health", ModifierData.new(20, ModifierData.Type.ADDITIVE))
##   print(attr.get_value("health"))  # 输出 120
##
extends Node
class_name AttributeSystem

## 属性数据结构
class AttributeData:
	var base_value: float = 0.0
	var modified_value: float = 0.0
	var modifiers: Array = []
	
	func _init(p_base_value: float = 0.0) -> void:
		base_value = p_base_value
		modified_value = p_base_value

## 修饰符数据结构
class ModifierData:
	enum Type {
		ADDITIVE,        # 固定值加成 (+20)
		PERCENTAGE,      # 百分比加成 (x1.2)
		MULTIPLY,        # 乘数 (x2)
		MIN_CLAMP,       # 最小值
		MAX_CLAMP,       # 最大值
	}
	
	var value: float
	var type: Type
	var source: String = ""  # 修饰符来源（用于调试）
	var duration: float = 0.0  # 持续时间（0表示永久）
	var elapsed: float = 0.0
	
	func _init(p_value: float, p_type: Type = Type.ADDITIVE, p_source: String = "") -> void:
		value = p_value
		type = p_type
		source = p_source
	
	func is_expired() -> bool:
		return duration > 0 and elapsed >= duration
	
	func tick(delta: float) -> void:
		if duration > 0:
			elapsed += delta

## 属性名 -> 属性数据
var attributes: Dictionary[String, AttributeData] = {}

## 修饰符变化信号
signal modifier_added(attr_name: String, modifier: ModifierData)
signal modifier_removed(attr_name: String, modifier: ModifierData)
signal attribute_changed(attr_name: String, old_value: float, new_value: float)

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	# 更新临时修饰符
	for attr_name in attributes:
		var attr = attributes[attr_name]
		var expired_modifiers = []
		
		for modifier in attr.modifiers:
			modifier.tick(delta)
			if modifier.is_expired():
				expired_modifiers.append(modifier)
		
		for modifier in expired_modifiers:
			remove_modifier(attr_name, modifier)

## 初始化属性
func set_base_value(attr_name: String, value: float) -> void:
	if not attr_name in attributes:
		attributes[attr_name] = AttributeData.new(value)
	else:
		attributes[attr_name].base_value = value
	_recalculate(attr_name)

## 获取修改后的属性值
func get_value(attr_name: String) -> float:
	if not attr_name in attributes:
		return 0.0
	return attributes[attr_name].modified_value

## 获取基础属性值
func get_base_value(attr_name: String) -> float:
	if not attr_name in attributes:
		return 0.0
	return attributes[attr_name].base_value

## 添加修饰符
func add_modifier(attr_name: String, modifier: ModifierData) -> void:
	if not attr_name in attributes:
		attributes[attr_name] = AttributeData.new(0.0)
	
	attributes[attr_name].modifiers.append(modifier)
	modifier_added.emit(attr_name, modifier)
	
	# 如果是临时修饰符，启用process
	if modifier.duration > 0:
		set_process(true)
	
	_recalculate(attr_name)

## 移除修饰符
func remove_modifier(attr_name: String, modifier: ModifierData) -> void:
	if not attr_name in attributes:
		return
	
	var modifiers = attributes[attr_name].modifiers
	if modifier in modifiers:
		modifiers.erase(modifier)
		modifier_removed.emit(attr_name, modifier)
		_recalculate(attr_name)

## 清空属性的所有修饰符
func clear_modifiers(attr_name: String) -> void:
	if not attr_name in attributes:
		return
	
	var modifiers = attributes[attr_name].modifiers.duplicate()
	for modifier in modifiers:
		remove_modifier(attr_name, modifier)

## 处理属性变化
func modify_base_value(attr_name: String, delta: float) -> void:
	if not attr_name in attributes:
		return
	
	var old_value = attributes[attr_name].base_value
	attributes[attr_name].base_value += delta
	_recalculate(attr_name)

## 内部：重新计算修改后的属性值
func _recalculate(attr_name: String) -> void:
	if not attr_name in attributes:
		return
	
	var attr = attributes[attr_name]
	var old_value = attr.modified_value
	
	# 按修饰符类型顺序应用
	var result = attr.base_value
	var additive_bonus = 0.0
	var percentage_mult = 1.0
	var final_mult = 1.0
	var min_val = -INF
	var max_val = INF
	
	for modifier in attr.modifiers:
		match modifier.type:
			ModifierData.Type.ADDITIVE:
				additive_bonus += modifier.value
			ModifierData.Type.PERCENTAGE:
				percentage_mult *= modifier.value
			ModifierData.Type.MULTIPLY:
				final_mult *= modifier.value
			ModifierData.Type.MIN_CLAMP:
				min_val = max(min_val, modifier.value)
			ModifierData.Type.MAX_CLAMP:
				max_val = min(max_val, modifier.value)
	
	# 应用修饰符顺序：加成 -> 百分比 -> 乘数 -> 夹紧
	result = (result + additive_bonus) * percentage_mult * final_mult
	result = clamp(result, min_val, max_val)
	
	attr.modified_value = result
	
	if old_value != result:
		attribute_changed.emit(attr_name, old_value, result)

## 获取属性的所有修饰符
func get_modifiers(attr_name: String) -> Array:
	if not attr_name in attributes:
		return []
	return attributes[attr_name].modifiers.duplicate()

## 获取所有属性名称
func get_attribute_names() -> PackedStringArray:
	return attributes.keys()

## 调试：输出属性信息
func debug_attributes() -> String:
	var output = "=== Attributes ===\n"
	for attr_name in attributes:
		var attr = attributes[attr_name]
		output += "%s: %.1f (base: %.1f) [%d modifiers]\n" % [
			attr_name,
			attr.modified_value,
			attr.base_value,
			attr.modifiers.size()
		]
	return output
