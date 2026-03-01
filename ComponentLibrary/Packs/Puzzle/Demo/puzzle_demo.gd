extends PackDemo

func _ready():
	pack_name = "Puzzle"
	super._ready()

func _populate_demo():
	var seq = SequenceSwitchComponent.new()
	seq.sequence = [1,2,3]
	add_child(seq)
	print("Puzzle demo: call seq.try_step(value) from console to test sequence")

