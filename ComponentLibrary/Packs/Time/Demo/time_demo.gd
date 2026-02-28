extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Time"

func _populate_demo():
    var t = TimelineSwitchComponent.new()
    t.timeline = ["a","b","c"]
    add_child(t)
    print("Time demo: use t.next() and t.prev() in console to cycle timeline")
