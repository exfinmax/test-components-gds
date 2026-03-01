## 高级战斗系统Demo - 展示属性、能力、效果的完整集成
##
extends PackDemo
class_name CombatAdvancedDemo

@onready var player = $Player
@onready var enemy = $Enemy

var player_combat_mgr: Node = null
var enemy_combat_mgr: Node = null

func _ready() -> void:
	super._ready()
	_setup_player()
	_setup_enemy()
	_setup_ui()

func _setup_player() -> void:
	# 创建玩家战斗系统
	player_combat_mgr = Node.new()
	player_combat_mgr.name = "CombatManager"
	player.add_child(player_combat_mgr)
	
	# 添加属性系统
	var attr = AttributeSystem.new()
	attr.name = "AttributeSystem"
	player_combat_mgr.add_child(attr)
	attr.set_base_value("health", 100)
	attr.set_base_value("stamina", 100)
	attr.set_base_value("attack", 15)
	attr.set_base_value("defense", 5)
	
	# 添加效果管理器
	var effects = EffectManager.new()
	effects.name = "EffectManager"
	player_combat_mgr.add_child(effects)
	
	# 添加冷却系统
	var cooldown = CooldownComponent.new()
	cooldown.name = "CooldownComponent"
	player_combat_mgr.add_child(cooldown)
	
	# 连接信号
	attr.attribute_changed.connect(_on_attribute_changed.bindv([player.name]))
	effects.effect_applied.connect(_on_effect_applied.bindv([player.name]))

func _setup_enemy() -> void:
	# 创建敌人战斗系统（与玩家类似）
	enemy_combat_mgr = Node.new()
	enemy_combat_mgr.name = "CombatManager"
	enemy.add_child(enemy_combat_mgr)
	
	var attr = AttributeSystem.new()
	attr.name = "AttributeSystem"
	enemy_combat_mgr.add_child(attr)
	attr.set_base_value("health", 80)
	attr.set_base_value("attack", 12)
	attr.set_base_value("defense", 3)

func _setup_ui() -> void:
	# 创建UI显示战斗信息
	var ui = Control.new()
	ui.name = "CombatUI"
	add_child(ui)

func _process(delta: float) -> void:
	# 演示：按空格进行一次攻击
	if Input.is_action_just_pressed("ui_accept"):
		_perform_attack()
	
	# 演示：按E应用燃烧效果
	if Input.is_action_just_pressed("ui_down"):
		_apply_burn_effect()

func _perform_attack() -> void:
	var player_attr = player_combat_mgr.get_node("AttributeSystem") as AttributeSystem
	var enemy_attr = enemy_combat_mgr.get_node("AttributeSystem") as AttributeSystem
	
	# 检查冷却
	var cooldown = player_combat_mgr.get_node("CooldownComponent") as CooldownComponent
	if cooldown.is_on_cooldown("attack"):
		print("攻击冷却中...")
		return
	
	# 计算伤害
	var player_attack = player_attr.get_value("attack")
	var enemy_defense = enemy_attr.get_value("defense")
	var damage = int(player_attack - enemy_defense * 0.5)
	damage = max(1, damage)
	
	# 应用伤害
	enemy_attr.modify_base_value("health", -damage)
	print("玩家造成 %d 伤害！敌人剩余血量: %.0f" % [
		damage,
		enemy_attr.get_value("health")
	])
	
	# 启动冷却
	cooldown.start_cooldown("attack", 1.0)

func _apply_burn_effect() -> void:
	var effects = player_combat_mgr.get_node("EffectManager") as EffectManager
	
	# 创建燃烧效果
	var burn = EffectManager.EffectData.new()
	burn.effect_name = "Burn"
	burn.duration = 3.0
	burn.tick_interval = 0.5
	burn.on_tick = func(_delta):
		var attr = player_combat_mgr.get_node("AttributeSystem") as AttributeSystem
		attr.modify_base_value("health", -5)
		print("燃烧造成伤害！")
	
	effects.apply_effect(burn)
	print("应用燃烧效果！")

func _on_attribute_changed(attr_name: String, old_value: float, new_value: float, owner_name: String) -> void:
	print("[%s] %s: %.0f -> %.0f" % [owner_name, attr_name, old_value, new_value])

func _on_effect_applied(effect: EffectManager.EffectData, owner_name: String) -> void:
	print("[%s] 应用效果: %s" % [owner_name, effect.effect_name])
