extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Platformer"

func _populate_demo():
	# demonstrate CoyoteJumpComponent behaviour via console
	var comp = CoyoteJumpComponent.new()
	add_child(comp)
	comp.connect("jump_buffered", Callable(self, "_on_jumped"))
	comp.connect("jump_consumed", Callable(self, "_on_jumped"))
	comp.connect("jump_rejected", Callable(self, "_on_jumped"))
	print("Platformer demo: component added. 调用 comp.queue_jump(), comp.notify_grounded(true/false) 来测试")

func _on_jumped(arg):
	print("signal", arg)
