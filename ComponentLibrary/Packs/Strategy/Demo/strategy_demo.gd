extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Strategy"

func _populate_demo():
    var q = ProductionQueueComponent.new()
    add_child(q)
    q.enqueue("unit", 3)
    print("Strategy demo: queue contains", q.queue_length())

