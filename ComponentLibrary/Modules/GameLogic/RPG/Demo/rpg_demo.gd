extends PackDemo

func _ready():
	pack_name = "RPG"
	super._ready()

func _setup_demo() -> void:
	print("\n========== RPG Demo ==========")

	# AttributeSetComponent 测试
	var attr := AttributeSetComponent.new()
	add_child(attr)
	attr.set_base_attribute(&"health",  100.0)
	attr.set_base_attribute(&"attack",   20.0)
	attr.set_base_attribute(&"defense",   5.0)

	print("  base health=%.0f  attack=%.0f  defense=%.0f" % [
		attr.get_base_attribute(&"health"),
		attr.get_base_attribute(&"attack"),
		attr.get_base_attribute(&"defense")])

	# 添加修饰符
	attr.add_modifier(&"iron_sword",  &"attack",  15.0, AttributeSetComponent.ModType.FLAT)
	attr.add_modifier(&"power_ring",  &"attack",   0.5, AttributeSetComponent.ModType.PERCENT_ADD)
	attr.add_modifier(&"vampiric_shield", &"defense",  2.0, AttributeSetComponent.ModType.MULTIPLY)

	print("  final attack=%.1f (expected (20+15)*1.5=52.5)" % attr.get_attribute(&"attack"))
	print("  final defense=%.1f (expected 5*2=10)"           % attr.get_attribute(&"defense"))

	attr.remove_modifier_source(&"iron_sword")
	print("  after remove iron_sword attack=%.1f (expected 20*1.5=30)" % attr.get_attribute(&"attack"))

	attr.queue_free()
	print("========== RPG Demo End ==========\n")

