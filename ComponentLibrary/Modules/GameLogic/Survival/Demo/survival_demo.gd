extends PackDemo

func _ready():
	pack_name = "Survival"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Survival Demo ==========")
	var se := StatusEffectComponent.new()
	add_child(se)

	se.effect_activated.connect(func(id, _p): print("  效果生效: %s" % id))
	se.effect_expired.connect(func(id): print("  效果过期: %s" % id))
	se.effect_ticked.connect(func(id, _p, _s): print("  tick: %s" % id))

	# 燃烧状态，持续 3 秒，每转一次触发一次
	se.add_effect(&"burn",  3.0, {"damage": 5.0})
	se.add_effect(&"slow",  2.0, {"factor": 0.5})
	se.add_effect(&"stun",  1.0, {})

	print("  has burn=%s  has slow=%s  has stun=%s" % [
		se.has_effect(&"burn"), se.has_effect(&"slow"), se.has_effect(&"stun")])
	print("  stacks burn=" + str(se.get_effect_stacks(&"burn")))

	se.remove_effect(&"stun")
	print("  after remove stun: has_stun=%s" % se.has_effect(&"stun"))

	se.clear_effects()
	print("  after clear_effects: has_burn=%s" % se.has_effect(&"burn"))

	se.queue_free()
	print("========== Survival Demo End ==========\n")
