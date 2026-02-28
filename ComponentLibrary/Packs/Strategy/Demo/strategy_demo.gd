extends PackDemo

func _ready():
	pack_name = "Strategy"
	._ready()

func _populate_demo():
    var q = ProductionQueueComponent.new()
    add_child(q)
    q.enqueue("unit", 3)
    print("Strategy demo: queue contains", q.queue_length())

