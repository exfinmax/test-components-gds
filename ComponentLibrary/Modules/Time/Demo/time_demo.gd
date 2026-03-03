## Time 模块演示 — TimeController / TimelineSwitchComponent
extends PackDemo

func _ready():
	pack_name = "Time"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Time Demo ==========")
	_demo_time_controller()
	print("========== Time Demo End ==========\n")


func _demo_time_controller() -> void:
	print("\n--- TimeController ---")
	var tc: Node = get_node_or_null("/root/TimeController")
	if not tc:
		print("  TimeController 单例未注册！跳过此测试")
		return

	print("  time_scale=%.1f  is_paused=%s" % [tc.time_scale, tc.is_paused])

	# 测试慢播效果
	tc.set_time_scale(0.5)
	print("  after set_time_scale(0.5): engine_ts=%.1f  get_compensation=%.1f" % [
		tc.engine_time_scale, tc.get_compensation_factor()])
	tc.set_time_scale(1.0)
	print("  restored: time_scale=%.1f" % tc.time_scale)

	print("  get_real_delta(0.016) with scale=1.0: %.4f" % tc.get_real_delta(0.016))
	tc.set_time_scale(0.5)
	print("  get_real_delta(0.008) with scale=0.5: %.4f (expected 0.016)" % tc.get_real_delta(0.008))
	tc.set_time_scale(1.0)
