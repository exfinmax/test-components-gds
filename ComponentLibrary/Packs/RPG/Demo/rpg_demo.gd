extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "RPG"

func _populate_demo():
    var attr = AttributeSetComponent.new()
    attr.set_attribute("health", 100)
    add_child(attr)
    print("RPG demo: use attr.get_attribute('health') or attr.modify('health',-10) in console.")

