extends PackDemo

func _ready():
	pack_name = "RPG"
	._ready()

func _populate_demo():
    var attr = AttributeSetComponent.new()
    attr.set_attribute("health", 100)
    add_child(attr)
    print("RPG demo: use attr.get_attribute('health') or attr.modify('health',-10) in console.")

