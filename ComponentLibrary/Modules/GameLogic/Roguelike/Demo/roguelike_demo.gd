extends PackDemo

func _ready():
	pack_name = "Roguelike"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Roguelike Demo ==========")
	var wt := WeightedSpawnTableComponent.new()
	wt.entries = [
		{"id": &"enemy",   "weight": 70.0, "payload": {"hp": 20}},
		{"id": &"treasure","weight": 20.0, "payload": {"gold": 10}},
		{"id": &"nothing", "weight": 10.0, "payload": {}},
	]
	add_child(wt)

	wt.rolled.connect(func(id, payload): print("  rolled: %s %s" % [id, str(payload)]))
	wt.roll_failed.connect(func(): print("  roll_failed"))

	print("  卷帱2次:")
	for i in 2:
		wt.roll_entry()

	# 小种子测试确定性
	wt.set_seed(42)
	var r1 := wt.roll_entry()
	wt.set_seed(42)
	var r2 := wt.roll_entry()
	print("  same_seed same_result: %s (expected true)" % str(r1.get("id") == r2.get("id")))

	wt.queue_free()
	print("========== Roguelike Demo End ==========\n")
