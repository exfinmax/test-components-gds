extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Roguelike"

func _populate_demo():
    var wt = WeightedSpawnTableComponent.new()
    wt.add_item("enemy", 70)
    wt.add_item("treasure", 30)
    add_child(wt)
    var btn = Button.new()
    btn.text = "Spawn"
    btn.rect_position = Vector2(20,20)
    btn.pressed.connect(func():
        var item = wt.spawn()
        print("spawned", item)
    )
    add_child(btn)

