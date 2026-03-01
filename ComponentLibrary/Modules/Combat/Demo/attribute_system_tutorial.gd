## AttributeSetComponent 教程 — 演示类型化修饰符的分层计算
##
## 计算顺序: base + FLAT → × (1 + PERCENT_ADD_sum) → × MULTIPLY → CLAMP
##
## [运行后在 Output 面板查看输出]
extends PackDemo
class_name AttributeSetTutorial

func _ready() -> void:
	super._ready()
	await get_tree().process_frame   # 等待一帧避免 _ready 顺序问题
	_demo_basic()
	_demo_layered_modifiers()
	_demo_source_management()
	await _demo_temporary_modifier()

## 1. 基础属性读写
func _demo_basic() -> void:
	print("\n=== 1. 基础属性读写 ===")
	var attrs := AttributeSetComponent.new()
	add_child(attrs)

	attrs.set_base_attribute(&"strength",     10.0)
	attrs.set_base_attribute(&"intelligence",  8.0)
	attrs.set_base_attribute(&"health",      100.0)

	print("  力量:    %.0f" % attrs.get_attribute(&"strength"))
	print("  智力:    %.0f" % attrs.get_attribute(&"intelligence"))
	print("  生命值: %.0f" % attrs.get_attribute(&"health"))

# modify_base_attribute 是 set_base_attribute(v + delta) 的快捷方式
	attrs.modify_base_attribute(&"health", -15.0)
	print("  扣血后: %.0f" % attrs.get_attribute(&"health"))

	attrs.queue_free()

## 2. 分层修饰符（FLAT → PERCENT_ADD → MULTIPLY → CLAMP）
func _demo_layered_modifiers() -> void:
	print("\n=== 2. 分层修饰符计算 ===")
	var attrs := AttributeSetComponent.new()
	add_child(attrs)
	attrs.set_base_attribute(&"strength", 10.0)

# FLAT: 固定值加算
	attrs.add_modifier(&"level_bonus",   &"strength", 5.0,  AttributeSetComponent.ModType.FLAT)
	print("  +5 FLAT    → %.0f  (期望 15)" % attrs.get_attribute(&"strength"))

# PERCENT_ADD: 百分比加算（多个 PERCENT_ADD 叠加后再乘）
	attrs.add_modifier(&"equip_bonus",   &"strength", 0.2,  AttributeSetComponent.ModType.PERCENT_ADD)
	print("  +20%% PADD → %.1f  (期望 18.0)" % attrs.get_attribute(&"strength"))

# MULTIPLY: 独立乘算
	attrs.add_modifier(&"talent_multi",  &"strength", 1.5,  AttributeSetComponent.ModType.MULTIPLY)
	print("  ×1.5 MUL   → %.1f  (期望 27.0)" % attrs.get_attribute(&"strength"))

	print("  公式: (10+5)×(1+0.2)×1.5 = %.1f" % attrs.get_attribute(&"strength"))

# CLAMP_MIN / CLAMP_MAX
	attrs.add_modifier(&"floor_mod",     &"strength", 30.0, AttributeSetComponent.ModType.CLAMP_MIN)
	print("  clamp≥30   → %.1f  (期望 30.0)" % attrs.get_attribute(&"strength"))

	attrs.queue_free()

## 3. source_id 管理（成批移除 Buff）
func _demo_source_management() -> void:
	print("\n=== 3. source_id 管理 ===")
	var attrs := AttributeSetComponent.new()
	add_child(attrs)
	attrs.set_base_attribute(&"attack", 20.0)

# 装备A给 attack 加 FLAT +8
	attrs.add_modifier(&"equipment_A", &"attack", 8.0,  AttributeSetComponent.ModType.FLAT)
# Buff 给 attack 加 PERCENT_ADD +50%
	attrs.add_modifier(&"rage_buff",   &"attack", 0.5,  AttributeSetComponent.ModType.PERCENT_ADD)
	print("  装备A+狂暴 → %.0f  (期望 42)" % attrs.get_attribute(&"attack"))
# (20+8)×(1+0.5) = 42

# 脱下装备A（移除该 source 的所有修饰符）
	attrs.remove_modifier_source(&"equipment_A")
	print("  脱下装备A  → %.0f  (期望 30)" % attrs.get_attribute(&"attack"))
# 20×(1+0.5) = 30

# Buff 结束
	attrs.remove_modifier_source(&"rage_buff")
	print("  狂暴结束   → %.0f  (期望 20)" % attrs.get_attribute(&"attack"))

	attrs.queue_free()

## 4. 模拟临时 Buff（用 Timer 延迟移除）
func _demo_temporary_modifier() -> void:
	print("\n=== 4. 临时修饰符（3 秒后自动移除）===")
	var attrs := AttributeSetComponent.new()
	add_child(attrs)
	attrs.set_base_attribute(&"speed", 200.0)

# 施加减速诅咒（-30%）
	attrs.add_modifier(&"curse_slow", &"speed", -0.3, AttributeSetComponent.ModType.PERCENT_ADD)
	print("  诅咒减速 → %.0f  (期望 140)" % attrs.get_attribute(&"speed"))

	await get_tree().create_timer(3.0).timeout
	attrs.remove_modifier_source(&"curse_slow")
	print("  3s后解除  → %.0f  (期望 200)" % attrs.get_attribute(&"speed"))

	attrs.queue_free()
	print("\n=== 教程结束 ===\n")