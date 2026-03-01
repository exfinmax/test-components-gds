extends PackDemo

func _ready():
	pack_name = "Roguelike"
	super._ready()

func _populate_demo():
	var wt = WeightedSpawnTableComponent.new()
	wt.add_item("enemy", 70)
	wt.add_item("treasure", 30)
	add_child(wt)
	var btn = Button.new()
	btn.text = "Spawn"
	btn.position = Vector2(20,20)
	btn.pressed.connect(func():
		var item = wt.spawn()
		print("spawned", item)
	)
	add_child(btn)

