## 能力系统（GAS风格）- 可扩展的能力框架
## 
## 特性：
## - 能力的激活、执行、结束流程
## - 能力冷却管理
## - 能力成本（消耗）
## - 能力标签系统
## - 能力预检查（开始前验证）
## 
## 使用示例：
##   var ability = AbilityComponent.new()
##   ability.ability_name = "Dash"
##   ability.cooldown_duration = 2.0
##   ability.cost = {"stamina": 20}
##   if ability.can_activate():
##       ability.activate(owner)
##
extends ComponentBase
class_name AbilityComponent

## 能力数据
class AbilityData:
	var name: String = ""
	var description: String = ""
	var cooldown: float = 0.0
	var cost: Dictionary = {}  # 资源消耗 {"stamina": 20}
	var tags: PackedStringArray = []
	var enabled: bool = true
	
	var current_cooldown: float = 0.0
	var is_active: bool = false

## 能力名称
@export var ability_name: String = "Ability"

## 能力描述
@export var ability_description: String = ""

## 冷却时间（秒）
@export var cooldown_duration: float = 1.0

## 能力消耗 格式: {"resource_name": amount}
@export var cost: Dictionary = {}

## 能力标签（用于交互和响应）
@export var tags: PackedStringArray = []

## 是否启用此能力
@export var enabled: bool = true

## 能力被激活信号
signal ability_activated(ability: AbilityComponent)

## 能力执行信号
signal ability_executed(ability: AbilityComponent)

## 能力结束信号
signal ability_ended(ability: AbilityComponent)

## 能力冷却完成信号
signal ability_cooldown_finished(ability: AbilityComponent)

## 当前冷却剩余时间
var current_cooldown: float = 0.0

## 能力是否正在激活
var is_active: bool = false

## 能力持续时间（如果需要）
var duration: float = 0.0
var elapsed_duration: float = 0.0

func _ready() -> void:
	super._ready()

func _process_component(delta: float) -> void:
	# 更新冷却
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown <= 0:
			current_cooldown = 0
			ability_cooldown_finished.emit(self)
	
	# 更新持续时间
	if is_active and duration > 0:
		elapsed_duration += delta
		if elapsed_duration >= duration:
			end_ability()

## 检查能力是否可以激活
func can_activate() -> bool:
	if not enabled:
		return false
	
	# 检查冷却
	if current_cooldown > 0:
		return false
	
	# 检查成本（如果父节点有属性集组件）
	if has_node("../AttributeSetComponent"):
		var attrs := get_node("../AttributeSetComponent") as AttributeSetComponent
		if attrs:
			for resource_name in cost:
				if attrs.get_attribute(resource_name) < cost[resource_name]:
					return false
	
	return true

## 激活能力
func activate(target: Node = null) -> bool:
	if not can_activate():
		return false
	
	# 消耗资源
	if has_node("../AttributeSetComponent"):
		var attrs := get_node("../AttributeSetComponent") as AttributeSetComponent
		if attrs:
			for resource_name in cost:
				attrs.modify_base_attribute(resource_name, -cost[resource_name])
	
	is_active = true
	elapsed_duration = 0.0
	
	ability_activated.emit(self)
	
	# 处理能力执行逻辑
	_on_ability_activate(target)
	
	ability_executed.emit(self)
	
	# 启动冷却
	current_cooldown = cooldown_duration
	
	return true

## 结束能力
func end_ability() -> void:
	if not is_active:
		return
	
	is_active = false
	_on_ability_end()
	
	ability_ended.emit(self)

## 虚拟方法：能力激活时调用（子类覆盖）
func _on_ability_activate(target: Node = null) -> void:
	# 子类实现具体逻辑
	pass

## 虚拟方法：能力结束时调用（子类覆盖）
func _on_ability_end() -> void:
	# 子类实现具体逻辑
	pass

## 获取冷却百分比 (0.0 - 1.0)
func get_cooldown_percent() -> float:
	if cooldown_duration == 0:
		return 1.0
	return 1.0 - (current_cooldown / cooldown_duration)

## 检查是否有指定标签
func has_tag(tag: String) -> bool:
	return tag in tags

## 添加标签
func add_tag(tag: String) -> void:
	if not tag in tags:
		tags.append(tag)

## 移除标签
func remove_tag(tag: String) -> void:
	tags.erase(tag)

## 获取冷却剩余时间
func get_cooldown_remaining() -> float:
	return current_cooldown

## 强制重置冷却
func reset_cooldown() -> void:
	current_cooldown = 0
	ability_cooldown_finished.emit(self)

## 强制设置冷却
func set_cooldown(cooldown: float) -> void:
	current_cooldown = max(0, cooldown)
