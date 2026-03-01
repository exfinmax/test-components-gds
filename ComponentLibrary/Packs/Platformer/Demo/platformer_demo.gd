extends PackDemo

func _ready():
	pack_name = "Platformer"
	super._ready()

func _populate_demo():
	# demonstrate CoyoteJumpComponent behaviour via console
	var comp = CoyoteJumpComponent.new()
	add_child(comp)
	comp.jump_buffered.connect(_on_jumped)
	comp.jump_consumed.connect(_on_jumped)
	comp.jump_rejected.connect(_on_jumped)
	print("Platformer demo: component added. 调用 comp.queue_jump(), comp.notify_grounded(true/false) 来测试")

func _on_jumped():
	print("signal fired")
