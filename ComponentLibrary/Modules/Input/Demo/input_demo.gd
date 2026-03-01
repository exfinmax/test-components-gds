## Input 模块演示 — InputBufferComponent / InputActionSetComponent
extends PackDemo

func _ready():
	pack_name = "Input"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Input Demo ==========")
	_demo_input_buffer()
	_demo_action_set()
	print("========== Input Demo End ==========\n")


func _demo_input_buffer() -> void:
	print("\n--- InputBufferComponent ---")
	var buf := InputBufferComponent.new()
	buf.buffer_window = 0.5     # 500ms 缓冲窗口（测试中足够宽裕）
	buf.max_buffer_size = 8
	add_child(buf)

	buf.action_buffered.connect(func(a): print("  buffered: %s" % a))

	# 模拟输入
	buf.buffer_action(&"jump")
	buf.buffer_action(&"attack")
	buf.buffer_action(&"dash")

	print("  pending=%d (expected 3)" % buf.get_pending_count())
	print("  is_buffered('jump')=%s (expected true)" % buf.is_buffered(&"jump"))

	# 消耗
	var ok1 := buf.consume(&"jump")
	print("  consume('jump')=%s (expected true)" % ok1)
	print("  consume('jump') again=%s (expected false)" % buf.consume(&"jump"))
	print("  pending=%d (expected 2)" % buf.get_pending_count())

	# 连招检测
	buf.clear()
	buf.buffer_action(&"up")
	buf.buffer_action(&"up")
	buf.buffer_action(&"down")
	buf.buffer_action(&"attack")
	var hadoro := buf.has_sequence([&"up", &"down", &"attack"])
	print("  has_sequence [up,down,attack]=%s (expected true)" % hadoro)
	var bad    := buf.has_sequence([&"up", &"dash"])
	print("  has_sequence [up,dash]=%s (expected false)" % bad)

	# get_recent
	var recent := buf.get_recent(3)
	print("  get_recent(3)=%s (expected [up,down,attack])" % str(recent))

	buf.queue_free()


func _demo_action_set() -> void:
	print("\n--- InputActionSetComponent ---")
	var sets := InputActionSetComponent.new()
	add_child(sets)

	sets.set_activated.connect(func(sid): print("  activated: %s" % sid))
	sets.set_deactivated.connect(func(sid): print("  deactivated: %s" % sid))

	sets.define_set(&"gameplay", [&"jump", &"attack", &"dash"])
	sets.define_set(&"menu",     [&"ui_accept", &"ui_cancel", &"ui_up", &"ui_down"])
	sets.define_set(&"dialogue", [&"ui_accept", &"skip"])

	sets.activate_set(&"gameplay")
	sets.activate_set(&"menu")

	print("  is_set_active('gameplay')=%s (expected true)"  % sets.is_set_active(&"gameplay"))
	print("  is_set_active('dialogue')=%s (expected false)" % sets.is_set_active(&"dialogue"))
	print("  is_action_in_active_set('jump')=%s (expected true)"      % sets.is_action_in_active_set(&"jump"))
	print("  is_action_in_active_set('skip')=%s (expected false)"     % sets.is_action_in_active_set(&"skip"))
	print("  get_active_actions=%s" % str(sets.get_active_actions()))

	# 切换到对话模式
	sets.switch_to(&"dialogue")
	print("  after switch_to('dialogue'): active=%s" % str(sets.get_active_sets()))
	print("  is_action_in_active_set('jump')=%s (expected false)" % sets.is_action_in_active_set(&"jump"))
	print("  is_action_in_active_set('skip')=%s (expected true)"  % sets.is_action_in_active_set(&"skip"))

	sets.queue_free()
