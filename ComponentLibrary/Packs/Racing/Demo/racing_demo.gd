extends PackDemo

func _ready():
	pack_name = "Racing"
	super._ready()

func _populate_demo():
	print("Racing demo: place checkpoints or lap counters in scene to observe components.")
