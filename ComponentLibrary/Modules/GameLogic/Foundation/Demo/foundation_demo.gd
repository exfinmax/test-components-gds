## Foundation 模块演示 — CooldownComponent / StateFlagComponent
extends PackDemo

func _ready():
	pack_name = "Foundation"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Foundation Demo ==========")
	_demo_cooldown()
	_demo_state_flag()
	print("========== Foundation Demo End ==========\n")


func _demo_cooldown() -> void:
	print("\n--- CooldownComponent ---")
	var cd := CooldownComponent.new()
	add_child(cd)

	# 启动冷却
	cd.start_cooldown(&"attack", 1.5)
	print("  start 'attack' 1.5s  | is_on_cooldown=%s  remaining=%.1fs" % [
		cd.is_on_cooldown(&"attack"), cd.get_remaining(&"attack")])
	print("  is_ready='attack': %s (expected false)" % cd.is_ready(&"attack"))
	print("  progress=%.2f (expected ~0.00)" % cd.get_progress(&"attack"))

	# 多标签并发
	cd.start_cooldown(&"skill_q", 3.0)
	cd.start_cooldown(&"skill_e", 5.0)
	print("  active_tags: %s" % str(cd.get_active_tags()))

	# 强制清除单个
	cd.clear_cooldown(&"skill_q")
	print("  after clear 'skill_q': active=%s" % str(cd.get_active_tags()))

	# 连接信号
	cd.cooldown_ready.connect(func(tag): print("  [signal] cooldown_ready: %s" % tag))
	cd.clear_all()
	print("  after clear_all: count=%d" % cd.get_active_tags().size())

	cd.queue_free()


func _demo_state_flag() -> void:
	print("\n--- StateFlagComponent ---")
	var flags := StateFlagComponent.new()
	add_child(flags)

	# 设置 / 读取
	flags.set_flag(&"is_dead",     false)
	flags.set_flag(&"in_dialogue", true)
	flags.set_flag(&"puzzle_locked", true)
	print("  is_dead=%s  in_dialogue=%s  puzzle_locked=%s" % [
		flags.get_flag(&"is_dead"),
		flags.get_flag(&"in_dialogue"),
		flags.get_flag(&"puzzle_locked")])

	# 信号测试
	flags.flag_changed.connect(func(f, v): print("  [signal] flag_changed: %s=%s" % [f, v]))
	flags.set_flag(&"is_dead", true)  # 触发信号

	# 移除
	flags.remove_flag(&"in_dialogue")
	print("  has 'in_dialogue': %s (expected false)" % flags.has_flag(&"in_dialogue"))
	print("  all_flags: %s" % str(flags.get_all_flags()))

	flags.clear_flags()
	print("  after clear: count=%d" % flags.get_all_flags().size())

	flags.queue_free()
