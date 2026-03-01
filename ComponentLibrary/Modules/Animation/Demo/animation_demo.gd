## Animation 模块演示 — AnimationStateComponent
extends PackDemo

func _ready():
	pack_name = "Animation"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Animation Demo ==========")
	_demo_animation_state()
	print("========== Animation Demo End ==========\n")


func _demo_animation_state() -> void:
	print("\n--- AnimationStateComponent ---")
	var asc := AnimationStateComponent.new()
	# 不绑定 AnimationPlayer，仅测试状态机逻辑
	add_child(asc)

	asc.state_changed.connect(func(old, nw): print("  state: %s → %s" % [old, nw]))
	asc.animation_finished.connect(func(sid): print("  animation_finished: %s" % sid))

	# 注册状态
	asc.register_state(&"idle",   &"idle_anim",   true)
	asc.register_state(&"run",    &"run_anim",     true)
	asc.register_state(&"attack", &"attack_anim",  false)
	asc.register_state(&"die",    &"die_anim",     false)

	print("  has_state 'idle'=%s  has_state 'fly'=%s" % [
		asc.has_state(&"idle"), asc.has_state(&"fly")])

	# 手动切换
	asc.start(&"idle")
	print("  current=%s (expected idle)" % asc.get_current_state())

	asc.transition_to(&"run")
	print("  current=%s (expected run)" % asc.get_current_state())

	asc.transition_to(&"attack")
	print("  current=%s (expected attack)" % asc.get_current_state())

	# 重复切换同状态不触发信号（应只有三次信号）
	asc.transition_to(&"attack")

	# 自动转换（用一个简单的 bool 模拟）
	var is_dead := false
	asc.add_auto_transition(&"attack", &"die", func(): return is_dead)
	is_dead = true
	asc._process(0.0)  # 手动触发一帧检测
	print("  after is_dead=true process: current=%s (expected die)" % asc.get_current_state())

	# 未知状态警告（不崩溃）
	asc.transition_to(&"unknown_state")
	print("  after unknown_state: current=%s (unchanged)" % asc.get_current_state())

	asc.queue_free()
