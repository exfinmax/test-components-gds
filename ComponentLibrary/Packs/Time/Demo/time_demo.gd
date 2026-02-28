extends PackDemo

func _ready():
	pack_name = "Time"
	._ready()

func _populate_demo():
	var t = TimelineSwitchComponent.new()
	t.timeline = ["a","b","c"]
	add_child(t)
	print("Time demo: use t.next() and t.prev() in console to cycle timeline")
