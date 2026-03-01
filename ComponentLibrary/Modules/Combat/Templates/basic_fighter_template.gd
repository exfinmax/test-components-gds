## 基础战士模板 — 展示 AttributeSetComponent + BuffComponent + AbilityComponent 集成
## 可直接作为 CharacterBody2D 子类使用
##
extends CharacterBody2D
class_name BasicFighterTemplate

# 组件引用
var attrs:       AttributeSetComponent = null
var buffs:       BuffComponent         = null
var status_fx:   StatusEffectComponent = null
var ability_mgr: AbilityComponent      = null
var cooldown:    CooldownComponent     = null

@export var initial_health:  float = 100.0
@export var initial_attack:  float = 15.0
@export var initial_defense: float = 5.0

var is_alive: bool = true

func _ready() -> void:
	_setup_attributes()
	_setup_effects()
	_setup_abilities()
	print("战士[%s]初始化完成 - 生命值: %.0f" % [name, attrs.get_attribute(&"health")])

func _setup_attributes() -> void:
	attrs = AttributeSetComponent.new()
	attrs.name = "AttributeSetComponent"
	add_child(attrs)
	attrs.set_base_attribute(&"health",  initial_health)
	attrs.set_base_attribute(&"attack",  initial_attack)
	attrs.set_base_attribute(&"defense", initial_defense)
	attrs.attribute_changed.connect(_on_attribute_changed)

func _setup_effects() -> void:
	buffs = BuffComponent.new()
	buffs.name = "BuffComponent"
	add_child(buffs)
	status_fx = StatusEffectComponent.new()
	status_fx.name = "StatusEffectComponent"
	add_child(status_fx)
	cooldown = CooldownComponent.new()
	cooldown.name = "CooldownComponent"
	add_child(cooldown)

func _setup_abilities() -> void:
	ability_mgr = AbilityComponent.new()
	ability_mgr.name = "AbilityComponent"
	add_child(ability_mgr)
	ability_mgr.cooldown_duration = 1.0
	ability_mgr.ability_name = "BasicAttack"

func take_damage(damage: float) -> void:
	if not is_alive: return
	attrs.modify_base_attribute(&"health", -damage)
	if attrs.get_attribute(&"health") <= 0.0:
		_on_death()

func heal(amount: float) -> void:
	var max_hp := attrs.get_base_attribute(&"health")
	attrs.modify_base_attribute(&"health", amount)
	if attrs.get_attribute(&"health") > max_hp:
		attrs.set_base_attribute(&"health", max_hp)

## 应用状态效果（燃烧、减速等），通过 StatusEffectComponent
func apply_status(effect_id: StringName, duration: float,
		payload: Dictionary = {}, tick_interval: float = 1.0) -> void:
	status_fx.add_effect(effect_id, duration, payload, tick_interval)

func remove_status(effect_id: StringName) -> void:
	status_fx.remove_effect(effect_id)

func _on_attribute_changed(attr_name: StringName, old_value: float, new_value: float) -> void:
	print("[%s] %s: %.0f → %.0f" % [name, attr_name, old_value, new_value])

func _on_death() -> void:
	is_alive = false
	print("[%s] 已死亡" % name)
	queue_free()

func debug_stats() -> String:
	return "HP: %.0f | ATK: %.0f | DEF: %.0f" % [
		attrs.get_attribute(&"health"),
		attrs.get_attribute(&"attack"),
		attrs.get_attribute(&"defense"),
	]
