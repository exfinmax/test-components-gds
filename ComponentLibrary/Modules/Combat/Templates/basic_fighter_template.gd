## 基础战士模板 - 展示如何集成属性、能力、效果系统
## 作为一个可直接使用的CharacterBody2D角色
##
extends CharacterBody2D
class_name BasicFighterTemplate

# 组件引用
var attribute_system: AttributeSystem = null
var ability_mgr: AbilityComponent = null
var effect_mgr: EffectManager = null
var cooldown_mgr: CooldownComponent = null

@export var initial_health: float = 100.0
@export var initial_attack: float = 15.0
@export var initial_defense: float = 5.0

var is_alive: bool = true

func _ready() -> void:
	_setup_attributes()
	_setup_abilities()
	_setup_effects()
	print("战士[%s]初始化完成 - 生命值: %.0f" % [name, attribute_system.get_value("health")])

func _setup_attributes() -> void:
	# 创建属性系统
	attribute_system = AttributeSystem.new()
	add_child(attribute_system)
	
	# 初始化属性
	attribute_system.set_base_value("health", initial_health)
	attribute_system.set_base_value("attack", initial_attack)
	attribute_system.set_base_value("defense", initial_defense)
	
	# 监听生命值变化
	attribute_system.attribute_changed.connect(_on_health_changed)

func _setup_abilities() -> void:
	ability_mgr = AbilityComponent.new()
	add_child(ability_mgr)
	
	# 配置能力
	ability_mgr.cooldown_duration = 1.0
	ability_mgr.ability_name = "BasicAttack"

func _setup_effects() -> void:
	effect_mgr = EffectManager.new()
	add_child(effect_mgr)
	
	cooldown_mgr = CooldownComponent.new()
	add_child(cooldown_mgr)

func take_damage(damage: float) -> void:
	if not is_alive:
		return
	
	var current_health = attribute_system.get_value("health")
	attribute_system.modify_base_value("health", -damage)
	
	if current_health <= 0:
		_on_death()

func heal(amount: float) -> void:
	var max_health = attribute_system.get_base_value("health")
	attribute_system.modify_base_value("health", amount)
	
	var current = attribute_system.get_value("health")
	if current > max_health:
		attribute_system.set_base_value("health", max_health)

func apply_buff(buff_name: String, duration: float, effect: Callable) -> void:
	var effect_data = EffectManager.EffectData.new()
	effect_data.effect_name = buff_name
	effect_data.duration = duration
	effect_data.on_tick = effect
	effect_mgr.apply_effect(effect_data)

func apply_debuff(debuff_name: String, duration: float, effect: Callable) -> void:
	apply_buff(debuff_name, duration, effect)

func _on_health_changed(attr_name: String, old_value: float, new_value: float) -> void:
	if attr_name == "health":
		print("[%s] 生命值变化: %.0f -> %.0f" % [name, old_value, new_value])

func _on_death() -> void:
	is_alive = false
	print("[%s] 已死亡" % name)
	queue_free()

func _process(delta: float) -> void:
	if effect_mgr:
		effect_mgr.process(delta)
	if cooldown_mgr:
		cooldown_mgr.process(delta)

func debug_stats() -> String:
	return "生命值: %.0f | 攻击: %.0f | 防御: %.0f" % [
		attribute_system.get_value("health"),
		attribute_system.get_value("attack"),
		attribute_system.get_value("defense")
	]
