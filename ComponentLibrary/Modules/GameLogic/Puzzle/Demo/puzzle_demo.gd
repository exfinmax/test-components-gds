extends PackDemo

func _ready():
	pack_name = "Puzzle"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Puzzle Demo ==========")
	var seq := SequenceSwitchComponent.new()
	seq.sequence = [&"red", &"green", &"blue"]
	add_child(seq)

	seq.sequence_progress.connect(func(idx, total): print("  progress %d/%d" % [idx, total]))
	seq.sequence_completed.connect(func(): print("  序列完成！"))
	seq.sequence_failed.connect(func(): print("  错误！序列重置"))

	# 正确顺序
	seq.input_step(&"red")
	seq.input_step(&"green")
	seq.input_step(&"blue")

	# 失败的输入
	print("  输入错误步骤:")
	seq.input_step(&"red")
	seq.input_step(&"blue")  # 应该是 green，触发 failed

	seq.queue_free()
	print("========== Puzzle Demo End ==========\n")
