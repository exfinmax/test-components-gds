## 高级战斗系统 Demo — 展示 AttributeSetComponent + BuffComponent + CooldownComponent 集成
## 按键说明（调试模式运行）：
##   [Enter]    向敌人发起一次攻击（带冷却）
##   [S/Down]   对自己施加燃烧状态效果
##   [W/Up]     给自己添加攻击强化 Buff
extends PackDemo
class_name CombatAdvancedDemo

## 玩家战斗节点
var player_attrs:    AttributeSetComponent
var player_cooldown: CooldownComponent
var player_status:   StatusEffectComponent
var player_buffs:    BuffComponent

## 敌人战斗节点
var enemy_attrs: AttributeSetComponent

func _ready() -> void:
	super._ready()
	_setup_player()
	_setup_enemy()
	_print_instructions()

func _setup_player() -> void:
	player_attrs = AttributeSetComponent.new()
	player_attrs.name = "Attrs"
	add_child(player_attrs)
	player_attrs.set_base_attribute(&"hp",      100.0)
	player_attrs.set_base_attribute(&"mp",       50.0)
	player_attrs.set_base_attribute(&"attack",   20.0)
	player_attrs.set_base_attribute(&"defense",   5.0)
	player_attrs.attribute_changed.connect(
		func(n, o, v): print("[玩家] %s: %.0f → %.0f" % [n, o, v]))

	player_cooldown = CooldownComponent.new()
	add_child(player_cooldown)

	player_status = StatusEffectComponent.new()
	add_child(player_status)
	player_status.effect_ticked.connect(_on_status_ticked)
	player_status.effect_expired.connect(func(id): print("[玩家] 状态结束: %s" % id))

	player_buffs = BuffComponent.new()
	add_child(player_buffs)

func _setup_enemy() -> void:
	enemy_attrs = AttributeSetComponent.new()
	enemy_attrs.name = "EnemyAttrs"
	add_child(enemy_attrs)
	enemy_attrs.set_base_attribute(&"hp",     80.0)
	enemy_attrs.set_base_attribute(&"defense", 3.0)
	enemy_attrs.attribute_changed.connect(
		func(n, o, v): print("[敌人] %s: %.0f → %.0f" % [n, o, v]))

func _process(delta: float) -> void:
	# 推进状态效果 tick（StatusEffectComponent 依赖 _process 驱动）
	player_status.tick(delta)

	if Input.is_action_just_pressed("ui_accept"):
		_perform_attack()
	if Input.is_action_just_pressed("ui_down"):
		_apply_burn()
	if Input.is_action_just_pressed("ui_up"):
		_apply_attack_buff()

func _perform_attack() -> void:
	if player_cooldown.is_on_cooldown(&"attack"):
		print("[攻击] 冷却中，剩余 %.1fs" % player_cooldown.get_remaining(&"attack"))
		return

	var atk := player_attrs.get_attribute(&"attack")
	var def := enemy_attrs.get_attribute(&"defense")
	var dmg := maxf(1.0, atk - def * 0.5)
	enemy_attrs.modify_base_attribute(&"hp", -dmg)
	print("[攻击] 造成 %.0f 伤害！敌人剩余 HP: %.0f" % [dmg, enemy_attrs.get_attribute(&"hp")])
	player_cooldown.start_cooldown(&"attack", 1.0)

func _apply_burn() -> void:
	# 使用 StatusEffectComponent：数据驱动，在 on_ticked 信号里处理效果
	player_status.add_effect(&"burn", 3.0, {"dmg_per_tick": 5.0}, 0.5)
	print("[状态] 施加燃烧效果（3s，每0.5s触发）")

func _apply_attack_buff() -> void:
	# 使用 AttributeSetComponent 修饰符：+30% 攻击，来源 "buff_rage"
	if player_attrs.has_modifier_source(&"buff_rage"):
		player_attrs.remove_modifier_source(&"buff_rage")
		print("[Buff] 移除狂暴（攻击恢复 %.0f）" % player_attrs.get_attribute(&"attack"))
	else:
		player_attrs.add_modifier(&"buff_rage", &"attack", 0.3, AttributeSetComponent.ModType.PERCENT_ADD)
		print("[Buff] 施加狂暴+30%%攻击（当前 %.0f）" % player_attrs.get_attribute(&"attack"))

func _on_status_ticked(effect_id: StringName, payload: Dictionary, stacks: int) -> void:
	if effect_id == &"burn":
		var dmg := float(payload.get("dmg_per_tick", 0.0)) * stacks
		player_attrs.modify_base_attribute(&"hp", -dmg)
		print("[燃烧] 造成 %.0f 伤害，剩余 HP: %.0f" % [dmg, player_attrs.get_attribute(&"hp")])

func _print_instructions() -> void:
	print("\n── CombatAdvancedDemo ──")
	print("[Enter]  攻击（1s 冷却）")
	print("[Down]   对自己施加燃烧")
	print("[Up]     切换狂暴 Buff (+30%% 攻击)")
	print("─────────────────────────\n")

