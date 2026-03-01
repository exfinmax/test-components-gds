## Combat 模块演示 — 整合 Health/Attack/Buff/Status/Knockback/Cooldown/Ability 组件
extends PackDemo


func _setup_demo() -> void:
	pack_name = "Combat"
	print("\n========== Combat Module Demo ==========")
	_demo_health_attack()
	_demo_buff_system()
	_demo_cooldown()
	_demo_knockback()
	print("========== Combat Demo End ==========\n")


func _demo_health_attack() -> void:
	print("\n--- Health & Attack ---")
	var hp := HealthComponent.new()
	add_child(hp)
	hp.max_health = 100.0
	hp.current_health = 100.0
	hp.died.connect(func(): print("  Entity died!"))
	hp.health_changed.connect(func(old, nw): print("  HP: %.0f -> %.0f" % [old, nw]))

	# Attack
	var atk := AttackComponent.new()
	add_child(atk)
	atk.damage = 25.0
	atk.knockback_force = 0.0   # no knockback for this test

	# Simulate 3 hits
	for i in 3:
		var dmg = atk.get_damage()
		hp.take_damage(dmg)
	print("  After 3 hits HP: %.0f" % hp.health)
	hp.queue_free()
	atk.queue_free()


func _demo_buff_system() -> void:
	print("\n--- Buff System ---")
	var buffs := BuffComponent.new()
	add_child(buffs)
	# BuffComponent depends on an AttributeSetComponent sibling
	var attrs := AttributeSetComponent.new()
	add_child(attrs)
	attrs.set_base_attribute(&"attack", 20.0)

	# Create a simple buff
	var buff := BuffEffect.new()
	buff.buff_id     = &"strength"
	buff.target_attr = &"attack"
	buff.flat_bonus  = 10.0
	buff.duration    = 5.0

	buffs.apply_buff(buff)
	print("  Buff applied. Buff count: %d" % buffs.get_buff_count())
	buffs.remove_buff(&"strength")
	print("  After remove:    %d" % buffs.get_buff_count())

	buffs.queue_free()
	attrs.queue_free()


func _demo_cooldown() -> void:
	print("\n--- Cooldown System ---")
	var cd := CooldownComponent.new()
	add_child(cd)

	cd.start_cooldown(&"skill_q", 2.0)
	print("  skill_q on cooldown: %s" % cd.is_on_cooldown(&"skill_q"))
	print("  skill_q remaining:   %.1fs" % cd.get_remaining(&"skill_q"))
	print("  Active tags: %s" % str(cd.get_active_tags()))
	cd.queue_free()


func _demo_knockback() -> void:
	print("\n--- Knockback Component ---")
	var kb = KnockbackComponent.new()
	add_child(kb)

	# CURVE mode (default)
	kb.decay_mode = KnockbackComponent.DecayMode.CURVE
	kb.apply_knockback_force(Vector2(300, -100))
	print("  Knockback active: %s" % kb.is_knocking_back())
	kb.cancel_knockback()
	print("  After cancel:     %s" % kb.is_knocking_back())
	kb.queue_free()
